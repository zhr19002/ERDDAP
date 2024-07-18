clc; clear;

Astn = 'A4';
d = load(['CTDEEP_' Astn '_QAQC.mat']);
avar = ["T";"S";"DO";"P";"C";"rho";"pH";"DOsat"];
dp_rng = fieldnames(d.StationQAQC);

% Concatenate QAQC results from structures of different depths
for i = 1:length(avar)
    av_check.(avar{i}) = d.StationQAQC.(dp_rng{1}).(avar{i}).check;
    for j = 2:length(dp_rng)
        c_tmp = d.StationQAQC.(dp_rng{j}).(avar{i}).check;
        av_check.(avar{i}) = [av_check.(avar{i});c_tmp];
    end
end

% Statistics of QAQC results
stats_tbl = table([1;2;3;4],'VariableNames',{'Flag'});
for i = 1:length(avar)
    tmp = tabulate(av_check.(avar{i}));
    for j = [1 3 4]
        if ~ismember(j,tmp(:,1))
            tmp = [tmp; [j 0 0]];
        end
    end
    tmp = sortrows(tmp);
    av_count = arrayfun(@(k) sprintf('%d (%.2f%%)', tmp(k,2), tmp(k,3)), 1:4, 'UniformOutput', false);
    stats_tbl.(avar{i}) = av_count';
end
disp(stats_tbl);