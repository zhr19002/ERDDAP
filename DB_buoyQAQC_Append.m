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

%%
% Append new climatology data to PostgreSQL
tblNames = {'ARTG_pb2_sbe37btm1','ARTG_pb2_sbe37btm2','ARTG_pb2_sbe37sfc', ...
            'EXRX_pb2_sbe37btm2','EXRX_pb2_sbe37mid', 'EXRX_pb2_sbe37sfc', ...
            'WLIS_pb2_sbe37btm1','WLIS_pb2_sbe37btm2', ...
            'WLIS_pb2_sbe37mid','WLIS_pb2_sbe37sfc'};

for tblname = tblNames
    tbl = tblname{1};
    % Extract a table from PostgreSQL
    dT = sqlread(conn, strcat('"',tbl,'"'));
    dT = renamevars(dT, {'degC','psu','mg/L','dBars','S/m'}, avars(1:5));
    % Filter new data in the table
    dTQ = sqlread(connQ, strcat('"',[tbl(1:4) '_' tbl(15:end) '_QAQC'],'"'));
    dT = dT(dT.TmStamp >= max(dTQ.TmStamp), :);
    if height(dT) < 2
        disp('No new data to add.');
        continue
    end

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
        [dQ, dC] = CheckBuoyDataQAQC(dT, loc{1}, QAQC, av{1});
        BuoyQAQC.([av{1} '_data']) = dT.(av{1});
        BuoyQAQC.([av{1} '_Q']) = dQ;
        BuoyQAQC.([av{1} '_FailedCount']) = dC;
    end
    
    % Add specific columns
    BuoyQAQC.latitude(:) = dTQ.latitude(1);
    BuoyQAQC.longitude(:) = dTQ.longitude(1);
    BuoyQAQC.station(:) = dTQ.station(1);
    BuoyQAQC.mooring_site_desc(:) = dTQ.mooring_site_desc(1);
    
    % Save the updated "BuoyQAQC" table to a CSV file
    writetable(BuoyQAQC, [tbl(1:4) '_' tbl(15:end) '_QAQC.csv']);
    fprintf('%s   %s   %d\n', min(dT.TmStamp), max(dT.TmStamp), height(dT));
end

% Meteorology
buoy = 'ARTG'; % {'ARTG','CLIS1','CLIS2','EXRX','WLIS'}
switch buoy
    case 'ARTG'
        dT = sqlread(conn, '"ARTG_pb1_metSens"');
        dT = renamevars(dT,'dewPt_Avg','dewPT_Avg');
    case 'CLIS1'
        dT = sqlread(conn, '"clis_cr1xPB4_metDat"');
        dT = renamevars(dT,'windSpd_kts','windSpd_Kts');
    case 'CLIS2'
        dT = sqlread(conn, '"clis_cr1xPB4_metRO"');
        dT = renamevars(dT,'windSpd_kts','windSpd_Kts');
    case 'EXRX'
        dT = sqlread(conn, '"EXRX_pb1_metRO"');
        dT = renamevars(dT,'dewPt_Avg','dewPT_Avg');
    case 'WLIS'
        dT = sqlread(conn, '"WLIS_pb4_metSens"');
        dT = renamevars(dT,'dewPt_Avg','dewPT_Avg');
end

% Wave
buoy = 'CLIS'; % {'CLIS','EXRX','WLIS'}
switch buoy
    case 'CLIS'
        dT = sqlread(conn, '"clis_cr1xPB4_waveDat"');
        % Covert string values to numeric values
        for av = waveVars
            dT.(av{1}) = str2double(dT.(av{1}));
        end
    case 'EXRX'
        dT = sqlread(conn, '"EXRX_pb3_svs603hr"');
    case 'WLIS'
        dT = sqlread(conn, '"WLIS_pb3_svs603HR"');
end