% 
% Plot the time series of station climatology data
% Highlight the marked outliers
% 

clc; clear;

% Set up parameters
Astn = 'E1';
av = 'T'; % {'T','S','DO','P','C','pH','rho','DOsat'}

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','stationQAQC','PortNumber',5432);

% Extract tables
d0 = sqlread(conn, strcat('"',['DEEP_' Astn '_WQ_QAQC'],'"'));
d0.time.Year = 0;
close(conn);

nfigs = floor(max(d0.depth)/5) + 1;
figure; tiledlayout(ceil(nfigs/2), 2);

% Flags to avoid duplicate legends
hasSus = false;
hasFail = false;

for i = 1:nfigs
    nexttile(i)
    hold on; grid on;
    
    d = d0((d0.depth>=5*i-5 & d0.depth<5*i), :);
    d_tmp = d.([av '_data']);
    c_tmp = d.([av '_Q']);
    
    % Plot the time series of station climatology data in all years
    plot(d.time,d_tmp,'b.','HandleVisibility','off');
    
    % Highlight the outliers
    iu1 = find(c_tmp==3);
    if ~isempty(iu1)
        if ~hasSus
            plot(d.time(iu1),d_tmp(iu1),'gs','DisplayName','Suspicious');
            hasSus = true;
        else
            plot(d.time(iu1),d_tmp(iu1),'gs','HandleVisibility','off');
        end
    end
    iu2 = find(c_tmp==4);
    if ~isempty(iu2)
        if ~hasFail
            plot(d.time(iu2),d_tmp(iu2),'rs','DisplayName','Fail');
            hasFail = true;
        else
            plot(d.time(iu2),d_tmp(iu2),'rs','HandleVisibility','off');
        end
    end
    
    xticks(datetime(0,1:12,1));
    xtickformat('MMM/dd');
    ylabel(av);
    title(['CTDEEP ' Astn ' (' num2str(5*i-5) '-' num2str(5*i) 'm)']);
    if i == 1
        legend show;
        lgd = legend('show');
        lgd.Orientation = 'horizontal';
        lgd.Layout.Tile = 'south';
    end
end

% saveas(gcf, [Astn '_QAQC (' av ').png']);