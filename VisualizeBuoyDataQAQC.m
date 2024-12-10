% 
% Plot the time series of buoy climatology data
% Highlight the marked outliers
% 

clc; clear;

% Set up parameters
Ayear = 2021;
av = 'T'; % {'T','S','DO','P','C','pH','rho','DOsat'}
buoy = 'ARTG'; loc = 'sfc'; 
Astn = 'E1'; dpL = 0; dpU = 3;

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connb = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','buoyQAQC','PortNumber',5432);
conns = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','stationQAQC','PortNumber',5432);

% Extract tables
dTb = sqlread(connb, strcat('"',[buoy '_' loc '_QAQC'],'"'));
dTb = dTb(year(dTb.TmStamp)==Ayear, :);
dTs = sqlread(conns, strcat('"',['DEEP_' Astn '_WQ_QAQC'],'"'));
dTs = dTs((dTs.depth>=dpL & dTs.depth<=dpU), :);
close(connb);
close(conns);

figure('position',[321,180,623,420]); hold on; grid on;

% Plot the time series of buoy data in Ayear
plot(dTb.TmStamp,dTb.([av '_data']),'b.','DisplayName',[buoy ' (' av ')']);

% Highlight the outliers
iu1 = find(floor(dTb.([av '_Q'])/10000)~=1);
plot(dTb.TmStamp(iu1),dTb.([av '_data'])(iu1),'rs','DisplayName','1-Threshold');
iu2 = find(mod(floor(dTb.([av '_Q'])/1000),10)~=1);
plot(dTb.TmStamp(iu2),dTb.([av '_data'])(iu2),'ro','DisplayName','2-JumpLim');
iu3 = find(mod(floor(dTb.([av '_Q'])/100),10)~=1);
plot(dTb.TmStamp(iu3),dTb.([av '_data'])(iu3),'gd','DisplayName','3-Gap');
iu4 = find(mod(floor(dTb.([av '_Q'])/10),10)~=1);
plot(dTb.TmStamp(iu4),dTb.([av '_data'])(iu4),'gp','DisplayName','4-PresRng');
iu5 = find(mod(dTb.([av '_Q']),10)~=1);
plot(dTb.TmStamp(iu5),dTb.([av '_data'])(iu5),'r^','DisplayName','5-Spike');

xticks(datetime(Ayear,1:12,1));
xtickformat('MMM/dd');
ylabel(av);
title([buoy '\_' loc ' ' num2str(Ayear) ' Data at ' Astn ' (' av ')']);
legend('Location','eastoutside');

%%
% Compare with the cruise climatology data
iu = find(year(dTs.time)==Ayear);
plot(dTs.time(iu), dTs.([av '_data'])(iu), ...
     'gs','MarkerFaceColor','g','DisplayName',['Cruises (' av ')']);

% Compare with the station climatology data
plot(datetime(Ayear,month(dTs.time),15), dTs.([av '_data']), ...
     '.','Color',[0.5,0.5,0.5],'DisplayName',[Astn ' (' av ')']);

% Get station climatology statistics
bdmean = zeros(1,12); bd50 = zeros(1,12); 
bd68L = zeros(1,12); bd68U = zeros(1,12);
bd95L = zeros(1,12); bd95U = zeros(1,12);
for nm = 1:12
    idx = find(month(dTs.time)==nm);
    if ~isempty(idx)
        tmp = dTs.([av '_data'])(idx);
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