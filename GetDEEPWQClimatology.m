function res = GetDEEPWQClimatology(astn, ZT, ZB, avar)
% 
% Get all the climatology data from astn in the depth range ZT to ZB and return the stats
% avar = {'T','S','DO','P','C','pH','rho','DOsat'}
% 
% Called from Proc2021_pH_data.m
% 

% astn = 'E1'; ZT = 0; ZB = 3; avar = 'T';

% Form ERDDAP request
aurl0 = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_WQ.mat?' ...
         'cruise_name%2Cstation_name%2Ctime%2Cdepth%2Csea_water_pressure%2C' ...
         'sea_water_electrical_conductivity%2Csea_water_temperature%2CpH%2C' ...
         'sea_water_salinity%2Coxygen_concentration_in_sea_water%2C' ...
         'percent_saturation%2Csea_water_density%2CStart_Date&' ...
	     'station_name=%22XX%22&time%3E=2002-01-01&time%3C=2023-12-31&' ...
	     'depth%3E=ZT&depth%3C=ZB'];
aurl = strrep(aurl0, 'XX', astn);
aurl = strrep(aurl, 'ZT', num2str(ZT));
aurl = strrep(aurl, 'ZB', num2str(ZB));
afile = ['CTDEEP_' avar '_' astn '_' num2str(ZT) '_' num2str(ZB) '.mat'];

if exist(afile, 'file')
    d = load(afile);
else
    wopt = weboptions;
    wopt.Timeout = 120;
    af = websave(afile, aurl, wopt);
    d = load(af);
end

daten = d.DEEP_WQ.Start_Date/(24*3600) + datetime(1970,1,1);

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
    tmp = d.DEEP_WQ.(avar_station.(avar))(iu);
    res.mninfo(nm) = mean(tmp(~isnan(tmp)));
    tmp = d.DEEP_WQ.(avar_station.(avar))(iu);
    res.sdinfo(nm) = std(tmp(~isnan(tmp)));
    res.upper(nm) = prctile(d.DEEP_WQ.(avar_station.(avar))(iu),2.5);
    res.lower(nm) = prctile(d.DEEP_WQ.(avar_station.(avar))(iu),97.5);
    res.bd16(nm) = prctile(d.DEEP_WQ.(avar_station.(avar))(iu),16);
    res.bd50(nm) = prctile(d.DEEP_WQ.(avar_station.(avar))(iu),50);
    res.bd84(nm) = prctile(d.DEEP_WQ.(avar_station.(avar))(iu),84);
end

res.data = NaN(max(res.nu), 12);
for nm = 1:12
    iu = find(mnth==nm);
    res.data(1:length(iu),nm) = d.DEEP_WQ.(avar_station.(avar))(iu);
end

end