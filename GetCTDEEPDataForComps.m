function [ds, db, CruiseNames] = GetCTDEEPDataForComps(Astn, Ayear, Nmth)
% 
% Gets station data from CTDEEP ERDDAP site
% 
% Calls GetCruiseDateRange.m
% Calls seperate_DEEP_Nut_data.m
% 
% Called from VisualizeBuoyDataQAQC.m
% Called from CheckShipSurveyDataQAQC.m
% 

Ayear = num2str(Ayear); wopts = weboptions; wopts.Timeout = 60;

aURLpat = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_Nutrient.mat?' ...
        'cruise%2CLab_ID%2CStation_Name%2CDepth_Code%2CDetection_Limit%2CDilution_Factor' ...
        '%2CPQL%2CParameter%2CResult%2Cnon_detect%2CUnits%2CComment%2CMonth%2Clatitude' ...
        '%2Clongitude%2CTime_ON_Station%2CTime_OFF_Station%2Ctime%2CStart_Date%2CEnd_Date' ...
        '%2CB_Sample_Depth%2CM_Sample_Depth%2CS_Sample_Depth%2CNB_Sample_Depth&' ...
        'Station_Name=~%22XX%22&time%3E=YYYY-MM-01T00%3A00%3A00Z&time%3C=YYYY-MM-31T00' ...
        '%3A00%3A00Z'];
aURL0 = strrep(aURLpat, 'YYYY', Ayear);
aURL0 = strrep(aURL0, 'XX', Astn);

CruiseDay = cell(size(Nmth,2), 1);
CruiseNames = cell(size(Nmth,2), 1);
dd = cell(size(Nmth,2), 1);
ds = cell(size(Nmth,2), 1);
db = cell(size(Nmth,2), 1);

% Step through months and get the data from the ERDDAP server
for nn = Nmth
    if nn < 10
        ann = sprintf('0%i', nn);
    else
        ann = sprintf('%i', nn);
    end
    
    aURL = strrep(aURL0, 'MM', ann);
    afile = ['DEEP_' Astn '_' Ayear '_' ann '.mat'];
    if ~exist(afile, 'file')
        disp(['Getting data from ERDDAP at ' Astn ' in ' Ayear '-' ann]);
        try
            af = websave(afile, aURL, wopts);
            dd{nn} = load(af);
        catch
            disp(['No data for ' afile]);
            dd{nn} = [];
        end
    else
        disp(['Loading local ' afile]);
        dirsz = dir(afile);
        if ~isempty(dirsz) & dirsz.bytes>0
            dd{nn} = load(afile);
        else
            dd{nn} = [];
        end
    end
end

% Now extract the required data for the surface and bottom. 
% Get both S and SDUP etc.
for nn = Nmth
    % Get the date range for the cruise since the database doesn't have that 
    % Note there may be more than one cruise per month.
    if ~isempty(dd{nn})
        [CruiseDay{nn}, CruiseNames{nn}] = GetCruiseDateRange(dd{nn}.DEEP_Nutrient);
        [ds{nn}, db{nn}] = seperate_DEEP_Nut_data(dd{nn}.DEEP_Nutrient, CruiseDay{nn});
    else
        ds{nn} = [];
        db{nn} = [];
        CruiseNames{nn} = [];
        CruiseDay{nn} = [];
    end
end

end