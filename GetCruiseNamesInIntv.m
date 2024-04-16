function [CruiseDay, CruiseNames] = GetCruiseNamesInIntv(Ayear, ann)
% 
% extract the CTDEEP_WQ cruise names available on ERRDAP
% request a json table
% CruiseDay{nn}
% 

%Ayear = '2021'; ann = '06';

aURLpat = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_Cruise_Info.json?'...
           'cruise_name%2CStart_Date%2CEnd_Date&Start_Date%3E=YYYY-MM-01T00%3A00%3A00Z'...
           '&Start_Date%3C=YYYY-MM-31T24%3A00%3A00Z'];

aURL0 = strrep(aURLpat, 'YYYY', Ayear);
aURL = strrep(aURL0, 'MM', ann);

data = webread(aURL);
CruiseDay = cell(length(data.table.rows), 1);
CruiseNames = cell(length(data.table.rows), 1);
for nn = 1:length(data.table.rows) % number of cruises in the month
    CruiseDay{nn}.start = data.table.rows{nn}{2};
    CruiseDay{nn}.end = data.table.rows{nn}{3};
    CruiseNames{nn} = data.table.rows{nn}{1};
end

end