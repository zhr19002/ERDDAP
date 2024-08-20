% 
% Plot the time series of buoy data from "Buoy_buoy_QAQC.mat"
% Highlight the marked outliers
% 

clc; clear;

% Set up parameters
Astn = 'E1';
buoy = 'ARTG'; loc = 'sfc'; Ayear = 2022;
av = 'T'; % {'T','S','DO','P','C','pH','rho','DOsat'}

d = load(['Buoy_' buoy '_QAQC.mat']);
d = d.BuoyQAQC;
iu = find(year(d.(loc).time)==Ayear);
d_tmp = d.(loc).(av).data;
c_tmp = d.(loc).(av).QAQCTests;

figure('position',[321,180,623,420]); hold on; grid on;

% Plot the time series of buoy data in Ayear
plot(d.(loc).time(iu),d_tmp(iu),'b.','DisplayName',[buoy ' (' av ')']);

% Highlight the outliers
iu1 = find(year(d.(loc).time)==Ayear & floor(c_tmp/10000)~=1);
plot(d.(loc).time(iu1),d_tmp(iu1),'rd','DisplayName','1-Threshold');
iu2 = find(year(d.(loc).time)==Ayear & mod(floor(c_tmp/1000),10)~=1);
plot(d.(loc).time(iu2),d_tmp(iu2),'ro','DisplayName','2-JumpLim');
iu3 = find(year(d.(loc).time)==Ayear & mod(floor(c_tmp/100),10)~=1);
plot(d.(loc).time(iu3),d_tmp(iu3),'rs','DisplayName','3-Gap');
iu4 = find(year(d.(loc).time)==Ayear & mod(floor(c_tmp/10),10)~=1);
plot(d.(loc).time(iu4),d_tmp(iu4),'rp','DisplayName','4-PresRng');
iu5 = find(year(d.(loc).time)==Ayear & mod(c_tmp,10)~=1);
plot(d.(loc).time(iu5),d_tmp(iu5),'r^','DisplayName','5-Spike');

xticks(datetime(Ayear,1:12,1));
xtickformat('MMM/dd');
ylabel(av);
title([buoy '\_' loc ' ' num2str(Ayear) ' Data at ' Astn ' (' av ')']);
legend('Location','eastoutside');

%%
% Compare with the cruise climatology data from "Cruises_Ayear_QAQC.mat"
d_crs = load(['Cruises_' num2str(Ayear) '_QAQC.mat']);
d_crs = d_crs.CruiseQAQC;
crs = fieldnames(d_crs);

% Determine the depth range ZT to ZB
ZT = 5*floor((min(d.(loc).depth)-0.1)/5);
ZB = ZT + 5;
dpth = ['depth_' num2str(ZT) '_' num2str(ZB)];

% Flags to avoid duplicate legends
hasFlag = false;

for i = 1:length(crs)
    crsT = d_crs.(crs{i}).(Astn).(dpth).time;
    crsD = d_crs.(crs{i}).(Astn).(dpth).(av).data;
    if ~hasFlag
        plot(crsT,crsD,'gs','MarkerFaceColor','g','DisplayName',['Cruises (' av ')']);
        hasFlag = true;
    else
        plot(crsT,crsD,'gs','MarkerFaceColor','g','HandleVisibility','off');
    end
end

%%
% Compare with the station climatology data from "CTDEEP_Astn_QAQC.mat"
d_stn = load(['CTDEEP_' Astn '_QAQC.mat']);
d_stn = d_stn.StationQAQC;

stnT = datetime(Ayear, month(d_stn.(dpth).time), 15);
stnD = d_stn.(dpth).(av).data;
plot(stnT,stnD,'.','Color',[0.5,0.5,0.5],'DisplayName',[Astn ' (' av ')']);

% Get station climatology statistics
bdmean = zeros(1,12); bd50 = zeros(1,12); 
bd68L = zeros(1,12); bd68U = zeros(1,12);
bd95L = zeros(1,12); bd95U = zeros(1,12);
for nm = 1:12
    idx = find(month(stnT)==nm);
    if ~isempty(idx)
        tmp = stnD(idx);
        bdmean(nm) = mean(tmp(~isnan(tmp))); bd50(nm) = prctile(tmp,50);
        bd68L(nm) = prctile(tmp,16); bd68U(nm) = prctile(tmp,84);
        bd95L(nm) = prctile(tmp,2.5); bd95U(nm) = prctile(tmp,97.5);
    end
end

% Put station climatology statistics patch on the graph
dt = datetime(Ayear, 1:12, 15);
plot(dt, bdmean, 'k-', 'DisplayName', 'Mean');
plot(dt, bd50, 'm-.', 'DisplayName', 'Median');
plot(dt, bd68L, 'm--', 'DisplayName', '68% boundary');
plot(dt, bd68U, 'm--', 'HandleVisibility', 'off');
pp = patch([dt(1) dt dt(end) fliplr(dt)], ...
           [bd95L(1) bd95L bd95L(end) fliplr(bd95U)], ...
           'b','DisplayName','95% boundary');
pp.FaceAlpha = 0.2; pp.EdgeAlpha = 0.2;
pp.FaceColor = [0.1 0.9 0.7]; pp.EdgeColor = [0.1 0.9 0.7];

%%
saveas(gcf, [buoy '_' loc ' ' num2str(Ayear) ' Data at ' Astn ' (' av ').png']);

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