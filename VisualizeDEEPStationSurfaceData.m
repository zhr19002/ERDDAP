% Calls GetDEEPStationSurfaceData.m
Astn = 'E1';
[ut, res] = GetDEEPStationSurfaceData(Astn);
%%
% Plot the mean monthly variation
figure;
subplot(5,1,1)
    plot(datetime(0,1:12,15),res.Temp.mn); hold on;
    plot(datetime(0,1:12,15),res.Temp.mn+res.Temp.sd,'r-');
    plot(datetime(0,1:12,15),res.Temp.mn-res.Temp.sd,'r-');
    xticks(datetime(0,1:12,1)); grid on;
    xtickformat('MMM'); ylabel('Temp (C)');
    title(['CTDEEP Station ' Astn ' Surface Climatology']);

subplot(5,1,2)
    plot(datetime(0,1:12,15),res.Sal.mn); hold on;
    plot(datetime(0,1:12,15),res.Sal.mn-res.Sal.sd,'r-');
    plot(datetime(0,1:12,15),res.Sal.mn+res.Sal.sd,'r-');
    xticks(datetime(0,1:12,1)); grid on;
    xtickformat('MMM'); ylabel('Sal');

subplot(5,1,3)
    plot(datetime(0,1:12,15),res.CHLA.mn); hold on;
    plot(datetime(0,1:12,15),res.CHLA.bd84,'r-'); 
    plot(datetime(0,1:12,15),res.CHLA.bd26,'r-'); 
    xticks(datetime(0,1:12,1)); grid on;
    xtickformat('MMM'); ylabel('CHLA (\mug/l)');

subplot(5,1,4)
    plot(datetime(0,1:12,15),res.beta.mn); hold on;
    plot(datetime(0,1:12,15),res.beta.bd84,'r-');
    plot(datetime(0,1:12,15),res.beta.bd26,'r-');
    xticks(datetime(0,1:12,1)); grid on;
    xtickformat('MMM'); ylabel('\beta (m^{-1})');
   
subplot(5,1,5)
    plot(datetime(0,1:12,15),res.PAR0.mn); hold on;
    plot(datetime(0,1:12,15),res.PAR0.bd84,'r-');
    plot(datetime(0,1:12,15),res.PAR0.bd26,'r-');
    xticks(datetime(0,1:12,1)); grid on;
    xtickformat('MMM'); ylabel('PAR (\muEm^{-2}s^{-1})');
%%
% Plot the residual series to examine interannual variability and the low pass filtered values
figure;
subplot(2,1,1)
    plot(ut,res.Temp.anom,'b.'); hold on;
    ylabel('Temp Anomaly (C)');
    plot(ut,res.Temp.fltanom,'r-','linewidth',2);
    xticks(datetime(1992:2023,1,1)); grid on;
    xtickformat('yyyy');
    title(['Near surface data: Station ' Astn]);

subplot(2,1,2); 
    plot(ut,res.Sal.anom,'b.'); hold on;
    ylabel('Sal Anomaly');
    plot(ut,res.Sal.fltanom,'r-','linewidth',2);
    xticks(datetime(1992:2023,1,1)); grid on;
    xtickformat('yyyy');
%%
figure;
subplot(3,1,1); 
    plot(ut,res.PARmx.anom,'b.'); hold on;
    plot(ut,res.PAR0.anom,'rs');
    ylabel('PAR anomaly (\muEm^{-2}s^{-1})');
    plot(ut,res.PARmx.fltanom,'b-','linewidth',2);
    plot(ut,res.PAR0.fltanom,'r-','linewidth',2);
    xticks(datetime(1992:2023,1,1)); grid on;
    xtickformat('yyyy');
    title(['Near surface data: Station ' Astn]);

subplot(3,1,2); 
    plot(ut,res.CHLA.anom,'b.'); hold on;
    plot(ut,res.CHLA.fltanom,'b-','linewidth',2); hold on;
    ylabel('CHLA (corrected) (\mug/l)');
    xticks(datetime(1992:2023,1,1)); grid on;
    xtickformat('yyyy');

subplot(3,1,3);
    plot(ut,res.beta.anom,'rs'); hold on;
    ylabel('Extinction, \beta (m^{-1})');
    plot(ut,res.beta.fltanom,'b-','linewidth',2);
    xticks(datetime(1992:2023,1,1)); grid on;
    xtickformat('yyyy'); 
%%
% Plot the filtered anomalies on the same graph scaled by the sd
% These aren't very enlightening at E1
figure;
plot(ut,res.Temp.fltanom./std(res.Temp.fltanom(~isnan(res.Temp.fltanom))),...
     'b-','DisplayName','Temp'); hold on;
plot(ut,res.Sal.fltanom./std(res.Sal.fltanom(~isnan(res.Sal.fltanom))),...
     'r-','DisplayName','Sal'); hold on;
plot(ut,res.CHLA.fltanom./std(res.CHLA.fltanom(~isnan(res.CHLA.fltanom))),...
     'g-','DisplayName','CHLA'); hold on;
plot(ut,res.beta.fltanom./std(res.beta.fltanom(~isnan(res.beta.fltanom))),...
     'c-','DisplayName','\beta'); hold on;
plot(ut,res.PAR0.fltanom./std(res.PAR0.fltanom(~isnan(res.PAR0.fltanom))),...
     'm-','DisplayName','PAR'); hold on;
legend('Location','southeast');
title(['Filtered anomalies at Station ' Astn]);
%%
figure;
subplot(3,2,1)
    plot(res.CHLA.fltanom./std(res.CHLA.fltanom(~isnan(res.CHLA.fltanom))), ...
         res.beta.fltanom./std(res.beta.fltanom(~isnan(res.beta.fltanom))), '.');
    xlabel('CHLA'); ylabel('\beta');

subplot(3,2,2)
    plot(res.PAR0.fltanom./std(res.PAR0.fltanom(~isnan(res.PAR0.fltanom))), ...
         res.CHLA.fltanom./std(res.CHLA.fltanom(~isnan(res.CHLA.fltanom))), '.');
    xlabel('PAR0'); ylabel('CHLA');

subplot(3,2,3)
    plot(res.Temp.fltanom./std(res.Temp.fltanom(~isnan(res.Temp.fltanom))), ...
         res.CHLA.fltanom./std(res.CHLA.fltanom(~isnan(res.CHLA.fltanom))), '.');
    xlabel('Temp'); ylabel('CHLA');

subplot(3,2,4)
    plot(res.Sal.fltanom./std(res.Sal.fltanom(~isnan(res.Sal.fltanom))), ...
         res.CHLA.fltanom./std(res.CHLA.fltanom(~isnan(res.CHLA.fltanom))), '.');
    xlabel('Sal'); ylabel('CHLA');

subplot(3,2,5)
    plot(res.Sal.fltanom./std(res.CHLA.fltanom(~isnan(res.CHLA.fltanom))), ...
         res.Temp.fltanom./std(res.beta.fltanom(~isnan(res.beta.fltanom))), '.');
    xlabel('Sal'); ylabel('Temp');