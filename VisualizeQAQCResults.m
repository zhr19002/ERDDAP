% Set up parameters
Ayear = 2023; Nmth = 4:10; Station = 'E1'; buoy = 'ARTG';
info = 'DO'; % ["T", "S", "DO", "pH"]
loc = 'btm1';
% ylim([2 13]); saveas(gcf, [buoy loc ' ' num2str(Ayear) ' Climatology at ' Station ' (' info ').png']);


% Connect to the database
% Extract tables from the database (e.g., "ARTG_btm1", "ARTG_btm2", "ARTG_sfc")
username = 'lisicos';
password = 'vncq489';

conn = postgresql(username,password,'Server','merlin.dms.uconn.edu',...
    'DatabaseName','provLNDB','PortNumber',5432);

% Extract tables from database
dbname = append(buoy, "_pb2_sbe37", loc);
buoy_loc = sqlread(conn, append('"',dbname,'"'));

% Filter 2021 ARTG data
buoy_loc_rf = buoy_loc.TmStamp >= datetime(Ayear,01,01) & ...
              buoy_loc.TmStamp <= datetime(Ayear,12,31); % Change conditions

buoy_loc_Ayear = sortrows(buoy_loc(buoy_loc_rf, :), 'TmStamp');

close(conn);

%%
info_para = struct('T','degC', 'S','psu', 'DO','mg/L', 'pH','pH');

% Plot the time sereis for a specific year buoy data
figure;
plot(buoy_loc_Ayear.TmStamp, buoy_loc_Ayear.(info_para.(info)), 'b.');
hold on; grid on;
xticks(datetime(Ayear, 1:12, 1)); grid on;
xtickformat('MMM/dd');
ylabel([info,' (',info_para.(info),')']);
title([buoy loc ' ' num2str(Ayear) ' Climatology at ' Station ' (' info ')']);

%%
switch contains(loc,'btm')
    case 0
        ZT = 0; ZB = 3;
    case 1
        ZT = 20; ZB = 30;
end

% Get the CTDEEP data for the 2021 cruises
[~, ~, CruiseNames] = GetCTDEEPDataForComps(Station, num2str(Ayear), Nmth);
% Specify the surface range of the data from the DEEP CTDs that need to be used
SrfDepRng = [ZT ZB];
% Specify the Layer above the max dep to average the bottom values
BdepLayer = 3;

dCTD_Station = GetCTDEEP_CTD_DataForComps(Station, CruiseNames, SrfDepRng, BdepLayer);

% Plot the CTDEEP data
for nn = 1:length(dCTD_Station)
    if ~isempty(dCTD_Station{nn})
        plot(dCTD_Station{nn}.SmnTime,dCTD_Station{nn}.SmnTemp,'gs','MarkerFaceColor','g');
    end
end

%%
%------------------------ Get the E1 climatology ------------------------%
Station_info_clim = GetDEEPWQClimatology(Station, ZT, ZB, info);

% Put the climatology patch on the CHL graph
t1 = datetime(Ayear, 1:12, 15);
y1 = Station_info_clim.upper;
y2 = Station_info_clim.lower;

plot(t1, Station_info_clim.mninfo, 'k^-'); hold on;
pp = patch([t1(1) t1(1:end) t1(end) fliplr(t1(1:end))], ...
           [y2(1) y1 y2(end) fliplr(y2)], 'b');
pp.FaceAlpha = 0.2; pp.EdgeAlpha = 0.2;
pp.FaceColor = [0.1 0.9 0.7]; pp.EdgeColor = [0.1 0.9 0.7];

plot(t1, Station_info_clim.bd16, 'm--');
plot(t1, Station_info_clim.bd50, 'm--');
plot(t1, Station_info_clim.bd84, 'm--');

%%
%------------------------------ QAQC Checks ------------------------------%
% QAQC parameters
din = buoy_loc.(info_para.(info));
dd = abs(diff(din)); dd = dd([1 1:end]);
SPK_REF = (din(1:end-2) + din(3:end))/2;
SPK_REF = SPK_REF([1 1:end end]);
SPK = abs(din-SPK_REF);

QAQC.Thesholds = [prctile(din,0.5) prctile(din,99.5)];
QAQC.Delta = [prctile(dd,99) prctile(dd,99.5)];
QAQC.THRSHLD = [prctile(SPK,99) prctile(SPK,99.5);
                prctile(SPK,99) prctile(SPK,99.5)];
QAQC.ExpectedTimeIncr = 0.25/24;     % Expected data sample period (days)
QAQC.TolExpectedTimeIncr = 0.25/48;  % Tolerance in sample period  (days)
QAQC.PresIntvTest = [0 3; 20 30];    % Expected pressure range (dBar) for surface and bottom

% QAQC tests
avar1 = [info 'QAQCT1'];
avar2 = [info 'QAQCT2'];
avar3 = [info 'QAQCT3'];
avar4 = [info 'QAQCT4'];
avar5 = [info 'QAQCT5'];
avarT = [info 'QAQCTC'];

T = buoy_loc_Ayear;
T.(avarT) = zeros(size(T.(info_para.(info))));

T.(avar1) = ImplementThresoldQAQC(T.(info_para.(info)), T.TmStamp, QAQC);
T.(avarT) = T.(avarT) + 1;

T.(avar2) = ImplementDeltaQAQC(T.(info_para.(info)), QAQC);
T.(avarT) = T.(avarT) + 1;

T.(avar3) = ImplementGapTestQAQC(T.TmStamp, QAQC);
T.(avarT) = T.(avarT) + 1;

T.(avar4) = ImplementPresIntvTestQAQC(T.depth, QAQC, loc);
T.(avarT) = T.(avarT) + 1;

T.(avar5) = ImplementSpikeTestQAQC(T.(info_para.(info)), QAQC, loc);
T.(avarT) = T.(avarT) + 1;

% Plot outliers through QAQC checks
iu1 = find(T.(avar1) ~= 1);
plot(T.TmStamp(iu1), T.(info_para.(info))(iu1), 'rd');

iu2 = find(T.(avar2) ~= 1);
plot(T.TmStamp(iu2), T.(info_para.(info))(iu2), 'ro');

iu3 = find(T.(avar3) ~= 1);
plot(T.TmStamp(iu3), T.(info_para.(info))(iu3), 'rs');

iu4 = find(T.(avar4) ~= 1);
plot(T.TmStamp(iu4), T.(info_para.(info))(iu4), 'gd');

iu5 = find(T.(avar5) ~= 1);
plot(T.TmStamp(iu5), T.(info_para.(info))(iu5), 'go');