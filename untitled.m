clc; clear;

% Set up parameters
Astn = 'E1';
buoy = 'ARTG'; Ayear = 2024;
av1 = 'T'; av2 = 'S'; av3 = 'P'; % {'T','S','DO','P','C','pH','rho','DOsat'}

% Plot time series for buoy data in a specific year
d = load([buoy '_QAQC.mat']);
d = d.BuoyQAQC;

figure; tiledlayout(3,1);

for loc = {'btm1','btm2','sfc'}
    nexttile
    d_tmp1 = d.(loc{1}).(av1).data;
    d_tmp2 = d.(loc{1}).(av2).data;
    d_tmp3 = d.(loc{1}).(av3).data;
    iu = find(year(d.(loc{1}).time)==Ayear);
    
    plot(d.(loc{1}).time(iu),d_tmp1(iu),'r.','DisplayName',[' (' av1 ')']);
    hold on; grid on;
    plot(d.(loc{1}).time(iu),d_tmp2(iu),'g.','DisplayName',[' (' av2 ')']);
    plot(d.(loc{1}).time(iu),d_tmp3(iu),'b.','DisplayName',[' (' av3 ')']);
    xticks(datetime(Ayear,1:12,1));
    xtickformat('MMM/dd');
    title([buoy '\_' loc{1} ' ' num2str(Ayear)]);
end

ax = nexttile(1);
lgd = legend(ax,'Orientation','horizontal');
lgd.Layout.Tile = 'south';