function [CruiseDay, CruiseNames] = GetCruiseDateByCruiseName(d)
% 
% Enquire from ERDDAP for the cruise dates by cruise names
% 
% Called from GetCTDEEP_NutDataForComps.m
% 

wopts = weboptions; wopts.Timeout = 60;
AllCruiseNames = d.cruise;
CruiseNames = unique(AllCruiseNames, 'rows');

aURLp = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_Cruise_Info.json?cruise_name%2C' ...
         'Start_Date%2CEnd_Date&cruise_name=%22CCCC%22'];

CruiseDay = cell(size(CruiseNames,1), 1);
for nc = 1:size(CruiseNames,1)
    % Request the cruise dates for each cruise
    CruiseName = upper(deblank(CruiseNames(nc,:)));
    aURL = strrep(aURLp, 'CCCC', CruiseName);
    try
        data = webread(aURL, wopts);
        data = data.table.rows{1};
        CruiseDay{nc}(1,1) = datetime(data{2},'InputFormat','yyyy-MM-dd''T''HH:mm:ssZ','TimeZone','UTC');
        CruiseDay{nc}(2,1) = datetime(data{3},'InputFormat','yyyy-MM-dd''T''HH:mm:ssZ','TimeZone','UTC');
        CruiseDay{nc}(3,1) = mean(CruiseDay{nc}(1:2));
    catch
        fprintf('Resource Not Found in URL containing "%s"\n', CruiseName);
    end
end

end