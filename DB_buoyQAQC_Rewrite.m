% 
% Rewrite the "buoyQAQC" database when adding new data to tables:
% Step 1: Retrieve a table and sort it by "TmStamp"
% Step 2: Update QAQC columns by re-running QAQC checks
% Step 3: Store the updated table and rename it in PostgreSQL
% 

clc; clear;

% Change the table name
tblName = '"ARTG_btm1_QAQC"';

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
dTQ = sqlread(connQ, tblName);
dT = sortrows(dTQ, 'TmStamp');
fprintf('%s   %s   %s   %d\n', tblName, min(dT.TmStamp), max(dT.TmStamp), height(dT));

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
    if contains(tblName, 'ARTG')
        QAQC = load('QAQC_E1_WQ.mat');
    elseif contains(tblName, 'EXRX')
        QAQC = load('QAQC_A4_WQ.mat');
    elseif contains(tblName, 'WLIS')
        QAQC = load('QAQC_C1_WQ.mat');
    else
        QAQC = load('QAQC_I2_WQ.mat');
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

%%
clc; clear;
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);

% tbldata = sqlfind(connQ, "");

tblNames = {'ARTG_btm1_QAQC','ARTG_btm2_QAQC','ARTG_sfc_QAQC', ...
            'CLIS_btm_QAQC','CLIS_sfc_QAQC', ...
            'EXRX_btm1_QAQC','EXRX_btm2_QAQC','EXRX_mid_QAQC','EXRX_sfc_QAQC', ...
            'WLIS_btm1_QAQC','WLIS_btm2_QAQC','WLIS_mid_QAQC','WLIS_sfc_QAQC', ...
            'ARTG_Met_QAQC','CLIS1_Met_QAQC','CLIS2_Met_QAQC','EXRX_Met_QAQC','WLIS_Met_QAQC', ...
            'CLIS_Wave_QAQC','EXRX_Wave_QAQC','WLIS_Wave_QAQC'
            };

for tbl = tblNames
    d1 = sqlread(connQ, strcat('"',tbl{1},'"'));
    fprintf('%s   %s   %s   %d\n', tbl{1}, min(d1.TmStamp), max(d1.TmStamp), height(d1));
    % d2 = sqlread(connQ, strcat('"',[tbl{1} '_new'],'"'));
    % fprintf('%s   %s   %s   %d\n', tbl{1}, d2.TmStamp(1), d2.TmStamp(end), height(d2));
    % if min(d1.TmStamp)==d2.TmStamp(1) && max(d1.TmStamp)==d2.TmStamp(end) && height(d1)==height(d2)
    %     fprintf('%s correct\n', tbl{1});
    % else
    %     fprintf('%s wrong\n', tbl{1});
    % end
    
    % Drop the table from PostgreSQL
    % execute(connQ, ['DROP TABLE "' tbl{1} '";']);
    % Rename the table
    % execute(connQ, ['ALTER TABLE "' tbl{1} '_new" RENAME TO "' tbl{1} '";']);
end

close(connQ);