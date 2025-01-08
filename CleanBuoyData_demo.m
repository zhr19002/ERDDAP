% 
% Plot time series of T, S, P for buoy data in a specific year
% 

clc; clear;

% Set up parameters
buoy = 'ARTG'; loc = 'sfc'; Ayear = 2024;

figure; tiledlayout(2,1);
for i = 1:2
    nexttile
    
    % Load dataset
    d = load([buoy '_QAQC_' num2str(i-1) '.mat']);
    d = d.BuoyQAQC;
    d_T = d.(loc).T.data;
    d_S = d.(loc).S.data;
    d_P = d.(loc).P.data;
    
    iu = find(year(d.(loc).time)==Ayear);
    plot(d.(loc).time(iu),d_T(iu),'r.','DisplayName','T (degC)');
    hold on; grid on;
    plot(d.(loc).time(iu),d_S(iu),'g.','DisplayName','S (psu)');
    plot(d.(loc).time(iu),d_P(iu),'b.','DisplayName','P (dBars)');
    
    xticks(datetime(Ayear,1:12,1));
    xtickformat('MMM/dd');
    if i == 1
        title(['Original ' num2str(Ayear) ' time series at ' buoy '\_' loc]);
    else
        title(['Cleaned ' num2str(Ayear) ' time series at ' buoy '\_' loc]);
    end
end

ax = nexttile(1);
lgd = legend(ax,'Orientation','horizontal');
lgd.Layout.Tile = 'south';

% saveas(gcf, [num2str(Ayear) '_' buoy '_' loc '.png']);