% 
% Run a demo
% Calls GetCTDEEP_WQDataForComps.m
% 

clc; clear;
Astn = 'E1'; Ayear = 2021; Nmth = 1:12;

% Get data for the year and month
[dd, ~, ~] = GetCTDEEP_WQDataForComps(Astn, Ayear, Nmth);

% There may be more than 1 cruise to plot the temperature profile
for mnth = Nmth
    if size(dd{mnth},2) > 0
        figure;
        aleg = cell(size(dd{mnth},2), 1);
        for nn = 1:size(dd{mnth},2)
            pres = dd{mnth}{nn}.DEEP_WQ.sea_water_pressure;
            temp = dd{mnth}{nn}.DEEP_WQ.sea_water_temperature;
            plot(temp, -pres, '-'); hold on;
            aleg{nn} = [dd{mnth}{nn}.DEEP_WQ.cruise_name(1,:) ': ' ...
                        dd{mnth}{nn}.DEEP_WQ.station_name(1,:)];
        end
        legend(aleg,'Location','southeast');
        xlabel('Temperature');
        ylabel('Depth (m)');
    end
end