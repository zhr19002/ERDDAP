function res = GetDEEPWQClimStats(Astn, ZT, ZB, avar)
% 
% Return the stats of station climatology data
% avar = {'T','S','DO','P','C','pH','rho','DOsat'}
% 
% Calls GetDEEPWQClimData.m
% Called from CheckStationDataQAQC.m
% 

% astn = 'E1'; ZT = 0; ZB = 3; avar = 'T';

d = GetDEEPWQClimData(Astn, ZT, ZB);
daten = d.Start_Date/(24*3600) + datetime(1970,1,1);

% Average by month
[~, mnth, ~] = datevec(daten);

avar_station = struct('T','sea_water_temperature','S','sea_water_salinity', ...
                      'DO','oxygen_concentration_in_sea_wat','pH','pH', ...
                      'P','sea_water_pressure','C','sea_water_electrical_conductivi', ...
                      'rho','sea_water_density','DOsat','percent_saturation');

for nm = 1:12
    iu = find(mnth==nm);
    res.ndays(nm) = length(unique(daten(iu)));
    res.nu(nm) = length(iu);
    tmp = d.(avar_station.(avar))(iu);
    res.mninfo(nm) = mean(tmp(~isnan(tmp)));
    tmp = d.(avar_station.(avar))(iu);
    res.sdinfo(nm) = std(tmp(~isnan(tmp)));
    res.bd99lower(nm) = prctile(d.(avar_station.(avar))(iu),0.5);
    res.bd95lower(nm) = prctile(d.(avar_station.(avar))(iu),2.5);
    res.bd16(nm) = prctile(d.(avar_station.(avar))(iu),16);
    res.bd50(nm) = prctile(d.(avar_station.(avar))(iu),50);
    res.bd84(nm) = prctile(d.(avar_station.(avar))(iu),84);
    res.bd95upper(nm) = prctile(d.(avar_station.(avar))(iu),97.5);
    res.bd99upper(nm) = prctile(d.(avar_station.(avar))(iu),99.5);
end

res.data = NaN(max(res.nu), 12);
for nm = 1:12
    iu = find(mnth==nm);
    res.data(1:length(iu),nm) = d.(avar_station.(avar))(iu);
end

end