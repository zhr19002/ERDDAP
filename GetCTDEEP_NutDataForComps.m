function [ds, db, CruiseNames] = GetCTDEEP_NutDataForComps(Astn, Ayear, Nmth)
% 
% Get station data (dd, ds, db) from ERDDAP
% 
% Calls GetCruiseDateByCruiseName.m
% Calls SepCTDEEP_NutData.m
% 

wopts = weboptions; wopts.Timeout = 120;
Ayear = num2str(Ayear);

aURLpat = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_Nutrient.mat?cruise%2C' ...
           'Lab_ID%2CStation_Name%2CDepth_Code%2CDetection_Limit%2CDilution_Factor%2CPQL' ...
           '%2CParameter%2CResult%2Cnon_detect%2CUnits%2CComment%2CMonth%2Clatitude%2C' ...
           'longitude%2CTime_ON_Station%2CTime_OFF_Station%2Ctime%2CStart_Date%2CEnd_Date' ...
           '%2CB_Sample_Depth%2CM_Sample_Depth%2CS_Sample_Depth%2CNB_Sample_Depth&' ...
           'Station_Name=%22XX%22&time%3E=YYYY-MM-01&time%3C=YYYY-MM-31'];
aURL0 = strrep(aURLpat, 'XX', Astn);
aURL0 = strrep(aURL0, 'YYYY', Ayear);

d = cell(12,1);
% Step through months and get station data from ERDDAP
for nn = Nmth
    if nn < 10
        Amonth = sprintf('0%i', nn);
    else
        Amonth = sprintf('%i', nn);
    end
    
    aURL = strrep(aURL0, 'MM', Amonth);
    afile = ['DEEPNut_' Astn '_' Ayear '_' Amonth '.mat'];

    % Request station nutrient data
    if ~exist(afile, 'file')
        disp(['Getting data from ERDDAP at ' Astn ' in ' Ayear '-' Amonth]);
        try
            af = websave(afile, aURL, wopts);
            d{nn} = load(af);
            d{nn} = d{nn}.DEEP_Nutrient;
        catch
            disp(['No data at ' Astn ' in ' Ayear '-' Amonth]);
            d{nn} = [];
        end
    else
        disp(['Loading local ' afile]);
        if ~isempty(dir(afile)) & dir(afile).bytes>0
            d{nn} = load(afile);
            d{nn} = d{nn}.DEEP_Nutrient;
        else
            d{nn} = [];
        end
    end
end

CruiseDay = cell(12,1); CruiseNames = cell(12,1);
ds = cell(12,1); db = cell(12,1);
% Extract the required data for the surface and bottom
for nn = Nmth
    if ~isempty(d{nn})
        % Get the cruise date range
        % Note that there may be more than one cruise per month
        [CruiseDay{nn}, CruiseNames{nn}] = GetCruiseDateByCruiseName(d{nn});
        [ds{nn}, db{nn}] = SepCTDEEP_NutData(d{nn}, CruiseDay{nn});
    else
        CruiseDay{nn} = []; CruiseNames{nn} = [];
        ds{nn} = []; db{nn} = [];
    end
end

end