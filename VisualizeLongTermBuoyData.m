% 
% Plot the long-term time series of buoy climatology data
% Highlight suspicious data points
% 

clc; clear;

% Set up parameters
buoy = 'ARTG'; loc = 'sfc';
avars = {'T','S','DO','P','C','rho','DOsat'};
units = {'degC','psu','mg/L','dBars','S/m','kg/m3','percent'};

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','buoyQAQC','PortNumber',5432);
dT = sqlread(conn, ['"' buoy '_' loc '_QAQC"']);
close(conn);

% Plot long-term time series with highlighted suspicious data points
figure;
for i = 1:7
    subplot(7,1,i); hold on; grid on;
    iu1 = find(floor(dT.([avars{i} '_Q'])/10000)~=4);
    plot(dT.TmStamp(iu1),dT.([avars{i} '_data'])(iu1),'b.');
    iu2 = find(floor(dT.([avars{i} '_Q'])/10000)==3);
    plot(dT.TmStamp(iu2),dT.([avars{i} '_data'])(iu2),'gs');
    xtickformat('yyyy-MM');
    ylabel([avars{i} ' (' units{i} ')']);
end

% saveas(gcf, [buoy '_' loc '.png']);