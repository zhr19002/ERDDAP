clc; clear;
buoys = {'ARTG','CLIS1','CLIS2','EXRX','WLIS'};
metVars = {'windSpd_Kts','windDir_M','windDir_STD','windSpd_Max','windDir_SMM', ...
           'fiveSecAvg_Max','airTemp_Avg','relHumid_Avg','baroPress_Avg','dewPT_Avg'};

% Set up parameters
buoy = buoys{1};
av = metVars{1};

d = load([buoy '_MET_QAQC.mat']);
d = d.MetQAQC;

% Print min and max values of a variable in multiple years
uyears = unique(year(d.time));
for i = 1:length(uyears)
    iu = find(year(d.time)==uyears(i));
    d_tmp = d.(av).data(iu);
    fprintf('Year %d: values = [%f, %f]\n', uyears(i), min(d_tmp), max(d_tmp));
end

% Plot time series for buoy MET data in multiple years
figure;
hold on; grid on;
for i = 1:length(uyears)
    if ~ismember(uyears(i), [2001]) % Exclude one year
        iu1 = find(year(d.time)==uyears(i));
        [~, mm, dd] = datevec(d.time(iu1));
        dt = datetime(0,mm,dd);
        d_tmp = d.(av).data(iu1);
        c_tmp = d.(av).check(iu1);
        plot(dt,d_tmp,'.','DisplayName',num2str(uyears(i)));
        iu2 = find(c_tmp==4);
        plot(dt(iu2),d_tmp(iu2),'rs','HandleVisibility','off');
    end
end
xticks(datetime(0,1:12,1));
xtickformat('MMM/dd');
ylabel(strrep(av,'_','\_'));
title([buoy ' (' strrep(av,'_','\_') ')']);
legend('Location','eastoutside');