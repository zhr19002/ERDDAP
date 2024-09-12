function [ds, db] = GetCTDEEP_Nut_Data(Astn, Ayear)
% 
% Get station data [ds, db] from ERDDAP
% 
% Calls GetCruiseDateByCruiseName.m
% Calls SepCTDEEP_NutData.m
% 

Ayear = num2str(Ayear);
wopts = weboptions; wopts.Timeout = 120;

% Form ERDDAP request
al = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_Nutrient.mat?' ...
      'cruise%2CStation_Name%2CDepth_Code%2CPQL%2CParameter%2CResult%2C' ...
      'latitude%2Clongitude%2CTime_ON_Station%2Ctime%2C' ...
      'B_Sample_Depth%2CM_Sample_Depth%2CS_Sample_Depth%2CNB_Sample_Depth' ...
      '&Station_Name=%22XX%22&time%3E=YYYY-MM-01&time%3C=YYYY-MM-31'];
al = strrep(al, 'XX', Astn);
al = strrep(al, 'YYYY', Ayear);

% Step through 12 months and get station nutrient data from ERDDAP
d = cell(12,1);
for nn = 1:12
    if nn < 10
        Amonth = sprintf('0%i', nn);
    else
        Amonth = sprintf('%i', nn);
    end

    % Request station nutrient data
    aurl = strrep(al, 'MM', Amonth);
    afile = ['CTDEEP_Nut_' Astn '_' Ayear '_' Amonth '.mat'];
    if ~exist(afile, 'file')
        disp(['Getting data from ERDDAP at ' Astn ' in ' Ayear '-' Amonth]);
        try
            af = websave(afile, aurl, wopts);
            d{nn} = load(af);
            d{nn} = d{nn}.DEEP_Nutrient;
            % Save the updated .mat file
            DEEP_Nutrient = d{nn};
            save(afile, 'DEEP_Nutrient');
        catch
            disp(['No data at ' Astn ' in ' Ayear '-' Amonth]);
            d{nn} = {};
        end
    else
        if ~isempty(dir(afile)) & dir(afile).bytes>0
            d{nn} = load(afile);
            d{nn} = d{nn}.DEEP_Nutrient;
        else
            d{nn} = {};
        end
    end
end

CruiseDay = cell(12,1); ds = cell(12,1); db = cell(12,1);
% Extract the required data for the surface and bottom
for nn = 1:12
    if ~isempty(d{nn})
        % Get cruise dates
        CruiseDay{nn} = GetCTDEEP_CruiseDay(d{nn});
        [ds{nn}, db{nn}] = SepNutData(d{nn}, CruiseDay{nn});
    else
        CruiseDay{nn} = {}; ds{nn} = {}; db{nn} = {};
    end
end

end