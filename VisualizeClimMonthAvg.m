% 
% Calls EstimateBeta.m
% Calls ComputeMonthAvg.m
% 

clc; clear;

Astn = 'E1'; dpth = 'depth_0_5'; FigOn = 0;

d = load(['CTDEEP_' Astn '_QAQC.mat']);
d = d.StationQAQC.(dpth);
dt = unique(d.time);

% Compute statistics of selected variables
for av = {'T','S','Chl','Chl2'}
    dd.([av{1} '_avg']) = zeros(length(dt),1);
    for i = 1:length(dt)
        iu = find(d.time == dt(i));
        d_tmp = d.(av{1}).data(iu);
        d_tmp = d_tmp(~isnan(d_tmp));
        dd.([av{1} '_avg'])(i) = mean(d_tmp);
    end
    % Compute monthly averages
    res.(av{1}) = ComputeMonthAvg(dt, dd.([av{1} '_avg']));
end

% Estimate beta
beta = zeros(length(dt),1);
PAR0 = zeros(length(dt),1);
PARmx = zeros(length(dt),1);
for i = 1:length(dt)
    iu = find(d.time == dt(i));
    [beta(i), PAR0(i)] = EstimateBeta(d.depth(iu), d.PAR.data(iu), FigOn);
    PARmx(i) = max(d.PAR.data(iu));
end
% Compute monthly averages
res.beta = ComputeMonthAvg(dt, beta);
res.PAR0 = ComputeMonthAvg(dt, PAR0);
res.PARmx = ComputeMonthAvg(dt, PARmx);

%%
% Plot the mean monthly variation
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
% Plot the residual series to examine interannual variability and the low pass filtered values
figure;
subplot(2,1,1); hold on; grid on;
plot(dt, res.T.anom, 'b.');
ylabel('T Anomaly (degC)');
plot(dt, res.T.fltanom, 'r-', 'linewidth',2);
xticks(datetime(1992:2023,1,1));
xtickformat('yyyy');

subplot(2,1,2); hold on; grid on;
plot(dt, res.S.anom, 'b.');
ylabel('S Anomaly (psu)');
plot(dt, res.S.fltanom, 'r-', 'linewidth',2);
xticks(datetime(1992:2023,1,1));
xtickformat('yyyy');

%%
figure;
subplot(3,1,1); hold on; grid on;
plot(dt, res.PARmx.anom, 'b.');
plot(dt, res.PAR0.anom, 'rs');
ylabel('PAR anomaly (\muEm^{-2}s^{-1})');
plot(dt, res.PARmx.fltanom, 'b-', 'linewidth',2);
plot(dt, res.PAR0.fltanom, 'r-', 'linewidth',2);
xticks(datetime(1992:2023,1,1));
xtickformat('yyyy');

subplot(3,1,2); hold on; grid on;
plot(dt, res.Chl.anom, 'b.');
plot(dt, res.Chl.fltanom, 'b-', 'linewidth',2);
ylabel('Chl (\mug/l)');
xticks(datetime(1992:2023,1,1));
xtickformat('yyyy');

subplot(3,1,3); hold on; grid on;
plot(dt, res.beta.anom, 'rs');
ylabel('Extinction, \beta (m^{-1})');
plot(dt, res.beta.fltanom, 'b-', 'linewidth',2);
xticks(datetime(1992:2023,1,1));
xtickformat('yyyy');

%%
% Plot the filtered anomalies on the same graph scaled by the sd
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