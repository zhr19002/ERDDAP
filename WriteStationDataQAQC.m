% 
% Identify and flag station climatology data outliers
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 
% Calls GetDEEPWQClimData.m
% Calls ImplementThresholdQAQC.m
% Calls WriteNETCDFstationFile.m
% 

clc; clear;
Astn = 'E1';
av_stn = struct('T','sea_water_temperature','S','sea_water_salinity', ...
                'DO','oxygen_concentration_in_sea_wat','pH','pH', ...
                'P','sea_water_pressure','C','sea_water_electrical_conductivi', ...
                'rho','sea_water_density','DOsat','percent_saturation');

% Read station group parameters
if ismember(Astn, {'A2','A4','B3','C1','C2','D3','E1','09','15'})
    stnGroup = 'WStations';
elseif ismember(Astn, {'F2','F3','H2','H4','H6'})
    stnGroup = 'CStations';
else
    stnGroup = 'EStations';
end
QAQC = load([stnGroup '_para.mat']);
QAQC = QAQC.QAQC_para;

% Download station climatology data in the depth range ZT to ZB
for ZT = 0:5:40
    ZB = ZT+5;
    % Get station climatology data
    d = GetDEEPWQClimData(Astn, ZT, ZB);
    if ~isempty(d)
        % Shorten field names
        dpth = ['depth_' num2str(ZT) '_' num2str(ZB)];
        clim.(dpth).time = d.time/(24*3600)+datetime(1970,1,1);
        clim.(dpth).depth = d.depth;
        % Check each variable in station climatology data
        for av = {'T','S','DO','P','C','pH','rho','DOsat'}
            if isfield(d, av_stn.(av{1}))
                % Form QAQC structure 
                clim.(dpth).(av{1}).data = d.(av_stn.(av{1}));
                d_tmp = clim.(dpth).(av{1}).data;
                dt = clim.(dpth).time;
                c_tmp = ImplementThresholdQAQC(d_tmp, dt, QAQC, dpth, av{1});
                clim.(dpth).(av{1}).check = c_tmp;
            end
        end
    end
end

% Save QAQC results
StationQAQC = clim;
save(['CTDEEP_' Astn '_QAQC.mat'], 'StationQAQC');

%%
% Save all the data plotted in a structure that can be exported to NETCDF
d0 = GetDEEPWQClimData(Astn, 0, 5);
latlon = [mode(d0.latitude), mode(d0.longitude)];
dp_rng = fieldnames(StationQAQC);
for i = 1:length(dp_rng)
    stnDep = max(StationQAQC.(dp_rng{i}).depth);
    WriteNETCDFstationFile(Astn, dp_rng{i}, latlon, stnDep, StationQAQC.(dp_rng{i}));
end