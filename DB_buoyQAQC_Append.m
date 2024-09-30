clc; clear;

% Fixed parameters
avars = {'T','S','DO','P','C','pH','rho','DOsat'};
avars_data = {'T_data','S_data','DO_data','P_data','C_data','pH_data','rho_data','DOsat_data'};
metVars = {'windSpd_Kts','windSpd_Max','fiveSecAvg_Max','windDir_M', ...
           'airTemp_Avg','relHumid_Avg','baroPress_Avg','dewPT_Avg'};
waveVars = {'Hsig_m','Hmax_m','Tdom_s','Tavg_s','waveDir','meanDir'};

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','provLNDB','PortNumber',5432);
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);

% Extract tables
tblNames = {'ARTG_pb2_sbe37btm1', 'ARTG_pb2_sbe37btm2', 'ARTG_pb2_sbe37sfc' ...
            'clis_cr1xPB4_sbe37Btm', 'clis_cr1xPB4_sbe37Sfc', ...
            'EXRX_pb2_sbe37btm2','EXRX_pb2_sbe37mid','EXRX_pb2_sbe37sfc', ...
            'WLIS_pb2_sbe37btm1','WLIS_pb2_sbe37btm2','WLIS_pb2_sbe37mid','WLIS_pb2_sbe37sfc'};

for tbl = tblNames
    dT = sqlread(conn, strcat('"',tbl{1},'"'));
    dT = renamevars(dT, {'degC','psu','mg/L','dBars','S/m'}, avars(1:5));
    dT = sortrows(dT, 'TmStamp');
    
    % Calculate rho
    dT.('rho') = real(sw_dens(dT.S,dT.T,dT.P)-1000);
    % Calculate DOsat (convert to mg/L)
    dT.('DOsat') = 100*dT.DO ./ (sw_satO2(dT.S,dT.T)*1.33);
    % Replace DOsat values greater than 1000 with NaN
    dT.('DOsat')(dT.('DOsat') > 1000) = NaN;
    % Add the pH column
    dT.('pH')(:) = NaN;
end

fprintf('%s   %s\n', min(dT.TmStamp), max(dT.TmStamp));
writetable(dT, [buoy '_' loc{1} '_QAQC.csv']);

%%
% QAQC checks
if contains(tblName, 'Wave')
    QAQC = readtable('QAQC_Para_Wave.csv', ReadRowNames=true);
    for av = waveVars
        [dQ, dC] = CheckMetWaveQAQC(dT, QAQC, av{1});
        dT.([av{1} '_Q']) = dQ;
        dT.([av{1} '_FailedCount']) = dC;
    end
elseif contains(tblName, 'Met')
    QAQC = readtable('QAQC_Para_Met.csv', ReadRowNames=true);
    for av = metVars
        [dQ, dC] = CheckMetWaveQAQC(dT, QAQC, av{1});
        dT.([av{1} '_Q']) = dQ;
        dT.([av{1} '_FailedCount']) = dC;
    end
else
    if contains(tblName, 'CLIS')
        QAQC = load('QAQC_Para_CStations.mat');
    else
        QAQC = load('QAQC_Para_WStations.mat');  
    end
    QAQC = QAQC.QAQC;
    dT = renamevars(dT, avars_data, avars);
    loc = tblName(7:9);
    for av = avars
        [dQ, dC] = CheckBuoyDataQAQC(dT, loc, QAQC, av{1});
        dT.([av{1} '_Q']) = dQ;
        dT.([av{1} '_FailedCount']) = dC;
    end
    dT = renamevars(dT, avars, avars_data);
end

% Quoted to preserve case sensitivity
colNames = strcat('"',dT.Properties.VariableNames,'"');
dT.Properties.VariableNames = colNames;

% Create a new table in PostgreSQL
query = ['CREATE TABLE IF NOT EXISTS ' tblName(1:end-1) '_new" ' ...
         '(LIKE ' tblName ' INCLUDING ALL);'];
execute(connQ, query);

% Write to the new table in PostgreSQL
try
    batchSize = 10000;
    for i = 1:ceil(height(dT)/batchSize)
        startRow = (i-1)*batchSize + 1;
        endRow = min(i*batchSize, height(dT));
        batchData = dT(startRow:endRow, :);
        % Write the batch to PostgreSQL
        sqlwrite(connQ, [tblName(1:end-1) '_new"'], batchData);
        disp(['Row ' num2str(startRow) '-' num2str(endRow) ' written to PostgreSQL successfully.']);
    end
catch ME
    disp(ME.message);
end

close(connQ);