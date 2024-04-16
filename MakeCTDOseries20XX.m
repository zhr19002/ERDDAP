% 
% Plot the time sereis for the 2023 ARTG data
% 

% Plot the temperature series
figure;
subplot(2,1,1);
plot(ARTG_sfc_2023.TmStamp,ARTG_sfc_2023.degC,'.');
xticks(datetime(2023, 5:11, 1)); grid on;
xtickformat('MMM/dd');
title('ARTG Surface'); ylabel('Temperature');

subplot(2,1,2);
plot(ARTG_btm1_2023.TmStamp,ARTG_btm1_2023.degC,'r.'); hold on;
plot(ARTG_btm2_2023.TmStamp,ARTG_btm2_2023.degC,'b.'); hold on;
xticks(datetime(2023, 5:11, 1)); grid on;
xtickformat('MMM/dd');
title('ARTG Bottom'); ylabel('Temperature');

% Plot the salinity series


% Plot the dissolved oxygen series

