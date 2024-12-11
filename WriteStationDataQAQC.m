% 
% Identify and flag station climatology data outliers
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 
% Calls GetCTDEEP_Clim_Data.m
% Calls ImplementThresholdTest.m
% Calls WriteStationNETCDF.m
% 

clc; clear;
Astn = 'A4'; % {'A4','C1','E1','I2'}

% Fixed parameters
av_stn = struct('T','sea_water_temperature','S','sea_water_salinity', ...
                'DO','oxygen_concentration_in_sea_wat','P','sea_water_pressure', ...
                'C','sea_water_electrical_conductivi','pH','pH', ...
                'rho','sea_water_density','DOsat','percent_saturation', ...
                'PAR','PAR','Chl','Chlorophyll','Corrected_Chl','Corrected_Chlorophyll');

% Read station group QAQC parameters
if ismember(Astn, {'A2','A4','B3','C1','C2','D3','E1','09','15'})
    stnGroup = 'WStations';
elseif ismember(Astn, {'F2','F3','H2','H4','H6'})
    stnGroup = 'CStations';
else
    stnGroup = 'EStations';
end
QAQC = load(['QAQC_' stnGroup '_WQ.mat']);
QAQC = QAQC.QAQC;

% Download station climatology data in the depth range ZT to ZB
for ZT = 0:5:40
    ZB = ZT+5;
    % Get station climatology data
    d = GetCTDEEP_Clim_Data(Astn, ZT, ZB, 1);
    if ~isempty(d)
        % Shorten field names
        dpth = ['depth_' num2str(ZT) '_' num2str(ZB)];
        clim.(dpth).time = d.time/(24*3600)+datetime(1970,1,1);
        clim.(dpth).depth = d.depth;
        % Check each variable in station climatology data
        for av = {'T','S','DO','P','C','pH','rho','DOsat','PAR','Chl','Corrected_Chl'}
            if isfield(d, av_stn.(av{1}))
                % Form QAQC structure 
                clim.(dpth).(av{1}).data = d.(av_stn.(av{1}));
                d_tmp = clim.(dpth).(av{1}).data;
                dt = clim.(dpth).time;
                c_tmp = ImplementThresholdTest(d_tmp, dt, QAQC, dpth, av{1});
                clim.(dpth).(av{1}).check = c_tmp;
            end
        end
    end
end

% Save station climatology QAQC parameters
for dp = fieldnames(clim)'
    for av = {'T','S','DO','P','C','pH','rho','DOsat','PAR','Chl','Corrected_Chl'}
        % Station climatology data cleaning
        iu1 = find(clim.(dp{1}).(av{1}).check==1);
        d_time = clim.(dp{1}).time(iu1);
        d_data = clim.(dp{1}).(av{1}).data(iu1);
        para = table('Size', [10,12], ...
                     'VariableTypes', repmat({'double'},1,12), ...
                     'VariableNames', arrayfun(@num2str,1:12,'UniformOutput',false), ...
                     'RowNames',{'count','mean','std','median','upper','lower','bd99','bd84','bd16','bd1'});
        for nm = 1:12
            iu2 = find(month(d_time)==nm);
            if ~isempty(iu2)
                data = d_data(iu2);
                data = data(~isnan(data));
            else
                data = 0;
            end
            
            para{1,nm} = length(iu2);
            para{2,nm} = mean(data);
            para{3,nm} = std(data);
            para{4,nm} = median(data);
            para{5,nm} = max(data);
            para{6,nm} = min(data);
            para{7,nm} = prctile(data,99);
            para{8,nm} = prctile(data,84);
            para{9,nm} = prctile(data,16);
            para{10,nm} = prctile(data,1);
        end
        QAQC.(dp{1}).(av{1}) = para;
    end
end
save(['QAQC_' Astn '_WQ.mat'], 'QAQC');

%%
% Save all the data plotted in a structure that can be exported to NETCDF
d0 = GetCTDEEP_Clim_Data(Astn, 0, 5, 1);
latlon = [mode(d0.latitude), mode(d0.longitude)];
dp_rng = fieldnames(clim);
for i = 1:length(dp_rng)
    stnDep = max(clim.(dp_rng{i}).depth);
    WriteStationNETCDF(Astn, dp_rng{i}, latlon, stnDep, clim.(dp_rng{i}));
end