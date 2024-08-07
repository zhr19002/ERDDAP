clc; clear;
% Station name
Astn = 'E1';

d = load(['CTDEEP_' Astn '_QAQC.mat']);
d = d.StationQAQC;

dp_rng = fieldnames(d);
for i = 1:length(dp_rng)
    for av = {'T','S','DO','P','C','pH','rho','DOsat'}
        for nm = 1:12
            iu = find(month(d.(dp_rng{i}).time)==nm);
            if ~isempty(iu)
                d_tmp = d.(dp_rng{i}).(av{1}).data(iu);
            else
                d_tmp = 0;
            end
            stats.(dp_rng{i}).(av{1}).nu(nm) = length(iu);
            stats.(dp_rng{i}).(av{1}).bd1(nm) = prctile(d_tmp,1);
            stats.(dp_rng{i}).(av{1}).bd99(nm) = prctile(d_tmp,99);
        end
    end
end