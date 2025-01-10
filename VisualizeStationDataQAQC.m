% 
% Plot the time series of station climatology data
% Highlight the marked outliers
% 

clc; clear;

% Set up parameters
Astn = 'E1'; dpL = 0; dpU = 5;
avars = {'T','S','DO','P','C','pH','rho','DOsat'};
units = {'degC','psu','mg/L','dBars','S/m','/','kg/m3','percent'};

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','stationQAQC','PortNumber',5432);
d = sqlread(conn, ['"DEEP_' Astn '_WQ_QAQC"']);
close(conn);

% Preprocess data
d = d((d.depth>=dpL & d.depth<dpU), :);
d.time.Year = 0;
d.S_data(d.S_data < 5) = NaN;
d.C_data(d.C_data > 50) = NaN;
d.rho_data(d.rho_data < 15) = NaN;

figure; tiledlayout(4,2);

for i = 1:length(avars)
    nexttile(i)
    hold on; grid on;
    
    d_tmp = d.([avars{i} '_data']);
    c_tmp = d.([avars{i} '_Q']);
    
    % Plot the time series of station climatology data in all years
    plot(d.time,d_tmp,'b.','HandleVisibility','off');
    
    % Highlight the outliers
    iu1 = find(c_tmp==3);
    plot(d.time(iu1),d_tmp(iu1),'gs','DisplayName','Suspicious');
    iu2 = find(c_tmp==4);
    plot(d.time(iu2),d_tmp(iu2),'rs','DisplayName','Fail');
    
    xticks(datetime(0,1:12,1));
    xtickformat('MMM/dd');
    ylabel([avars{i} ' (' units{i} ')']);
    title([Astn ' (' avars{i} ') at ' num2str(dpL) '-' num2str(dpU) 'm']);
    if i == 1
        legend show;
        lgd = legend('show');
        lgd.Orientation = 'horizontal';
        lgd.Layout.Tile = 'south';
    end
end

% saveas(gcf, [Astn '_QAQC.png']);