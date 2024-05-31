% 
% Calls GetCTDEEPDataForComps.m
% Calls GetCTDEEP_CTD_DataForComps.m
% Calls GetDEEPWQClimStats.m
% Calls CleanBuoyData.m
% Calls CheckBuoyDataQAQC.m
% 

clc; clear;
% Set up parameters
Ayear = 2021; buoy = 'ARTG'; loc = 'sfc';
avar = 'T'; % {'T','S','DO','P','C','pH','rho','DOsat'}

% Fixed parameters
avar_buoy = struct('T','degC','S','psu','DO','mg/L','P','dBars','C','S/m', ...
                   'pH','none','rho','kg/m^3','DOsat','percent');
avar_station = struct('T','mnTemp','S','mnSal','DO','mnDO','P','mnPres', ...
                      'C','mnCond','pH','mnPH','rho','mnRho','DOsat','mnDOsat');
buoy_station = struct('ARTG','E1','CLIS','C1','EXRX','A4');

switch contains(loc,'btm')
    case 0
        ZT = 0; ZB = 3;
    case 1
        ZT = 20; ZB = 30;
end

%%
% Read buoy database for a specific year
% 
% Connect to database
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','provLNDB','PortNumber',5432);

% tbldata = sqlfind(conn,"")

% Extract tables from database
dbname = append(buoy,"_pb2_sbe37",loc);
buoy_loc = sqlread(conn,append('"',dbname,'"'));

% Filter buoy data in a specific year
buoy_loc_rf = buoy_loc.TmStamp >= datetime(Ayear,01,01) & ...
              buoy_loc.TmStamp <= datetime(Ayear,12,31);
buoy_loc = sortrows(buoy_loc(buoy_loc_rf,:),'TmStamp');

% Calculate rho and DOsat
buoy_loc.('kg/m^3') = sw_dens(buoy_loc.('psu'),buoy_loc.('degC'),buoy_loc.('dBars'))-1000;
sat = sw_satO2(buoy_loc.('psu'),buoy_loc.('degC'))*1.33; % Converted to mg/L
buoy_loc.('percent') = 100*buoy_loc.('mg/L')./sat;

close(conn);

%%
% Get cruise names from CTDEEP data in a specific year
[~,~,CruiseNames] = GetCTDEEPDataForComps(buoy_station.(buoy),Ayear,1:12);
% Get CTDEEP ship survey data
dCTD_Station = GetCTDEEP_CTD_DataForComps(buoy_station.(buoy),CruiseNames,ZT,ZB);

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
            plot(dCTD_Station{n}.mnTime,dCTD_Station{n}.(avar_station.(avar)), ...
                 'gs','MarkerFaceColor','g','DisplayName',['Ship Survey (' avar ')']);
        else
            plot(dCTD_Station{n}.mnTime,dCTD_Station{n}.(avar_station.(avar)), ...
                 'gs','MarkerFaceColor','g','HandleVisibility','off');
        end
    end
end

%%
% Get station climatology data
clim_stats = GetDEEPWQClimStats(buoy_station.(buoy),ZT,ZB,avar);

% Put the station climatology patch on the graph
t = datetime(Ayear,1:12,15);
y1 = clim_stats.bd95lower;
y2 = clim_stats.bd95upper;

% Plot station raw data
plot(t,clim_stats.data(1,:),'.','Color',[0.5,0.5,0.5], ...
     'DisplayName',[buoy_station.(buoy) ' (' avar ')']);
plot(t,clim_stats.data(2:end,:),'.','Color',[0.5,0.5,0.5], ...
     'HandleVisibility','off');

% Plot station stats
plot(t,clim_stats.mninfo,'k-','DisplayName','Mean');
plot(t,clim_stats.bd50,'m-.','DisplayName','Median');
plot(t,clim_stats.bd16,'m--','DisplayName','68% boundary');
plot(t,clim_stats.bd84,'m--','HandleVisibility','off');
pp = patch([t(1) t t(end) fliplr(t(1:end))], ...
           [y1(1) y1 y1(end) fliplr(y2)],'b','DisplayName','95% boundary');
pp.FaceAlpha = 0.2; pp.EdgeAlpha = 0.2;
pp.FaceColor = [0.1 0.9 0.7]; pp.EdgeColor = [0.1 0.9 0.7];

%%
% Buoy data cleaning
para = mean(clim_stats.bd84 - clim_stats.bd16);
buoydata = CleanBuoyData(buoy_loc,avar,para);

% Plot time series for buoy data in a specific year
plot(buoydata.TmStamp,buoydata.(avar_buoy.(avar)),'b.', ...
     'DisplayName',[buoy ' (' avar ')']);
xticks(datetime(Ayear,1:12,1));
xtickformat('MMM/dd');
ylabel([avar,' (',avar_buoy.(avar),')']);
title([buoy '\_' loc ' ' num2str(Ayear) ' Climatology at ' ...
       buoy_station.(buoy) ' (' avar ')']);
legend('Location','eastoutside');

%%
% QAQC checks
[QAQC,buoydataQAQC] = CheckBuoyDataQAQC(buoydata,loc,avar,avar_buoy);

% Plot outliers through QAQC checks
iu1 = find(floor(buoydataQAQC.QAQCTests/10000) ~= 1);
plot(buoydataQAQC.TmStamp(iu1),buoydataQAQC.(avar_buoy.(avar))(iu1), ...
     'rd','DisplayName','Threshold test');
iu2 = find(mod(floor(buoydataQAQC.QAQCTests/1000),10) ~= 1);
plot(buoydataQAQC.TmStamp(iu2),buoydataQAQC.(avar_buoy.(avar))(iu2), ...
     'ro','DisplayName','Jump limit test');
iu3 = find(mod(floor(buoydataQAQC.QAQCTests/100),10) ~= 1);
plot(buoydataQAQC.TmStamp(iu3),buoydataQAQC.(avar_buoy.(avar))(iu3), ...
     'rs','DisplayName','Gap test');
iu4 = find(mod(floor(buoydataQAQC.QAQCTests/10),10) ~= 1);
plot(buoydataQAQC.TmStamp(iu4),buoydataQAQC.(avar_buoy.(avar))(iu4), ...
     'rp','DisplayName','Pressure range test');
iu5 = find(mod(buoydataQAQC.QAQCTests,10) ~= 1);
plot(buoydataQAQC.TmStamp(iu5),buoydataQAQC.(avar_buoy.(avar))(iu5), ...
     'r^','DisplayName','Spike test');

%%
% ylim(QAQC.Thesholds); 
% saveas(gcf, [buoy '_' loc ' ' num2str(Ayear) ' Climatology at ' buoy_station.(buoy) ' (' avar ').png']);

% % Ginput
% disp('Click twice to zoom in.');
% [xp, yp] = ginput(2); 
% ppx = [xp(1) xp(2) xp(2) xp(1) xp(1)];
% ppy = [yp(1) yp(1) yp(2) yp(2) yp(1)];
% color = [0.6 0.6 0.6];
% ppxy = patch(ppx, ppy, color, 'HandleVisibility','off');
% ppxy.FaceAlpha = 0.2; ppxy.EdgeAlpha = 0.2;
% ppxy.FaceColor = color; ppxy.EdgeColor = color;
% xdate = num2ruler(xp, gca().XAxis);
% xlim(sort(xdate)); ylim(sort(yp));