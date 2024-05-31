function d = GetDEEPWQClimData(Astn, ZT, ZB)
% 
% Get all the climatology data from astn in the depth range ZT to ZB
% 
% Called from CheckStationDataQAQC.m
% 

% astn = 'E1'; ZT = 0; ZB = 3;

% Form ERDDAP request
aurl0 = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_WQ.mat?' ...
         'cruise_name%2Cstation_name%2Ctime%2Clatitude%2Clongitude%2Cdepth%2C' ...
         'sea_water_pressure%2Csea_water_electrical_conductivity%2Csea_water_temperature' ...
         '%2CpH%2Csea_water_salinity%2Coxygen_concentration_in_sea_water%2C' ...
         'percent_saturation%2Csea_water_density%2CStart_Date&' ...
	     'station_name=%22XX%22&depth%3E=ZT&depth%3C=ZB'];
aurl = strrep(aurl0, 'XX', Astn);
aurl = strrep(aurl, 'ZT', num2str(ZT));
aurl = strrep(aurl, 'ZB', num2str(ZB));
afile = ['CTDEEP_' Astn '_' num2str(ZT) '_' num2str(ZB) '.mat'];

if exist(afile, 'file')
    d = load(afile);
else
    wopt = weboptions;
    wopt.Timeout = 120;
    af = websave(afile, aurl, wopt);
    d = load(af);
end

d = d.DEEP_WQ;

end