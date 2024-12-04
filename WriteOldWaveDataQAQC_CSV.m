% 
% Identify and flag buoy wave data outliers
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 

clc; clear;
buoy = 'WLIS';
waveVars = {'Hsig_m','Hmax_m','Tdom_s','Tavg_s','waveDir','meanDir'};

% Read wave QAQC parameters
QAQC = readtable('QAQC_Para_Wave.csv', ReadRowNames=true);

% Process tables from FTP site
switch buoy
    case 'WLIS'
        files = dir(fullfile('WA*.csv'));
        cols = {'DateTime','Hs','Hmax','DominantPeriod','AveragePeriodTe','WaveDirection','MeanWaveDir'};
        % Concatenate tables in CSV files
        dT = table();
        for i = 1:length(files)
            file = fullfile(files(i).name);
            opts = detectImportOptions(file);
            opts.DataLines = [2, Inf];
            d_tmp = readtable(file, opts);
            d_tmp = d_tmp(2:end, cols);
            dT = [dT; d_tmp];
        end
        dT.Properties.VariableNames = [{'TmStamp'}, waveVars];
        dT = sortrows(dT, 'TmStamp');
end

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
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);
dTQ = sqlread(connQ, strcat('"',[buoy '_Wave_QAQC'],'"'));
waveQAQC.depth(:) = dTQ.depth(1);
waveQAQC.latitude(:) = dTQ.latitude(1);
waveQAQC.longitude(:) = dTQ.longitude(1);
waveQAQC.station(:) = dTQ.station(1);
waveQAQC.mooring_site_desc(:) = dTQ.mooring_site_desc(1);
close(connQ);

% Save the updated "waveQAQC" table to a CSV file
waveQAQC.TmStamp.Format = 'dd-MMM-yyyy HH:mm:ss';
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

% Write the table to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);
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