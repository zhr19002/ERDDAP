% 
% Plot the long-term time series of buoy data
% Highlight suspicious data points
% 

clc; clear;

% Set 1 for climotology, 2 for meteorology, 3 for wave
type = 3;
buoy = 'WLIS'; loc = 'sfc';

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','buoyQAQC','PortNumber',5432);

% Set up parameters
switch type
    case 1
        avars = {'T_data','S_data','DO_data','P_data','C_data','rho_data','DOsat_data'};
        vnames = {'T','S','DO','P','C','rho','DOsat'};
        units = {'degC','psu','mg/L','dBars','S/m','kg/m3','percent'};
        dT = sqlread(conn, ['"' buoy '_' loc '_QAQC"']);
    case 2
        avars = {'windSpd_Kts','windSpd_Max','fiveSecAvg_Max','windDir_M'};
        vnames = {'windSpd','windGust','fiveSecAvg','windDir'};
        units = {'kts','kts','kts','deg'};
        % avars = {'airTemp_Avg','relHumid_Avg','baroPress_Avg','dewPT_Avg'};
        % vnames = {'airTemp','relHumid','baroPress','dewPT'};
        % units = {'celsius','percent','millibars','celsius'};
        dT = sqlread(conn, ['"' buoy '_Met_QAQC"']);
    case 3
        avars = {'Hsig_m','Hmax_m','Tdom_s','Tavg_s','waveDir','meanDir'};
        vnames = {'Hsig','Hmax','Tdom','Tavg','waveDir','meanDir'};
        units = {'m','m','s','s','deg','deg'};
        dT = sqlread(conn, ['"' buoy '_Wave_QAQC"']);
end

dT = dT(dT.TmStamp < datetime(2025,1,1), :);
close(conn);

% Plot long-term time series with highlighted suspicious data points
figure;
len = length(avars);
for i = 1:len
    subplot(len,1,i); hold on; grid on;
    if type == 1
        iu1 = find(floor(dT.([vnames{i} '_Q'])/10000)~=4);
        iu2 = find(floor(dT.([vnames{i} '_Q'])/10000)==3);
    else
        iu1 = find(floor(dT.([avars{i} '_Q'])/1000)~=4);
        iu2 = find(floor(dT.([avars{i} '_Q'])/1000)==3);
    end
    plot(dT.TmStamp(iu1),dT.(avars{i})(iu1),'b.');
    plot(dT.TmStamp(iu2),dT.(avars{i})(iu2),'gs');
    xtickformat('yyyy-MM');
    ylabel([vnames{i} ' (' units{i} ')']);
end