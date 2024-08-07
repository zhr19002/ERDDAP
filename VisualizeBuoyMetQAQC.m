clc; clear;
buoys = {'ARTG','CLIS1','CLIS2','EXRX','WLIS'};
metVars = {'windSpd_Kts','windSpd_Max','fiveSecAvg_Max','windDir_M', ...
           'airTemp_Avg','relHumid_Avg','baroPress_Avg','dewPT_Avg'};

% Set up parameters
buoy = buoys{1};
av = metVars{1};

d = load([buoy '_MET_QAQC.mat']);
d = d.MetQAQC;

% Plot time series for MET data in multiple years
figure;
hold on; grid on;
uyears = unique(year(d.time));
for i = 1:length(uyears)
    if ~ismember(uyears(i), [2000,2001]) % Exclude one year
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
                c_delta = d.(av).deltaCheck(iu1);
                iu3 = find(c_delta==4);
                plot(dt(iu3),d_tmp(iu3),'ro','HandleVisibility','off');
            end
        else
            c_delta = d.(av).deltaCheck(iu1);
            iu3 = find(c_delta==4);
            plot(dt(iu3),d_tmp(iu3),'ro','HandleVisibility','off');
        end
    end
end
xticks(datetime(0,1:12,1));
xtickformat('MMM/dd');
ylabel(strrep(av,'_','\_'));
title([buoy ' (' strrep(av,'_','\_') ')']);
legend('Location','eastoutside');