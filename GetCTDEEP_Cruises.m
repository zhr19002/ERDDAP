function CruiseNames = GetCTDEEP_Cruises(Ayear, Amonth)
% 
% Get cruise info in Ayear-Amonth from ERRDAP
% 
% Called from WriteCruiseDataQAQC.m
% 

al = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_Cruise_Info.json?' ...
      'cruise_name%2CStart_Date%2CEnd_Date&End_Date%3E=YYYY-MM-01&End_Date%3C=YYYY-MM-31'];
aurl = strrep(al, 'YYYY', num2str(Ayear));
aurl = strrep(aurl, 'MM', Amonth);

try
    cruise = webread(aurl);
catch
    disp(['No cruise in ' num2str(Ayear) '-' Amonth]);
    cruise = {}; CruiseNames = {};
end

if ~isempty(cruise)
    CruiseNames = cell(size(cruise.table.rows));
    for nc = 1:numel(cruise.table.rows)
        CruiseNames{nc} = cruise.table.rows{nc}{1};
    end
end

end