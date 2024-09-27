clc; clear;

tblName = '"EXRX_btm2_QAQC"';

% Fixed parameters
avars = {'T','S','DO','P','C','pH','rho','DOsat'};
avars_data = {'T_data','S_data','DO_data','P_data','C_data','pH_data','rho_data','DOsat_data'};
metVars = {'windSpd_Kts','windSpd_Max','fiveSecAvg_Max','windDir_M', ...
           'airTemp_Avg','relHumid_Avg','baroPress_Avg','dewPT_Avg'};
waveVars = {'Hsig_m','Hmax_m','Tdom_s','Tavg_s','waveDir','meanDir'};

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);

% Sort the "TmStamp" column
dT0 = sqlread(connQ, tblName);
dT = sortrows(dT0, 'TmStamp');
fprintf('%s   %s\n', min(dT.TmStamp), max(dT.TmStamp));

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