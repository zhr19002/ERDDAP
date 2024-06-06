clc; clear;
Ayear = 2021; ZT_max = 5;

avar_station = struct('T','sea_water_temperature','S','sea_water_salinity', ...
                      'DO','oxygen_concentration_in_sea_wat','pH','pH', ...
                      'P','sea_water_pressure','C','sea_water_electrical_conductivi', ...
                      'rho','sea_water_density','DOsat','percent_saturation');
% Read station parameters
station_para = readtable('Station_Para.csv', ReadRowNames=true);

for Astn = {'E1'}
    for Ayear = 2021:2021
        for ZT = 0:5:ZT_max
            ZB = ZT+5;
            % Get cruise names from CTDEEP in a specific year
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            [~,~,CruiseNames] = GetCTDEEP_WQDataForComps(Astn{1}, Ayear, 1:12);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Get CTDEEP ship survey data
            dCTD = GetCTDEEP_CTD_Stats(Astn{1},CruiseNames,ZT,ZB);
            
            for avar = {'T','S','DO','P','C','pH','rho','DOsat'}
                for ii = 1:numel(dCTD)
                    if isfield(dCTD{ii}, avar_station.(avar{1}))
                        crs = dCTD{ii}.cruise_name(1,:);
                        stn = dCTD{ii}.station_name(1,:);
                        dpth = ['depth_' num2str(ZT) '_' num2str(ZB)];

                        clim.(crs).(stn).(dpth).time = dCTD{ii}.time;
                        clim.(crs).(stn).(dpth).depth = dCTD{ii}.depth;
                        clim.(crs).(stn).(dpth).(avar{1}) = dCTD{ii}.(avar_station.(avar{1}));
                        clim.(crs).(stn).(dpth).([avar{1} '_Check']) = ones(size(dCTD{1}.time));
                        iu1 = find(dCTD{ii}.(avar_station.(avar{1})) < station_para.(avar{1})('Min_Value') | ...
                                   dCTD{ii}.(avar_station.(avar{1})) > station_para.(avar{1})('Max_Value') | ...
                                   isnan(dCTD{ii}.(avar_station.(avar{1}))));
                        if ~isempty(iu1)
                            clim.(crs).(stn).(dpth).([avar{1} '_Check'])(iu1) = 4;
                        end
                        % Get station climatology statistics
                        clim_stats = GetDEEPWQClimStats(Astn{1}, ZT, ZB, avar{1});
                        % check the specific month climatology data
                        for MM = 1:12
                            iu2 = find(month(dCTD{ii}.mnTime) == MM);
                            if ~isempty(iu2)
                                iu3 = find(dCTD{ii}.(avar_station.(avar{1}))(iu2) < clim_stats.bd99lower(MM) | ...
                                           dCTD{ii}.(avar_station.(avar{1}))(iu2) > clim_stats.bd99upper(MM));
                                if ~isempty(iu3)
                                    clim.(crs).(stn).(dpth).([avar{1} '_Check'])(iu3) = 3;
                                end
                            end
                        end

                    end
                end
            end
        
        end
    end
end

