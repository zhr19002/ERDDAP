function [CruiseDay, CruiseNames] = GetCruiseNames(Ayear, Amonth)
% 
% Extract CTDEEP_WQ cruise names from ERRDAP
% 
% Called from GetCTDEEP_WQDataForComps.m
% 

aURLpat = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_Cruise_Info.json?cruise_name%2C' ...
           'Start_Date%2CEnd_Date&Start_Date%3E=YYYY-MM-01&Start_Date%3C=YYYY-MM-31'];
aURL0 = strrep(aURLpat, 'YYYY', num2str(Ayear));
aURL = strrep(aURL0, 'MM', Amonth);

try
    data = webread(aURL);
catch
    disp(['No cruises in ' num2str(Ayear) '-' Amonth]);
    data = {}; CruiseDay = {}; CruiseNames = {};
end

if ~isempty(data)
    CruiseDay = cell(size(data.table.rows));
    CruiseNames = cell(size(data.table.rows));
    for nc = 1:numel(data.table.rows)
        CruiseNames{nc} = data.table.rows{nc}{1};
        CruiseDay{nc}.start = data.table.rows{nc}{2};
        CruiseDay{nc}.end = data.table.rows{nc}{3};
    end
end

end