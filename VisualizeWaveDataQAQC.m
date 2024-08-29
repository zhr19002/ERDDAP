% 
% Plot the time series of buoy wave data from "Buoy_buoy_Wave_QAQC.mat"
% Highlight the marked outliers
% 

clc; clear;
buoys = {'CLIS','EXRX','WLIS'};
waveVars = {'Hsig_m','Hmax_m','Tdom_s','Tavg_s','DP1','DP2', ...
            'waveDir','meanDir','rmsTilt','maxTilt','GN','chksum'};

% Set up parameters
buoy = buoys{1};
av = waveVars{1};

d = load(['Buoy_' buoy '_Wave_QAQC.mat']);
d = d.waveQAQC;
uyears = unique(year(d.time));

% Plot the time series of wave data in all years
figure; hold on; grid on;

for i = 1:length(uyears)
    if ~ismember(uyears(i), [2000,2001]) % Exclude some years
        iu1 = find(year(d.time)==uyears(i));
        [~, mm, dd] = datevec(d.time(iu1));
        dt = datetime(0,mm,dd);
        d_tmp = d.(av).data(iu1);
        plot(dt,d_tmp,'.','DisplayName',num2str(uyears(i)));
        if ~ismember(av, ["waveDir","meanDir"])
            c_tmp = d.(av).check(iu1);
            iu2 = find(c_tmp==4);
            plot(dt(iu2),d_tmp(iu2),'rd','HandleVisibility','off');
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

% saveas(gcf, [buoy '_Wave_QAQC (' av ').png']);