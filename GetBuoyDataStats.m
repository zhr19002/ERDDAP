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
        for nm = 1:12
            c_tmp = d.(locs{i}).(av{1}).QAQCTests;
            switch drng_type
                case 1
                    iu = find(month(d.(locs{i}).time)==nm);
                case 2
                    iu = find(month(d.(locs{i}).time)==nm & floor(c_tmp/10000)~=4);
                case 3
                    iu = find(month(d.(locs{i}).time)==nm & floor(c_tmp/10000)==1);
            end
            if ~isempty(iu)
                d_tmp = d.(locs{i}).(av{1}).data(iu);
            else
                d_tmp = 0;
            end
            stats.(locs{i}).(av{1}).nu(nm) = length(iu);
            stats.(locs{i}).(av{1}).mean(nm) = mean(d_tmp(~isnan(d_tmp)));
            stats.(locs{i}).(av{1}).std(nm) = std(d_tmp(~isnan(d_tmp)));
        end
    end
end