function [dd, CruiseDay, CruiseNames] = GetCTDEEP_WQDataForComps(Astn, Ayear, Nmth)
% 
% Get station data (dd) from ERDDAP
% 
% Note that Nmth may be a range (e.g., Nmth = 1:3), then dd{1:3} is returned
% Since there may be more than 1 cruise per month, 
% then dd{3}{1}, dd{3}{2}, etc. are returned
% 
% Calls GetCruiseNames.m
% Called from GetCTDEEP_WQDataForComps_demo.m
% 

wopts = weboptions; wopts.Timeout = 60;
Ayear = num2str(Ayear);

aURLpat = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_WQ.mat?cruise_name' ...
           '%2Cstation_name%2Ctime%2Clatitude%2Clongitude%2Cdepth%2Csea_water_pressure' ...
           '%2Csea_water_electrical_conductivity%2Csea_water_temperature%2CpH%2C' ...
           'sea_water_salinity%2Coxygen_concentration_in_sea_water%2Cpercent_saturation%2C' ...
           'sea_water_density%2CStart_Date&cruise_name=%22NNNNNNN%22&station_name=%22XX%22' ...
           '&time%3E=YYYY-MM-01&time%3C=YYYY-MM-31'];
aURL0 = strrep(aURLpat, 'XX', Astn);
aURL0 = strrep(aURL0, 'YYYY', Ayear);

dd = cell(12,1); CruiseDay = cell(12,1); CruiseNames = cell(12,1);
% Step through months and get station data from ERDDAP
for nn = Nmth
    if nn < 10
        Amonth = sprintf('0%i', nn);
    else
        Amonth = sprintf('%i', nn);
    end
    
    % Get the list of cruises
    [CruiseDay{nn}, CruiseNames{nn}] = GetCruiseNames(Ayear, Amonth);
    aURL = strrep(aURL0, 'MM', Amonth);
    
    % Request data from each cruise
    for nc = 1:length(CruiseNames{nn})
        afile = ['DEEPWQ_' Astn '_' CruiseNames{nn}{nc} '.mat'];
        if ~exist(afile, 'file')
            disp(['Getting data from ERDDAP at ' Astn ' on ' CruiseNames{nn}{nc}]);
            try
                aURL = strrep(aURL, 'NNNNNNN', CruiseNames{nn}{nc});
                af = websave(afile, aURL, wopts);
                dd{nn}{nc} = load(af);
                dd{nn}{nc} = dd{nn}{nc}.DEEP_WQ;
                dd{nn}{nc}.CruiseDay = CruiseDay{nn}{nc};
                dd{nn}{nc}.CruiseNames = CruiseNames{nn}{nc};
                DEEP_WQ = dd{nn}{nc};
                save(af, 'DEEP_WQ');
            catch
                disp(['No data at ' Astn ' on ' CruiseNames{nn}{nc}]);
                dd{nn}{nc} = [];
            end
        else
            disp(['Loading local ' afile]);
            if ~isempty(dir(afile)) & dir(afile).bytes>0
                dd{nn}{nc} = load(afile);
            else
                dd{nn}{nc} = [];
            end
        end
    end
end

end