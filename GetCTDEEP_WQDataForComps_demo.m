% Run a demo
% Calls GetCTDEEP_WQDataForComps.m

Ast = 'E1'; Ayear = '2021'; Nmth = 3:12;

% Get data for the year and month
[dd, ~, ~] = GetCTDEEP_WQDataForComps(Ast, Ayear, Nmth);

% There may be more than 1 cruise to plot the temperature profile
for mth = Nmth
    if size(dd{mth},2) > 0
        figure;
        aleg = cell(size(dd{mth},2), 1);
        for nn = 1:size(dd{mth},2)
            pres = dd{mth}{nn}.DEEP_WQ.sea_water_pressure;
            temp = dd{mth}{nn}.DEEP_WQ.sea_water_temperature;
            plot(temp, -pres, '-'); hold on;
            aleg{nn} = [dd{mth}{nn}.DEEP_WQ.cruise_name(1,:) ': ' ...
                        dd{mth}{nn}.DEEP_WQ.station_name(1,:)];
        end
        legend(aleg,'Location','southeast');
        xlabel('Temperature');
        ylabel('Depth (m)');
    end
end