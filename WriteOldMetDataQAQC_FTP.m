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
% d3 = load('wlis2003_met.mat'); d3 = d3.wlis2003_met;
% d3.('fiveSecAvg_Max')(:) = NaN; d3.('dewPT_Avg')(:) = NaN;
% d3 = renamevars(d3,'windSpd_kts','windSpd_Kts');
% d5 = load('wlis2004_par.mat'); d5 = d5.wlis2wxpar_EST;
% d5.TmStamp = datetime(d5.Date+d5.Time,'Format','dd-MMM-yyyy HH:mm:ss');
% d5.('fiveSecAvg_Max')(:) = NaN; d5.('dewPT_Avg')(:) = NaN;
% d5 = renamevars(d5,'windSpd_MAX','windSpd_Max');
% d6 = load('wlis2006_met.mat'); d6 = d6.WLIS_metDat_2006;
% d6 = renamevars(d6,{'EST','dewPt_Avg'},{'TmStamp','dewPT_Avg'});
% d7 = load('wlis2007_met.mat'); d7 = d7.WLIS_metDat_2007;
% d7 = renamevars(d7,{'EST','dewPt_Avg'},{'TmStamp','dewPT_Avg'});
d8 = load('wlis2008_met.mat'); d8 = d8.WLIS_metDat_2008;
d8 = renamevars(d8,{'EST','dewPt_Avg'},{'TmStamp','dewPT_Avg'});

% Preprocess the mat file
d = d8;
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