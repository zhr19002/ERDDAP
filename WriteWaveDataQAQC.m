% 
% Identify and flag buoy wave data outliers
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 
% Calls CheckMetWaveQAQC.m
% Calls WriteWaveNETCDF.m
% 

clc; clear;
buoy = 'CLIS'; % {'CLIS','EXRX','WLIS'}
waveVars = {'Hsig_m','Hmax_m','Tdom_s','Tavg_s','waveDir','meanDir'};

% Read wave QAQC parameters
QAQC = readtable('QAQC_Para_Wave.csv', ReadRowNames=true);

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','provLNDB','PortNumber',5432);

% tbldata = sqlfind(conn,"")

% Extract tables from PostgreSQL
switch buoy
    case 'CLIS'
        dT = sqlread(conn, '"clis_cr1xPB4_waveDat"');
        % Covert string values to numeric values
        for av = waveVars
            dT.(av{1}) = str2double(dT.(av{1}));
        end
    case 'EXRX'
        dT = sqlread(conn, '"EXRX_pb3_svs603hr"');
    case 'WLIS'
        dT = sqlread(conn, '"WLIS_pb3_svs603HR"');
end

dT = sortrows(dT, 'TmStamp');
close(conn);

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

% Add specific columns
waveQAQC.depth(:) = mode(dT.depth);
waveQAQC.latitude(:) = mode(dT.latitude);
waveQAQC.longitude(:) = mode(dT.longitude);
waveQAQC.station(:) = mode(categorical(dT.station));
waveQAQC.mooring_site_desc(:) = mode(categorical(dT.mooring_site_desc));

% Save the updated "waveQAQC" table to a CSV file
writetable(waveQAQC, [buoy '_Wave_QAQC.csv']);
fprintf('%s   %s   %s\n', min(waveQAQC.TmStamp), max(waveQAQC.TmStamp), waveQAQC.TmStamp.TimeZone);

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
% % Drop the table from PostgreSQL
% execute(connQ, strcat("DROP TABLE ",tblName));

close(connQ);

%%
opts = detectImportOptions([buoy '_Wave_QAQC.csv']);
opts = setvaropts(opts,'TmStamp','InputFormat','dd-MMM-yyyy HH:mm:ss');
d = readtable([buoy '_Wave_QAQC.csv'], opts);

% Create the "waveQAQC" struct
waveQAQC = struct();
waveQAQC.time = d.TmStamp;
for av = waveVars
    waveQAQC.(av{1}).data = d.(av{1});
    waveQAQC.(av{1}).QAQC = d.([av{1} '_Q']);
    waveQAQC.(av{1}).FailedCount = d.([av{1} '_FailedCount']);
end

% Save the updated "waveQAQC" struct to a .mat file
save(['Buoy_' buoy '_Wave_QAQC.mat'], 'waveQAQC');

%%
% Save all the data plotted in a structure that can be exported to NETCDF
latlon = [d.latitude(1), d.longitude(1)];
stnDep = d.depth(1);
WriteWaveNETCDF(buoy, latlon, stnDep, waveQAQC);