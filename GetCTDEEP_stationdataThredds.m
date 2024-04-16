function d = GetCTDEEP_stationdataThredds(Anm, Acrs)
% 
% Go get the data from station Anm on cruise Acrs from the lisicos Thredds
% server and return a structure with the salinity temperature and density
% 
% Called from GetCTDEEP_CTD_DataForComps.m
% 

wopts = weboptions;
wopts.Timeout = 100;

% Anm = 'C2'; Acrs = 'WQOCT18';
% Anm = 'F2'; Acrs = 'HYJUL21';

% Define the URL template
a1 = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_WQ.mat?' ...
    'cruise_name%2Cstation_name%2Ctime%2Clatitude%2Clongitude%2Cdepth_code%2Cdepth%2C' ...
    'sea_water_pressure%2Csea_water_electrical_conductivity%2Csea_water_temperature%2C' ...
    'oxygen_sensor_temp%2CPAR%2CChlorophyll%2CCorrected_Chlorophyll%2CpH%2Csea_water_salinity%2C' ...
    'oxygen_concentration_in_sea_water%2Cwinkler%2Ccorrected_oxygen%2Cpercent_saturation_100%2C' ...
    'percent_saturation%2Csea_water_density%2CStart_Date%2CEnd_Date%2CTime_ON_Station%2C' ...
    'Time_OFF_Station&cruise_name=%22XX%22&station_name=%22YY%22'];

aurl = strrep(a1, 'XX', Acrs);
aurl = strrep(aurl, 'YY', Anm);
afile = append('CTDEEP_CTDprofile_', Acrs, '_', Anm, '.mat');

if ~exist(afile, 'file')
    disp('Getting data from ERDAPP... wait');
    try
        af = websave(afile, aurl, wopts);
        disp(['Saved ' afile]);
        dt = load(af);
    catch
        disp('No response from ERDDAP, and no mat file');
        return
    end
else
    dt = load(afile);
end

dt = struct2table(dt.DEEP_WQ);
columnNames = dt.Properties.VariableNames;
d = [];

% Seperate data into a structure with fields determined by the column names
for nn = 1:size(dt,2)
    tmp = cell(size(dt,1),1);
    if ischar(dt{1,nn})
        for mm = 1:size(dt,1)
            tmp{mm} = dt{mm,nn};
        end
        d.(columnNames{nn}) = tmp;
    
    % Parse times correctly
    elseif strcmp(columnNames{nn}, 'time') | ...
           strcmp(columnNames{nn}, 'Start_Date') | ...
           strcmp(columnNames{nn}, 'End_Date')
        for mm = 1:size(dt,1)
            if strcmp(dt{mm,nn}, 'ND') | isempty(dt{mm,nn})
                tmp{mm} = NaN;
            else
                tmp{mm} = dt{mm,nn}/(24*3600) + datetime(1970,1,1); 
            end
        end
        d.(columnNames{nn}) = tmp;
    
    else
        for mm = 1:size(dt,1)
            if isnan(dt{mm,nn})
                tmp{mm} = NaN;
            else
                tmp{mm} = dt{mm,nn};
            end
        end
        d.(columnNames{nn}) = tmp;
    end
end

end