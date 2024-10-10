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
        dT2.TmStamp.TimeZone = 'America/New_York';
        dT2.TmStamp = datetime(dT2.TmStamp,'TimeZone','UTC');
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
waveQAQC.TmStamp.TimeZone = 'America/New_York';
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