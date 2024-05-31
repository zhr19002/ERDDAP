function stationdataQAQC = CheckStationDataQAQC(Astn, ZT_max)
% 
% Identify and flag station climatology data outliers
% (1 = pass; 3 = beyond 99% data range; 4 = beyond max-min range)
% 
% Calls GetDEEPWQClimData.m
% Calls GetDEEPWQClimStats.m
% 

avar_station = struct('T','sea_water_temperature','S','sea_water_salinity', ...
                      'DO','oxygen_concentration_in_sea_wat','pH','pH', ...
                      'P','sea_water_pressure','C','sea_water_electrical_conductivi', ...
                      'rho','sea_water_density','DOsat','percent_saturation');
% Read station parameters
station_para = readtable('Station_Para.csv', ReadRowNames=true);

% Download station climatology data in the depth range ZT to ZB
for ZT = 0:2:ZT_max
    ZB = ZT+2;
    % Get station climatology dataset
    clim_d = GetDEEPWQClimData(Astn, ZT, ZB);
    clim = struct2table(clim_d);
    
    % Check Lon/Lat columns
    clim.latitude(:) = mode(clim.latitude);
    clim.longitude(:) = mode(clim.longitude);
    % clim = clim(clim.latitude == mode(clim.latitude), :);
    % clim = clim(clim.longitude == mode(clim.longitude), :);
    daten = clim.Start_Date/(24*3600) + datetime(1970,1,1);
    [~, mnth, ~] = datevec(daten); %Extract the months of start dates
    clim.mnth = mnth;

    % Check station climatology data
    for avar = {'T','S','DO','P','C','pH','rho','DOsat'}
        if isfield(clim_d, avar_station.(avar{1}))
            clim.([avar{1} '_Check']) = ones(size(clim,1), 1);
            iu1 = find(clim.(avar_station.(avar{1})) < station_para.(avar{1})('Min_Value') | ...
                      clim.(avar_station.(avar{1})) > station_para.(avar{1})('Max_Value') | ...
                      isnan(clim.(avar_station.(avar{1}))));
            if ~isempty(iu1)
                clim.([avar{1} '_Check'])(iu1) = 4;
            end
            % Get station climatology statistics
            clim_stats = GetDEEPWQClimStats(Astn, ZT, ZB, avar{1});
            % check the specific month climatology data
            for MM = 1:12
                tmp = clim.(avar_station.(avar{1}))(clim.mnth == MM);
                iu2 = find(tmp < clim_stats.bd99lower(MM) | ...
                           tmp > clim_stats.bd99upper(MM));
                if ~isempty(iu2)
                    clim.([avar{1} '_Check'])(iu2) = 3;
                end
            end
        end
    end
    clim.mnth = [];
    stationdataQAQC = clim;
    save(['CTDEEP_' Astn '_' num2str(ZT) '_' num2str(ZB) '_QAQC.mat'], 'clim');
end