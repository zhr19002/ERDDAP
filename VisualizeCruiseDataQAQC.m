% 
% Plot the time series of cruise climatology data from "Cruises_Ayear_QAQC.mat"
% Highlight the marked outliers
% 

clc; clear;

% Set up parameters
Astn = 'E1'; Ayear = 2021;
av = 'T'; % {'T','S','DO','P','C','pH','rho','DOsat'}

d = load(['Cruises_' num2str(Ayear) '_QAQC.mat']);
d = d.CruiseQAQC;
crs = fieldnames(d);
dp_rng = fieldnames(d.(crs{1}).(Astn));

figure; tiledlayout(ceil(length(dp_rng)/2),2);

for i = 1:length(dp_rng)
    nexttile(i)
    for ci = 1:length(crs)
        if contains(crs{ci},num2str(mod(Ayear,100)))
            dt = d.(crs{ci}).(Astn).(dp_rng{i}).time;
            d_tmp = d.(crs{ci}).(Astn).(dp_rng{i}).(av).data;
            c_tmp = d.(crs{ci}).(Astn).(dp_rng{i}).(av).check;

            % Plot the time series of cruise climatology data in Ayear
            plot(dt,d_tmp,'b.','HandleVisibility','off');
            hold on; grid on;
            
            % Highlight the outliers
            iu1 = find(c_tmp==3);
            plot(dt(iu1),d_tmp(iu1),'gs','DisplayName','Suspicious');
            iu2 = find(c_tmp==4);
            plot(dt(iu2),d_tmp(iu2),'rs','DisplayName','Fail');
            
            xticks(datetime(Ayear,1:12,1));
            xtickformat('MMM/dd');
            ylabel(av);
            depth = replace(dp_rng{i}(7:end),'_','-');
            title([Astn '\_Cruises (' depth 'm)']);
        end
    end
end

ax = nexttile(1);
lgd = legend(ax,'Orientation','horizontal');
lgd.Layout.Tile = 'south';

% saveas(gcf, [Astn '_Cruises_' num2str(Ayear) '_QAQC (' av ').png']);