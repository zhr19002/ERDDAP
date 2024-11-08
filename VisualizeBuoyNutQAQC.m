% 
% Plot the time series of buoy nutrient data
% Highlight the marked outliers
% 

clc; clear;

% Set up parameters
Ayear = 2021;
buoy = 'ARTG';
var = 'FL'; % {'PAR','FL','NTU'}
Astn = 'C1';
% Ayear = 2019; buoy = 'CLIS'; var = 'NO3'; Astn = 'C1';

% Fixed parameters
colb = struct('PAR','PAR_Raw','FL','chl_ugL','NTU','turbidity_NTU','NO3','NNO3');
cols = struct('PAR','PAR_data','FL','Corrected_Chl_data','NTU','TSS','NO3','NOX-LC');

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connb = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','buoyQAQC','PortNumber',5432);
conns = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','stationQAQC','PortNumber',5432);

% Extract tables
dTb = sqlread(connb, strcat('"',[buoy '_' var '_QAQC'],'"'));
dTb = dTb(year(dTb.TmStamp)==Ayear, :);
if ismember(var, {'PAR','FL'})
    dTs = sqlread(conns, strcat('"',['DEEP_' Astn '_WQ_QAQC'],'"'));
    dTs = dTs((dTs.depth>=0 & dTs.depth<=3), :);
    stnD = dTs.(cols.(var));
else
    dTs = sqlread(conns, strcat('"',['DEEP_' Astn '_Nutrient_QAQC'],'"'));
    dTs = dTs((dTs.Depth_Code=='S' & dTs.Parameter==cols.(var)), :);
    stnD = dTs.Result;
end
close(connb);
close(conns);

figure('position',[321,180,623,420]); hold on; grid on;

% Plot the time series of buoy data in Ayear
vlabel = strrep(colb.(var),'_','\_');
plot(dTb.TmStamp,dTb.(colb.(var)),'b.','DisplayName',[buoy ' (' vlabel ')']);

% Highlight the outliers
iu1 = find(floor(dTb.([colb.(var) '_Q'])/1000)~=1);
plot(dTb.TmStamp(iu1),dTb.(colb.(var))(iu1),'rs','DisplayName','1-Threshold');
iu2 = find(mod(floor(dTb.([colb.(var) '_Q'])/100),10)~=1);
plot(dTb.TmStamp(iu2),dTb.(colb.(var))(iu2),'ro','DisplayName','2-JumpLim');
iu3 = find(mod(floor(dTb.([colb.(var) '_Q'])/10),10)~=1);
plot(dTb.TmStamp(iu3),dTb.(colb.(var))(iu3),'gd','DisplayName','3-Gap');
iu4 = find(mod(dTb.([colb.(var) '_Q']),10)~=1);
plot(dTb.TmStamp(iu4),dTb.(colb.(var))(iu4),'r^','DisplayName','4-Spike');

xticks(datetime(Ayear,1:12,1));
xtickformat('MMM/dd');
ylabel(vlabel);
title([buoy ' ' num2str(Ayear) ' Data at ' Astn ' (' vlabel ')']);
legend('Location','eastoutside');

%%
% Compare with the cruise nutrient data
iu = find(year(dTs.time)==Ayear);
plot(dTs.time(iu), stnD(iu), ...
     'gs','MarkerFaceColor','g','DisplayName',['Cruises (' vlabel ')']);

% Compare with the station nutrient data
plot(datetime(Ayear,month(dTs.time),15), stnD, ...
     '.','Color',[0.5,0.5,0.5],'DisplayName',[Astn ' (' vlabel ')']);

% Get station nutrient statistics
bdmean = zeros(1,12); bd50 = zeros(1,12); 
bd68L = zeros(1,12); bd68U = zeros(1,12);
bd95L = zeros(1,12); bd95U = zeros(1,12);
for nm = 1:12
    idx = find(month(dTs.time)==nm);
    if ~isempty(idx)
        tmp = stnD(idx);
        bdmean(nm) = mean(tmp(~isnan(tmp))); bd50(nm) = prctile(tmp,50);
        bd68L(nm) = prctile(tmp,16); bd68U(nm) = prctile(tmp,84);
        bd95L(nm) = prctile(tmp,2.5); bd95U(nm) = prctile(tmp,97.5);
    end
end

% Put station nutrient statistics patch on the graph
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