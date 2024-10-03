% 
% Generate a statistics table of QAQC results from "Buoy_buoy_Wave_QAQC.mat"
% 

clc; clear;

buoy = 'CLIS'; % {'CLIS','EXRX','WLIS'}

d = load(['Buoy_' buoy '_Wave_QAQC.mat']);
d = d.waveQAQC;
waveVars = {'Hsig_m','Hmax_m','Tdom_s','Tavg_s','waveDir','meanDir'};

% Statistics of QAQC results
stats_tbl = table((0:4)','VariableNames',{'FailedCount'});
for i = 1:length(waveVars)
    tmp = tabulate(d.(waveVars{i}).FailedCount);
    for n = 0:4
        if ~ismember(n,tmp(:,1))
            tmp = [tmp; [n 0 0]];
        end
    end
    tmp = sortrows(tmp);
    av_count = arrayfun(@(i) sprintf('%d (%.2f%%)', tmp(i,2), tmp(i,3)), 1:5, 'UniformOutput', false);
    stats_tbl.(waveVars{i}) = av_count';
end
disp(stats_tbl);