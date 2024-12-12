% 
% Append new data to the "buoyQAQC" database
% Step 1: Save new data
% Step 2: Append new data to PostgreSQL
% 

clc; clear;

% Table names
tblNames = { ...
    ... Climatology data
    'ARTG_pb2_sbe37btm1','ARTG_pb2_sbe37btm2','ARTG_pb2_sbe37sfc', ...
    'clis_cr1xPB4_sbe37Btm','clis_cr1xPB4_sbe37Sfc', ...
    'EXRX_pb2_sbe37btm2','EXRX_pb2_sbe37mid', 'EXRX_pb2_sbe37sfc', ...
    'WLIS_pb2_sbe37btm1','WLIS_pb2_sbe37btm2','WLIS_pb2_sbe37mid','WLIS_pb2_sbe37sfc', ...
    ... Meteorology data
    'ARTG_pb1_metSens','clis_cr1xPB4_metDat','clis_cr1xPB4_metRO', ...
    'EXRX_pb1_metRO','WLIS_pb4_metSens', ...
    ... Wave data
    'clis_cr1xPB4_waveDat','EXRX_pb3_svs603hr','WLIS_pb3_svs603HR', ...
    ... ADCP data
    'clis_cr1xPB4_adcpDat','EXRX_pb1_adcpDat','WLIS_pb1_adcpDat', ...
    ... Nutrient data
    'ARTG_pb1_PARdenDat','ARTG_pb1_sbeECOFL','ARTG_pb1_sbeECONTU','CLIS_pb4_SunaNO3'};

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','provLNDB','PortNumber',5432);
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','buoyQAQC','PortNumber',5432);

% Append new data to the "buoyQAQC" database
for i = 1:length(tblNames)
    if i <= 12
        % Save new climatology data
        [dbname, d] = SaveNewClimData(conn, connQ, tblNames{i});
    elseif i > 12 && i <= 17
        % Save new meteorology data
        [dbname, d] = SaveNewMetData(conn, connQ, tblNames{i});
    elseif i > 17 && i <= 20
        % Save new wave data
        [dbname, d] = SaveNewWaveData(conn, connQ, tblNames{i});
    elseif i > 20 && i <= 23
        % Save new ADCP data
        [dbname, d] = SaveNewADCPData(conn, connQ, tblNames{i});
    else
        % Save new nutrient data
        [dbname, d] = SaveNewNutData(conn, connQ, tblNames{i});
    end
    % Append new data to PostgreSQL
    if height(d) > 1
        AppendNewData(connQ, dbname, d);
    end
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
if contains(tbl, 'ARTG')
    loc = tbl(15:end);
    QAQC = load('QAQC_E1_WQ.mat');
elseif contains(tbl, 'EXRX')
    loc = tbl(15:end);
    QAQC = load('QAQC_A4_WQ.mat');
elseif contains(tbl, 'WLIS')
    loc = tbl(15:end);
    QAQC = load('QAQC_C1_WQ.mat');
else
    loc = lower(tbl(end-2:end));
    QAQC = load('QAQC_I2_WQ.mat');
end
QAQC = QAQC.QAQC;

% Extract a table from PostgreSQL
dbname = [upper(tbl(1:4)) '_' loc '_QAQC'];
dT = sqlread(conn, strcat('"',tbl,'"'));
dT = renamevars(dT, {'degC','psu','mg/L','dBars','S/m'}, avars(1:5));

% Filter new data in the table
dTQ = sqlread(connQ, strcat('"',dbname,'"'));
dT = dT(dT.TmStamp >= max(dTQ.TmStamp), :);

% Create the "BuoyQAQC" table
BuoyQAQC = table();
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
    
    BuoyQAQC.TmStamp = dT.TmStamp;
    BuoyQAQC.depth = dT.P;
    for av = avars
        % Run QAQC tests
        [dQ, dC] = CheckBuoyDataQAQC(dT, loc, QAQC, av{1});
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
    BuoyQAQC = dTQ(dTQ.TmStamp >= max(dTQ.TmStamp), :);
    fprintf('No new data to add to "%s"\n', dbname);
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

% Create the "MetQAQC" table
MetQAQC = table();
if height(dT) > 1
    dT = sortrows(dT, 'TmStamp');
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
    MetQAQC = dTQ(dTQ.TmStamp >= max(dTQ.TmStamp), :);
    fprintf('No new data to add to "%s"\n', dbname);
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
end

% Filter new data in the table
dbname = [upper(tbl(1:4)) '_Wave_QAQC'];
dTQ = sqlread(connQ, strcat('"',dbname,'"'));
dT = dT(dT.TmStamp >= max(dTQ.TmStamp), :);

% Create the "waveQAQC" table
waveQAQC = table();
if height(dT) > 1
    dT = sortrows(dT, 'TmStamp');
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
    waveQAQC = dTQ(dTQ.TmStamp >= max(dTQ.TmStamp), :);
    fprintf('No new data to add to "%s"\n', dbname);
end
end


% 
% Function: Save new ADCP data
% 
function [dbname, ADCP] = SaveNewADCPData(conn, connQ, tbl)
% Extract a table from PostgreSQL
dT = sqlread(conn, strcat('"',tbl,'"'));

% Filter new data in the table
dbname = [upper(tbl(1:4)) '_ADCP'];
dTQ = sqlread(connQ, strcat('"',dbname,'"'));
dT = dT(dT.TmStamp >= max(dTQ.TmStamp), :);

if height(dT) > 1
    dT = sortrows(dT, 'TmStamp');
    % Create the "result" structure to store values of each field
    result = struct();
    for i = 1:height(dT)
        try
            res = DecodeADCP(dT.adcpString_RDI_PD12{i});
            for field = fieldnames(res)'
                result(i).(field{1}) = res.(field{1});
            end
        catch ME
            for field = fieldnames(result)'
                result(i).(field{1}) = [];
            end
        end
    end
    
    % Assign values to the "ADCP" table
    ADCP = struct2table(result);
    ADCP.TmStamp = dT.TmStamp;
    ADCP = movevars(ADCP, 'TmStamp', 'Before', 1);
    
    % Remove empty rows
    ADCP = ADCP(~cellfun('isempty', ADCP.ID), :);
    
    % Convert columns to a specific format
    ADCP.vels = cellfun(@(x) mat2str(x), ADCP.vels, 'UniformOutput', false);
    ADCP.mtime = datetime(string(ADCP.mtime));
    
    % Save the updated "ADCP" table
    if height(ADCP) > 1
        fprintf('%s   %s   %s   %d\n', dbname, min(ADCP.TmStamp), max(ADCP.TmStamp), height(ADCP));
    else
        fprintf('No new data to add to "%s"\n', dbname);
    end
else
    ADCP = dTQ(dTQ.TmStamp >= max(dTQ.TmStamp), :);
    fprintf('No new data to add to "%s"\n', dbname);
end
end


% 
% Function: Save new nutrient data
% 
function [dbname, NutQAQC] = SaveNewNutData(conn, connQ, tbl)
% Fixed parameters
colVars = {'PAR_Raw','chl_ugL','turbidity_NTU','NNO3'};

% Extract a table from PostgreSQL
dT = sqlread(conn, strcat('"',tbl,'"'));
dT(:, {'RecNum','CR1XBatt','CR1XTemp'}) = [];

if contains(tbl, 'PAR')
    dbname = [tbl(1:4) '_PAR_QAQC'];
    QAQC = load('QAQC_E1_WQ.mat');
elseif contains(tbl, 'FL')
    dT(:, {'Date','EST'}) = [];
    dT = renamevars(dT,'chl_ug/L','chl_ugL');
    dbname = [tbl(1:4) '_FL_QAQC'];
    QAQC = load('QAQC_E1_WQ.mat');
elseif contains(tbl, 'NTU')
    dT(:, {'Date','EST'}) = [];
    dbname = [tbl(1:4) '_NTU_QAQC'];
    QAQC = load('QAQC_E1_Nutrient.mat');
else
    dbname = [tbl(1:4) '_NO3_QAQC'];
    QAQC = load('QAQC_I2_Nutrient.mat');
end
QAQC = QAQC.QAQC;

% Filter new data in the table
dTQ = sqlread(connQ, strcat('"',dbname,'"'));
dT = dT(dT.TmStamp >= max(dTQ.TmStamp), :);

% Create the "NutQAQC" table
NutQAQC = table();
if height(dT) > 1
    dT = sortrows(dT, 'TmStamp');  
    for i = 1:width(dT)
        col = dT.Properties.VariableNames{i};
        NutQAQC.(col) = dT.(col);
        if ismember(col, colVars)
            % Run QAQC tests
            [dQ, dC] = CheckNutDataQAQC(dT, QAQC, col);
            NutQAQC.([col '_Q']) = dQ;
            NutQAQC.([col '_FailedCount']) = dC;
        end
    end
    
    % Modify specific columns
    if strcmp(tbl(1:4), 'ARTG')
        NutQAQC.latitude(:) = mode(dT.latitude);
        NutQAQC.longitude(:) = mode(dT.longitude);
        NutQAQC.station(:) = mode(categorical(dT.station));
        NutQAQC.mooring_site_desc(:) = mode(categorical(dT.mooring_site_desc));
        NutQAQC.depth(:) = mode(dT.depth);
    end
    
    % Save the updated "NutQAQC" table
    fprintf('%s   %s   %s   %d\n', dbname, min(dT.TmStamp), max(dT.TmStamp), height(dT));
else
    NutQAQC = dTQ(dTQ.TmStamp >= max(dTQ.TmStamp), :);
    fprintf('No new data to add to "%s"\n', dbname);
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