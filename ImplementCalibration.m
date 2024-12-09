% function d = ImplementCalibration(dT, buoy, var)
% 
% Calibrate nutrient data based on UConn samples
% 
% Called from WriteNutDataQAQC.m
% 

clc; clear;

username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);
dT = sqlread(connQ, '"CLIS_NO3_QAQC"');
dT = dT(:, {'TmStamp','NNO3'}); buoy = 'CLIS'; var = 'NO3';

d = dT{:, 2};

switch var
    case 'NTU'
        file = 'Buoy_TSS.csv';
        opts = detectImportOptions(file);
        opts = setvaropts(opts,'TmStamp','InputFormat','MM/dd/uuuu HH:mm');
        T = readtable(file, opts);
        T = T(startsWith(T.Field, buoy), :);
        T = T(:,{'TmStamp','smc_mgL'});
        T.Properties.VariableNames = {'time','result'};
    case 'NO3'
        file = 'Buoy_NOX.csv';
        opts = detectImportOptions(file);
        opts = setvaropts(opts,3:4,'InputFormat','MM/dd/uuuu');
        T = readtable(file, opts);
        T = T(startsWith(T.FIELD, buoy), :);
        T = T(:,{'Collected','NOX'});
        T.Properties.VariableNames = {'time','result'};
end

% Calibrate 2019 data
T0 = T(year(T.time)==2019, :);
dT0 = dT(year(dT.TmStamp)==2019, :);

% 3-hour window average on raw data
dT0 = sortrows(dT0,'TmStamp');
window = round(3/mean(hours(diff(dT0.TmStamp))));
dT0.avgVar = movmean(dT0{:,2}, window, 'omitnan');

% Downsampling raw data
samples = zeros(height(T0),1);
for i = 1:height(T0)
    iu = dT0.TmStamp>=T0.time(i) & dT0.TmStamp<T0.time(i)+days(1);
    samples(i) = mean(dT0.avgVar(iu));
end

% Linear fit
p = polyfit(samples, T0.result, 1);
startDate = datetime(2019, min(month(T0.time)), 1);
endDate = datetime(2019, max(month(T0.time))+1, 1);
iz = find(dT.TmStamp>=startDate & dT.TmStamp<endDate);
d(iz) = polyval(p, d(iz));

% end


figure; hold on; grid on;
plot(dT.TmStamp, dT.NNO3, 'b.');
plot(dT0.TmStamp, dT0.avgVar, 'r-');
plot(dT.TmStamp, d, 'm*');
plot(T0.time, T0.result, 'gs', 'MarkerFaceColor', 'g');