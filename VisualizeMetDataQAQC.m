% 
% Plot the time series of buoy meteorology data from "Buoy_buoy_Met_QAQC.mat"
% Highlight the marked outliers
% 

clc; clear;
buoys = {'ARTG','CLIS1','CLIS2','EXRX','WLIS'};
metVars = {'windSpd_Kts','windSpd_Max','fiveSecAvg_Max','windDir_M', ...
           'airTemp_Avg','relHumid_Avg','baroPress_Avg','dewPT_Avg'};

% Set up parameters
buoy = buoys{1};
av = metVars{1};

d = load(['Buoy_' buoy '_Met_QAQC.mat']);
d = d.MetQAQC;
uyears = unique(year(d.time));

% Plot the time series of meteorology data in all years
figure; hold on; grid on;

for i = 1:length(uyears)
    if ~ismember(uyears(i), [2000,2001]) % Exclude some years
        iu1 = find(year(d.time)==uyears(i));
        [~, mm, dd] = datevec(d.time(iu1));
        dt = datetime(0,mm,dd);
        d_tmp = d.(av).data(iu1);
        plot(dt,d_tmp,'.','DisplayName',num2str(uyears(i)));
        if ~ismember(av, "windDir_M")
            c_tmp = d.(av).check(iu1);
            iu2 = find(c_tmp==4);
            plot(dt(iu2),d_tmp(iu2),'rd','HandleVisibility','off');
            if ismember(av, "windSpd_Kts")
                c_jump = d.(av).jumpCheck(iu1);
                iu3 = find(c_jump==4);
                plot(dt(iu3),d_tmp(iu3),'ro','HandleVisibility','off');
            end
        else
            c_jump = d.(av).jumpCheck(iu1);
            iu3 = find(c_jump==4);
            plot(dt(iu3),d_tmp(iu3),'ro','HandleVisibility','off');
        end
    end
end

xticks(datetime(0,1:12,1));
xtickformat('MMM/dd');
ylabel(strrep(av,'_','\_'));
title([buoy ' (' strrep(av,'_','\_') ')']);
legend('Location','eastoutside');

% saveas(gcf, [buoy '_Met_QAQC (' av ').png']);