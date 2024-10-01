% 
% Append new data to the "buoyQAQC" database
% Step 1: Save new data
% Step 2: Append new data to PostgreSQL
% 

clc; clear;

% Table names
tblNames = {'ARTG_pb2_sbe37btm1','ARTG_pb2_sbe37btm2','ARTG_pb2_sbe37sfc', ...
            'EXRX_pb2_sbe37btm2','EXRX_pb2_sbe37mid', 'EXRX_pb2_sbe37sfc', ...
            'WLIS_pb2_sbe37btm1','WLIS_pb2_sbe37btm2','WLIS_pb2_sbe37mid', ...
            'WLIS_pb2_sbe37sfc', 'ARTG_pb1_metSens','clis_cr1xPB4_metDat', ...
            'clis_cr1xPB4_metRO','EXRX_pb1_metRO',  'WLIS_pb4_metSens', ...
            'clis_cr1xPB4_waveDat','EXRX_pb3_svs603hr','WLIS_pb3_svs603HR'};

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','provLNDB','PortNumber',5432);
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','buoyQAQC','PortNumber',5432);

% Append new data to the "buoyQAQC" database
for i = 1:length(tblNames)
    if i <= 10
        % Save new climatology data
        [dbname, d] = SaveNewClimData(conn, connQ, tblNames{i});
    elseif i >10 && i <=15
        % Save new meteorology data
        [dbname, d] = SaveNewMetData(conn, connQ, tblNames{i});
    else
        % Save new wave data
        [dbname, d] = SaveNewWaveData(conn, connQ, tblNames{i});
    end
    % Append new data to PostgreSQL
    AppendNewData(connQ, dbname, d);
end

close(conn);
close(connQ);

%%
% 
% Function: Save new climatology data
% 
function [dbname, BuoyQAQC] = SaveNewClimData(conn, connQ, tbl)
% Fixed parameters
avars = {'T','S','DO','P','C','pH','rho','DOsat'};

% Read station group QAQC parameters
if contains(tbl, 'clis', 'IgnoreCase', true)
    QAQC = load('QAQC_Para_CStations.mat');
else
    QAQC = load('QAQC_Para_WStations.mat');
end
QAQC = QAQC.QAQC;

% Extract a table from PostgreSQL
dT = sqlread(conn, strcat('"',tbl,'"'));
dT = renamevars(dT, {'degC','psu','mg/L','dBars','S/m'}, avars(1:5));

% Filter new data in the table
dbname = [tbl(1:4) '_' tbl(15:end) '_QAQC'];
dTQ = sqlread(connQ, strcat('"',dbname,'"'));
dT = dT(dT.TmStamp >= max(dTQ.TmStamp), :);

if height(dT) > 1
    dT = sortrows(dT, 'TmStamp');
    % Calculate rho
    dT.('rho') = real(sw_dens(dT.S,dT.T,dT.P)-1000);
    % Calculate DOsat (convert to mg/L)
    dT.('DOsat') = 100*dT.DO ./ (sw_satO2(dT.S,dT.T)*1.33);
    % Replace DOsat values greater than 1000 with NaN
    dT.('DOsat')(dT.('DOsat') > 1000) = NaN;
    % Add the pH column
    dT.('pH')(:) = NaN;
    
    % Create the "BuoyQAQC" table
    BuoyQAQC = table();
    BuoyQAQC.TmStamp = dT.TmStamp;
    BuoyQAQC.depth = dT.P;
    for av = avars
        % Run QAQC tests
        [dQ, dC] = CheckBuoyDataQAQC(dT, tbl(15:end), QAQC, av{1});
        BuoyQAQC.([av{1} '_data']) = dT.(av{1});
        BuoyQAQC.([av{1} '_Q']) = dQ;
        BuoyQAQC.([av{1} '_FailedCount']) = dC;
    end
    
    % Add specific columns
    BuoyQAQC.latitude(:) = dTQ.latitude(1);
    BuoyQAQC.longitude(:) = dTQ.longitude(1);
    BuoyQAQC.station(:) = dTQ.station(1);
    BuoyQAQC.mooring_site_desc(:) = dTQ.mooring_site_desc(1);
    
    % Save the updated "BuoyQAQC" table
    fprintf('%s   %s   %s   %d\n', dbname, min(dT.TmStamp), max(dT.TmStamp), height(dT));
else
    fprintf('No new data to add to "%s"', dbname);
end
end


% 
% Function: Save new meteorology data
% 
function [dbname, MetQAQC] = SaveNewMetData(conn, connQ, tbl)
% Fixed parameters
metVars = {'windSpd_Kts','windSpd_Max','fiveSecAvg_Max','windDir_M', ...
           'airTemp_Avg','relHumid_Avg','baroPress_Avg','dewPT_Avg'};

% Read meteorology QAQC parameters
QAQC = readtable('QAQC_Para_Met.csv', ReadRowNames=true);

% Extract a table from PostgreSQL
dT = sqlread(conn, strcat('"',tbl,'"'));
if contains(tbl, 'clis')
    dT = renamevars(dT,'windSpd_kts','windSpd_Kts');
    if contains(tbl, 'Dat')
        dbname = 'CLIS1_Met_QAQC';
    else
        dbname = 'CLIS2_Met_QAQC';
    end
else
    dT = renamevars(dT,'dewPt_Avg','dewPT_Avg');
    dbname = [tbl(1:4) '_Met_QAQC'];
end

% Filter new data in the table
dTQ = sqlread(connQ, strcat('"',dbname,'"'));
dT = dT(dT.TmStamp >= max(dTQ.TmStamp), :);

if height(dT) > 1
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
    MetQAQC.depth(:) = dTQ.depth(1);
    MetQAQC.latitude(:) = dTQ.latitude(1);
    MetQAQC.longitude(:) = dTQ.longitude(1);
    MetQAQC.station(:) = dTQ.station(1);
    MetQAQC.mooring_site_desc(:) = dTQ.mooring_site_desc(1);
    
    % Save the updated "MetQAQC" table
    fprintf('%s   %s   %s   %d\n', dbname, min(dT.TmStamp), max(dT.TmStamp), height(dT));
else
    fprintf('No new data to add to "%s"', dbname);
end
end


% 
% Function: Save new wave data
% 
function [dbname, waveQAQC] = SaveNewWaveData(conn, connQ, tbl)
% Fixed parameters
waveVars = {'Hsig_m','Hmax_m','Tdom_s','Tavg_s','waveDir','meanDir'};

% Read wave QAQC parameters
QAQC = readtable('QAQC_Para_Wave.csv', ReadRowNames=true);

% Extract a table from PostgreSQL
dT = sqlread(conn, strcat('"',tbl,'"'));
if contains(tbl, 'clis')
    % Covert string values to numeric values
    for av = waveVars
        dT.(av{1}) = str2double(dT.(av{1}));
    end
    dbname = [upper(tbl(1:4)) '_Wave_QAQC'];
else
    dbname = [tbl(1:4) '_Wave_QAQC'];
end

% Filter new data in the table
dTQ = sqlread(connQ, strcat('"',dbname,'"'));
dT = dT(dT.TmStamp >= max(dTQ.TmStamp), :);

if height(dT) > 1
    dT = sortrows(dT, 'TmStamp');

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
    waveQAQC.depth(:) = dTQ.depth(1);
    waveQAQC.latitude(:) = dTQ.latitude(1);
    waveQAQC.longitude(:) = dTQ.longitude(1);
    waveQAQC.station(:) = dTQ.station(1);
    waveQAQC.mooring_site_desc(:) = dTQ.mooring_site_desc(1);
    
    % Save the updated "waveQAQC" table
    fprintf('%s   %s   %s   %d\n', dbname, min(dT.TmStamp), max(dT.TmStamp), height(dT));
else
    fprintf('No new data to add to "%s"', dbname);
end
end


% 
% Function: Append new data to PostgreSQL
% 
function AppendNewData(connQ, dbname, d)
% Remove the first row
d(1, :) = [];
dbname = strcat('"',dbname,'"');

% Quoted to preserve case sensitivity
colNames = strcat('"',d.Properties.VariableNames,'"');
d.Properties.VariableNames = colNames;
try
    batchSize = 10000;
    for i = 1:ceil(height(d)/batchSize)
        startRow = (i-1)*batchSize + 1;
        endRow = min(i*batchSize, height(d));
        batchData = d(startRow:endRow, :);
        % Write the batch to PostgreSQL
        sqlwrite(connQ, dbname, batchData);
        disp(['Row ' num2str(startRow) '-' num2str(endRow) ' written to PostgreSQL successfully.']);
    end
catch ME
    disp(ME.message);
end
end