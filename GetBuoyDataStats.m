clc; clear;
% Buoy name
buoy = 'ARTG';
% (1 = raw data; 2 = max-min data range boundary; 3 = 98% data range boundary)
drng_type = 1;

d = load([buoy '_QAQC.mat']);
d = d.BuoyQAQC;
locs = fieldnames(d);
for i = 1:length(locs)
    for av = {'T','S','DO','P','C','pH','rho','DOsat'}
        switch drng_type
            case 1
                tmp = floor(d.(locs{i}).(av{1}).QAQCTests/10000);
                iu = find(tmp~=0);
            case 2
                tmp = floor(d.(locs{i}).(av{1}).QAQCTests/10000);
                iu = find(tmp~=4);
            case 3
                tmp = floor(d.(locs{i}).(av{1}).QAQCTests/10000);
                iu = find(tmp==1);
        end
        if ~isempty(iu)
            tmp = d.(locs{i}).(av{1}).data(iu);
        else
            tmp = 0;
        end
        stats.(locs{i}).(av{1}).mean = mean(tmp(~isnan(tmp)));
        stats.(locs{i}).(av{1}).std = std(tmp(~isnan(tmp)));
    end
end