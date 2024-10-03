% 
% Generate a statistics table of QAQC results from "Buoy_buoy_Met_QAQC.mat"
% 

clc; clear;

buoy = 'ARTG'; % {'ARTG','CLIS1','CLIS2','EXRX','WLIS'}

d = load(['Buoy_' buoy '_Met_QAQC.mat']);
d = d.MetQAQC;
metVars = ["windSpd_Kts";"windSpd_Max";"fiveSecAvg_Max";"windDir_M"; ...
           "airTemp_Avg";"relHumid_Avg";"baroPress_Avg";"dewPT_Avg"];

% Statistics of QAQC results
stats_tbl = table((0:4)','VariableNames',{'FailedCount'});
for i = 1:length(metVars)
    tmp = tabulate(d.(metVars{i}).FailedCount);
    for n = 0:4
        if ~ismember(n,tmp(:,1))
            tmp = [tmp; [n 0 0]];
        end
    end
    tmp = sortrows(tmp);
    av_count = arrayfun(@(i) sprintf('%d (%.2f%%)', tmp(i,2), tmp(i,3)), 1:5, 'UniformOutput', false);
    stats_tbl.(metVars{i}) = av_count';
end
disp(stats_tbl);