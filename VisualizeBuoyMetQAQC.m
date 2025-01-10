% 
% Plot the time series of buoy meteorology data
% Highlight the marked outliers
% 

clc; clear;

% Set up parameters
Ayear = 2024;
buoy = 'WLIS';
% {'windSpd_Kts','windSpd_Max','fiveSecAvg_Max','windDir_M',
%  'airTemp_Avg','relHumid_Avg','baroPress_Avg','dewPT_Avg'}
av = 'windSpd_Kts';

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','buoyQAQC','PortNumber',5432);
dT = sqlread(conn, ['"' buoy '_Met_QAQC"']);
dT = dT(year(dT.TmStamp)==Ayear, :);
close(conn);

figure('position',[321,180,623,420]); hold on; grid on;

% Plot the time series of buoy data in Ayear
plot(dT.TmStamp,dT.(av),'b.','DisplayName',[buoy ' (' av ')']);

% Highlight the outliers
iu1 = find(floor(dT.([av '_Q'])/1000)~=1);
plot(dT.TmStamp(iu1),dT.(av)(iu1),'rs','DisplayName','1-Threshold');
iu2 = find(mod(floor(dT.([av '_Q'])/100),10)~=1);
plot(dT.TmStamp(iu2),dT.(av)(iu2),'ro','DisplayName','2-JumpLim');
iu3 = find(mod(floor(dT.([av '_Q'])/10),10)~=1);
plot(dT.TmStamp(iu3),dT.(av)(iu3),'gd','DisplayName','3-Gap');
iu4 = find(mod(dT.([av '_Q']),10)~=1);
plot(dT.TmStamp(iu4),dT.(av)(iu4),'r^','DisplayName','4-Spike');

xticks(datetime(Ayear,1:12,1));
xtickformat('MMM/dd');
ylabel(av);
legend('Location','eastoutside');