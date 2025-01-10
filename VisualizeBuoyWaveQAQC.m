% 
% Plot the time series of buoy meteorology data
% 

clc; clear;

% Set up parameters
buoy = 'WLIS'; Ayear = 2024;
avars = {'Hsig_m','Hmax_m','Tdom_s','Tavg_s','waveDir','meanDir'};
vnames = {'Hsig','Hmax','Tdom','Tavg','waveDir','meanDir'};
units = {'m','m','s','s','degrees','degrees'};

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','buoyQAQC','PortNumber',5432);
dT = sqlread(conn, ['"' buoy '_Wave_QAQC"']);
dT = dT(year(dT.TmStamp)==Ayear, :);
close(conn);

% Plot the time series of buoy meteorology data
figure; tiledlayout(6,1);
for i = 1:6
    nexttile(i); hold on; grid on;
    
    % Plot original data points
    plot(dT.TmStamp,dT.(avars{i}),'b.','HandleVisibility','off');
    
    % Highlight the outliers
    iu1 = find(floor(dT.([avars{i} '_Q'])/1000)~=1);
    plot(dT.TmStamp(iu1),dT.(avars{i})(iu1),'rs','DisplayName','1-Threshold');
    iu2 = find(mod(floor(dT.([avars{i} '_Q'])/100),10)~=1);
    plot(dT.TmStamp(iu2),dT.(avars{i})(iu2),'ro','DisplayName','2-JumpLim');
    iu3 = find(mod(floor(dT.([avars{i} '_Q'])/10),10)~=1);
    plot(dT.TmStamp(iu3),dT.(avars{i})(iu3),'gd','DisplayName','3-Gap');
    iu4 = find(mod(dT.([avars{i} '_Q']),10)~=1);
    plot(dT.TmStamp(iu4),dT.(avars{i})(iu4),'r^','DisplayName','4-Spike');
    
    xticks(datetime(Ayear,1:12,1));
    xtickformat('MMM/dd');
    ylabel([vnames{i} ' (' units{i} ')']);
    if i == 1
        legend show;
        lgd = legend('show');
        lgd.Orientation = 'horizontal';
        lgd.Layout.Tile = 'south';
    end
end