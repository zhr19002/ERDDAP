function res = GetDEEPWQClimatology(astn, ZT, ZB)
% 
% Get all the pH data from astn in the depth range ZT to ZB and return the stats
% 
% Called from Proc2021_pH_data.m
% 

% astn = 'E1'; ZT = 20; ZB = 30;

if ~ischar(ZT) | ~ischar(ZB)
    disp('Depth range should be characters');
    ZT = num2str(ZT); ZB = num2str(ZB);
end

% Form ERDDAP request
aurl0 = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_WQ.mat?' ...
         'cruise_name%2Cstation_name%2Ctime%2Cdepth%2CpH%2CStart_Date&' ...
	     'station_name=~%22XX%22&time%3E=2000-12-17T00%3A00%3A00Z&time%3C=2022-12-17T00%3A00%3A00Z&' ...
	     'depth%3E=ZT&depth%3C=ZB'];

aurl = strrep(aurl0, 'XX', astn);
aurl = strrep(aurl, 'ZT', ZT);
aurl = strrep(aurl, 'ZB', ZB);
afile = ['CTDEEP_PH_' astn '_' ZT '_' ZB '.mat'];

if exist(afile, 'file')
    d = load(afile);
else
    wopt = weboptions;
    wopt.Timeout = 120;
    af = websave(afile, aurl, wopt);
    d = load(af);
end

% RETURNED INFO
% cruise_name: [19120×7 char]
% station_name: [19120×2 char]
% time: [19120×1 double]
% depth: [19120×1 single]
% pH: [19120×1 single]
% Start_Date: [19120×1 double]

daten = d.DEEP_WQ.Start_Date/(24*3600) + datetime(1970,1,1);

% Average by month
[~, mnth, ~] = datevec(daten);
for nm = 1:12
    iu = find(mnth==nm);
    res.ndays(nm) = length(unique(daten(iu)));
    res.nu(nm) = length(iu);
    tmp = d.DEEP_WQ.pH(iu);
    res.mnpH(nm) = mean(tmp(~isnan(tmp)));
    tmp = d.DEEP_WQ.pH(iu);
    res.sdpH(nm) = std(tmp(~isnan(tmp)));
    res.upper(nm) = mean(max(d.DEEP_WQ.pH(iu)));
    res.lower(nm) = mean(min(d.DEEP_WQ.pH(iu)));
    res.bd26(nm) = prctile(d.DEEP_WQ.pH(iu),26);
    res.bd50(nm) = prctile(d.DEEP_WQ.pH(iu),50);
    res.bd84(nm) = prctile(d.DEEP_WQ.pH(iu),84);
end

end