% Plot the time sereis for the 2021 ARTG data
% (temperature, salinity, dissolved oxygen)

% Plot the temperature series
figure;
subplot(3,1,1);
plot(ARTG_sfc_2021.TmStamp,ARTG_sfc_2021.degC,'b.');
xticks(datetime(2021, 4:11, 1)); grid on;
xtickformat('MMM/dd');
title('ARTG Surface'); ylabel('Temperature');

subplot(3,1,2);
plot(ARTG_btm1_2021.TmStamp,ARTG_btm1_2021.degC,'r.');
xticks(datetime(2021, 4:11, 1)); grid on;
xtickformat('MMM/dd');
title('ARTG Bottom 1'); ylabel('Temperature');

subplot(3,1,3);
plot(ARTG_btm2_2021.TmStamp,ARTG_btm2_2021.degC,'r.');
xticks(datetime(2021, 4:11, 1)); grid on;
xtickformat('MMM/dd');
title('ARTG Bottom 2'); ylabel('Temperature');

% Plot the salinity series
figure;
subplot(3,1,1);
plot(ARTG_sfc_2021.TmStamp,ARTG_sfc_2021.psu,'b.');
xticks(datetime(2021, 4:11, 1)); grid on;
xtickformat('MMM/dd');
title('ARTG Surface'); ylabel('Salinity');

subplot(3,1,2);
plot(ARTG_btm1_2021.TmStamp,ARTG_btm1_2021.psu,'r.');
xticks(datetime(2021, 4:11, 1)); grid on;
xtickformat('MMM/dd');
title('ARTG Bottom 1'); ylabel('Salinity');

subplot(3,1,3);
plot(ARTG_btm2_2021.TmStamp,ARTG_btm2_2021.psu,'r.');
xticks(datetime(2021, 4:11, 1)); grid on;
xtickformat('MMM/dd');
title('ARTG Bottom 2'); ylabel('Salinity');

% Plot the dissolved oxygen series
figure;
subplot(3,1,1);
plot(ARTG_sfc_2021.TmStamp,ARTG_sfc_2021.("mg/L"),'b.');
xticks(datetime(2021, 4:11, 1)); grid on;
xtickformat('MMM/dd');
title('ARTG Surface'); ylabel('DO');

subplot(3,1,2);
plot(ARTG_btm1_2021.TmStamp,ARTG_btm1_2021.("mg/L"),'r.');
xticks(datetime(2021, 4:11, 1)); grid on;
xtickformat('MMM/dd');
title('ARTG Bottom 1'); ylabel('DO');

subplot(3,1,3);
plot(ARTG_btm2_2021.TmStamp,ARTG_btm2_2021.("mg/L"),'r.');
xticks(datetime(2021, 4:11, 1)); grid on;
xtickformat('MMM/dd');
title('ARTG Bottom 2'); ylabel('DO');