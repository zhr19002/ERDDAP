% Run a demo
% Calls GetCTDEEP_WQDataForComps.m

Ast = 'A4'; Ayear = '2022'; Nmth = 7;

% Get data for the year and month
[dd, ~, ~] = GetCTDEEP_WQDataForComps(Ast, Ayear, Nmth);

% There may be more than 1 cruise to plot the temperature profile
if size(dd{Nmth},2) > 0
    figure;
    aleg = cell(size(dd{Nmth},2), 1);
    for nn = 1:size(dd{Nmth},2)
        pres = dd{Nmth}{nn}.DEEP_WQ.sea_water_pressure;
        temp = dd{Nmth}{nn}.DEEP_WQ.sea_water_temperature;
        plot(temp, -pres, '-'); hold on;
        aleg{nn} = [dd{Nmth}{nn}.DEEP_WQ.cruise_name(1,:) ': ' ...
                    dd{Nmth}{nn}.DEEP_WQ.station_name(1,:)];
    end
    legend(aleg, 'location', 'eastoutside');
    xlabel('Temperature');
    ylabel('depth (m)');
end