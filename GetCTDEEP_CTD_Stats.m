function d = GetCTDEEP_CTD_Stats(Astn, CruiseNames, ZT, ZB)
% 
% Get CTD statistics for cruises at Astn in the depth range ZT to ZB
% 
% "CruiseNames" is a structure with an element for each month, and there may be 
% multiple cruises within each month that need to be combined into a single series
% 
% Calls GetCTDEEP_CTD_Data.m
% 
% Called from WriteCruiseDataQAQC.m
% 

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

d = cell(size(CN));
for nc = 1:numel(CN)
    % Get cruise climatology data on CN{nc} at Astn
    d{nc} = GetCTDEEP_CTD_Data(Astn, CN{nc}, ZT, ZB);
    if ~isempty(d{nc})
        % Mean values for each variable in the depth range ZT to ZB
        tmp = d{nc}.depth;
        d{nc}.mnDepth = mean(tmp(~isnan(tmp)));
        tmp = d{nc}.time;
        d{nc}.mnTime = mean(tmp(~isnan(tmp)));
        d{nc}.mnTime = d{nc}.mnTime/(24*3600) + datetime(1970,1,1);
        tmp = d{nc}.sea_water_temperature;
        d{nc}.mnTemp = mean(tmp(~isnan(tmp)));
        tmp = d{nc}.sea_water_salinity;
        d{nc}.mnSal = mean(tmp(~isnan(tmp)));
        tmp = d{nc}.oxygen_concentration_in_sea_wat;
        d{nc}.mnDO = mean(tmp(~isnan(tmp)));
        tmp = d{nc}.sea_water_pressure;
        d{nc}.mnPres = mean(tmp(~isnan(tmp)));
        tmp = d{nc}.sea_water_electrical_conductivi;
        d{nc}.mnCond = mean(tmp(~isnan(tmp)));
        tmp = d{nc}.pH;
        d{nc}.mnPH = mean(tmp(~isnan(tmp)));
        tmp = d{nc}.sea_water_density;
        d{nc}.mnRho = mean(tmp(~isnan(tmp)));
        tmp = d{nc}.percent_saturation;
        d{nc}.mnDOsat = mean(tmp(~isnan(tmp)));
    end
end

end