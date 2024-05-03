function res = GetDEEPWQClimatology(astn, ZT, ZB, info)
% 
% Get all the climatology data from astn in the depth range ZT to ZB and return the stats
% info = ["T", "S", "DO", "pH"]
% 
% Called from Proc2021_pH_data.m
% 

% astn = 'E1'; ZT = 0; ZB = 3; info = 'T';

% Form ERDDAP request
aurl0 = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_WQ.mat?' ...
         'cruise_name%2Cstation_name%2Ctime%2Cdepth%2Csea_water_temperature%2CpH%2Csea_water_salinity%2Coxygen_concentration_in_sea_water%2CStart_Date&' ...
	     'station_name=%22XX%22&time%3E=2000-12-17&time%3C=2022-12-17&' ...
	     'depth%3E=ZT&depth%3C=ZB'];
aurl = strrep(aurl0, 'XX', astn);
aurl = strrep(aurl, 'ZT', num2str(ZT));
aurl = strrep(aurl, 'ZB', num2str(ZB));
afile = ['CTDEEP_' info '_' astn '_' num2str(ZT) '_' num2str(ZB) '.mat'];

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

info_struct = struct('T','sea_water_temperature', 'S','sea_water_salinity', ...
                     'DO','oxygen_concentration_in_sea_wat', 'pH','pH');

for nm = 1:12
    iu = find(mnth==nm);
    res.ndays(nm) = length(unique(daten(iu)));
    res.nu(nm) = length(iu);
    tmp = d.DEEP_WQ.(info_struct.(info))(iu);
    res.mninfo(nm) = mean(tmp(~isnan(tmp)));
    tmp = d.DEEP_WQ.(info_struct.(info))(iu);
    res.sdinfo(nm) = std(tmp(~isnan(tmp)));
    res.upper(nm) = mean(max(d.DEEP_WQ.(info_struct.(info))(iu)));
    res.lower(nm) = mean(min(d.DEEP_WQ.(info_struct.(info))(iu)));
    res.bd16(nm) = prctile(d.DEEP_WQ.(info_struct.(info))(iu),16);
    res.bd50(nm) = prctile(d.DEEP_WQ.(info_struct.(info))(iu),50);
    res.bd84(nm) = prctile(d.DEEP_WQ.(info_struct.(info))(iu),84);
end

end