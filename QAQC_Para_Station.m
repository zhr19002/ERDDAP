% 
% Create QAQC tables for different depths in a region
% 
% Calls GetCTDEEP_Clim_Data.m
% 
% Creates "QAQC_Para_(W/C/E)Stations.mat"
% 

clc; clear;
Astn = 'WStations'; % {'WStations','CStations','EStations'}

fields = {'station_name','time','latitude','longitude','depth', ...
          'sea_water_temperature','sea_water_salinity', ...
          'oxygen_concentration_in_sea_wat','pH', ...
          'sea_water_pressure','sea_water_electrical_conductivi', ...
          'sea_water_density','percent_saturation'};
av_stn = struct('T','sea_water_temperature','S','sea_water_salinity', ...
                'DO','oxygen_concentration_in_sea_wat','pH','pH', ...
                'P','sea_water_pressure','C','sea_water_electrical_conductivi', ...
                'rho','sea_water_density','DOsat','percent_saturation');

% Download station climatology data in the depth range ZT to ZB
for ZT = 0:5:40
    ZB = ZT+5;
    % Select station group
    switch Astn
        case 'WStations'
            stnGroup = {'A2','A4','B3','C1','C2','D3','E1','09','15'};  
        case 'CStations'
            stnGroup = {'F2','F3','H2','H4','H6'};
        case 'EStations'
            stnGroup = {'I2','J2','K2','M3'};
    end
    % Initialize climatology data structure in the depth range ZT to ZB
    d = struct();
    for i = 1:length(fields)
        d.(fields{i}) = [];
    end
    % Get station group climatology data
    for i = 1:length(stnGroup)
        d0 = GetCTDEEP_Clim_Data(stnGroup{i}, ZT, ZB, 1);
        for j = 1:length(fields)
            if isfield(d0, fields{j})
                d.(fields{j}) = [d.(fields{j}); d0.(fields{j})];
            end
        end
    end
    % Shorten field names
    dpth = ['depth_' num2str(ZT) '_' num2str(ZB)];
    clim.(dpth).time = d.time/(24*3600)+datetime(1970,1,1);
    % Check each variable in station climatology data
    for av = {'T','S','DO','P','C','pH','rho','DOsat'}
        if isfield(d, av_stn.(av{1}))
            % Form QAQC structure
            clim.(dpth).(av{1}) = d.(av_stn.(av{1}));
        end
    end
end

%%
dp_rng = fieldnames(clim);
for i = 1:length(dp_rng)
    for av = {'T','S','DO','P','C','pH','rho','DOsat'}
        para = table('Size', [5,12], ...
                     'VariableTypes', repmat({'double'},1,12), ...
                     'VariableNames', arrayfun(@num2str,1:12,'UniformOutput',false), ...
                     'RowNames',{'count','max_val','min_val','bd_99','bd_1'});
        for nm = 1:12
            iu = find(month(clim.(dp_rng{i}).time)==nm);
            if ~isempty(iu)
                data = clim.(dp_rng{i}).(av{1})(iu);
            else
                data = 0;
            end
            
            % Calibrate thresholds
            switch av{1}
                case 'T'
                    rng = [-5 30];
                case 'S'
                    rng = [5 35];
                case 'DO'
                    rng = [0 20];
                case 'P'
                    rng = [0 70];
                case 'C'
                    rng = [0 50];
                case 'pH'
                    rng = [6 10];
                case 'rho'
                    rng = [16 25];
                case 'DOsat'
                    rng = [0 150];
            end
            
            para{1,nm} = length(iu);
            para{2,nm} = min(prctile(data,99.99), rng(2));
            para{3,nm} = max(prctile(data,0.01), rng(1));
            para{4,nm} = min(prctile(data,99), rng(2));
            para{5,nm} = max(prctile(data,1), rng(1));
        end
        QAQC.(dp_rng{i}).(av{1}) = para;
    end
end

% Save QAQC parameters of a group of stations
save(['QAQC_Para_' Astn '.mat'], 'QAQC');