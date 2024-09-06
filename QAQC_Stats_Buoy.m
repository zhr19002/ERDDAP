% 
% Generate a statistics table of QAQC results from "Buoy_buoy_QAQC.mat"
% 

clc; clear;
iloc = 1;

buoy = 'ARTG'; locs = {'btm1','btm2','sfc'};
% buoy = 'EXRX'; locs = {'btm2','mid','sfc'};
% buoy = 'WLIS'; locs = {'btm1','btm2','mid','sfc'};
% buoy = 'CLIS'; locs = {'btm','sfc'};

d = load(['Buoy_' buoy '_QAQC.mat']);
avar = ["T";"S";"DO";"P";"C";"rho";"pH";"DOsat"];

% Statistics of QAQC results
stats_tbl = table((0:5)','VariableNames',{'FailedCount'});
for av = 1:length(avar)
    tmp = tabulate(d.BuoyQAQC.(locs{iloc}).(avar{av}).FailedCount);
    for n = 0:5
        if ~ismember(n,tmp(:,1))
            tmp = [tmp; [n 0 0]];
        end
    end
    tmp = sortrows(tmp);
    av_count = arrayfun(@(i) sprintf('%d (%.2f%%)', tmp(i,2), tmp(i,3)), 1:6, 'UniformOutput', false);
    stats_tbl.(avar{av}) = av_count';
end
disp(stats_tbl);