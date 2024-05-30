function d = GetCTDEEP_CTD_DataForComps(Astn, CruiseNames, DepRng)
% 
% Get the CTD profile data from the CTDEEP ERDDAP archive by CruiseName
% 
% CruiseNames is a structure with an element for each month. There may be 
% multiple cruises in each month need to put them into a single series.
% 
% Calls GetCTDEEP_stationdataThredds.m
% 

% Astn = 'C1';
% CruiseNames = {'WQJUN19';['HYJUL19';'WQJUL19'];['HYAUG19';'WQAUG19'];[];'WQOCT19'};
% DepRang = [0 3];

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
    d{nn} = GetCTDEEP_stationdataThredds(Astn, CN{nn});
    if isfield(d{nn}, 'depth')
        % Average properties in the depth range specified
        iuse = find(cell2mat(d{nn}.depth)>=DepRng(1) & cell2mat(d{nn}.depth)<=DepRng(2));
        if isempty(iuse)
            iuse = find(cell2mat(d{nn}.depth)>=0 & cell2mat(d{nn}.depth)<=max(cell2mat(d{nn}.depth)));
        end
        tmp = cell2mat(d{nn}.depth(iuse));
        d{nn}.mnDepth = mean(tmp(~isnan(tmp)));
        tmp = cell2mat(d{nn}.sea_water_temperature(iuse));
        d{nn}.mnTemp = mean(tmp(~isnan(tmp)));
        tmp = cell2mat(d{nn}.sea_water_salinity(iuse));
        d{nn}.mnSal = mean(tmp(~isnan(tmp)));
        tmp = cell2mat(d{nn}.oxygen_concentration_in_sea_wat(iuse));
        d{nn}.mnDO = mean(tmp(~isnan(tmp)));
        tmp = cell2mat(d{nn}.sea_water_pressure(iuse));
        d{nn}.mnPres = mean(tmp(~isnan(tmp)));
        tmp = cell2mat(d{nn}.sea_water_electrical_conductivi(iuse));
        d{nn}.mnCond = mean(tmp(~isnan(tmp)));
        tmp = cell2mat(d{nn}.pH(iuse));
        d{nn}.mnPH = mean(tmp(~isnan(tmp)));
        tmp = cell2mat(d{nn}.sea_water_density(iuse));
        d{nn}.mnRho = mean(tmp(~isnan(tmp)));
        tmp = cell2table(d{nn}.Start_Date(iuse)).Var1;
        d{nn}.mnTime = mean(tmp);
        tmp = cell2mat(d{nn}.PAR(iuse));
        d{nn}.mnPAR = mean(tmp(~isnan(tmp)));
        tmp = cell2mat(d{nn}.Chlorophyll(iuse));
        d{nn}.mnCHL = mean(tmp(~isnan(tmp)));
        tmp = cell2mat(d{nn}.Corrected_Chlorophyll(iuse));
        d{nn}.mnCorCHL = mean(tmp(~isnan(tmp)));
        tmp = cell2mat(d{nn}.percent_saturation(iuse));
        d{nn}.mnDOsat = mean(tmp(~isnan(tmp)));
    end
end

end