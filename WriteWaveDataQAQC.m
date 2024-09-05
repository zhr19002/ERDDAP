% 
% Identify and flag buoy wave data outliers
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 
% Calls ImplementJumpLimTest.m
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
        dbname = '"clis_cr1xPB4_waveDat"';
        dT = sqlread(conn, dbname);
        % Covert string values to numeric values
        for av = waveVars
            dT.(av{1}) = str2double(dT.(av{1}));
        end
    case 'EXRX'
        dbname = '"EXRX_pb3_svs603hr"';
        dT = sqlread(conn, dbname);
    case 'WLIS'
        dbname = '"WLIS_pb3_svs603HR"';
        dT = sqlread(conn, dbname);
end

dT = sortrows(dT, 'TmStamp');
close(conn);

% Eliminate outliers for specific columns
dT.depth(:) = mode(dT.depth);
dT.latitude(:) = mode(dT.latitude);
dT.longitude(:) = mode(dT.longitude);
dT.station(:) = mode(categorical(dT.station));
dT.mooring_site_desc(:) = mode(categorical(dT.mooring_site_desc));

% Create the "waveQAQC" table
waveQAQC = table();
waveQAQC.TmStamp = dT.TmStamp;
for av = waveVars
    % Run QAQC tests
    waveQAQC.(av{1}) = dT.(av{1});
    if ismember(av{1}, ["waveDir","meanDir"])
        % Jump limit test
        d_tmp = cos(dT.(av{1})*pi/180);
        waveQAQC.([av{1} '_jumpQ']) = ImplementJumpLimTest(d_tmp);
    else
        d_tmp = dT.(av{1});
        waveQAQC.([av{1} '_Q']) = ones(size(dT.TmStamp));
        % Threshold test
        iu = find(d_tmp<QAQC.(av{1})('min_val') | d_tmp>QAQC.(av{1})('max_val') | isnan(d_tmp));
        if ~isempty(iu)
            waveQAQC.([av{1} '_Q'])(iu) = 4;
        end
    end
end
waveQAQC.depth = dT.depth;
waveQAQC.latitude = dT.latitude;
waveQAQC.longitude = dT.longitude;
waveQAQC.station = dT.station;
waveQAQC.mooring_site_desc = dT.mooring_site_desc;

% Save the updated "MetQAQC" table to a CSV file
writetable(waveQAQC, [buoy '_Wave_QAQC.csv']);

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
vNames = cell(1, 2*length(waveVars));
for i = 1:length(waveVars)
    vNames{2*i-1} = sprintf('"%s" %s',waveVars{i},'FLOAT');
    if ismember(waveVars{i}, ["waveDir","meanDir"])
        vNames{2*i} = sprintf('"%s_jumpQ" %s',waveVars{i},'INTEGER');
    else
        vNames{2*i} = sprintf('"%s_Q" %s',waveVars{i},'INTEGER');
    end
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
    if ismember(av{1}, ["waveDir","meanDir"])
        waveQAQC.(av{1}).jumpCheck = d.([av{1} '_jumpQ']);
    else
        waveQAQC.(av{1}).check = d.([av{1} '_Q']);
    end
end

% Save the updated "waveQAQC" struct to a .mat file
save(['Buoy_' buoy '_Wave_QAQC.mat'], 'waveQAQC');

%%
% Save all the data plotted in a structure that can be exported to NETCDF
latlon = [d.latitude(1), d.longitude(1)];
stnDep = d.depth(1);
WriteWaveNETCDF(buoy, latlon, stnDep, waveQAQC);