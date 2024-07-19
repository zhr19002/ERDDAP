clc; clear;

buoy = 'ARTG'; locs = {'btm1','btm2','sfc'};
% buoy = 'EXRX'; locs = {'btm2','mid','sfc'};
% buoy = 'CLIS'; locs = {'btm'};

din = load([buoy '_QAQC.mat']);
avar = ["T";"S";"DO";"P";"C";"rho";"pH";"DOsat"];

% Jump limit and spike parameters
min_jmp = zeros(length(avar),1); max_jmp = zeros(length(avar),1);
min_spk = zeros(length(avar),1); max_spk = zeros(length(avar),1);
for av = 1:length(avar)
    % Change location
    d = din.BuoyQAQC.(locs{1}).(avar{av}).data;
    
    % min_jump and max_jump values
    jmp = abs(diff(d));
    jmp = jmp([1 1:end]);
    min_jmp(av) = prctile(jmp,99.5);
    max_jmp(av) = prctile(jmp,99.9);
    
    % min_spike and max_spike values
    spk_ref = (d(1:end-2) + d(3:end))/2;
    spk_ref = spk_ref([1 1:end end]);
    spk = abs(d-spk_ref);
    min_spk(av) = prctile(spk,99.5);
    max_spk(av) = prctile(spk,99.9);
end

jmp_spk_tbl = table(avar,min_jmp,max_jmp,min_spk,max_spk);
disp(jmp_spk_tbl);

%%
% Statistics of QAQC results
stats_tbl = table((0:5)','VariableNames',{'FailedTestsCount'});
for av = 1:length(avar)
    tmp = tabulate(din.BuoyQAQC.(locs{1}).(avar{av}).FailedTestsCount);
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