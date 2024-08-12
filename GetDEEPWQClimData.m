function d = GetDEEPWQClimData(Astn, ZT, ZB)
% 
% Get all the climatology data from Astn in the depth range ZT to ZB
% 
% Called from WriteStationDataQAQC.m
% 

ZT = num2str(ZT); ZB = num2str(ZB);
wopts = weboptions; wopts.Timeout = 120;

% Form ERDDAP request
aurl0 = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_WQ.mat?station_name%2C' ...
         'time%2Clatitude%2Clongitude%2Cdepth%2Csea_water_pressure%2C' ...
         'sea_water_electrical_conductivity%2Csea_water_temperature%2CpH%2Csea_water_salinity' ...
         '%2Coxygen_concentration_in_sea_water%2Cpercent_saturation%2Csea_water_density' ...
         '&station_name=%22XX%22&depth%3E=ZT&depth%3C=ZB'];
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