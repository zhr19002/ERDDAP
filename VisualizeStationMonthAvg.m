% 
% Calls EstimateBetaPAR.m
% Calls ComputeStationMonthAvg.m
% 

clc; clear;

Astn = 'E1'; dpth = 'depth_0_5';

d = load(['CTDEEP_' Astn '_QAQC.mat']);
d = d.StationQAQC.(dpth);
dt = unique(d.time);

% Compute averages of selected variables
for av = {'T','S','Chl','Chl2'}
    dd.([av{1} '_avg']) = zeros(length(dt),1);
    for i = 1:length(dt)
        iu = find(d.time == dt(i));
        d_tmp = d.(av{1}).data(iu);
        d_tmp = d_tmp(~isnan(d_tmp));
        dd.([av{1} '_avg'])(i) = mean(d_tmp);
    end
    % Compute monthly averages
    res.(av{1}) = ComputeStationMonthAvg(dt, dd.([av{1} '_avg']));
end

% Estimate beta and calculate PAR values
beta = zeros(length(dt),1);
PAR0 = zeros(length(dt),1);
PARmx = zeros(length(dt),1);
for i = 1:length(dt)
    iu = find(d.time == dt(i));
    [beta(i), PAR0(i)] = EstimateBetaPAR(d.depth(iu), d.PAR.data(iu), 0);
    PARmx(i) = max(d.PAR.data(iu));
end
% Compute monthly averages
res.beta = ComputeStationMonthAvg(dt, beta);
res.PAR0 = ComputeStationMonthAvg(dt, PAR0);
res.PARmx = ComputeStationMonthAvg(dt, PARmx);

%%
% Plot mean monthly variation
figure;
subplot(5,1,1); hold on; grid on;
plot(datetime(0,1:12,15), res.T.mn);
plot(datetime(0,1:12,15), res.T.mn+res.T.sd, 'r-');
plot(datetime(0,1:12,15), res.T.mn-res.T.sd, 'r-');
xticks(datetime(0,1:12,1));
xtickformat('MMM'); ylabel('T (degC)');

subplot(5,1,2); hold on; grid on;
plot(datetime(0,1:12,15), res.S.mn);
plot(datetime(0,1:12,15), res.S.mn-res.S.sd, 'r-');
plot(datetime(0,1:12,15), res.S.mn+res.S.sd, 'r-');
xticks(datetime(0,1:12,1));
xtickformat('MMM'); ylabel('S (psu)');

subplot(5,1,3); hold on; grid on;
plot(datetime(0,1:12,15), res.Chl.mn);
plot(datetime(0,1:12,15), res.Chl.bd84, 'r-'); 
plot(datetime(0,1:12,15), res.Chl.bd16, 'r-'); 
xticks(datetime(0,1:12,1));
xtickformat('MMM'); ylabel('Chl (\mug/l)');

subplot(5,1,4); hold on; grid on;
plot(datetime(0,1:12,15), res.beta.mn);
plot(datetime(0,1:12,15), res.beta.bd84, 'r-');
plot(datetime(0,1:12,15), res.beta.bd16, 'r-');
xticks(datetime(0,1:12,1));
xtickformat('MMM'); ylabel('\beta (m^{-1})');
   
subplot(5,1,5); hold on; grid on;
plot(datetime(0,1:12,15), res.PAR0.mn);
plot(datetime(0,1:12,15), res.PAR0.bd84, 'r-');
plot(datetime(0,1:12,15), res.PAR0.bd16, 'r-');
xticks(datetime(0,1:12,1));
xtickformat('MMM'); ylabel('PAR (\muEm^{-2}s^{-1})');

%%
% Plot residual series to examine interannual variability
figure;
subplot(5,1,1); hold on; grid on;
plot(dt, res.T.anom, 'b.');
plot(dt, res.T.fltanom, 'r-', 'linewidth',2);
ylabel('T Anomaly (degC)');
xticks(datetime(1992:2023,1,1));
xtickformat('yyyy');

subplot(5,1,2); hold on; grid on;
plot(dt, res.S.anom, 'b.');
plot(dt, res.S.fltanom, 'r-', 'linewidth',2);
ylabel('S Anomaly (psu)');
xticks(datetime(1992:2023,1,1));
xtickformat('yyyy');

subplot(5,1,3); hold on; grid on;
plot(dt, res.Chl.anom, 'b.');
plot(dt, res.Chl.fltanom, 'r-', 'linewidth',2);
ylabel('Chl (\mug/l)');
xticks(datetime(1992:2023,1,1));
xtickformat('yyyy');

subplot(5,1,4); hold on; grid on;
plot(dt, res.beta.anom, 'b.');
plot(dt, res.beta.fltanom, 'r-', 'linewidth',2);
ylabel('Extinction, \beta (m^{-1})');
xticks(datetime(1992:2023,1,1));
xtickformat('yyyy');

subplot(5,1,5); hold on; grid on;
plot(dt, res.PARmx.anom, 'b.');
plot(dt, res.PAR0.anom, 'ro');
plot(dt, res.PARmx.fltanom, 'b-', 'linewidth',2);
plot(dt, res.PAR0.fltanom, 'r-', 'linewidth',2);
ylabel('PAR anomaly (\muEm^{-2}s^{-1})');
xticks(datetime(1992:2023,1,1));
xtickformat('yyyy');

%%
% Plot filtered anomalies scaled by standard deviation
vars = {'T','S','Chl','beta','PAR0'};
colors = {'b-','r-','g-','c-','m-'};

figure; hold on; grid on;
for i = 1:length(vars)
    d_tmp = res.(vars{i}).fltanom;
    d_tmp = d_tmp(~isnan(d_tmp));
    plot(dt, d_tmp./std(d_tmp), colors{i}, 'DisplayName',vars{i});
end
legend('Location','southeast');
title(['Filtered anomalies at Station ' Astn]);