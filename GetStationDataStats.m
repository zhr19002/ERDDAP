clc; clear;
Astn = 'E1';
d = load(['CTDEEP_' Astn '_QAQC.mat']);

dp_rng = fieldnames(d.stationQAQC);
for i = 1:length(dp_rng)
    for av = {'T','S','DO','P','C','pH','rho','DOsat'}
        iu = find(d.stationQAQC.(dp_rng{i}).(av{1}).check==1);
        if ~isempty(iu)
            tmp = d.stationQAQC.(dp_rng{i}).(av{1}).data(iu);
        else
            tmp = 0;
        end
        stats.(dp_rng{i}).(av{1}).mean = mean(tmp);
        stats.(dp_rng{i}).(av{1}).std = std(tmp);
        stats.(dp_rng{i}).(av{1}).bd1 = prctile(tmp,1);
        stats.(dp_rng{i}).(av{1}).bd2_5 = prctile(tmp,2.5);
        stats.(dp_rng{i}).(av{1}).bd16 = prctile(tmp,16);
        stats.(dp_rng{i}).(av{1}).bd50 = prctile(tmp,50);
        stats.(dp_rng{i}).(av{1}).bd84 = prctile(tmp,84);
        stats.(dp_rng{i}).(av{1}).bd97_5 = prctile(tmp,97.5);
        stats.(dp_rng{i}).(av{1}).bd99 = prctile(tmp,99);
    end
end
        
