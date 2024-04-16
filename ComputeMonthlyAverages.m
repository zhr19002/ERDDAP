function res = ComputeMonthlyAverages(daten, d)
% 
% Average by month and return the mean and anomalies
% 
% Called from GetDEEPStationSurfaceData.m
% 

[~,mnth,~] = datevec(daten);
res.anom = NaN*ones(length(daten),1);

for nm = 1:12
    iu = find(mnth==nm);
    res.ndays(nm) = length(unique(daten(iu)));
    res.nu(nm) = length(iu);
    tmp = d(iu);
    res.mn(nm) = mean(tmp(~isnan(tmp)));
    res.sd(nm) = std(tmp(~isnan(tmp)));
    res.upper(nm) = mean(max(d(iu)));
    res.lower(nm) = mean(min(d(iu)));
    res.bd26(nm) = prctile(d(iu),26);
    res.bd50(nm) = prctile(d(iu),50);
    res.bd84(nm) = prctile(d(iu),84);
    % Compute the deviation from mean and the residual sddev
    res.anom(iu) = d(iu)-res.mn(nm);
    tmp = d(iu)-res.mn(nm);
    res.residual_sd(nm) = std(tmp(~isnan(tmp)));
end

% Replace any nans with noise
noise = std(res.anom(~isnan(res.anom)));
inan = find(isnan(res.anom));

% Nint = 2;
% if ~isempty(inan)
%     for nn = 1:length(inan)
%         iu = [max([inan(nn)-Nint 1]):inan(nn)-1 ...
%               inan(nn)+1 min([inan(nn)+Nint length(res.anom)])];
%         repval = mean(res.anom(iu)) + noise*rand(1);
%         res.anom(inan(nn)) = repval;
%     end
% end

res.anom(inan) = noise*rand(size(inan));

NF = 48;    % This should have a 24 month cut off. 
res.fltanom = filter2(ones(NF,1)/NF, res.anom, 'same');

end