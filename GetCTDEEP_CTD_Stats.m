function d = GetCTDEEP_CTD_Stats(Astn, CruiseNames, ZT, ZB)
% 
% Get the CTD profile data from the CTDEEP ERDDAP archive by CruiseName
% 
% CruiseNames is a structure with an element for each month. There may be 
% multiple cruises in each month need to put them into a single series.
% 
% Calls GetCTDEEP_CTD_Data.m
% 
% Called from VisualizeBuoyDataQAQC.m
% Called from CheckShipSurveyDataQAQC.m
% 

% CruiseNames = {'WQJUN19';['HYJUL19';'WQJUL19'];['HYAUG19';'WQAUG19'];[];'WQOCT19'};

cellnum = 0;
for nn = 1:size(CruiseNames,1)
    if ~isempty(CruiseNames{nn})
        for nc = 1:size(CruiseNames{nn},1)
            cellnum = cellnum + 1;
        end
    end
end

nct = 0;
CN = cell(cellnum,1);
for nn = 1:size(CruiseNames,1)
    if ~isempty(CruiseNames{nn})
        for nc = 1:size(CruiseNames{nn},1)
            nct = nct + 1;
            CN{nct} = CruiseNames{nn}(nc,:);
        end
    end
end

d = cell(cellnum,1);
for nn = 1:cellnum
    d{nn} = GetCTDEEP_CTD_Data(Astn, CN{nn});
    if isfield(d{nn}, 'depth')
        % Average properties in the depth range specified
        iu = find(cell2mat(d{nn}.depth)>=ZT & cell2mat(d{nn}.depth)<=ZB);
        if isempty(iu)
            iu = find(cell2mat(d{nn}.depth)>=0 & cell2mat(d{nn}.depth)<=max(cell2mat(d{nn}.depth)));
        end
        tmp = cell2mat(d{nn}.depth(iu));
        d{nn}.mnDepth = mean(tmp(~isnan(tmp)));
        tmp = cell2mat(d{nn}.sea_water_temperature(iu));
        d{nn}.mnTemp = mean(tmp(~isnan(tmp)));
        tmp = cell2mat(d{nn}.sea_water_salinity(iu));
        d{nn}.mnSal = mean(tmp(~isnan(tmp)));
        tmp = cell2mat(d{nn}.oxygen_concentration_in_sea_wat(iu));
        d{nn}.mnDO = mean(tmp(~isnan(tmp)));
        tmp = cell2mat(d{nn}.sea_water_pressure(iu));
        d{nn}.mnPres = mean(tmp(~isnan(tmp)));
        tmp = cell2mat(d{nn}.sea_water_electrical_conductivi(iu));
        d{nn}.mnCond = mean(tmp(~isnan(tmp)));
        tmp = cell2mat(d{nn}.pH(iu));
        d{nn}.mnPH = mean(tmp(~isnan(tmp)));
        tmp = cell2mat(d{nn}.sea_water_density(iu));
        d{nn}.mnRho = mean(tmp(~isnan(tmp)));
        tmp = cell2table(d{nn}.Start_Date(iu)).Var1;
        d{nn}.mnTime = mean(tmp);
        tmp = cell2mat(d{nn}.PAR(iu));
        d{nn}.mnPAR = mean(tmp(~isnan(tmp)));
        tmp = cell2mat(d{nn}.Chlorophyll(iu));
        d{nn}.mnCHL = mean(tmp(~isnan(tmp)));
        tmp = cell2mat(d{nn}.Corrected_Chlorophyll(iu));
        d{nn}.mnCorCHL = mean(tmp(~isnan(tmp)));
        tmp = cell2mat(d{nn}.percent_saturation(iu));
        d{nn}.mnDOsat = mean(tmp(~isnan(tmp)));
    end
end

end