function res = GetDEEPWQClimStats(Astn, ZT, ZB, av)
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
    res.ndays(nm) = length(unique(daten(iu)));
    res.nu(nm) = length(iu);
    tmp = d.(av_stn.(av))(iu);
    res.mninfo(nm) = mean(tmp(~isnan(tmp)));
    tmp = d.(av_stn.(av))(iu);
    res.sdinfo(nm) = std(tmp(~isnan(tmp)));
    res.bd99lower(nm) = prctile(d.(av_stn.(av))(iu),0.5);
    res.bd95lower(nm) = prctile(d.(av_stn.(av))(iu),2.5);
    res.bd16(nm) = prctile(d.(av_stn.(av))(iu),16);
    res.bd50(nm) = prctile(d.(av_stn.(av))(iu),50);
    res.bd84(nm) = prctile(d.(av_stn.(av))(iu),84);
    res.bd95upper(nm) = prctile(d.(av_stn.(av))(iu),97.5);
    res.bd99upper(nm) = prctile(d.(av_stn.(av))(iu),99.5);
end

res.data = NaN(max(res.nu), 12);
for nm = 1:12
    iu = find(month(daten)==nm);
    res.data(1:length(iu),nm) = d.(av_stn.(av))(iu);
end

end