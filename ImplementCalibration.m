function d = ImplementCalibration(din, dt, buoy, tvar)
% 
% Calibrate nutrient data based on UConn samples
% 
% Called from WriteNutDataQAQC.m
% 

d = din;

switch tvar
    case 'NTU'
        file = 'Buoy_TSS.csv';
        opts = detectImportOptions(file);
        opts = setvaropts(opts,'TmStamp','InputFormat','MM/dd/uuuu HH:mm');
        T = readtable(file, opts);
        T = T(startsWith(T.Field, buoy), :);
        T = T(:,{'TmStamp','smc_mgL'});
        T.Properties.VariableNames = {'time','Result'};
    case 'NO3'
        % file = 'Buoy_NOX.csv';
        % opts = detectImportOptions(file);
        % opts = setvaropts(opts,3:4,'InputFormat','MM/dd/uuuu');
        % T = readtable(file, opts);
        % T = T(startsWith(T.FIELD, buoy), :);
        % T = T(:,{'Collected','NOX'});
        % T.Properties.VariableNames = {'time','Result'};

        username = 'lisicos';
        password = 'vncq489';
        connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
            'DatabaseName','stationQAQC','PortNumber',5432);
        T = sqlread(connQ, '"DEEP_I2_Nutrient_QAQC"');
        close(connQ);
        T = T(T.time>=dateshift(min(dt),'start','month') & ...
              T.time<=dateshift(max(dt),'end','month') & ...
              T.Parameter=="NOX-LC", {'time','Result'});

        % 3-hour window average on raw data
        dT0 = table(dt, din, 'VariableNames',{'time','var'});
        dT0 = sortrows(dT0, 'time');
        window = round(3/mean(hours(diff(dT0.time))));
        dT0.mvAvg = movmean(dT0.var, window, 'omitnan');
        
        % Downsampling raw data
        T.Sample = zeros(height(T),1);
        for i = 1:height(T)
            iu = find(dT0.time>=T.time(i) & dT0.time<T.time(i)+days(2));
            T.Sample(i) = mean(dT0.mvAvg(iu));
        end
        
        % Linear fit
        p = polyfit(T.Sample, T.Result, 1);
        d = polyval(p, din);
end

end