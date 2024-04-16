function [Daten, CruiseNames] = GetCruiseDateRange(d)
% 
% enquire from ERRDAP what the cruisedate range is
% 

% d = load('DEEP_Nutrient.mat');
% d = d.DEEP_Nutrient;

AllCruiseNames = d.cruise;
CruiseNames = unique(AllCruiseNames, 'rows');

aURLp = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/'...
         'DEEP_Cruise_Info.asc?cruise_name%2CStart_Date%2CEnd_Date&cruise_name'...
         '=~%22CCCC%22'];
wopts = weboptions;
wopts.Timeout = 60;

Daten = cell(size(CruiseNames,1), 1);

for nn = 1:size(CruiseNames,1)
    % for each cruise name make a request for the dates
    % there should only be one line of data returned
    CruiseName = upper(deblank(CruiseNames(nn,:)));
    aURL = strrep(aURLp, 'CCCC', CruiseName);
    
    try
        tmp = webread(aURL, wopts);
        
        % locate data in output str
        idata = strfind(tmp, CruiseName);
        adata = tmp(idata+length(CruiseName)+2 : end);
        tt = sscanf(adata, '%f, %f');
        
        %convert to datenum and put the middle date in element 3
        Daten{nn} = tt/(24*3600) + datetime(1970,1,1);
        Daten{nn}(3) = mean(Daten{nn}(1:2));
    catch
        fprintf('Resource Not Found in URL containing "%s"\n', CruiseName);
    end
end

end