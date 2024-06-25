function [lat, lon, maxDepth] = GetDEEPWQClimDepth(Astn, Ayear)
% 
% Get max depth at a station in a specific year
% 
% Called from WriteStationDataQAQC.m
% Called from WriteShipSurveyDataQAQC.m
% 

wopts = weboptions; wopts.Timeout = 120;

% Form ERDDAP request
aurl0 = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_WQ.mat?station_name%2Ctime%2C' ...
         'latitude%2Clongitude%2Cdepth&station_name=%22XX%22&time%3E=YYYY-01-01&time%3C=YYYY-12-31'];
aurl = strrep(aurl0, 'XX', Astn);
aurl = strrep(aurl, 'YYYY', num2str(Ayear));

afile = ['CTDEEP_' Astn '_' num2str(Ayear) '.mat'];
if ~exist(afile, 'file')
    disp(['Getting data from ERDDAP at ' Astn ' in ' num2str(Ayear)]);
    try
        af = websave(afile, aurl, wopts);
        d = load(af);
        maxDepth = max(d.DEEP_WQ.depth);
        lat = mode(d.DEEP_WQ.latitude);
        lon = mode(d.DEEP_WQ.longitude);
    catch
        disp(['No data at ' Astn ' in ' num2str(Ayear)]);
        maxDepth = 0; lat = 0; lon = 0;
    end
else
    if ~isempty(dir(afile)) & dir(afile).bytes>0
        d = load(afile);
        maxDepth = max(d.DEEP_WQ.depth);
        lat = mode(d.DEEP_WQ.latitude);
        lon = mode(d.DEEP_WQ.longitude);
    else
        maxDepth = 0; lat = 0; lon = 0;
    end
end

end