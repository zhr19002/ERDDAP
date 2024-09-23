% 
% Identify and flag buoy meteorology data outliers
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 

clc; clear;
buoy = 'ARTG'; % {'ARTG','CLIS1','CLIS2','EXRX','WLIS'}
metVars = {'windSpd_Kts','windSpd_Max','fiveSecAvg_Max','windDir_M', ...
           'airTemp_Avg','relHumid_Avg','baroPress_Avg','dewPT_Avg'};

% Fixed parameters
cols_old = {'timestamp','windSpdKts','windSpdMax','windGust5sec', ...
            'windDirM','airDegC','relHumid','baroPress','dewDegC'};
cols_new = [{'TmStamp'}, metVars];

% Read meteorology QAQC parameters
QAQC = readtable('QAQC_Para_Met.csv', ReadRowNames=true);

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','provData','PortNumber',5432);

% tbldata = sqlfind(conn,"")

% Extract tables from PostgreSQL
switch buoy
    case 'ARTG'
        dT = sqlread(conn, '"artg_wx"');
        dT = renamevars(dT, cols_old, cols_new);
    case 'CLIS1'
        dT = sqlread(conn, '"clis_wx"');
        cols_old{4} = 'windGust3sec';
        dT = renamevars(dT, cols_old, cols_new);
    case 'CLIS2'
        dT = sqlread(conn, '"CLIS_pb1_metDat"');
        dT = renamevars(dT, {'WindSpd','maxWindSpd','WindDir','AirTemp', ...
             'RelHumidity','BaroPress','DewPt'}, [metVars(1:2),metVars(4:8)]);
        dT.TmStamp.TimeZone = 'UTC';
        dT.('fiveSecAvg_Max')(:) = NaN;
    case 'EXRX'
        dT = sqlread(conn, '"exrx_wx"');
        dT = renamevars(dT, cols_old, cols_new);
    case 'WLIS'
        dT = sqlread(conn, '"wlis_wx"');
        dT = renamevars(dT, cols_old, cols_new);
end
% Filter TmStamp outliers
% dT(dT.TmStamp <= datetime('01-Jan-1904','TimeZone','UTC'), :) = [];
dT = sortrows(dT, 'TmStamp');
close(conn);

% Add specific columns
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
         'DatabaseName','buoyQAQC','PortNumber',5432);
dbname0 = strcat('"',[buoy '_Met_QAQC'],'"');
dT0 = sqlread(connQ, dbname0);
dT.depth(:) = dT0.depth(1);
dT.latitude(:) = dT0.latitude(1);
dT.longitude(:) = dT0.longitude(1);
dT.station(:) = dT0.station(1);
dT.mooring_site_desc(:) = dT0.mooring_site_desc(1);
close(connQ);

% Create the "MetQAQC" table
MetQAQC = table();
MetQAQC.TmStamp = dT.TmStamp;
for av = metVars
    % Clean meteorology data
    dT.(av{1})(dT.(av{1}) < -1000) = NaN;
    % Run QAQC tests
    [dQ, dC] = CheckMetWaveQAQC(dT, QAQC, av{1});
    MetQAQC.(av{1}) = dT.(av{1});
    MetQAQC.([av{1} '_Q']) = dQ;
    MetQAQC.([av{1} '_FailedCount']) = dC;
end
MetQAQC.depth = dT.depth;
MetQAQC.latitude = dT.latitude;
MetQAQC.longitude = dT.longitude;
MetQAQC.station = dT.station;
MetQAQC.mooring_site_desc = dT.mooring_site_desc;

% Save the updated "MetQAQC" table to a CSV file
writetable(MetQAQC, [buoy '_Met_QAQC.csv']);
fprintf('%s   %s\n', min(dT.TmStamp), max(dT.TmStamp));

%%
% Read the CSV file into a table
tbl = [buoy '_Met_QAQC'];
opts = detectImportOptions([tbl '.csv']);
opts = setvaropts(opts,'TmStamp','InputFormat','dd-MMM-yyyy HH:mm:ss');
MetQAQC = readtable([tbl '.csv'], opts);

% Quoted to preserve case sensitivity
tblName = strcat('"',tbl,'"');
colNames = strcat('"',MetQAQC.Properties.VariableNames,'"');
MetQAQC.Properties.VariableNames = colNames;

% Define data type for each column
vNames = cell(1, 3*length(metVars));
for i = 1:length(metVars)
    vNames{3*i-2} = sprintf('"%s" %s',metVars{i},'FLOAT');
    vNames{3*i-1} = sprintf('"%s_Q" %s',metVars{i},'INTEGER');
    vNames{3*i} = sprintf('"%s_FailedCount" %s',metVars{i},'INTEGER');
end
query = strjoin(vNames, ', ');
query = ['CREATE TABLE ' tblName ' (' ...
         '"TmStamp" TIMESTAMP, ', query, ... 
         ', "depth" FLOAT, "latitude" FLOAT, "longitude" FLOAT, ' ...
         '"station" VARCHAR, "mooring_site_desc" VARCHAR);'];

% Write the table to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);
execute(connQ, query);
try
    batchSize = 10000;
    for i = 1:ceil(height(MetQAQC)/batchSize)
        startRow = (i-1)*batchSize + 1;
        endRow = min(i*batchSize, height(MetQAQC));
        batchData = MetQAQC(startRow:endRow, :);
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