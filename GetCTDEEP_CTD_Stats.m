function d = GetCTDEEP_CTD_Stats(Astn, CruiseNames, ZT, ZB)
% 
% Get the CTD profile statistics at a station by CruiseNames
% 
% CruiseNames is a structure with an element for each month. There may be 
% multiple cruises in each month that need to put them into a single series
% 
% Calls GetCTDEEP_CTD_Data.m
% 
% Called from VisualizeBuoyDataQAQC.m
% Called from WriteShipSurveyDataQAQC.m
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
    d{nc} = GetCTDEEP_CTD_Data(Astn, CN{nc}, ZT, ZB);
    if ~isempty(d{nc})
        % Average properties in the depth range specified
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
        tmp = d{nc}.PAR;
        d{nc}.mnPAR = mean(tmp(~isnan(tmp)));
        tmp = d{nc}.Chlorophyll;
        d{nc}.mnCHL = mean(tmp(~isnan(tmp)));
        tmp = d{nc}.Corrected_Chlorophyll;
        d{nc}.mnCorCHL = mean(tmp(~isnan(tmp)));
    end
end

end