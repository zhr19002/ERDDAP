% 
% Identify and flag ship survey data outliers
% (1 = pass; 3 = beyond 99% data range; 4 = beyond max-min range)
% 
% Calls GetCruiseNames.m
% Calls GetDEEPWQClimDepth.m
% Calls GetCTDEEP_CTD_Stats.m
% Calls GetDEEPWQClimStats.m
% 

clc; clear;
Ayear0 = 2021; Ayear1 = 2021;
av_stn = struct('T','sea_water_temperature','S','sea_water_salinity', ...
                'DO','oxygen_concentration_in_sea_wat','pH','pH', ...
                'P','sea_water_pressure','C','sea_water_electrical_conductivi', ...
                'rho','sea_water_density','DOsat','percent_saturation');
% Read station parameters
stn_para = readtable('Station_Para.csv', ReadRowNames=true);

for Astn = {'E1'}
    for Ayear = Ayear0:Ayear1
        % Get cruise names for 12 months in a specific year
        CruiseNames = cell(12,1);
        for nn = 1:12
            if nn < 10
                Amonth = sprintf('0%i', nn);
            else
                Amonth = sprintf('%i', nn);
            end
            [~, CruiseNames{nn}] = GetCruiseNames(Ayear, Amonth);
        end
        % Get max depth at a station
        maxDepth = GetDEEPWQClimDepth(Astn{1}, Ayear);
        % Get ship survey data in a depth range for all cruises at a station
        for ZT = 0:5:5*floor(maxDepth/5)
            ZB = ZT+5;
            dCTD = GetCTDEEP_CTD_Stats(Astn{1},CruiseNames,ZT,ZB);
            % Check each variable in ship survey data
            for av = {'T','S','DO','P','C','pH','rho','DOsat'}
                % Get station climatology statistics
                stats = GetDEEPWQClimStats(Astn{1}, ZT, ZB, av{1});
                % Check ship survey data for each cruise
                for nc = 1:numel(dCTD)
                    if isfield(dCTD{nc}, av_stn.(av{1}))
                        % Shorten field names
                        crs = dCTD{nc}.cruise_name(1,:);
                        stn = dCTD{nc}.station_name(1,:);
                        dpth = ['depth_' num2str(ZT) '_' num2str(ZB)];
                        % Form QAQC structure
                        clim.(crs).(stn).(dpth).time = dCTD{nc}.time/(24*3600)+datetime(1970,1,1);
                        clim.(crs).(stn).(dpth).depth = dCTD{nc}.depth;
                        clim.(crs).(stn).(dpth).(av{1}).data = dCTD{nc}.(av_stn.(av{1}));
                        clim.(crs).(stn).(dpth).(av{1}).check = ones(size(dCTD{nc}.time));
                        % Check max-min thresholds
                        d_tmp = clim.(crs).(stn).(dpth).(av{1}).data;
                        iu1 = find(d_tmp < stn_para.(av{1})('Min_Value') | ...
                                   d_tmp > stn_para.(av{1})('Max_Value') | ...
                                   isnan(d_tmp));
                        if ~isempty(iu1)
                            clim.(crs).(stn).(dpth).(av{1}).check(iu1) = 4;
                        end
                        % Check 98% data range thresholds for each month
                        for MM = 1:12
                            iu2 = find(month(clim.(crs).(stn).(dpth).time) == MM & ...
                                       (d_tmp < stats.bd1(MM) | d_tmp > stats.bd99(MM)));
                            if ~isempty(iu2)
                                clim.(crs).(stn).(dpth).(av{1}).check(iu2) = 3;
                            end
                        end
                    end
                end
            end
        end
    end
end

% Save QAQC results
ShipSurveyQAQC = clim;
save(['CTDEEP_Cruises_' num2str(Ayear0) '_' num2str(Ayear1) '_QAQC.mat'], 'ShipSurveyQAQC');