function [CruiseDay, CruiseNames] = GetCTDEEP_Cruises(Ayear, Amonth)
% 
% Get cruise information from ERRDAP in Ayear-Amonth
% 
% Called from WriteCruiseDataQAQC.m
% 

aURLpat = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_Cruise_Info.json?cruise_name%2C' ...
           'Start_Date%2CEnd_Date&Start_Date%3E=YYYY-MM-01&Start_Date%3C=YYYY-MM-31'];
aURL0 = strrep(aURLpat, 'YYYY', num2str(Ayear));
aURL = strrep(aURL0, 'MM', Amonth);

try
    cruise = webread(aURL);
catch
    disp(['No cruise in ' num2str(Ayear) '-' Amonth]);
    cruise = {}; CruiseDay = {}; CruiseNames = {};
end

if ~isempty(cruise)
    CruiseDay = cell(size(cruise.table.rows));
    CruiseNames = cell(size(cruise.table.rows));
    for nc = 1:numel(cruise.table.rows)
        CruiseNames{nc} = cruise.table.rows{nc}{1};
        CruiseDay{nc}.start = cruise.table.rows{nc}{2};
        CruiseDay{nc}.end = cruise.table.rows{nc}{3};
    end
end

end