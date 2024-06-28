% 
% Calls GetCruiseNames.m
% Calls GetCTDEEP_CTD_Stats.m
% Calls GetDEEPWQClimStats.m
% 

clc; clear;
% Set up parameters
Astn = 'E1';
buoy = 'ARTG'; loc = 'sfc'; Ayear = 2022;
av = 'T'; % {'T','S','DO','P','C','pH','rho','DOsat'}

% Fixed parameters
av_stn = struct('T','mnTemp','S','mnSal','DO','mnDO','P','mnPres', ...
                'C','mnCond','pH','mnPH','rho','mnRho','DOsat','mnDOsat');
switch loc
    case 'sfc'
        ZT = 0; ZB = 3;
    case 'mid'
        ZT = 5; ZB = 15;
    case {'btm','btm1','btm2'}
        ZT = 20; ZB = 30;
end

% Plot time series for buoy data in a specific year
d = load([buoy '_QAQC.mat']);
d = d.BuoyQAQC;
iu = find(year(d.(loc).time)==Ayear);
d_tmp = d.(loc).(av).data;
c_tmp = d.(loc).(av).QAQCTests;

figure; hold on; grid on;

plot(d.(loc).time(iu),d_tmp(iu),'b.','DisplayName',[buoy ' (' av ')']);
xticks(datetime(Ayear,1:12,1));
xtickformat('MMM/dd');
ylabel(av);
title([buoy '\_' loc ' ' num2str(Ayear) ' Climatology at ' Astn ' (' av ')']);
legend('Location','eastoutside');

% Plot outliers through QAQC checks
iu1 = find(year(d.(loc).time)==Ayear & floor(c_tmp/10000)~=1);
plot(d.(loc).time(iu1),d_tmp(iu1),'rd','DisplayName','Threshold test');
iu2 = find(year(d.(loc).time)==Ayear & mod(floor(c_tmp/1000),10)~=1);
plot(d.(loc).time(iu2),d_tmp(iu2),'ro','DisplayName','Jump limit test');
iu3 = find(year(d.(loc).time)==Ayear & mod(floor(c_tmp/100),10)~=1);
plot(d.(loc).time(iu3),d_tmp(iu3),'rs','DisplayName','Gap test');
iu4 = find(year(d.(loc).time)==Ayear & mod(floor(c_tmp/10),10)~=1);
plot(d.(loc).time(iu4),d_tmp(iu4),'rp','DisplayName','Pressure range test');
iu5 = find(year(d.(loc).time)==Ayear & mod(c_tmp,10)~=1);
plot(d.(loc).time(iu5),d_tmp(iu5),'r^','DisplayName','Spike test');

%%
% Get cruise names for 12 months in a specific year
CruiseNames = cell(12,1);
for nn = 1:12
    if nn < 10
        Amonth = sprintf('0%i', nn);
    else
        Amonth = sprintf('%i', nn);
    end
    [~, CruiseNames{nn}] = GetCruiseNames(Ayear, Amonth);
end
% Get ship survey data in a depth range for all cruises at a station
dCTD = GetCTDEEP_CTD_Stats(Astn,CruiseNames,ZT,ZB);

% Plot CTDEEP ship survey data
for nn = 1:length(dCTD)
    if ~isempty(dCTD{nn})
        break
    end
end

for n = 1:length(dCTD)
    if ~isempty(dCTD{n})
        if n == nn
            plot(dCTD{n}.mnTime,dCTD{n}.(av_stn.(av)),'gs','MarkerFaceColor','g', ...
                 'DisplayName',['Ship Survey (' av ')']);
        else
            plot(dCTD{n}.mnTime,dCTD{n}.(av_stn.(av)),'gs','MarkerFaceColor','g', ...
                 'HandleVisibility','off');
        end
    end
end

%%
% Get station climatology data
stats = GetDEEPWQClimStats(Astn,ZT,ZB,av);

% Put the station climatology patch on the graph
t = datetime(Ayear,1:12,15);
y1 = stats.bd2_5;
y2 = stats.bd97_5;

% Plot station raw data
plot(t,stats.data(1,:),'.','Color',[0.5,0.5,0.5],'DisplayName',[Astn ' (' av ')']);
plot(t,stats.data(2:end,:),'.','Color',[0.5,0.5,0.5],'HandleVisibility','off');

% Plot station stats
plot(t,stats.mean,'k-','DisplayName','Mean');
plot(t,stats.bd50,'m-.','DisplayName','Median');
plot(t,stats.bd16,'m--','DisplayName','68% boundary');
plot(t,stats.bd84,'m--','HandleVisibility','off');
pp = patch([t(1) t t(end) fliplr(t(1:end))], ...
           [y1(1) y1 y1(end) fliplr(y2)],'b','DisplayName','95% boundary');
pp.FaceAlpha = 0.2; pp.EdgeAlpha = 0.2;
pp.FaceColor = [0.1 0.9 0.7]; pp.EdgeColor = [0.1 0.9 0.7];

%%
% QAQC_para = readtable('QAQC_Para.csv', ReadRowNames=true);
% QAQC.Thesholds = [QAQC_para.(av)('Min_Value') QAQC_para.(av)('Max_Value')];
% ylim(QAQC.Thesholds);
% saveas(gcf, [buoy '_' loc ' ' num2str(Ayear) ' Climatology at ' Astn ' (' av ').png']);

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