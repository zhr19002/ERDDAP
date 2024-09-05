% 
% Generate a statistics table of QAQC results from "Buoy_buoy_Wave_QAQC.mat"
% 

clc; clear;
buoy = 'CLIS'; % {'CLIS','EXRX','WLIS'}
waveVars = {'Hsig_m','Hmax_m','Tdom_s','Tavg_s','waveDir','meanDir'};

d = load(['Buoy_' buoy '_Wave_QAQC.mat']);
d = d.waveQAQC;

% Statistics of QAQC results
stats_tbl = table((1:4)','VariableNames',{'Flag'});
for i = 1:length(waveVars)
    if ismember(waveVars{i}, ["waveDir","meanDir"])
        tmp = tabulate(d.(waveVars{i}).jumpCheck);
    else
        tmp = tabulate(d.(waveVars{i}).check);
    end
    % Count # of flags from 1 to 4
    for n = 1:4
        if ~ismember(n,tmp(:,1))
            tmp = [tmp; [n 0 0]];
        end
    end
    tmp = sortrows(tmp);
    av_count = arrayfun(@(i) sprintf('%d (%.2f%%)', tmp(i,2), tmp(i,3)), 1:4, 'UniformOutput', false);
    stats_tbl.(waveVars{i}) = av_count';
end
disp(stats_tbl);