% 
% Generate a statistics table of QAQC results from "Buoy_buoy_QAQC.mat"
% 

clc; clear;

iloc = 1;

buoy = 'ARTG'; locs = {'btm1','btm2','sfc'};
% buoy = 'EXRX'; locs = {'btm2','mid','sfc'};
% buoy = 'CLIS'; locs = {'btm'};
% buoy = 'WLIS'; locs = {'btm1','btm2','mid','sfc'};
% buoy = 'clis_cr1x'; locs = {'Btm','Sfc'};

d = load(['Buoy_' buoy '_QAQC.mat']);
avar = ["T";"S";"DO";"P";"C";"rho";"pH";"DOsat"];
bvar = ["timeQ";"depthQ"];

% Statistics of QAQC results
stats_tbl = table((0:3)','VariableNames',{'FailedTestsCount'});
for av = 1:length(avar)
    tmp = tabulate(d.BuoyQAQC.(locs{iloc}).(avar{av}).FailedTestsCount);
    for n = 0:3
        if ~ismember(n,tmp(:,1))
            tmp = [tmp; [n 0 0]];
        end
    end
    tmp = sortrows(tmp);
    av_count = arrayfun(@(i) sprintf('%d (%.2f%%)', tmp(i,2), tmp(i,3)), 1:4, 'UniformOutput', false);
    stats_tbl.(avar{av}) = av_count';
end
disp(stats_tbl);

% Statistics of timeQ & depthQ
stats_tbl2 = table((1:4)','VariableNames',{'Flag'});
for av = 1:length(bvar)
    tmp = tabulate(d.BuoyQAQC.(locs{iloc}).(bvar{av}));
    for n = 1:4
        if ~ismember(n,tmp(:,1))
            tmp = [tmp; [n 0 0]];
        end
    end
    tmp = sortrows(tmp);
    av_count = arrayfun(@(i) sprintf('%d (%.2f%%)', tmp(i,2), tmp(i,3)), 1:4, 'UniformOutput', false);
    stats_tbl2.(bvar{av}) = av_count';
end
disp(stats_tbl2);