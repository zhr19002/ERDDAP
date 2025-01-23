% 
% Plot the time series of station nutrient data
% Highlight the marked outliers
% 

clc; clear;

% Set up parameters
Astn = 'E1';
avars = {'PAR','CHLA','BIOSI-LC','DIP','DOC','NH#-LC','NOX-LC'};
units = {'uE/S/m2','ug/L','mg/L','mg/L','mg/L','mg/L','mg/L'};
% avars = {'PC','PN','PP-LC','SIO2-LC','TDN-LC','TDP','TSS'};
% units = {'mg/L','mg/L','mg/L','mg/L','mg/L','mg/L','mg/L'};

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','stationQAQC','PortNumber',5432);
d1 = sqlread(conn, ['"DEEP_' Astn '_WQ_QAQC"']);
d2 = sqlread(conn, ['"DEEP_' Astn '_Nutrient_QAQC"']);
close(conn);

% Preprocess data
d1 = d1((d1.depth>=0 & d1.depth<5), :);
d1.time.Year = 0;
d1.Properties.VariableNames = strrep(d1.Properties.VariableNames, 'Corrected_Chl', 'CHLA');
d2 = d2(startsWith(d2.Depth_Code, 'S'), :);
d2.time.Year = 0;

figure; tiledlayout(4,2);

for i = 1:length(avars)
    nexttile(i)
    hold on; grid on;
    
    if ismember(avars{i}, {'PAR','CHLA'})
        d = d1;
        d_tmp = d.([avars{i} '_data']);
        c_tmp = d.([avars{i} '_Q']);
    else
        d = d2;
        d = d(strcmp(d.Parameter, avars{i}), :);
        d_tmp = d.Result;
        c_tmp = d.Result_Q;
    end
    
    % Plot the time series of station nutrient data in all years
    plot(d.time,d_tmp,'b.','HandleVisibility','off');
    
    % Highlight the outliers
    iu1 = find(c_tmp==3);
    plot(d.time(iu1),d_tmp(iu1),'gs','DisplayName','Suspicious');
    iu2 = find(c_tmp==4);
    plot(d.time(iu2),d_tmp(iu2),'rs','DisplayName','Fail');
    
    xticks(datetime(0,1:12,1));
    xtickformat('MMM/dd');
    ylabel([avars{i} ' (' units{i} ')']);
    title([Astn ' (' avars{i} ') at the surface']);
    if i == 1
        legend show;
        lgd = legend('show');
        lgd.Orientation = 'horizontal';
        lgd.Layout.Tile = 'south';
    end
end