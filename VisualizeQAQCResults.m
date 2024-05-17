clc; clear; close all;

% Set up parameters
Ayear = 2023; Nmth = 1:12; Station = 'E1'; buoy = 'ARTG';
loc = 'sfc';
info = 'S'; % ["T", "S", "DO", "pH"]

% Fixed parameters
info_para1 = struct('T','degC', 'S','psu', 'DO','mg/L', 'pH','pH');
info_para2 = struct('T','mnTemp', 'S','mnSal', 'DO','mnDO', 'pH','mnPH');

switch contains(loc,'btm')
    case 0
        ZT = 0; ZB = 3;
    case 1
        ZT = 20; ZB = 30;
end

%%
% Connect to database
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu',...
    'DatabaseName','provLNDB','PortNumber',5432);

% Extract tables from database
dbname = append(buoy, "_pb2_sbe37", loc);
buoy_loc = sqlread(conn, append('"',dbname,'"'));

% Filter buoy data in a specific year
buoy_loc_rf = buoy_loc.TmStamp >= datetime(Ayear,01,01) & ...
              buoy_loc.TmStamp <= datetime(Ayear,12,31); % Change conditions
buoy_loc_Ayear = sortrows(buoy_loc(buoy_loc_rf, :), 'TmStamp');

close(conn);

%%
% Get cruise names from CTDEEP data in a specific year
[~, ~, CruiseNames] = GetCTDEEPDataForComps(Station, num2str(Ayear), Nmth);
% Specify the surface range from CTDEEP CTD data
DepRng = [ZT ZB];
% Get CTDEEP ship survey data
dCTD_Station = GetCTDEEP_CTD_DataForComps(Station, CruiseNames, DepRng);

% Plot CTDEEP ship survey data
for nn = 1:length(dCTD_Station)
    if ~isempty(dCTD_Station{nn})
        break
    end
end

figure; hold on; grid on;
for n = 1:length(dCTD_Station)
    if ~isempty(dCTD_Station{n})
        if n == nn
            plot(dCTD_Station{n}.mnTime,dCTD_Station{n}.(info_para2.(info)), ...
                 'gs','MarkerFaceColor','g','DisplayName',['Ship Survey (' info ')']);
        else
            plot(dCTD_Station{n}.mnTime,dCTD_Station{n}.(info_para2.(info)), ...
                 'gs','MarkerFaceColor','g','HandleVisibility','off');
        end
    end
end

%%
% Get station climatology data
Station_info_clim = GetDEEPWQClimatology(Station, ZT, ZB, info);

% Put the station climatology patch on the graph
t1 = datetime(Ayear, 1:12, 15);
y1 = Station_info_clim.upper;
y2 = Station_info_clim.lower;

% Plot station raw data
plot(t1,Station_info_clim.data(1,:),'.','Color',[0.5,0.5,0.5],'DisplayName',[Station ' (' info ')']);
plot(t1,Station_info_clim.data(2:end,:),'.','Color',[0.5,0.5,0.5],'HandleVisibility','off');

% Plot station stats
plot(t1,Station_info_clim.mninfo,'k-','DisplayName','Mean');
plot(t1,Station_info_clim.bd50,'m-.','DisplayName','Median');
plot(t1,Station_info_clim.bd16,'m--','DisplayName','68% boundary');
plot(t1,Station_info_clim.bd84,'m--','HandleVisibility','off');
pp = patch([t1(1) t1(1:end) t1(end) fliplr(t1(1:end))], ...
           [y2(1) y1 y2(end) fliplr(y2)],'b','DisplayName','95% boundary');
pp.FaceAlpha = 0.2; pp.EdgeAlpha = 0.2;
pp.FaceColor = [0.1 0.9 0.7]; pp.EdgeColor = [0.1 0.9 0.7];

%%
% Buoy data cleaning
para = max(Station_info_clim.bd84 - Station_info_clim.bd16);
buoydata = CleanBuoyData(buoy_loc_Ayear, info, para);

% Plot time series for buoy data in a specific year
plot(buoydata.TmStamp,buoydata.(info_para1.(info)),'b.','DisplayName',[buoy ' (' info ')']);
xticks(datetime(Ayear, 1:12, 1));
xtickformat('MMM/dd');
ylabel([info,' (',info_para1.(info),')']);
title([buoy '\_' loc ' ' num2str(Ayear) ' Climatology at ' Station ' (' info ')']);
legend('Location','eastoutside');

%%
% QAQC Checks
% Read QAQC parameters
QAQC_para = readtable('QAQC_Para.csv', ReadRowNames=true);

QAQC.Thesholds = [QAQC_para.(info)('Min_Value') QAQC_para.(info)('Max_Value')];
QAQC.Delta = [QAQC_para.(info)('Min_Jump') QAQC_para.(info)('Max_Jump')];
QAQC.THRSHLD = [QAQC_para.(info)('SPK_sfc_bot') QAQC_para.(info)('SPK_sfc_top');
                QAQC_para.(info)('SPK_btm_bot') QAQC_para.(info)('SPK_btm_top')];
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

T = buoydata;
T.(avarT) = zeros(size(T.(info_para1.(info))));

T.(avar1) = ImplementThresoldQAQC(T.(info_para1.(info)), T.TmStamp, QAQC);
T.(avarT) = T.(avarT) + 1;

T.(avar2) = ImplementDeltaQAQC(T.(info_para1.(info)), QAQC);
T.(avarT) = T.(avarT) + 1;

T.(avar3) = ImplementGapTestQAQC(T.TmStamp, QAQC);
T.(avarT) = T.(avarT) + 1;

T.(avar4) = ImplementPresIntvTestQAQC(T.depth, QAQC, loc);
T.(avarT) = T.(avarT) + 1;

T.(avar5) = ImplementSpikeTestQAQC(T.(info_para1.(info)), QAQC, loc);
T.(avarT) = T.(avarT) + 1;

% Plot outliers through QAQC checks
iu1 = find(T.(avar1) ~= 1);
plot(T.TmStamp(iu1),T.(info_para1.(info))(iu1),'rd','DisplayName','Threshold test');

iu2 = find(T.(avar2) ~= 1);
plot(T.TmStamp(iu2),T.(info_para1.(info))(iu2),'ro','DisplayName','Jump limit test');

iu3 = find(T.(avar3) ~= 1);
plot(T.TmStamp(iu3),T.(info_para1.(info))(iu3),'rs','DisplayName','Gap test');

iu4 = find(T.(avar4) ~= 1);
plot(T.TmStamp(iu4),T.(info_para1.(info))(iu4),'rp','DisplayName','Pressure range test');

iu5 = find(T.(avar5) ~= 1);
plot(T.TmStamp(iu5),T.(info_para1.(info))(iu5),'r^','DisplayName','Spike test');

%%
% ylim(QAQC.Thesholds); saveas(gcf, [buoy '_' loc ' ' num2str(Ayear) ' Climatology at ' Station ' (' info ').png']);

% Ginput
disp('Click twice to zoom in.');
[xp, yp] = ginput(2); 
ppx = [xp(1) xp(2) xp(2) xp(1) xp(1)];
ppy = [yp(1) yp(1) yp(2) yp(2) yp(1)];
color = [0.6 0.6 0.6];
ppxy = patch(ppx, ppy, color, 'HandleVisibility','off');
ppxy.FaceAlpha = 0.2; ppxy.EdgeAlpha = 0.2;
ppxy.FaceColor = color; ppxy.EdgeColor = color;
xdate = num2ruler(xp, gca().XAxis);
xlim(sort(xdate)); ylim(sort(yp));