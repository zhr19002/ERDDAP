function [dd, CruiseDay, CruiseNames] = GetCTDEEP_WQDataForComps(Ast, Ayear, Nmth)
% 
% Gets station data from CTDEEP ERDDAP site.
% 
% Modified from GetCTDEEPDataForComps to access the WQ archive and return
% the salinity, temperature, pressure and DO.
% 
% Note that Nmth may be a range e.g. [1:3], then dd{1:3} is returned.
% Since there may be more than 1 cruise per month, then 
% dd{3}{1}.DEEP_WQ and dd{3}{2}.DEEP_WQ etc contain the data.
% 
% Returned variables are extensive
% 
%                      cruise_name
%                     station_name
%                             time
%                         latitude
%                        longitude
%                       depth_code
%                            depth
%               sea_water_pressure
%  sea_water_electrical_conductivi
%            sea_water_temperature
%               oxygen_sensor_temp
%                              PAR
%                      Chlorophyll
%            Corrected_Chlorophyll
%                               pH
%               sea_water_salinity
%  oxygen_concentration_in_sea_wat
%                          winkler
%                 corrected_oxygen
%           percent_saturation_100
%               percent_saturation
%                sea_water_density
%                       Start_Date
%                         End_Date
%                  Time_ON_Station
%                 Time_OFF_Station
% 
% Inputs: Ast (for station), Ayear (year), Nmth (month)
% 
% Calls GetCruiseNamesInIntv.m
% Called from GetCTDEEP_WQDataForComps_demo.m
% 

wopts = weboptions;
wopts.Timeout = 60;

aURLpatt = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_WQ.mat?'...
            'cruise_name%2Cstation_name%2Ctime%2Clatitude%2Clongitude'...
            '%2Cdepth_code%2Cdepth%2Csea_water_pressure' ...
            '%2Csea_water_electrical_conductivity%2Csea_water_temperature' ...
            '%2Coxygen_sensor_temp%2CPAR%2CChlorophyll%2CCorrected_Chlorophyll'...
            '%2CpH%2Csea_water_salinity%2Coxygen_concentration_in_sea_water'...
            '%2Cwinkler%2Ccorrected_oxygen%2Cpercent_saturation_100'...
            '%2Cpercent_saturation%2Csea_water_density%2CStart_Date%2CEnd_Date'...
            '%2CTime_ON_Station%2CTime_OFF_Station&' ...
            'cruise_name=%22NNNNNNN%22&station_name=%22XX%22&' ...
            'time%3E=YYYY-MM-01&time%3C=YYYY-MM-31'];

aURL0 = strrep(aURLpatt, 'XX', Ast);
aURL0 = strrep(aURL0, 'YYYY', Ayear);

CruiseDay = cell(size(Nmth,2), 1);
CruiseNames = cell(size(Nmth,2), 1);
dd = cell(size(Nmth,2), 1);

% Step through months and get the data from the ERDDAP server
for nn = Nmth
    if nn < 10
        ann = sprintf('0%i', nn);
    else
        ann = sprintf('%i', nn);
    end
    
    aURL = strrep(aURL0, 'MM', ann);
    
    % Get the list of cruises in the interval
    [CruiseDay{nn}, CruiseNames{nn}] = GetCruiseNamesInIntv(Ayear, ann);
    
    % Now request the data from each cruise
    for nc = 1:length(CruiseNames{nn})
        Acrus = CruiseNames{nn}{nc};
        afile = ['DEEPWQ_' Ast '_' Acrus '.mat'];
        if ~exist(afile, 'file')
            disp(['Getting data from ERDDAP at ' Ast ' in ' Acrus]);
            try
                aURL = strrep(aURL, 'NNNNNNN', Acrus);
                af = websave(afile, aURL, wopts);
                dd{nn}{nc} = load(af);
                dd{nn}{nc}.DEEP_WQ.CruiseDay = CruiseDay{nn}{nc};
                dd{nn}{nc}.DEEP_WQ.CruiseNames = CruiseNames{nn}{nc};
                DEEP_WQ = dd{nn}{nc}.DEEP_WQ;
                save(af, 'DEEP_WQ');
            catch
                disp(['No data for ' 'DEEPWQ_' Ast '_' Ayear '_' ann])
                dd{nn} = [];
            end
        else
            % Need to fix this to load all the files for a summer month
            disp(['Loading local ' afile]);
            dirsz = dir(afile);
            if ~isempty(dirsz) & dirsz.bytes>0
                dd{nn}{nc} = load(afile);
            else
                dd{nn}{nc} = [];
            end
        end
    end
end

end