% 
% Identify and flag ship survey data outliers
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 
% Calls GetCruiseNames.m
% Calls GetCTDEEP_CTD_Stats.m
% Calls ImplementThresholdTest.m
% Calls WriteCruiseNETCDF.m
% 

clc; clear;
Ayear = 2021;
av_stn = struct('T','sea_water_temperature','S','sea_water_salinity', ...
                'DO','oxygen_concentration_in_sea_wat','pH','pH', ...
                'P','sea_water_pressure','C','sea_water_electrical_conductivi', ...
                'rho','sea_water_density','DOsat','percent_saturation');

% Get max depth at a station
for Astn = {'A4','B3','C1','C2','D3','E1','F3'}
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
    % Get ship survey data in a depth range for all cruises at a station
    for ZT = 0:5:40
        ZB = ZT+5;
        dCTD = GetCTDEEP_CTD_Stats(Astn{1},CruiseNames,ZT,ZB);
        for nc = 1:numel(dCTD)
            if ~isempty(dCTD{nc})
                % Shorten field names
                crs = dCTD{nc}.cruise_name(1,:);
                stn = dCTD{nc}.station_name(1,:);
                dpth = ['depth_' num2str(ZT) '_' num2str(ZB)];
                clim.(crs).(stn).(dpth).time = dCTD{nc}.time/(24*3600)+datetime(1970,1,1);
                clim.(crs).(stn).(dpth).depth = dCTD{nc}.depth;
                % Check each variable in ship survey data
                for av = {'T','S','DO','P','C','pH','rho','DOsat'}
                    if isfield(dCTD{nc}, av_stn.(av{1}))
                        % Form QAQC structure
                        clim.(crs).(stn).(dpth).(av{1}).data = dCTD{nc}.(av_stn.(av{1}));
                        d_tmp = clim.(crs).(stn).(dpth).(av{1}).data;
                        dt = clim.(crs).(stn).(dpth).time;
                        c_tmp = ImplementThresholdTest(d_tmp, dt, QAQC, dpth, av{1});
                        clim.(crs).(stn).(dpth).(av{1}).check = c_tmp;
                    end
                end
            end
        end
    end
end

% Save QAQC results
CruiseQAQC = clim;
save(['CTDEEP_Cruises_' num2str(Ayear) '_QAQC.mat'], 'CruiseQAQC');

%%
% Save all the data plotted in a structure that can be exported to NETCDF
crs = fieldnames(CruiseQAQC);
for i = 1:length(crs)
    stn = fieldnames(CruiseQAQC.(crs{i}));
    for j = 1:length(stn)
        d0 = GetDEEPWQClimData(stn{j}, 0, 5);
        latlon = [mode(d0.latitude), mode(d0.longitude)];
        dp = fieldnames(CruiseQAQC.(crs{i}).(stn{j}));
        for k = 1:length(dp)
            stnDep = max(CruiseQAQC.(crs{i}).(stn{j}).(dp{k}).depth);
            WriteCruiseNETCDF(crs{i}, stn{j}, dp{k}, latlon, stnDep, CruiseQAQC.(crs{i}).(stn{j}).(dp{k}));
        end
    end
end