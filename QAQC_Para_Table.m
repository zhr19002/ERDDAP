clc; clear;

Astn = 'WStations'; % {'WStations','CStations','EStations'}
max_depth = 50; % {50,50,50}
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
for ZT = 0:5:max_depth
    ZB = ZT+5;
    % Initialize climatology data structure in the depth range ZT to ZB
    d = struct();
    for i = 1:length(fields)
        d.(fields{i}) = [];
    end
    % Select station group
    switch Astn
        case 'WStations'
            stnGroup = {'A2','A4','B3','C1','C2','D3','E1','09','15'};  
        case 'CStations'
            stnGroup = {'F2','F3','H2','H4','H6'};
        case 'EStations'
            stnGroup = {'I2','J2','K2','M3'};
    end
    % Get station group climatology data
    for i = 1:length(stnGroup)
        d0 = GetDEEPWQClimData(stnGroup{i}, ZT, ZB);
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
            clim.(dpth).(av{1}).data = d.(av_stn.(av{1}));
        end
    end
end

% Save raw data of a group of stations
save([Astn '_raw_data.mat'], 'clim');

%%
clc; clear;
Astn = 'WStations';
clim = load([Astn '_raw_data.mat']);
clim = clim.clim;

dp_rng = fieldnames(clim);
for i = 1:length(dp_rng)
    for av = {'T','S','DO','P','C','pH','rho','DOsat'}
        para = table('Size', [7, 12], ...
                     'VariableTypes', repmat({'double'}, 1, 12), ...
                     'VariableNames',arrayfun(@num2str,1:12,'UniformOutput',false), ...
                     'RowNames',{'count','max_val','min_val','max_val2','min_val2','bd_99','bd_1'});
        for nm = 1:12
            iu = find(month(clim.(dp_rng{i}).time)==nm);
            if ~isempty(iu)
                d = clim.(dp_rng{i}).(av{1}).data(iu);
            else
                d = 0;
            end
            count = length(iu);
            max_val = max(d); min_val = min(d);
            max_val2 = prctile(d,99.99); min_val2 = prctile(d,0.01);
            bd_99 = prctile(d,99); bd_1 = prctile(d,1);
            
            para{1, nm} = count;
            para{2, nm} = max_val;
            para{3, nm} = min_val;
            para{4, nm} = max_val2;
            para{5, nm} = min_val2;
            para{6, nm} = bd_99;
            para{7, nm} = bd_1; 
        end
        QAQC_para.(dp_rng{i}).(av{1}) = para;
    end
end

% Save QAQC parameters of a group of stations
save([Astn '_para.mat'], 'QAQC_para');