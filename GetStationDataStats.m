clc; clear;
% Station name
Astn = 'E1';
% (1 = raw data; 2 = max-min data range boundary; 3 = 98% data range boundary)
drng_type = 1;

d = load(['CTDEEP_' Astn '_QAQC.mat']);
d = d.StationQAQC;
dp_rng = fieldnames(d);
for i = 1:length(dp_rng)
    for av = {'T','S','DO','P','C','pH','rho','DOsat'}
        for nm = 1:12
            c_tmp = d.(dp_rng{i}).(av{1}).check;
            switch drng_type
                case 1
                    iu = find(month(d.(dp_rng{i}).time)==nm);
                case 2
                    iu = find(month(d.(dp_rng{i}).time)==nm & c_tmp~=4);
                case 3
                    iu = find(month(d.(dp_rng{i}).time)==nm & c_tmp==1);
            end
            if ~isempty(iu)
                d_tmp = d.(dp_rng{i}).(av{1}).data(iu);
            else
                d_tmp = 0;
            end
            stats.(dp_rng{i}).(av{1}).nu(nm) = length(iu);
            stats.(dp_rng{i}).(av{1}).mean(nm) = mean(d_tmp(~isnan(d_tmp)));
            stats.(dp_rng{i}).(av{1}).std(nm) = std(d_tmp(~isnan(d_tmp)));
            stats.(dp_rng{i}).(av{1}).bd1(nm) = prctile(d_tmp,1);
            stats.(dp_rng{i}).(av{1}).bd2_5(nm) = prctile(d_tmp,2.5);
            stats.(dp_rng{i}).(av{1}).bd16(nm) = prctile(d_tmp,16);
            stats.(dp_rng{i}).(av{1}).bd50(nm) = prctile(d_tmp,50);
            stats.(dp_rng{i}).(av{1}).bd84(nm) = prctile(d_tmp,84);
            stats.(dp_rng{i}).(av{1}).bd97_5(nm) = prctile(d_tmp,97.5);
            stats.(dp_rng{i}).(av{1}).bd99(nm) = prctile(d_tmp,99);
        end
    end
end