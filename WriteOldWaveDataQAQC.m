% 
% Identify and flag buoy wave data outliers
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 

clc; clear;
buoy = 'CLIS'; % {'CLIS','WLIS'}
waveVars = {'Hsig_m','Hmax_m','Tdom_s','Tavg_s','waveDir','meanDir'};

% Fixed parameters
cols = {'TmStamp','Hsig','Hmax','Tsig','Tavg','waveDir','meanDir'};

% Read wave QAQC parameters
QAQC = readtable('QAQC_Para_Wave.csv', ReadRowNames=true);

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','provData','PortNumber',5432);

% tbldata = sqlfind(conn,"")

% Extract tables from PostgreSQL
switch buoy
    case 'CLIS'
        dT1 = sqlread(conn, '"clis_wv"');
        dT1 = renamevars(dT1,'timestamp','TmStamp');
        dT1.('waveDir')(:) = NaN;
        dT2 = sqlread(conn, '"CLIS_pb3_WaveStat"');
        dT2.TmStamp.TimeZone = 'UTC';
        dT2.('waveDir')(:) = NaN;
        dT = [dT1(:,cols); dT2(:,cols)];
        dT = renamevars(dT, cols(2:7), waveVars);
    case 'WLIS'
        dT = sqlread(conn, '"wlis_wv"');
        dT = renamevars(dT, {'timestamp','Hsig','domPD','avgPD'}, ...
             {'TmStamp','Hsig_m','Tdom_s','Tavg_s'});
        dT.('Hmax_m')(:) = NaN;
        dT.('waveDir')(:) = NaN;
        dT.('meanDir')(:) = NaN;
end
% Filter TmStamp outliers
dT(dT.TmStamp <= datetime('01-Jan-1904','TimeZone','UTC'), :) = [];
dT = sortrows(dT, 'TmStamp');
close(conn);

% Add specific columns
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
         'DatabaseName','buoyQAQC','PortNumber',5432);
dbname0 = strcat('"',[buoy '_Wave_QAQC'],'"');
dT0 = sqlread(connQ, dbname0);
dT.depth(:) = dT0.depth(1);
dT.latitude(:) = dT0.latitude(1);
dT.longitude(:) = dT0.longitude(1);
dT.station(:) = dT0.station(1);
dT.mooring_site_desc(:) = dT0.mooring_site_desc(1);
close(connQ);

% Create the "waveQAQC" table
waveQAQC = table();
waveQAQC.TmStamp = dT.TmStamp;
for av = waveVars
    % Run QAQC tests
    [dQ, dC] = CheckMetWaveQAQC(dT, QAQC, av{1});
    waveQAQC.(av{1}) = dT.(av{1});
    waveQAQC.([av{1} '_Q']) = dQ;
    waveQAQC.([av{1} '_FailedCount']) = dC;
end
waveQAQC.depth = dT.depth;
waveQAQC.latitude = dT.latitude;
waveQAQC.longitude = dT.longitude;
waveQAQC.station = dT.station;
waveQAQC.mooring_site_desc = dT.mooring_site_desc;

% Save the updated "waveQAQC" table to a CSV file
writetable(waveQAQC, [buoy '_Wave_QAQC.csv']);
fprintf('%s   %s\n', min(dT.TmStamp), max(dT.TmStamp));

%%
% Read the CSV file into a table
tbl = [buoy '_Wave_QAQC'];
opts = detectImportOptions([tbl '.csv']);
opts = setvaropts(opts,'TmStamp','InputFormat','dd-MMM-yyyy HH:mm:ss');
waveQAQC = readtable([tbl '.csv'], opts);

% Quoted to preserve case sensitivity
tblName = strcat('"',tbl,'"');
colNames = strcat('"',waveQAQC.Properties.VariableNames,'"');
waveQAQC.Properties.VariableNames = colNames;

% Define data type for each column
vNames = cell(1, 3*length(waveVars));
for i = 1:length(waveVars)
    vNames{3*i-2} = sprintf('"%s" %s',waveVars{i},'FLOAT');
    vNames{3*i-1} = sprintf('"%s_Q" %s',waveVars{i},'INTEGER');
    vNames{3*i} = sprintf('"%s_FailedCount" %s',waveVars{i},'INTEGER');
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
    for i = 1:ceil(height(waveQAQC)/batchSize)
        startRow = (i-1)*batchSize + 1;
        endRow = min(i*batchSize, height(waveQAQC));
        batchData = waveQAQC(startRow:endRow, :);
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