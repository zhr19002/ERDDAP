clc; clear;
buoy = 'ARTG'; % {'ARTG','CLIS1','CLIS2','EXRX','WLIS'}
metVars = ["windSpd_Kts";"windSpd_Delta";"windSpd_Max";"fiveSecAvg_Max"; ...
           "windDir_M";"airTemp_Avg";"relHumid_Avg";"baroPress_Avg";"dewPT_Avg"];

d = load([buoy '_MET_QAQC.mat']);
d = d.MetQAQC;

% Statistics of MET QAQC results
stats_tbl = table((1:4)','VariableNames',{'Flag'});
for i = 1:length(metVars)
    if ismember(metVars{i}, "windSpd_Delta")
        tmp = tabulate(d.(metVars{1}).deltaCheck);
    elseif ismember(metVars{i}, "windDir_M")
        tmp = tabulate(d.(metVars{i}).deltaCheck);
    else
        tmp = tabulate(d.(metVars{i}).check);
    end
    % Count # of flags from 1 to 4
    for n = 1:4
        if ~ismember(n,tmp(:,1))
            tmp = [tmp; [n 0 0]];
        end
    end
    tmp = sortrows(tmp);
    av_count = arrayfun(@(i) sprintf('%d (%.2f%%)', tmp(i,2), tmp(i,3)), 1:4, 'UniformOutput', false);
    stats_tbl.(metVars{i}) = av_count';
end
disp(stats_tbl);