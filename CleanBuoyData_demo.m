% 
% Plot time series of T, S, P for buoy data in a specific year
% 

clc; clear;

% Set up parameters
buoy = 'ARTG'; Ayear = 2022;

d = load(['Buoy_' buoy '_QAQC.mat']);
d = d.BuoyQAQC;

figure; tiledlayout(3,1);
for loc = {'btm1','btm2','sfc'}
    nexttile
    d_T = d.(loc{1}).T.data;
    d_S = d.(loc{1}).S.data;
    d_P = d.(loc{1}).P.data;

    iu = find(year(d.(loc{1}).time)==Ayear);
    plot(d.(loc{1}).time(iu),d_T(iu),'r.','DisplayName','T (degC)');
    hold on; grid on;
    plot(d.(loc{1}).time(iu),d_S(iu),'g.','DisplayName','S (psu)');
    plot(d.(loc{1}).time(iu),d_P(iu),'b.','DisplayName','P (dBars)');

    xticks(datetime(Ayear,1:12,1));
    xtickformat('MMM/dd');
    title([buoy '\_' loc{1} ' ' num2str(Ayear) ' time series for T, S, P']);
end

ax = nexttile(1);
lgd = legend(ax,'Orientation','horizontal');
lgd.Layout.Tile = 'south';

% saveas(gcf, [buoy '_' num2str(Ayear) '.png']);