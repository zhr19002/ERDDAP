% This script reads and plot the data from ARTG in 2021.
% It also get the CTD profile data and the CTDEEP data and plot it as well.
% 
% Calls:
%   "artg_oct2021_recovery.mat"
%   ImplementQAQC.m
%   GetUCONNDataForComps.m
%   GetCTDEEPDataForComps.m
%   GetDEEPWQClimatology.m
%   MakeBuoyMetaData.m
%   OutputARTG2022_pH_NCFILE.m
% 

% SUNA QAQC parameters
% Select SPIKE thresholds for the surface
% Specify what DEEP data CTDEEP data from ERDDAP
Ast = 'E1'; Ayear = '2021'; Nmth = 4:10;
% Specify the surface range of the data from the DEEP CTDs that need to be used
SrfDepRng = [0 3];
% Specify the Layer above the max dep to average the bottom values
BdepLayer = 3;
% Specify the time range to plot and label
nyear = sscanf(Ayear,'%f');
Trng = [datetime(nyear, [4 11], 1)];
Tticks = [datetime(nyear, 4:11, 1)];

% Load file
load('artg_oct2021_recovery.mat');
% These are the table names
Nmflu = fieldnames(artg_fl);
Nmtur = fieldnames(artg_ntu);
Nmpar = fieldnames(artg_par);
NmNOX = fieldnames(artg_suna);
Nmbtm1 = fieldnames(artgbtm1_21);
Nmbtm2 = fieldnames(artgbtm2_21);
Nmsrfr = fieldnames(artgsfc_21);
Nmmet = fieldnames(met2021);
NmPh = fieldnames(hcpH);

% Get the ship samples but suppress data plot
NoFig = 0;
% Get data from CESE spreadsheet
dUC = GetUCONNDataForComps('ARTG', NoFig);

% Which should be mg/l
[dsE1, dbE1, CruiseNamesE1] = GetCTDEEPDataForComps('E1', Ayear, Nmth);

% Process the pH from ARTG
figure;
subplot(4,1,1)
    plot(datetime(hcpH.DateTimeUTC0500), hcpH.PressureDecibar, 'b+');
    hold on; grid on;
    ylabel('Depth');
subplot(4,1,2)
    hcpH.pHpH(1:6) = NaN;
    plot(datetime(hcpH.DateTimeUTC0500), hcpH.pHpH, 'b+');
    hold on; grid on;
    ylabel('pH');
subplot(4,1,3)
    plot(datetime(hcpH.DateTimeUTC0500), hcpH.Salinitypsu, 'b+');
    hold on; grid on;
    ylabel('Salinity');
subplot(4,1,4)
    plot(datetime(hcpH.DateTimeUTC0500), hcpH.TemperatureCelsius, 'b+');
    hold on; grid on;
    ylabel('Temperature');
%%
% Get the CTDEEP data for the 2021 cruises
dCTD_E1 = GetCTDEEP_CTD_DataForComps('E1', CruiseNamesE1, SrfDepRng, BdepLayer);

% Plot the CTDEEP data
for nn = 1:length(dCTD_E1)
    if ~isempty(dCTD_E1{nn})
        subplot(4,1,1)
            plot(dCTD_E1{nn}.BmnTime,dCTD_E1{nn}.BmnDepth,'gs','MarkerFaceColor','g');
            hold on; grid on;
            ylabel('Depth');
        subplot(4,1,2)
            plot(dCTD_E1{nn}.BmnTime,dCTD_E1{nn}.BmnPH,'gs','MarkerFaceColor','g');
            hold on; grid on;
            ylabel('pH');
        subplot(4,1,3)
            plot(dCTD_E1{nn}.BmnTime,dCTD_E1{nn}.BmnSal,'gs','MarkerFaceColor','g');
            hold on; grid on;
            ylabel('Salinity');
        subplot(4,1,4)
            plot(dCTD_E1{nn}.BmnTime,dCTD_E1{nn}.BmnTemp,'gs','MarkerFaceColor','g');
            hold on; grid on;
            ylabel('Temperature');
    end
end
%%
% --------------Get the E1 climatology---------------------------
E1_pH_clim = GetDEEPWQClimatology('E1','20','30');

% Put the climatology patch on the CHL graph
t1 = datetime(nyear, 1:12, 15);
y1 = E1_pH_clim.upper; y2 = E1_pH_clim.lower;

figure;
plot(datetime(hcpH.DateTimeUTC0500), hcpH.pHpH, 'r.'); hold on;
plot(t1, E1_pH_clim.mnpH, 'k^-'); hold on;
pp = patch([t1(1) t1(1:end) t1(end) fliplr(t1(1:end))], ...
           [y2(1) y1 y2(end) fliplr(y2)], 'b');
pp.FaceAlpha = 0.2; pp.EdgeAlpha = 0.2;
pp.FaceColor = [0.1 0.9 0.7]; pp.EdgeColor = [0.1 0.9 0.7];
ylim([7 9]);

plot(t1, E1_pH_clim.bd26, 'r--'); hold on;
plot(t1, E1_pH_clim.bd84, 'r--'); hold on;
plot(t1, E1_pH_clim.bd50, 'r--'); hold on;
ylabel('pH'); grid on;
title('ARTG 2021 pH and Climatology at E1 (from CTDEEP)');

% Put 2021 data on plot
plot(datetime(hcpH.DateTimeUTC0500),hcpH.pHpH,'b+'); hold on;
for nn = 1:length(dCTD_E1)
    if ~isempty(dCTD_E1{nn})
        plot(dCTD_E1{nn}.BmnTime,dCTD_E1{nn}.BmnPH,'gs','MarkerFaceColor','g');
    end
end

%%
%------------------------- Write NETCDF----------------------------------%
Anotes = 'The estimates of pH are from a SeaBird HydrocatL pH sensor.';

% smthpH = filter2(ones(2*Filterlength,1)/(2*Filterlength), hcpH.pHpH, 'same');
% hcpH.smthpH = smthpH;
% 
% rng = [12 length(smthpH)-15];
% 
% subplot(4,1,2)
% plot(datetime(hcpH.DateTimeUTC0500(rng)),smthpH(rng),'r-','linewidth',2); hold on;

% figure; hist(abs(diff(hcpH.pHpH)),100);
% set(gca,'YSCale','log'); hold on;

% Seabird HydrocatL QAQC options
QAQC.Thesholds = [6.5 8.5];         % Only data (micro g/l) in this range are acceptable
QAQC.Delta = [0.075 0.1];           % Only time changes smaller than this are allowed
QAQC.THRSHLD = [0.06 0.1; 0.06 0.1];
QAQC.ExpectedTimeIncr = 0.25/24;    % Expected data sample period (days)
QAQC.TolExpectedTimeIncr = 0.25/48; % Tolerance in sample period  (days)
QAQC.PresIntvTest = [0 3; 20 30];   % Expected pressure range (dBar) for surface and bottom

hcpH.EST = datetime(hcpH.DateTimeUTC0500);       % The QAQC routine expect these fields
hcpH.TIMESTAMP = datetime(hcpH.DateTimeUTC0500); % The QAQC routine expect these fields
hcpH.prdM = hcpH.PressureDecibar;

dout = ImplementSpikeTestQAQC(hcpH.pHpH, QAQC, 'btm'); % Run a simple Spike QAQC test
hcpH.pHpHQAQC = dout;

meta = MakeBuoyMetaData('hcpH', Anotes, 1);
dd = OutputARTG2021_pH_NCFILE('ARTG_Bottom_pH.nc', hcpH, meta, []);