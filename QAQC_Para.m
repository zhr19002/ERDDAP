clc; clear;

buoy = 'ARTG'; locs = {'btm1','btm2','sfc'};
% buoy = 'EXRX'; locs = {'btm2','mid','sfc'};
% buoy = 'CLIS'; locs = {'btm'};

din = load([buoy '_QAQC.mat']);
avar = ["T";"S";"DO";"P";"C";"rho";"pH";"DOsat"];

% Jump limit and spike parameters
min_jmp = zeros(length(avar),1); max_jmp = zeros(length(avar),1);
min_spk = zeros(length(avar),1); max_spk = zeros(length(avar),1);
for i = 1:length(avar)
    % Change location
    d = din.BuoyQAQC.(locs{1}).(avar{i}).data;
    
    % min_jump and max_jump values
    jmp = abs(diff(d));
    jmp = jmp([1 1:end]);
    min_jmp(i) = prctile(jmp,99.5);
    max_jmp(i) = prctile(jmp,99.9);
    
    % min_spike and max_spike values
    spk_ref = (d(1:end-2) + d(3:end))/2;
    spk_ref = spk_ref([1 1:end end]);
    spk = abs(d-spk_ref);
    min_spk(i) = prctile(spk,99.5);
    max_spk(i) = prctile(spk,99.9);
end

jmp_spk_tbl = table(avar,min_jmp,max_jmp,min_spk,max_spk);
disp(jmp_spk_tbl);

%%
% Statistics of QAQC results
stats_tbl = table([0;1;2;3;4],'VariableNames',{'FailedTestsCount'});
for i = 1:length(avar)
    tmp = tabulate(din.BuoyQAQC.(locs{1}).(avar{i}).FailedTestsCount);
    av_count = arrayfun(@(ii) sprintf('%d (%.2f%%)', tmp(ii,2), tmp(ii,3)), 1:height(tmp), 'UniformOutput', false);
    stats_tbl.(avar{i}) = av_count';
end
disp(stats_tbl);