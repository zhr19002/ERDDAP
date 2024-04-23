function [ut, res] = GetDEEPStationSurfaceData(Astn)
% 
% Get the Surface Values in all DEEP records by station.
% Make time sereis figures and then a mean annual cycle.
% Save the results for later use in a mat file.
% 
% Calls:
%   EstimateBeta.m
%   ComputeMonthlyAverages.m
% 
% Called from VisualizeDEEPStationSurfaceData.m
% 

FigsOn = 0; % Set >0 for graphs

wopt = weboptions;
wopt.Timeout = 300;

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

daten = d.DEEP_WQ.Start_Date/(24*3600) + datetime(1970,1,1);

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
for nt = 1:lut
    iu = find(daten==ut(nt));
    % PAR measured from the ship is subject to shading error 
    % and not very reliable to compute the extinction coeff
    PARmx(nt) = max(d.DEEP_WQ.PAR(iu)); 
    [PAR0(nt), PAR0upper(nt), PAR0lower(nt), beta(nt), ...
     betaupper(nt), betalower(nt), ParCorr(nt)] = ...
    EstimateBeta(d.DEEP_WQ.depth(iu), d.DEEP_WQ.PAR(iu), FigsOn);
    
    tmp = d.DEEP_WQ.sea_water_temperature(iu);
    Tempavg(nt) = mean(tmp(~isnan(tmp)));
    tmp = d.DEEP_WQ.sea_water_temperature(iu);
    Tempmax(nt) = mean(tmp(~isnan(tmp)));
    tmp = d.DEEP_WQ.sea_water_temperature(iu);
    Tempmin(nt) = mean(tmp(~isnan(tmp)));
    tmp = d.DEEP_WQ.sea_water_salinity(iu);
    Salavg(nt) = mean(tmp(~isnan(tmp)));
    tmp = d.DEEP_WQ.sea_water_salinity(iu);
    Salmax(nt) = mean(tmp(~isnan(tmp)));
    tmp = d.DEEP_WQ.sea_water_salinity(iu);
    Salmin(nt) = mean(tmp(~isnan(tmp)));
    tmp = d.DEEP_WQ.Chlorophyll(iu);
    CHLAavg(nt) = mean(tmp(~isnan(tmp)));
    tmp = d.DEEP_WQ.Chlorophyll(iu);
    CHLAMax(nt) = mean(tmp(~isnan(tmp)));
    tmp = d.DEEP_WQ.Chlorophyll(iu);
    CHLAMin(nt) = mean(tmp(~isnan(tmp)));
    tmp = d.DEEP_WQ.Corrected_Chlorophyll(iu);
    CHLA_Coravg(nt) = mean(tmp(~isnan(tmp)));
    tmp = d.DEEP_WQ.Corrected_Chlorophyll(iu);
    CHLA_CorMax(nt) = mean(tmp(~isnan(tmp)));
    tmp = d.DEEP_WQ.Corrected_Chlorophyll(iu);
    CHLA_CorMin(nt) = mean(tmp(~isnan(tmp)));
end

% Plot time series of the raw T&S data
figure;
subplot(2,1,1)
    plot(daten,d.DEEP_WQ.sea_water_temperature,'b.'); hold on;
    plot(ut,Tempavg,'rs'); hold on;
    ylabel('Temperature (C)');
    xticks(datetime(1992:2023,1,1)); grid on;
    xtickformat('yyyy');
    title(['Near surface data: Station ' Astn]);
    
subplot(2,1,2); 
    plot(daten,d.DEEP_WQ.sea_water_salinity,'b.'); hold on;
    plot(ut,Salavg,'rs'); hold on;
    ylabel('Practical Salinity');
    xticks(datetime(1992:2023,1,1)); grid on;
    xtickformat('yyyy');
    ylim([23 30]); % Set up y-axis limits

% Explore the relationship between the max measured PAR and the extrpolated 
% surface value assuming that the extinction coeff is uniform
figure;
plot(PARmx,PAR0,'b.'); hold on;
iu = find(ParCorr>0.8);
errorbar(PARmx(iu),PAR0(iu),PAR0(iu)-PAR0lower(iu),PAR0upper(iu)-PAR0(iu),'vertical','r+');
xlabel('PARmx'); ylabel('PAR0');

% Plot time series of the raw PAR, CHLA, and extinction coeff data
figure;
subplot(3,1,1)
    plot(daten,d.DEEP_WQ.PAR,'b.'); hold on; 
    plot(ut,PARmx,'gs'); hold on;  
    plot(ut,PAR0,'rs'); hold on;
    ylabel('PAR (\muEm^{-2}s^{-1})');
    xticks(datetime(1992:2023,1,1)); grid on;
    xtickformat('yyyy');
    title(['Near surface data: Station ' Astn]);
    
subplot(3,1,2)
    plot(daten,d.DEEP_WQ.Corrected_Chlorophyll,'b.'); hold on;
    plot(ut,CHLA_Coravg,'rs'); hold on;
    ylabel('CHLA (corrected) (\mug/l)');
    xticks(datetime(1992:2023,1,1)); grid on;
    xtickformat('yyyy');

subplot(3,1,3)
    plot(ut,beta,'rs'); hold on;
    ylabel('Extinction, \beta (m^{-1})');
    xticks(datetime(1992:2023,1,1)); grid on;
    xtickformat('yyyy');

% Make the monthly averages
res.Temp = ComputeMonthlyAverages(ut, Tempavg);
res.Sal = ComputeMonthlyAverages(ut, Salavg);
res.CHLA = ComputeMonthlyAverages(ut, CHLA_Coravg);
res.PAR0 = ComputeMonthlyAverages(ut, PAR0);
res.PARmx = ComputeMonthlyAverages(ut, PARmx);
res.beta = ComputeMonthlyAverages(ut, beta);

% Save the results fdisor use elsewhere
disp(['Saving: ' 'ARTG_SurfaceData' Astn '.mat']);
save(['ARTG_SurfaceData' Astn '.mat'], 'res', 'Astn', 'Atop', 'Abot');

end