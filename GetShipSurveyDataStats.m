clc; clear;
% Year range
Ayear0 = 2021; Ayear1 = 2021;
% (1 = raw data; 2 = max-min data range boundary; 3 = 98% data range boundary)
drng_type = 1;

d = load(['CTDEEP_Cruises_' num2str(Ayear0) '_' num2str(Ayear1) '_QAQC.mat']);
d = d.ShipSurveyQAQC;
crs = fieldnames(d);
for i = 1:length(crs)
    stn = fieldnames(d.(crs{i}));
    for j = 1:length(stn)
        dp = fieldnames(d.(crs{i}).(stn{j}));
        for k = 1:length(dp)
            for av = {'T','S','DO','P','C','pH','rho','DOsat'}
                switch drng_type
                    case 1
                        iu = find(d.(crs{i}).(stn{j}).(dp{k}).(av{1}).check~=0);
                    case 2
                        iu = find(d.(crs{i}).(stn{j}).(dp{k}).(av{1}).check~=4);
                    case 3
                        iu = find(d.(crs{i}).(stn{j}).(dp{k}).(av{1}).check==1);
                end
                if ~isempty(iu)
                    tmp = d.(crs{i}).(stn{j}).(dp{k}).(av{1}).data(iu);
                else
                    tmp = 0;
                end
                stats.(crs{i}).(stn{j}).(dp{k}).(av{1}).mean = mean(tmp(~isnan(tmp)));
                stats.(crs{i}).(stn{j}).(dp{k}).(av{1}).std = std(tmp(~isnan(tmp)));
            end
        end
    end
end