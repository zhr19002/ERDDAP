clc; clear;

buoys = {'ARTG1','CLIS1','EXRX1','EXRX2','EXRX3','WLIS1','WLIS2','clis2','clis3'};
metVars = {'windSpd_Kts','windDir_M','windDir_STD','windSpd_Max','windDir_SMM', ...
           'fiveSecAvg_Max','airTemp_Avg','relHumid_Avg','baroPress_Avg','dewPT_Avg'};

% Set up parameters
buoy = buoys{2};
av = metVars{10};

d = load([buoy '_MET_QAQC.mat']);
d = d.BuoyQAQC;

% Print min and max values of a variable in multiple years
uyears = unique(year(d.time));
for i = 1:length(uyears)
    iu = find(year(d.time)==uyears(i));
    d_tmp = d.(av).data(iu);
    fprintf('Year %d: values = [%f, %f]\n', uyears(i), min(d_tmp), max(d_tmp));
end

%%
% Plot time series for buoy MET data in multiple years
figure;
hold on; grid on;
for i = 1:length(uyears)
    % Exclude one year
    if uyears(i) ~= 2000
        iu = find(year(d.time)==uyears(i));
        [~, mm, dd] = datevec(d.time(iu));
        d_tmp = d.(av).data(iu);
        plot(datetime(0,mm,dd),d_tmp,'.','DisplayName',num2str(uyears(i)));
    end
end
xticks(datetime(0,1:12,1));
xtickformat('MMM/dd');
ylabel(av);
legend('Location','eastoutside');