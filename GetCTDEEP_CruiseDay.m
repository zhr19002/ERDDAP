function CruiseDay = GetCTDEEP_CruiseDay(d)
% 
% Enquire from ERDDAP for cruise dates
% 
% Called from GetCTDEEP_Nut_Data.m
% 

wopts = weboptions; wopts.Timeout = 120;

al = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_Cruise_Info.json?' ...
      'cruise_name%2CStart_Date%2CEnd_Date&cruise_name=%22XX%22'];

CruiseNames = unique(d.cruise, 'rows');
CruiseDay = cell(size(CruiseNames,1),1);
for nc = 1:size(CruiseNames,1)
    % Request cruise dates for each cruise
    CruiseName = upper(deblank(CruiseNames(nc,:)));
    aurl = strrep(al, 'XX', CruiseName);
    try
        data = webread(aurl, wopts);
        data = data.table.rows{1};
        CruiseDay{nc}(1,1) = datetime(data{2},'InputFormat','yyyy-MM-dd''T''HH:mm:ssZ','TimeZone','UTC');
        CruiseDay{nc}(2,1) = datetime(data{3},'InputFormat','yyyy-MM-dd''T''HH:mm:ssZ','TimeZone','UTC');
    catch
        fprintf('Resource Not Found in URL containing "%s"\n', CruiseName);
    end
end

end