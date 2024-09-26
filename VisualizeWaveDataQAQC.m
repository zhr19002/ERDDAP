% 
% Plot the time series of buoy wave data from "Buoy_buoy_Wave_QAQC.mat"
% Highlight the marked outliers
% 

clc; clear;
buoys = {'CLIS','EXRX','WLIS'};
waveVars = {'Hsig_m','Hmax_m','Tdom_s','Tavg_s','waveDir','meanDir'};

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
        c_tmp = d.(av).QAQC(iu1);
        iu2 = find(floor(c_tmp/1000)~=1);
        plot(dt(iu2),d_tmp(iu2),'ro','HandleVisibility','off');
    end
end

xticks(datetime(0,1:12,1));
xtickformat('MMM/dd');
ylabel(strrep(av,'_','\_'));
title([buoy ' (' strrep(av,'_','\_') ')']);
legend('Location','eastoutside');

% saveas(gcf, [buoy '_Wave_QAQC (' av ').png']);