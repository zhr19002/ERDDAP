function [ut, res] = GetDEEPStationSurfaceData(Astn)
% 
% Get the Surface Values in all DEEP records by station.
% Make time sereis figures and then a mean annual cycle.
% Save the results for later use in a mat file.
% 
% Calls:
%   EstimateBeta.m
%   ComputeMonthAvg.m
% 
% Called from VisualizeDEEPStationSurfaceData.m
% 

FigsOn = 0; % Set > 0 for plotting
wopt = weboptions; wopt.Timeout = 300;

% Get the surface data from top 3 m of all profiles at Astn
Atop = num2str(0); Abot = num2str(3);

% Define URL pattern
aurl0 = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_WQ.mat?'...
        'cruise_name%2Cstation_name%2Ctime%2Clatitude%2Clongitude%2C'...
        'sea_water_temperature%2CPAR%2CChlorophyll%2CCorrected_Chlorophyll%2C'...
        'sea_water_salinity%2Cdepth%2CStart_Date%2CTime_ON_Station&' ...
        'station_name=~%22XX%22&depth%3E=ZZT&depth%3C=ZZB'];

aurl = strrep(aurl0, 'XX', Astn);
aurl = strrep(aurl, 'ZZT', Atop);
aurl = strrep(aurl, 'ZZB', Abot);

afile = ['DEEPstation_SurfaceData' Astn '.mat'];
if ~exist(afile, 'file')
    af = websave(afile, aurl, wopt);
    d = load(af);
else
    d = load(afile);
end
d = d.DEEP_WQ;

daten = d.Start_Date/(24*3600) + datetime(1970,1,1);

% Find the unique times and profiles
ut = unique(daten);
lut = length(ut);

% Initialization
PARmx = zeros(lut,1);

PAR0 = zeros(lut,1); PAR0upper = zeros(lut,1); PAR0lower = zeros(lut,1);
beta = zeros(lut,1); betaupper = zeros(lut,1); betalower = zeros(lut,1);
ParCorr = zeros(lut,1);

Tempavg = zeros(lut,1); Tempmax = zeros(lut,1); Tempmin = zeros(lut,1);
Salavg = zeros(lut,1); Salmax = zeros(lut,1); Salmin = zeros(lut,1);
CHLAavg = zeros(lut,1); CHLAMax = zeros(lut,1); CHLAMin = zeros(lut,1);
CHLA_Coravg = zeros(lut,1); CHLA_CorMax = zeros(lut,1); CHLA_CorMin = zeros(lut,1);

% Process to get the max PAR and mean of other stuff
for i = 1:lut
    iu = find(daten==ut(i));
    % PAR measured from the ship is subject to shading error 
    % and not very reliable to compute the extinction coeff
    PARmx(i) = max(d.PAR(iu));

    [PAR0(i), PAR0upper(i), PAR0lower(i), ...
     beta(i), betaupper(i), betalower(i), ...
     ParCorr(i)] = EstimateBeta(d.depth(iu), d.PAR(iu), FigsOn);
    
    tmp = d.sea_water_temperature(iu);
    Tempavg(i) = mean(tmp(~isnan(tmp)));
    tmp = d.sea_water_temperature(iu);
    Tempmax(i) = mean(tmp(~isnan(tmp)));
    tmp = d.sea_water_temperature(iu);
    Tempmin(i) = mean(tmp(~isnan(tmp)));
    tmp = d.sea_water_salinity(iu);
    Salavg(i) = mean(tmp(~isnan(tmp)));
    tmp = d.sea_water_salinity(iu);
    Salmax(i) = mean(tmp(~isnan(tmp)));
    tmp = d.sea_water_salinity(iu);
    Salmin(i) = mean(tmp(~isnan(tmp)));
    tmp = d.Chlorophyll(iu);
    CHLAavg(i) = mean(tmp(~isnan(tmp)));
    tmp = d.Chlorophyll(iu);
    CHLAMax(i) = mean(tmp(~isnan(tmp)));
    tmp = d.Chlorophyll(iu);
    CHLAMin(i) = mean(tmp(~isnan(tmp)));
    tmp = d.Corrected_Chlorophyll(iu);
    CHLA_Coravg(i) = mean(tmp(~isnan(tmp)));
    tmp = d.Corrected_Chlorophyll(iu);
    CHLA_CorMax(i) = mean(tmp(~isnan(tmp)));
    tmp = d.Corrected_Chlorophyll(iu);
    CHLA_CorMin(i) = mean(tmp(~isnan(tmp)));
end

% Make the monthly averages
res.Temp = ComputeMonthAvg(ut, Tempavg);
res.Sal = ComputeMonthAvg(ut, Salavg);
res.CHLA = ComputeMonthAvg(ut, CHLA_Coravg);
res.PAR0 = ComputeMonthAvg(ut, PAR0);
res.PARmx = ComputeMonthAvg(ut, PARmx);
res.beta = ComputeMonthAvg(ut, beta);

% Save the results fdisor use elsewhere
disp(['Saving: ' 'ARTG_SurfaceData' Astn '.mat']);
save(['ARTG_SurfaceData' Astn '.mat'], 'res', 'Astn', 'Atop', 'Abot');

end