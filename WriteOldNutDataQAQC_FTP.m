% 
% Identify and flag buoy nutrients data outliers
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 

clc; clear;
buoy = 'WLIS'; year = 2008;
% d2 = load('wlis2002.mat'); d2 = d2.wlis_wq2002;
% d2.('ysiBtm_fluoRFU')(:) = NaN; d2.('ysiSfc_fluoRFU')(:) = NaN;
% d3 = load('wlis2003_wq.mat'); d3 = d3.wlis2003_wq;
% d3.('ysiBtm_fluoRFU')(:) = NaN; d3.('ysiSfc_fluoRFU')(:) = NaN;
% d4 = load('wlis2004_wq.mat'); d4 = d4.wlis2ysi2004;
% d4.('btm_fluoRFU')(:) = NaN;
% d5 = load('wlis2005_wq.mat'); d5 = d5.wlis2ysi2005;
% d5.('btm_fluoRFU')(:) = NaN;
% d6 = load('wlis2006_wq.mat');
% d7 = load('wlis2007_wq.mat');
d8 = load('wlis2008_wq.mat'); d8.btmYSI_2008.('btm_CHLmgL')(:) = NaN;

% Fixed parameters
avars = {'TSS','CHLA'};
cols_new = [{'TmStamp','depth'}, avars];
buoyStn = struct('ARTG','E1','CLIS','I2','EXRX','A4','WLIS','C1');
if year < 2004
    locs = {'btm','sfc'};
    cols_btm = {'TmStamp','ysiBtm_m','ysiBtm_NTU','ysiBtm_fluoRFU'};
    cols_sfc = {'TmStamp','ysiSfc_m','ysiSfc_NTU','ysiSfc_fluoRFU'};
elseif year < 2006
    locs = {'btm','mid','sfc'};
    cols_btm = {'EST','btm_depthM','btm_turbNTU','btm_fluoRFU'};
    cols_mid = {'EST','mid_depthM','mid_turbNTU','mid_fluoRFU'};
    cols_sfc = {'EST','sfc_depthM','sfc_turbNTU','sfc_fluoRFU'};
else
    locs = {'btm','mid','sfc'};
    cols_btm = {'EST','btm_depthM','btm_turbNTU','btm_CHLmgL'};
    cols_mid = {'EST','mid_depthM','mid_turbNTU','mid_CHLmgL'};
    cols_sfc = {'EST','sfc_depthM','sfc_turbNTU','sfc_CHLmgL'};
end

% Write QAQCed buoy files
for loc = locs
    switch buoy
        case 'WLIS'
            % Preprocess the mat file
            % dT = d5;
            % dT = d6.([loc{1} 'YSI_2006']);
            % dT = d7.([loc{1} 'YSI_2007']);
            dT = d8.([loc{1} 'YSI_2008']);
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
    
    % Create the "NutQAQC" table
    NutQAQC = table();
    NutQAQC.TmStamp = dT.TmStamp;
    NutQAQC.depth = dT.depth;
    for av = avars
        NutQAQC.(av{1}) = dT.(av{1});
        % Read station QAQC parameters
        if ismember(av{1}, {'PAR','CHLA'})
            QAQC = load(['QAQC_' buoyStn.(buoy) '_WQ.mat']);
        else
            QAQC = load(['QAQC_' buoyStn.(buoy) '_Nutrient.mat']);
        end
        QAQC = QAQC.QAQC;
        % Run QAQC tests
        [dQ1, dC1] = CheckNutDataQAQC(NutQAQC, loc{1}, QAQC, av{1});
        NutQAQC.([av{1} '_Q']) = dQ1;
        NutQAQC.([av{1} '_FailedCount']) = dC1;
        % Add calibrated columns
        NutQAQC.(['Adjusted_' av{1}]) = ImplementCalibration(dT.(av{1}), dT.TmStamp, buoy, av{1});
        [dQ2, dC2] = CheckNutDataQAQC(NutQAQC, loc{1}, QAQC, ['Adjusted_' av{1}]);
        NutQAQC.(['Adjusted_' av{1} '_Q']) = dQ2;
        NutQAQC.(['Adjusted_' av{1} '_FailedCount']) = dC2;
    end
    
    % Add specific columns
    username = 'lisicos';
    password = 'vncq489';
    connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
         'DatabaseName','buoyQAQC','PortNumber',5432);
    dTQ = sqlread(connQ, strcat('"',[buoy '_' loc{1} '_NutrQAQC'],'"'));
    NutQAQC.latitude(:) = dTQ.latitude(1);
    NutQAQC.longitude(:) = dTQ.longitude(1);
    NutQAQC.station(:) = dTQ.station(1);
    NutQAQC.mooring_site_desc(:) = dTQ.mooring_site_desc(1);
    close(connQ);
    
    % Save the updated "BuoyQAQC" table to a CSV file
    NutQAQC.TmStamp.Format = 'dd-MMM-yyyy HH:mm:ss';
    NutQAQC.TmStamp.TimeZone = 'America/New_York';
    writetable(NutQAQC, [buoy '_' loc{1} '_NutrQAQC.csv']);
    fprintf('%s   %s   %s\n', min(NutQAQC.TmStamp), max(NutQAQC.TmStamp), NutQAQC.TmStamp.TimeZone);
end

%%
% Read the CSV file into a table
num = 1;
tbl = [buoy '_' locs{num} '_NutrQAQC'];
opts = detectImportOptions([tbl '.csv']);
opts = setvaropts(opts,'TmStamp','InputFormat','dd-MMM-yyyy HH:mm:ss');
NutQAQC = readtable([tbl '.csv'], opts);

% Quoted to preserve case sensitivity
tblName = strcat('"',tbl,'"');
colNames = strcat('"',NutQAQC.Properties.VariableNames,'"');
NutQAQC.Properties.VariableNames = colNames;

% Write the table to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);
try
    batchSize = 10000;
    for i = 1:ceil(height(NutQAQC)/batchSize)
        startRow = (i-1)*batchSize + 1;
        endRow = min(i*batchSize, height(NutQAQC));
        batchData = NutQAQC(startRow:endRow, :);
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