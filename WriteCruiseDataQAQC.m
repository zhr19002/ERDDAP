% 
% Identify and flag cruise climatology data outliers
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 
% Calls GetCTDEEP_Cruises.m
% Calls GetCTDEEP_CTD_Data.m
% Calls ImplementThresholdTest.m
% Calls GetCTDEEP_Clim_Data.m
% Calls WriteCruiseNETCDF.m
% 

clc; clear;

Ayear = 2021;
stnGrp = {'A4','B3','C1','C2','D3','E1','F3'};

% Fixed parameters
av_stn = struct('T','sea_water_temperature','S','sea_water_salinity', ...
                'DO','oxygen_concentration_in_sea_wat','P','sea_water_pressure', ...
                'C','sea_water_electrical_conductivi','pH','pH', ...
                'rho','sea_water_density','DOsat','percent_saturation', ...
                'PAR','PAR','Chl','Chlorophyll','Corrected_Chl','Corrected_Chlorophyll');

for Astn = stnGrp
    % Read station group QAQC parameters
    if ismember(Astn{1}, {'A2','A4','B3','C1','C2','D3','E1','09','15'})
        stns = 'WStations';
    elseif ismember(Astn{1}, {'F2','F3','H2','H4','H6'})
        stns = 'CStations';
    else
        stns = 'EStations';
    end
    QAQC = load(['QAQC_Para_' stns '.mat']);
    QAQC = QAQC.QAQC;
    
    % Get cruise names for all months in Ayear
    % There may be multiple cruises within a month
    CruiseNames = cell(12,1);
    for nn = 1:12
        if nn < 10
            Amonth = sprintf('0%i', nn);
        else
            Amonth = sprintf('%i', nn);
        end
        CruiseNames{nn} = GetCTDEEP_Cruises(Ayear, Amonth);
    end
    
    % Store each cruise name in the "CN" structure
    nct = 0;
    CN = cell(sum(cellfun(@length, CruiseNames)),1);
    for nc = 1:numel(CruiseNames)
        if ~isempty(CruiseNames{nc})
            for ncc = 1:numel(CruiseNames{nc})
                nct = nct + 1;
                CN{nct} = CruiseNames{nc}{ncc};
            end
        end
    end
    
    % Download cruise climatology data at Astn in the depth range ZT to ZB
    for ZT = 0:5:40
        ZB = ZT+5;
        % Get cruise climatology data for cruises at Astn
        d = GetCTDEEP_CTD_Data(Astn{1}, CN, ZT, ZB, 1);
        for nc = 1:numel(d)
            if ~isempty(d{nc})
                % Shorten field names
                crs = d{nc}.cruise_name{1};
                stn = d{nc}.station_name{1};
                dpth = ['depth_' num2str(ZT) '_' num2str(ZB)];
                clim.(crs).(stn).(dpth).time = d{nc}.time/(24*3600)+datetime(1970,1,1);
                clim.(crs).(stn).(dpth).depth = d{nc}.depth;
                % Check each variable in cruise climatology data
                for av = {'T','S','DO','P','C','pH','rho','DOsat','PAR','Chl','Corrected_Chl'}
                    if isfield(d{nc}, av_stn.(av{1}))
                        % Form QAQC structure
                        clim.(crs).(stn).(dpth).(av{1}).data = d{nc}.(av_stn.(av{1}));
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
save(['Cruises_' num2str(Ayear) '_QAQC.mat'], 'CruiseQAQC');

%%
% Get [latitude, longitude] for each station
stn_latlon = struct();
for Astn = stnGrp
    d0 = GetCTDEEP_Clim_Data(Astn{1}, 0, 5, 1);
    stn_latlon.(Astn{1}) = [mode(d0.latitude), mode(d0.longitude)];
end

% Save all the data plotted in a structure that can be exported to NETCDF
crs = fieldnames(CruiseQAQC);
for i = 1:length(crs)
    stn = fieldnames(CruiseQAQC.(crs{i}));
    for j = 1:length(stn)
        latlon = stn_latlon.(stn{j});
        dp = fieldnames(CruiseQAQC.(crs{i}).(stn{j}));
        for k = 1:length(dp)
            stnDep = max(CruiseQAQC.(crs{i}).(stn{j}).(dp{k}).depth);
            WriteCruiseNETCDF(crs{i}, stn{j}, dp{k}, latlon, stnDep, CruiseQAQC.(crs{i}).(stn{j}).(dp{k}));
        end
    end
end