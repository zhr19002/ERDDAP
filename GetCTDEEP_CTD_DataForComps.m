function d = GetCTDEEP_CTD_DataForComps(Astn, CruiseNames, DepRang, BdepLayer)
% 
% Get the CTD profile data from the CTDEEP ERDDAP archive by CruiseName
% CruiseNames is a structure with an element for each month. There may be 
% multiple cruises in each month need to put them into a single series
% 

% Astn = 'C2';
% CruiseNames = {["WQOCT18";"WQJUN21"], "HYJUL21"};
% DepRang = [0 30];
% BdepLayer = 30;

nct = 0;
for nn = 1:length(CruiseNames)
    if ~isempty(CruiseNames{nn})
        for nc = 1:length(CruiseNames{nn})
            nct = nct + 1;
            CN{nct} = CruiseNames{nn}(nc);
        end
    end
end

d = cell(nct,1);
for nn = 1:nct
    d{nn} = GetCTDEEP_stationdataThredds(Astn, CN{nn});
    if isfield(d{nn}, 'depth')
        % Average properties in the depth Range speced
        iuse = find(cell2mat(d{nn}.depth)>=DepRang(1) & cell2mat(d{nn}.depth)<=DepRang(2));
        
        if ~isempty(iuse)
            tmp = cell2mat(d{nn}.depth(iuse));
            d{nn}.SmnDepth = mean(tmp(~isnan(tmp)));
            tmp = cell2mat(d{nn}.sea_water_temperature(iuse));
            d{nn}.SmnTemp = mean(tmp(~isnan(tmp)));
            tmp = cell2mat(d{nn}.sea_water_salinity(iuse));
            d{nn}.SmnSal = mean(tmp(~isnan(tmp)));
            tmp = cell2mat(d{nn}.sea_water_density(iuse));
            d{nn}.SmnRho = mean(tmp(~isnan(tmp)));
            tmp = cell2mat(d{nn}.pH(iuse));
            d{nn}.SmnPH = mean(tmp(~isnan(tmp)));
            tmp = cell2mat(d{nn}.oxygen_concentration_in_sea_wat(iuse));
            d{nn}.SmnDO = mean(tmp(~isnan(tmp)));
            tmp = cell2table(d{nn}.Start_Date(iuse)).Var1;
            d{nn}.SmnTime = mean(tmp);
            tmp = cell2mat(d{nn}.PAR(iuse));
            d{nn}.SmnPAR = mean(tmp(~isnan(tmp)));
            tmp = cell2mat(d{nn}.Chlorophyll(iuse));
            d{nn}.SmnCHL = mean(tmp(~isnan(tmp)));
            tmp = cell2mat(d{nn}.Corrected_Chlorophyll(iuse));
            d{nn}.SmnCorCHL = mean(tmp(~isnan(tmp)));
        end
        
        maxdep = max(cell2mat(d{nn}.depth));    % Find sample in bottom range
        iuse = find(cell2mat(d{nn}.depth)>=maxdep-BdepLayer & cell2mat(d{nn}.depth)<=maxdep);
        
        if ~isempty(iuse)
            tmp = cell2mat(d{nn}.depth(iuse));
            d{nn}.BmnDepth = mean(tmp(~isnan(tmp)));
            tmp = cell2mat(d{nn}.sea_water_temperature(iuse));
            d{nn}.BmnTemp = mean(tmp(~isnan(tmp)));
            tmp = cell2mat(d{nn}.sea_water_salinity(iuse));
            d{nn}.BmnSal = mean(tmp(~isnan(tmp)));
            tmp = cell2mat(d{nn}.sea_water_density(iuse));
            d{nn}.BmnRho = mean(tmp(~isnan(tmp)));
            tmp = cell2mat(d{nn}.pH(iuse));
            d{nn}.BmnPH = mean(tmp(~isnan(tmp)));
            tmp = cell2mat(d{nn}.oxygen_concentration_in_sea_wat(iuse));
            d{nn}.BmnDO = mean(tmp(~isnan(tmp)));
            tmp = cell2table(d{nn}.Start_Date(iuse)).Var1;
            d{nn}.BmnTime = mean(tmp);
            tmp = cell2mat(d{nn}.PAR(iuse));
            d{nn}.BmnPAR = mean(tmp(~isnan(tmp)));
            tmp = cell2mat(d{nn}.Chlorophyll(iuse));
            d{nn}.BmnCHL = mean(tmp(~isnan(tmp)));
            tmp = cell2mat(d{nn}.Corrected_Chlorophyll(iuse));
            d{nn}.BmnCorCHL = mean(tmp(~isnan(tmp)));
        end
    end
end

end