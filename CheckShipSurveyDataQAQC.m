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
Ayear0 = 2021;
av_stn = struct('T','sea_water_temperature','S','sea_water_salinity', ...
                'DO','oxygen_concentration_in_sea_wat','pH','pH', ...
                'P','sea_water_pressure','C','sea_water_electrical_conductivi', ...
                'rho','sea_water_density','DOsat','percent_saturation');
% Read station parameters
stn_para = readtable('Station_Para.csv', ReadRowNames=true);

for Astn = {'E1'}
    for Ayear = Ayear0:2021
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
                clim_stats = GetDEEPWQClimStats(Astn{1}, ZT, ZB, av{1});
                % Check ship survey data for each cruise
                for nc = 1:numel(dCTD)
                    if isfield(dCTD{nc}, av_stn.(av{1}))
                        % Shorten field names
                        crs = dCTD{nc}.cruise_name(1,:);
                        stn = dCTD{nc}.station_name(1,:);
                        dpth = ['depth_' num2str(ZT) '_' num2str(ZB)];
                        % Form QAQC structure
                        clim.(crs).(stn).(dpth).time = dCTD{nc}.time;
                        clim.(crs).(stn).(dpth).depth = dCTD{nc}.depth;
                        clim.(crs).(stn).(dpth).(av{1}).data = dCTD{nc}.(av_stn.(av{1}));
                        clim.(crs).(stn).(dpth).(av{1}).check = ones(size(dCTD{nc}.time));
                        % Check max-min thresholds
                        iu1 = find(dCTD{nc}.(av_stn.(av{1})) < stn_para.(av{1})('Min_Value') | ...
                                   dCTD{nc}.(av_stn.(av{1})) > stn_para.(av{1})('Max_Value') | ...
                                   isnan(dCTD{nc}.(av_stn.(av{1}))));
                        if ~isempty(iu1)
                            clim.(crs).(stn).(dpth).(av{1}).check(iu1) = 4;
                        end
                        % Check 99% data range thresholds for each month
                        for MM = 1:12
                            iu2 = find(month(dCTD{nc}.mnTime) == MM);
                            if ~isempty(iu2)
                                iu3 = find(dCTD{nc}.(av_stn.(av{1}))(iu2) < clim_stats.bd99lower(MM) | ...
                                           dCTD{nc}.(av_stn.(av{1}))(iu2) > clim_stats.bd99upper(MM));
                                if ~isempty(iu3)
                                    clim.(crs).(stn).(dpth).(av{1}).check(iu3) = 3;
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    % Save QAQC results
    ShipSurveyDataQAQC = clim;
    save(['CTDEEP_' Astn{1} '_' num2str(Ayear0) '_' num2str(Ayear) '_QAQC.mat'], 'ShipSurveyDataQAQC');
end

