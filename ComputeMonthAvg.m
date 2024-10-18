function res = ComputeMonthAvg(dt, d)
% 
% Average by months and return the mean and anomalies
% 
% Called from VisualizeClimMonthAvg.m
% 

res.anom = NaN * ones(length(dt), 1);

for nm = 1:12
    iu = find(month(dt)==nm);

    res.ndays(nm) = length(unique(dt(iu)));
    res.nu(nm) = length(iu);

    d_tmp = d(iu);
    d_tmp = d_tmp(~isnan(d_tmp));
    res.mn(nm) = mean(d_tmp);
    res.sd(nm) = std(d_tmp);
    res.upper(nm) = max(d_tmp);
    res.lower(nm) = min(d_tmp);
    res.bd16(nm) = prctile(d_tmp,16);
    res.bd50(nm) = prctile(d_tmp,50);
    res.bd84(nm) = prctile(d_tmp,84);

    % Compute the deviation from mean and the residual sd
    res.anom(iu) = d(iu) - res.mn(nm);
    d_tmp = res.anom(iu);
    d_tmp = d_tmp(~isnan(d_tmp));
    res.residual_sd(nm) = std(d_tmp);
end

% Replace any nans with noise
noise = std(res.anom(~isnan(res.anom)));
inan = find(isnan(res.anom));
if ~isempty(inan)
    res.anom(inan) = noise*rand(size(inan));
end

NF = 48;    % This should have a 24 month cut off. 
res.fltanom = filter2(ones(NF,1)/NF, res.anom, 'same');

end