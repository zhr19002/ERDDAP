% 
% Plot the time series of station climatology data from "CTDEEP_Astn_QAQC.mat"
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

% Flags to avoid duplicate legends
hasSus = false;
hasFail = false;

for i = 1:length(dp_rng)
    nexttile(i)
    hold on; grid on;
    
    d.(dp_rng{i}).time.Year = 0;
    dt = d.(dp_rng{i}).time;
    d_tmp = d.(dp_rng{i}).(av).data;
    c_tmp = d.(dp_rng{i}).(av).check;
    
    % Plot the time series of station climatology data in all years
    plot(dt,d_tmp,'b.','HandleVisibility','off');
    
    % Highlight the outliers
    iu1 = find(c_tmp==3);
    if ~isempty(iu1)
        if ~hasSus
            plot(dt(iu1),d_tmp(iu1),'gs','DisplayName','Suspicious');
            hasSus = true;
        else
            plot(dt(iu1),d_tmp(iu1),'gs','HandleVisibility','off');
        end
    end
    iu2 = find(c_tmp==4);
    if ~isempty(iu2)
        if ~hasFail
            plot(dt(iu2),d_tmp(iu2),'rs','DisplayName','Fail');
            hasFail = true;
        else
            plot(dt(iu2),d_tmp(iu2),'gs','HandleVisibility','off');
        end
    end
    
    xticks(datetime(0,1:12,1));
    xtickformat('MMM/dd');
    ylabel(av);
    depth = replace(dp_rng{i}(7:end),'_','-');
    title([Astn ' (' depth 'm)']);
    if i == 1
        legend show;
        lgd = legend('show');
        lgd.Orientation = 'horizontal';
        lgd.Layout.Tile = 'south';
    end
end

% saveas(gcf, [Astn '_QAQC (' av ').png']);