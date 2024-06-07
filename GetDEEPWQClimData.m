function d = GetDEEPWQClimData(Astn, ZT, ZB)
% 
% Get all the climatology data from astn in the depth range ZT to ZB
% 
% Called from CheckStationDataQAQC.m
% 

wopts = weboptions; wopts.Timeout = 120;
ZT = num2str(ZT); ZB = num2str(ZB);

% Form ERDDAP request
aurl0 = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_WQ.mat?' ...
         'cruise_name%2Cstation_name%2Ctime%2Clatitude%2Clongitude%2Cdepth%2C' ...
         'sea_water_pressure%2Csea_water_electrical_conductivity%2Csea_water_temperature' ...
         '%2CpH%2Csea_water_salinity%2Coxygen_concentration_in_sea_water%2C' ...
         'percent_saturation%2Csea_water_density%2CStart_Date&' ...
	     'station_name=%22XX%22&depth%3E=ZT&depth%3C=ZB'];
aurl = strrep(aurl0, 'XX', Astn);
aurl = strrep(aurl, 'ZT', ZT);
aurl = strrep(aurl, 'ZB', ZB);

afile = ['CTDEEP_' Astn '_' ZT '_' ZB '.mat'];
if ~exist(afile, 'file')
    disp(['Getting data from ERDDAP at ' Astn ' (' ZT 'm-' ZB 'm)']);
    try
        af = websave(afile, aurl, wopts);
        d = load(af);
        d = d.DEEP_WQ;
    catch
        disp(['No data at ' Astn ' (' ZT 'm-' ZB 'm)']);
        d = {};
    end
else
    if ~isempty(dir(afile)) & dir(afile).bytes>0
        d = load(afile);
        d = d.DEEP_WQ;
    else
        d = {};
    end
end

end