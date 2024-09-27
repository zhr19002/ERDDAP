% 
% Identify and flag buoy climatology data outliers through 5 QAQC tests
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 

clc; clear;

buoy = 'ARTG'; locs = {'btm1','btm2'};
% buoy = 'CLIS'; locs = {'sfc'};
% buoy = 'EXRX'; locs = {'btm1','btm2','mid','sfc'};
% buoy = 'WLIS'; locs = {'btm1','btm2','mid','sfc'};

% Fixed parameters
avars = {'T','S','DO','P','C','pH','rho','DOsat'};
cols_old = {'timestamp','degC','sal','DOconc','decibars','cond_Spm'};
cols_new = [{'TmStamp'}, avars(1:5)];

% Read station group QAQC parameters
switch buoy
    case 'CLIS'
        QAQC = load('QAQC_Para_CStations.mat'); 
    otherwise
        QAQC = load('QAQC_Para_WStations.mat');
end
QAQC = QAQC.QAQC;

% Write QAQCed buoy files
for loc = locs
    % Connect to PostgreSQL
    username = 'lisicos';
    password = 'vncq489';
    conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
        'DatabaseName','provData','PortNumber',5432);
    
    % tbldata = sqlfind(conn,"")
    
    % Extract tables from PostgreSQL
    switch buoy
        case 'ARTG'
            dbname = strcat('"',['artg_sbe_' loc{1}],'"');
            dT = sqlread(conn, dbname);
            cols_old{6} = 'cond';
            dT = renamevars(dT, cols_old, cols_new);
            if strcmp(loc{1}, 'btm1')
                dT = dT(dT.TmStamp >= datetime('01-Jan-2016 00:00:00','TimeZone','UTC'), :);
                dT = dT(dT.TmStamp <= datetime('30-Jan-2016 23:59:59','TimeZone','UTC'), :);
            else
                dT = dT(dT.TmStamp >= datetime('01-Jan-2018 00:00:00','TimeZone','UTC'), :);
            end
        case 'CLIS'
            dT3 = sqlread(conn, '"CLIS_pb2_sbe37Sfc"');
            dT3.TmStamp.TimeZone = 'UTC';
            dT3 = renamevars(dT3, {'degC','psu','mg/L','dBars','S/m'}, avars(1:5));
            dT2 = sqlread(conn, '"clis_sbe37sfc"');
            dT2 = renamevars(dT2, cols_old, cols_new);
            dT1 = sqlread(conn, '"clis_ysi_sfc"');
            cols_old{5} = 'meters'; cols_old{6} = 'cond';
            dT1 = renamevars(dT1, cols_old, cols_new);
            dT = [dT1(:,cols_new); dT2(:,cols_new); dT3(:,cols_new)];
        otherwise
            dbname = strcat('"',[lower(buoy) '_sbe37' loc{1}],'"');
            dT = sqlread(conn, dbname);
            dT = renamevars(dT, cols_old, cols_new);
    end
    % Filter TmStamp outliers
    dT(dT.TmStamp <= datetime('01-Jan-1904','TimeZone','UTC'), :) = [];
    dT = sortrows(dT, 'TmStamp');
    close(conn);
    
    % Calculate rho
    dT.('rho') = real(sw_dens(dT.S,dT.T,dT.P)-1000);
    % Calculate DOsat (convert to mg/L)
    dT.('DOsat') = 100*dT.DO ./ (sw_satO2(dT.S,dT.T)*1.33);
    % Replace DOsat values greater than 1000 with NaN
    dT.('DOsat')(dT.('DOsat') > 1000) = NaN;
    % Add the pH column
    dT.('pH')(:) = NaN;
    
    % Add specific columns
    connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
         'DatabaseName','buoyQAQC','PortNumber',5432);
    dbname0 = strcat('"',[buoy '_' loc{1} '_QAQC'],'"');
    dT0 = sqlread(connQ, dbname0);
    dT.latitude(:) = dT0.latitude(1);
    dT.longitude(:) = dT0.longitude(1);
    dT.station(:) = dT0.station(1);
    dT.mooring_site_desc(:) = dT0.mooring_site_desc(1);
    close(connQ);
    
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
    BuoyQAQC.latitude = d.latitude;
    BuoyQAQC.longitude = d.longitude;
    BuoyQAQC.station = d.station;
    BuoyQAQC.mooring_site_desc = d.mooring_site_desc;
    
    % Save the updated "BuoyQAQC" table to a CSV file
    writetable(BuoyQAQC, [buoy '_' loc{1} '_QAQC.csv']);
    fprintf('%s   %s\n', min(d.TmStamp), max(d.TmStamp));
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