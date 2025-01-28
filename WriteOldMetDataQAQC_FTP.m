% 
% Identify and flag buoy meteorology data outliers
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 

clc; clear;
buoy = 'WLIS';

% Fixed parameters
metVars = {'windSpd_Kts','windSpd_Max','fiveSecAvg_Max','windDir_M', ...
           'airTemp_Avg','relHumid_Avg','baroPress_Avg','dewPT_Avg'};

% Read meteorology QAQC parameters
QAQC = readtable('QAQC_Para_Met.csv', ReadRowNames=true);

% Process tables from FTP site
d3 = load('wlis2003_met.mat'); d3 = d3.wlis2003_met;
d = d3;

% Preprocess the mat file
d = renamevars(d,'windSpd_kts','windSpd_Kts');
d.('fiveSecAvg_Max')(:) = NaN;
d.('dewPT_Avg')(:) = NaN;
dT = d(:, [{'TmStamp'}, metVars]);
dT = sortrows(dT, 'TmStamp');

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
username = 'lisicos';
password = 'vncq489';
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
MetQAQC.TmStamp.Format = 'dd-MMM-yyyy HH:mm:ss';
MetQAQC.TmStamp.TimeZone = 'America/New_York';
writetable(MetQAQC, [buoy '_Met_QAQC.csv']);
fprintf('%s   %s   %s\n', min(MetQAQC.TmStamp), max(MetQAQC.TmStamp), MetQAQC.TmStamp.TimeZone);

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