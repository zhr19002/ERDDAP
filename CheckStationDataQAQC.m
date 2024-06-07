% 
% Identify and flag station climatology data outliers
% (1 = pass; 3 = beyond 99% data range; 4 = beyond max-min range)
% 
% Calls GetDEEPWQClimDepth.m
% Calls GetDEEPWQClimData.m
% Calls GetDEEPWQClimStats.m
% 

clc; clear;
Astn = 'E1';
av_stn = struct('T','sea_water_temperature','S','sea_water_salinity', ...
                'DO','oxygen_concentration_in_sea_wat','pH','pH', ...
                'P','sea_water_pressure','C','sea_water_electrical_conductivi', ...
                'rho','sea_water_density','DOsat','percent_saturation');
% Read station parameters
stn_para = readtable('Station_Para.csv', ReadRowNames=true);

% Get max depth at a station
maxDepth = GetDEEPWQClimDepth(Astn, 2023);
% Download station climatology data in the depth range ZT to ZB
for ZT = 0:5:5*floor(maxDepth/5)
    ZB = ZT+5;
    % Get station climatology data
    d = GetDEEPWQClimData(Astn, ZT, ZB);
    % Check Lon/Lat
    d.latitude(:) = mode(d.latitude);
    d.longitude(:) = mode(d.longitude);
    % Check each variable in station climatology data
    for av = {'T','S','DO','P','C','pH','rho','DOsat'}
        % Get station climatology statistics
        stats = GetDEEPWQClimStats(Astn, ZT, ZB, av{1});
        if isfield(d, av_stn.(av{1}))
            % Shorten field names
            dpth = ['depth_' num2str(ZT) '_' num2str(ZB)];
            % Form QAQC structure
            clim.(dpth).latitude = d.latitude;
            clim.(dpth).longitude = d.longitude;
            clim.(dpth).time = d.time;
            clim.(dpth).depth = d.depth;
            clim.(dpth).(av{1}).data = d.(av_stn.(av{1}));
            clim.(dpth).(av{1}).check = ones(size(d.time));
            % Check max-min thresholds
            iu1 = find(d.(av_stn.(av{1})) < stn_para.(av{1})('Min_Value') | ...
                       d.(av_stn.(av{1})) > stn_para.(av{1})('Max_Value') | ...
                       isnan(d.(av_stn.(av{1}))));
            if ~isempty(iu1)
                clim.(dpth).(av{1}).check(iu1) = 4;
            end
            % Check 99% data range thresholds for each month
            for MM = 1:12
                iu2 = find(month(d.time/(24*3600) + datetime(1970,1,1)) == MM);
                iu3 = find(d.(av_stn.(av{1}))(iu2) < stats.bd1(MM) | ...
                           d.(av_stn.(av{1}))(iu2) > stats.bd99(MM));
                if ~isempty(iu3)
                    clim.(dpth).(av{1}).check(iu3) = 3;
                end
            end
        end
    end
end

% Save QAQC results
StationQAQC = clim;
save(['CTDEEP_' Astn '_QAQC.mat'], 'StationQAQC');