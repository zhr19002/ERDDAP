% 
% Plot the time series of station climatology data from "CTDEEP_station_QAQC.mat"
% Highlight the marked outliers
% 

clc; clear;

% Set up parameters
Astn = 'E1';
av = 'T'; % {'T','S','DO','P','C','pH','rho','DOsat'}

d = load(['CTDEEP_' Astn '_QAQC.mat']);
d = d.StationQAQC;
dp_rng = fieldnames(d);

figure; tiledlayout(ceil(length(dp_rng)/2),2);

for i = 1:length(dp_rng)
    nexttile(i)
    d.(dp_rng{i}).time.Year = 0;
    dt = d.(dp_rng{i}).time;
    d_tmp = d.(dp_rng{i}).(av).data;
    c_tmp = d.(dp_rng{i}).(av).check;

    % Plot the time series of station climatology data in all years
    plot(dt,d_tmp,'b.','HandleVisibility','off');
    hold on; grid on;
    
    % Highlight the outliers
    iu1 = find(c_tmp==3);
    plot(dt(iu1),d_tmp(iu1),'gs','DisplayName','Suspicious');
    iu2 = find(c_tmp==4);
    plot(dt(iu2),d_tmp(iu2),'rs','DisplayName','Fail');

    xticks(datetime(0,1:12,1));
    xtickformat('MMM/dd');
    ylabel(av);
    depth = replace(dp_rng{i}(7:end),'_','-');
    title([Astn ' (' depth 'm)']);
end

ax = nexttile(1);
lgd = legend('Orientation','horizontal');
lgd.Layout.Tile = 'south';

% saveas(gcf, [Astn '_QAQC (' av ').png']);