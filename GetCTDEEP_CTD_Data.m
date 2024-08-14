function d = GetCTDEEP_CTD_Data(Astn, Acrs, ZT, ZB)
% 
% Get CTD data on Acrs at Astn in the depth range ZT to ZB
% 
% Calls sw_dens.m
% 
% Called from GetCTDEEP_CTD_Stats.m
% 

wopts = weboptions; wopts.Timeout = 120;
ZT = num2str(ZT); ZB = num2str(ZB);

% Form ERDDAP request
aurl0 = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_WQ.mat?cruise_name%2C' ...
         'station_name%2Ctime%2Clatitude%2Clongitude%2Cdepth%2Csea_water_pressure%2C' ...
         'sea_water_electrical_conductivity%2Csea_water_temperature%2CpH%2Csea_water_salinity' ...
         '%2Coxygen_concentration_in_sea_water%2Cpercent_saturation%2Csea_water_density' ...
         '&cruise_name=%22XX%22&station_name=%22YY%22&depth%3E=ZT&depth%3C=ZB'];
aurl = strrep(aurl0, 'XX', Acrs);
aurl = strrep(aurl, 'YY', Astn);
aurl = strrep(aurl, 'ZT', ZT);
aurl = strrep(aurl, 'ZB', ZB);

afile = ['Cruise_' Acrs '_' Astn '_' ZT '_' ZB '.mat'];
if ~exist(afile, 'file')
    disp(['Getting data from ERDDAP on ' Acrs ' at ' Astn ' (' ZT 'm-' ZB 'm)']);
    try
        af = websave(afile, aurl, wopts);
        d = load(af);
        d = d.DEEP_WQ;
        % Calculate rho
        sw_S = d.sea_water_salinity;
        sw_T = d.sea_water_temperature;
        sw_P = d.sea_water_pressure;
        d.sea_water_density = real(sw_dens(sw_S,sw_T,sw_P)-1000);
        % Save the updated .mat file
        DEEP_WQ = d;
        save(afile, 'DEEP_WQ');
    catch
        disp(['No data on ' Acrs ' at ' Astn ' (' ZT 'm-' ZB 'm)']);
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