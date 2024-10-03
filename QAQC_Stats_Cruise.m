% 
% Generate a statistics table of QAQC results from "Cruises_Ayear_QAQC.mat"
% 

clc; clear;

Ayear = 2021;

d = load(['Cruises_' num2str(Ayear) '_QAQC.mat']);
d = d.CruiseQAQC;
avar = ["T";"S";"DO";"P";"C";"rho";"pH";"DOsat"];

% Concatenate QAQC results from structures of different cruises, stations, and depths
crs = fieldnames(d);
for i = 1:length(avar)
    for j = 1:length(crs)
        stn = fieldnames(d.(crs{j}));
        for k = 1:length(stn)
            d_tmp = d.(crs{j}).(stn{k});
            dpth = fieldnames(d_tmp);
            av_check.(avar{i}) = d_tmp.(dpth{1}).(avar{i}).check;
            for dp = 2:length(dpth)
                c_tmp = d_tmp.(dpth{dp}).(avar{i}).check;
                av_check.(avar{i}) = [av_check.(avar{i});c_tmp];
            end
        end
    end
end

% Statistics of QAQC results
stats_tbl = table((1:4)','VariableNames',{'Flag'});
for i = 1:length(avar)
    tmp = tabulate(av_check.(avar{i}));
    for n = 1:4
        if ~ismember(n,tmp(:,1))
            tmp = [tmp; [n 0 0]];
        end
    end
    tmp = sortrows(tmp);
    av_count = arrayfun(@(i) sprintf('%d (%.2f%%)', tmp(i,2), tmp(i,3)), 1:4, 'UniformOutput', false);
    stats_tbl.(avar{i}) = av_count';
end
disp(stats_tbl);