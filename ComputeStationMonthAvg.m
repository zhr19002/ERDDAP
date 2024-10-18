function res = ComputeStationMonthAvg(dt, d)
% 
% Calculate station monthly averages and anomalies
% 
% Called from VisualizeStationMonthAvg.m
% 

% Initialize the anomalies
res.anom = NaN * ones(length(dt),1);

for nm = 1:12
    iu = find(month(dt)==nm);
    
    % Count unique days and total data points for the current month
    res.ndays(nm) = length(unique(dt(iu)));
    res.nu(nm) = length(iu);
    
    % Calculate statistics for the current month
    d_tmp = d(iu);
    d_tmp = d_tmp(~isnan(d_tmp));
    res.mn(nm) = mean(d_tmp);
    res.sd(nm) = std(d_tmp);
    res.upper(nm) = max(d_tmp);
    res.lower(nm) = min(d_tmp);
    res.bd16(nm) = prctile(d_tmp,16);
    res.bd50(nm) = prctile(d_tmp,50);
    res.bd84(nm) = prctile(d_tmp,84);
    
    % Calculate the anomalies (deviation from the mean)
    res.anom(iu) = d(iu) - res.mn(nm);

    % Calculate the residual standard deviation of anomalies
    d_tmp = res.anom(iu);
    d_tmp = d_tmp(~isnan(d_tmp));
    res.residual_sd(nm) = std(d_tmp);
end

% Replace any NaN anomalies with random noise based on the standard deviation
noise = std(res.anom(~isnan(res.anom)));
inan = find(isnan(res.anom));
if ~isempty(inan)
    res.anom(inan) = noise*rand(size(inan));
end

% Apply a filter to the anomalies to smooth data
NF = 48; % Filter length, reflect a 24-month cutoff
res.fltanom = filter2(ones(NF,1)/NF, res.anom, 'same');

end