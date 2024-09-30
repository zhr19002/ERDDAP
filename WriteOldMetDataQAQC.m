% 
% Identify and flag buoy meteorology data outliers
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 

clc; clear;
buoy = 'CLIS1'; % {'CLIS1','EXRX','WLIS'}
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
    case 'CLIS1'
        dT1 = sqlread(conn, '"clis_wx"');
        cols_old{4} = 'windGust3sec';
        dT1 = renamevars(dT1, cols_old, cols_new);
        dT2 = sqlread(conn, '"CLIS_pb1_metDat"');
        dT2 = renamevars(dT2, {'WindSpd','maxWindSpd','WindDir','AirTemp', ...
             'RelHumidity','BaroPress','DewPt'}, [metVars(1:2),metVars(4:8)]);
        dT2.TmStamp.TimeZone = 'UTC';
        dT2.('fiveSecAvg_Max')(:) = NaN;
        dT = [dT1(:,cols_new); dT2(:,cols_new)];
    case 'EXRX'
        dT = sqlread(conn, '"exrx_wx"');
        dT = renamevars(dT, cols_old, cols_new);
    case 'WLIS'
        dT = sqlread(conn, '"wlis_wx"');
        dT = renamevars(dT, cols_old, cols_new);
end

% Filter TmStamp outliers
dT(dT.TmStamp <= datetime('01-Jan-1904','TimeZone','UTC'), :) = [];
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
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);
dTQ = sqlread(connQ, strcat('"',[buoy '_Met_QAQC'],'"'));
MetQAQC.depth(:) = dTQ.depth(1);
MetQAQC.latitude(:) = dTQ.latitude(1);
MetQAQC.longitude(:) = dTQ.longitude(1);
MetQAQC.station(:) = dTQ.station(1);
MetQAQC.mooring_site_desc(:) = dTQ.mooring_site_desc(1);
close(connQ);

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

% Write the table to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);
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