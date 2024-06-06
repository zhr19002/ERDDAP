function d = GetCTDEEP_CTD_Data(Astn, Acrs, ZT, ZB)
% 
% Get data from station (Astn) on cruise (Acrs) from ZT to ZB
% Return a structure with salinity, temperature, and density
% 
% Called from GetCTDEEP_CTD_Stats.m
% 

wopts = weboptions; wopts.Timeout = 120;
ZT = num2str(ZT); ZB = num2str(ZB);

% Define the URL template
a1 = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_WQ.mat?cruise_name%2Cstation_name' ...
      '%2Ctime%2Clatitude%2Clongitude%2Cdepth%2Csea_water_pressure%2Csea_water_electrical_conductivity' ...
      '%2Csea_water_temperature%2CPAR%2CChlorophyll%2CCorrected_Chlorophyll%2CpH%2Csea_water_salinity' ...
      '%2Coxygen_concentration_in_sea_water%2Cpercent_saturation%2Csea_water_density%2CStart_Date' ...
      '&cruise_name=%22XX%22&station_name=%22YY%22&depth%3E=ZT&depth%3C=ZB'];
aurl = strrep(a1, 'XX', Acrs);
aurl = strrep(aurl, 'YY', Astn);
aurl = strrep(aurl, 'ZT', ZT);
aurl = strrep(aurl, 'ZB', ZB);

afile = ['DEEP_CTD_' Astn '_' Acrs '_' ZT '_' ZB '.mat'];
if ~exist(afile, 'file')
    disp(['Getting data from ERDDAP at ' Astn ' on ' Acrs ' (' ZT 'm-' ZB 'm)']);
    try
        af = websave(afile, aurl, wopts);
        d = load(af);
        d = d.DEEP_WQ;
    catch
        disp(['No data at ' Astn ' on ' Acrs ' (' ZT 'm-' ZB 'm)']);
        d = {};
    end
else
    disp(['Loading local ' afile]);
    if ~isempty(dir(afile)) & dir(afile).bytes>0
        d = load(afile);
        d = d.DEEP_WQ;
    else
        d = {};
    end
end

end