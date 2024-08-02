clc; clear;
buoy = 'ARTG'; % {'ARTG','CLIS1','CLIS2','EXRX','WLIS'}
metVars = ["windSpd_Kts";"windDir_M";"windDir_STD";"windSpd_Max";"windDir_SMM"; ...
           "fiveSecAvg_Max";"airTemp_Avg";"relHumid_Avg";"baroPress_Avg";"dewPT_Avg"];

d = load([buoy '_MET_QAQC.mat']);
d = d.MetQAQC;

% Statistics of MET QAQC results
stats_tbl = table((1:4)','VariableNames',{'Flag'});
for av = 1:length(metVars)
    tmp = tabulate(d.(metVars{av}).check);
    for n = 1:4
        if ~ismember(n,tmp(:,1))
            tmp = [tmp; [n 0 0]];
        end
    end
    tmp = sortrows(tmp);
    av_count = arrayfun(@(i) sprintf('%d (%.2f%%)', tmp(i,2), tmp(i,3)), 1:4, 'UniformOutput', false);
    stats_tbl.(metVars{av}) = av_count';
end
disp(stats_tbl);