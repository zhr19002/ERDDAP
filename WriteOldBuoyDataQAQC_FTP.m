% 
% Identify and flag buoy climatology data outliers through 5 QAQC tests
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 

clc; clear;
buoy = 'WLIS'; year = 2006;
% d0 = load('wlis2000.mat'); d0 = d0.wlis_wq2000;
% d1 = load('wlis2001.mat'); d1 = d1.wlis_wq2001;
% d2 = load('wlis2002.mat'); d2 = d2.wlis_wq2002;
% d3 = load('wlis2003_wq.mat'); d3 = d3.wlis2003_wq;
% d4 = load('wlis2004_wq.mat'); d4 = d4.wlis2ysi2004;
% d5 = load('wlis2005_wq.mat'); d5 = d5.wlis2ysi2005;
d6 = load('wlis2006_wq.mat');

% Fixed parameters
avars = {'T','S','DO','P','C','pH','rho','DOsat'};
cols_new = [{'TmStamp'}, avars(1:5)];
if year < 2004
    locs = {'btm1','sfc'};
    cols_btm = {'TmStamp','ysiBtm_degC','ysiBtm_psu','ysiBtm_DOmgL','ysiBtm_m','ysiBtm_mSm'};
    cols_sfc = {'TmStamp','ysiSfc_degC','ysiSfc_psu','ysiSfc_DOmgL','ysiSfc_m','ysiSfc_mSm'};
else
    locs = {'btm1','mid','sfc'};
    cols_btm = {'EST','btm_degC','btm_sal','btm_DOmgL','btm_depthM','btm_CONDmScm'};
    cols_mid = {'EST','mid_degC','mid_sal','mid_DOmgL','mid_depthM','mid_CONDmScm'};
    cols_sfc = {'EST','sfc_degC','sfc_sal','sfc_DOmgL','sfc_depthM','sfc_CONDmScm'};
end

% Read station group QAQC parameters
switch buoy
    case 'ARTG'
        QAQC = load('QAQC_E1_WQ.mat');
    case 'EXRX'
        QAQC = load('QAQC_A4_WQ.mat');
    case 'WLIS'
        QAQC = load('QAQC_C1_WQ.mat');
    otherwise
        QAQC = load('QAQC_I2_WQ.mat');
end
QAQC = QAQC.QAQC;

% Write QAQCed buoy files
for loc = locs
    switch buoy
        case 'WLIS'
            % Preprocess the mat file
            % dT = d5;
            location = loc{1};
            dT = d6.([location(1:3) 'YSI_2006']);
            if contains(loc{1}, 'btm')
                dT = renamevars(dT, cols_btm, cols_new);
            elseif contains(loc{1}, 'mid')
                dT = renamevars(dT, cols_mid, cols_new);
            else
                dT = renamevars(dT, cols_sfc, cols_new);
            end
            dT = dT(:,cols_new);
    end
    dT = sortrows(dT, 'TmStamp');
    
    % Calculate rho
    dT.('rho') = real(sw_dens(dT.S,dT.T,dT.P)-1000);
    % Calculate DOsat (convert to mg/L)
    dT.('DOsat') = 100*dT.DO ./ (sw_satO2(dT.S,dT.T)*1.33);
    % Replace DOsat values greater than 1000 with NaN
    dT.('DOsat')(dT.('DOsat') > 1000) = NaN;
    % Add the pH column
    dT.('pH')(:) = NaN;
    
    % Clean buoy data
    d = CleanBuoyData(dT, avars);
    
    % Create the "BuoyQAQC" table
    BuoyQAQC = table();
    BuoyQAQC.TmStamp = d.TmStamp;
    BuoyQAQC.depth = d.P;
    for av = avars
        % Run QAQC tests
        [dQ, dC] = CheckBuoyDataQAQC(d, loc{1}, QAQC, av{1});
        BuoyQAQC.([av{1} '_data']) = d.(av{1});
        BuoyQAQC.([av{1} '_Q']) = dQ;
        BuoyQAQC.([av{1} '_FailedCount']) = dC;
    end
    
    % Add specific columns
    username = 'lisicos';
    password = 'vncq489';
    connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
         'DatabaseName','buoyQAQC','PortNumber',5432);
    dTQ = sqlread(connQ, strcat('"',[buoy '_' loc{1} '_QAQC'],'"'));
    BuoyQAQC.latitude(:) = dTQ.latitude(1);
    BuoyQAQC.longitude(:) = dTQ.longitude(1);
    BuoyQAQC.station(:) = dTQ.station(1);
    BuoyQAQC.mooring_site_desc(:) = dTQ.mooring_site_desc(1);
    close(connQ);
    
    % Save the updated "BuoyQAQC" table to a CSV file
    BuoyQAQC.TmStamp.Format = 'dd-MMM-yyyy HH:mm:ss';
    BuoyQAQC.TmStamp.TimeZone = 'America/New_York';
    writetable(BuoyQAQC, [buoy '_' loc{1} '_QAQC.csv']);
    fprintf('%s   %s   %s\n', min(BuoyQAQC.TmStamp), max(BuoyQAQC.TmStamp), BuoyQAQC.TmStamp.TimeZone);
end

%%
% Read the CSV file into a table
num = 1;
tbl = [buoy '_' locs{num} '_QAQC'];
opts = detectImportOptions([tbl '.csv']);
opts = setvaropts(opts,'TmStamp','InputFormat','dd-MMM-yyyy HH:mm:ss');
BuoyQAQC = readtable([tbl '.csv'], opts);

% Quoted to preserve case sensitivity
tblName = strcat('"',tbl,'"');
colNames = strcat('"',BuoyQAQC.Properties.VariableNames,'"');
BuoyQAQC.Properties.VariableNames = colNames;

% Write the table to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);
try
    batchSize = 10000;
    for i = 1:ceil(height(BuoyQAQC)/batchSize)
        startRow = (i-1)*batchSize + 1;
        endRow = min(i*batchSize, height(BuoyQAQC));
        batchData = BuoyQAQC(startRow:endRow, :);
        % Write the batch to PostgreSQL
        sqlwrite(connQ, tblName, batchData);
        disp(['Row ' num2str(startRow) '-' num2str(endRow) ' written to PostgreSQL successfully.']);
    end
catch ME
    disp(ME.message);
end

% % Check the table in PostgreSQL
% tbldata = sqlfind(connQ, "");
% dT = sqlread(connQ, tblName);

close(connQ);