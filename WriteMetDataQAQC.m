% 
% Identify and flag buoy meteorology data outliers
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 
% Calls CheckMetWaveQAQC.m
% Calls WriteMetNETCDF.m
% 

clc; clear;
buoy = 'ARTG'; % {'ARTG','CLIS1','CLIS2','EXRX','WLIS'}
metVars = {'windSpd_Kts','windSpd_Max','fiveSecAvg_Max','windDir_M', ...
           'airTemp_Avg','relHumid_Avg','baroPress_Avg','dewPT_Avg'};
tVars = [{'TmStamp'},metVars,{'longitude','latitude','station','mooring_site_desc','depth'}];

% Read meteorology QAQC parameters
QAQC = readtable('QAQC_Para_Met.csv', ReadRowNames=true);

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','provLNDB','PortNumber',5432);

% tbldata = sqlfind(conn,"")

% Extract tables from PostgreSQL
switch buoy
    case 'ARTG'
        dT1 = sqlread(conn, '"ARTG_pb2_metDat"');
        dT2 = sqlread(conn, '"ARTG_pb1_metSens"');
        dT2 = renamevars(dT2,'dewPt_Avg','dewPT_Avg');
        dT = [dT1(:,tVars); dT2(:,tVars)];
    case 'CLIS1'
        dT = sqlread(conn, '"clis_cr1xPB4_metDat"');
        dT = renamevars(dT,'windSpd_kts','windSpd_Kts');
    case 'CLIS2'
        dT = sqlread(conn, '"clis_cr1xPB4_metRO"');
        dT = renamevars(dT,'windSpd_kts','windSpd_Kts');
    case 'EXRX'
        dT1 = sqlread(conn, '"EXRX_pb2_metDat_arch1"');
        dT2 = sqlread(conn, '"EXRX_pb1_metRO"');
        dT2 = renamevars(dT2,'dewPt_Avg','dewPT_Avg');
        dT = [dT1(:,tVars); dT2(:,tVars)];
    case 'WLIS'
        dT1 = sqlread(conn, '"WLIS_pb1_metDat"');
        dT2 = sqlread(conn, '"WLIS_pb4_metSens"');
        dT2 = renamevars(dT2,'dewPt_Avg','dewPT_Avg');
        dT = [dT1(:,tVars); dT2(:,tVars)];
end

dT = dT(:, tVars);
dT = sortrows(dT, 'TmStamp');
close(conn);

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

% Add specific columns
MetQAQC.depth(:) = mode(dT.depth);
MetQAQC.latitude(:) = mode(dT.latitude);
MetQAQC.longitude(:) = mode(dT.longitude);
MetQAQC.station(:) = mode(categorical(dT.station));
MetQAQC.mooring_site_desc(:) = mode(categorical(dT.mooring_site_desc));

% Save the updated "MetQAQC" table to a CSV file
writetable(MetQAQC, [buoy '_Met_QAQC.csv']);

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
% % Drop the table from PostgreSQL
% execute(connQ, strcat("DROP TABLE ",tblName));

close(connQ);

%%
opts = detectImportOptions([buoy '_Met_QAQC.csv']);
opts = setvaropts(opts,'TmStamp','InputFormat','dd-MMM-yyyy HH:mm:ss');
d = readtable([buoy '_Met_QAQC.csv'], opts);

% Create the "MetQAQC" struct
MetQAQC = struct();
MetQAQC.time = d.TmStamp;
for av = metVars
    MetQAQC.(av{1}).data = d.(av{1});
    MetQAQC.(av{1}).QAQC = d.([av{1} '_Q']);
    MetQAQC.(av{1}).FailedCount = d.([av{1} '_FailedCount']);
end

% Save the updated "MetQAQC" struct to a .mat file
save(['Buoy_' buoy '_Met_QAQC.mat'], 'MetQAQC');

%%
% Save all the data plotted in a structure that can be exported to NETCDF
latlon = [d.latitude(1), d.longitude(1)];
stnDep = d.depth(1);
WriteMetNETCDF(buoy, latlon, stnDep, MetQAQC);