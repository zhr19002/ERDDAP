% 
% Plot the long-term time series of buoy nutrients
% Highlight suspicious data points
% 

clc; clear;

% Set up parameters
buoy = 'ARTG';
tvars = {'PAR','FL','NTU'};
avars = {'Adjusted_PAR','Adjusted_CHLA','Adjusted_TSS'};
vnames = {'PAR','CHLA','TSS'};
units = {'uE/S/m2','ug/L','mg/L'};

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','buoyQAQC','PortNumber',5432);

% Plot long-term time series with highlighted suspicious data points
figure;
for i = 1:length(tvars)
    % Extract tables
    dT = sqlread(conn, ['"' buoy '_' tvars{i} '_QAQC"']);
    dT = dT(dT.TmStamp < datetime(2025,1,1), :);
    
    % Plot long-term time series
    subplot(length(tvars),1,i); hold on; grid on;
    iu1 = find(floor(dT.([avars{i} '_Q'])/1000)~=4);
    plot(dT.TmStamp(iu1),dT.(avars{i})(iu1),'b.');
    iu2 = find(floor(dT.([avars{i} '_Q'])/1000)==3);
    plot(dT.TmStamp(iu2),dT.(avars{i})(iu2),'gs');
    xtickformat('yyyy-MM');
    ylabel([vnames{i} ' (' units{i} ')']);
end

close(conn);