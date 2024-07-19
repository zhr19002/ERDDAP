clc; clear;

Astn = 'A4';
d = load(['CTDEEP_' Astn '_QAQC.mat']);
avar = ["T";"S";"DO";"P";"C";"rho";"pH";"DOsat"];

% Concatenate QAQC results from structures of different depths
dpth = fieldnames(d.StationQAQC);
for av = 1:length(avar)
    av_check.(avar{av}) = d.StationQAQC.(dpth{1}).(avar{av}).check;
    for dp = 2:length(dpth)
        c_tmp = d.StationQAQC.(dpth{dp}).(avar{av}).check;
        av_check.(avar{av}) = [av_check.(avar{av});c_tmp];
    end
end

% Statistics of QAQC results
stats_tbl = table((1:4)','VariableNames',{'Flag'});
for av = 1:length(avar)
    tmp = tabulate(av_check.(avar{av}));
    for n = 1:4
        if ~ismember(n,tmp(:,1))
            tmp = [tmp; [n 0 0]];
        end
    end
    tmp = sortrows(tmp);
    av_count = arrayfun(@(i) sprintf('%d (%.2f%%)', tmp(i,2), tmp(i,3)), 1:4, 'UniformOutput', false);
    stats_tbl.(avar{av}) = av_count';
end
disp(stats_tbl);