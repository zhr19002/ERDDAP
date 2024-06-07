function stats = GetDEEPWQClimStats(Astn, ZT, ZB, av)
% 
% Return the stats of station climatology data
% av = {'T','S','DO','P','C','pH','rho','DOsat'}
% 
% Calls GetDEEPWQClimData.m
% Called from CheckStationDataQAQC.m
% 

d = GetDEEPWQClimData(Astn, ZT, ZB);
daten = d.Start_Date/(24*3600) + datetime(1970,1,1);
av_stn = struct('T','sea_water_temperature','S','sea_water_salinity', ...
                'DO','oxygen_concentration_in_sea_wat','pH','pH', ...
                'P','sea_water_pressure','C','sea_water_electrical_conductivi', ...
                'rho','sea_water_density','DOsat','percent_saturation');

for nm = 1:12
    iu = find(month(daten)==nm);
    stats.ndays(nm) = length(unique(daten(iu)));
    stats.nu(nm) = length(iu);
    tmp = d.(av_stn.(av))(iu);
    stats.mean(nm) = mean(tmp(~isnan(tmp)));
    stats.std(nm) = std(tmp(~isnan(tmp)));
    stats.bd1(nm) = prctile(tmp,1);
    stats.bd2_5(nm) = prctile(tmp,2.5);
    stats.bd16(nm) = prctile(tmp,16);
    stats.bd50(nm) = prctile(tmp,50);
    stats.bd84(nm) = prctile(tmp,84);
    stats.bd97_5(nm) = prctile(tmp,97.5);
    stats.bd99(nm) = prctile(tmp,99);
end

stats.data = NaN(max(stats.nu), 12);
for nm = 1:12
    iu = find(month(daten)==nm);
    stats.data(1:length(iu),nm) = d.(av_stn.(av))(iu);
end

end