% 
% Identify and flag buoy climatology data outliers through 5 QAQC tests
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 
% Calls sw_dens.m
% Calls sw_satO2.m
% Calls CleanBuoyData.m
% Calls CheckBuoyDataQAQC.m
% Calls WriteBuoyNETCDF.m
% 

clc; clear;

buoy = 'ARTG'; locs = {'btm1','btm2','sfc'};
% buoy = 'CLIS'; locs = {'btm','sfc'};
% buoy = 'EXRX'; locs = {'btm2','mid','sfc'};
% buoy = 'WLIS'; locs = {'btm1','btm2','mid','sfc'};

% Fixed parameters
avars = {'T','S','DO','P','C','pH','rho','DOsat'};

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
    % Connect to PostgreSQL
    username = 'lisicos';
    password = 'vncq489';
    conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
        'DatabaseName','provLNDB','PortNumber',5432);
    
    % tbldata = sqlfind(conn,"")
    
    % Extract tables from PostgreSQL
    switch buoy
        case 'CLIS'
            if strcmp(loc{1}, 'btm')
                dT1 = sqlread(conn, '"CLIS_pb2_sbe37btm"');
                dT2 = sqlread(conn, '"clis_cr1xPB4_sbe37Btm"');
                dT = [dT1(:,:); dT2(:,:)];
            else
                dT = sqlread(conn, '"clis_cr1xPB4_sbe37Sfc"');
            end
        otherwise
            dbname = strcat('"',[buoy '_pb2_sbe37' loc{1}],'"');
            dT = sqlread(conn, dbname);
    end
    dT = renamevars(dT, {'degC','psu','mg/L','dBars','S/m'}, avars(1:5));
    dT = sortrows(dT, 'TmStamp');
    close(conn);
    
    % Calculate rho
    dT.('rho') = real(sw_dens(dT.S,dT.T,dT.P)-1000);
    % Calculate DOsat (convert to mg/L)
    dT.('DOsat') = 100*dT.DO ./ (sw_satO2(dT.S,dT.T)*1.33);
    % Replace DOsat values greater than 1000 with NaN
    dT.('DOsat')(dT.('DOsat') > 1000) = NaN;
    
    % Add the pH column
    switch strcmp([buoy '_' loc{1}], 'ARTG_btm1')
        case 0
            dT.('pH')(:) = NaN;
        case 1
            dT.('pH')(:) = NaN;
            d0 = load('artg_sbe37_2013-2021_tablesrev.mat'); 
            d0 = d0.d.artgbtm2_21; d0 = sortrows(d0,'EST');
            dT.('pH')(year(dT.TmStamp)==2021) = [d0.pH; d0.pH(end)];
    end
    
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
    BuoyQAQC.latitude(:) = mode(dT.latitude);
    BuoyQAQC.longitude(:) = mode(dT.longitude);
    BuoyQAQC.station(:) = mode(categorical(dT.station));
    BuoyQAQC.mooring_site_desc(:) = mode(categorical(dT.mooring_site_desc));
    
    % Save the updated "BuoyQAQC" table to a CSV file
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

% Define data type for each column
vNames = cell(1, 3*length(avars));
for i = 1:length(avars)
    vNames{3*i-2} = sprintf('"%s_data" %s',avars{i},'FLOAT');
    vNames{3*i-1} = sprintf('"%s_Q" %s',avars{i},'INTEGER');
    vNames{3*i} = sprintf('"%s_FailedCount" %s',avars{i},'INTEGER');
end
query = strjoin(vNames, ', ');
query = ['CREATE TABLE ' tblName ' (' ...
         '"TmStamp" TIMESTAMP, "depth" FLOAT, ', query, ... 
         ', "latitude" FLOAT, "longitude" FLOAT, ' ...
         '"station" VARCHAR, "mooring_site_desc" VARCHAR);'];

% Write the table to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);
execute(connQ, query);
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
% % Drop the table from PostgreSQL
% execute(connQ, strcat("DROP TABLE ",tblName));

close(connQ);

%%
% Create the "BuoyQAQC" struct
BuoyQAQC = struct();
for loc = locs
    opts = detectImportOptions([buoy '_' loc{1} '_QAQC.csv']);
    opts = setvaropts(opts,'TmStamp','InputFormat','dd-MMM-yyyy HH:mm:ss');
    d = readtable([buoy '_' loc{1} '_QAQC.csv'], opts);
    BuoyQAQC.(loc{1}).time = d.TmStamp;
    BuoyQAQC.(loc{1}).depth = d.depth;
    for av = avars
        BuoyQAQC.(loc{1}).(av{1}).data = d.([av{1} '_data']);
        BuoyQAQC.(loc{1}).(av{1}).QAQC = d.([av{1} '_Q']);
        BuoyQAQC.(loc{1}).(av{1}).FailedCount = d.([av{1} '_FailedCount']);
    end
end

% Save the updated "BuoyQAQC" struct to a .mat file
save(['Buoy_' buoy '_QAQC.mat'], 'BuoyQAQC');

%%
% Save all the data plotted in a structure that can be exported to NETCDF
latlon = [d.latitude(1), d.longitude(1)];
for loc = locs
    stnDep = max(BuoyQAQC.(loc{1}).depth);
    WriteBuoyNETCDF(buoy, loc{1}, latlon, stnDep, BuoyQAQC.(loc{1}));
end