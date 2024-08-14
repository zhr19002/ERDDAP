function d = ImplementThresholdTest(din, dt, QAQC, dpth, var)
% 
% Threshold data or Gross Range Test in QARTOD and missing value test
% Set 1 for pass, 4 for fail, and 3 for suspicious
% 
% Called from CheckBuoyDataQAQC.m
% Called from WriteStationDataQAQC.m
% 

d = ones(size(din));  % Set QAQC code to 1

% Check QAQC thresholds for each month
for MM = 1:12
    isus = find(month(dt)==MM & ...
        (din<QAQC.(dpth).(var){'bd_1',MM} | din>QAQC.(dpth).(var){'bd_99',MM}));
    if ~isempty(isus)
        d(isus) = 3;
    end

    ifail = find(month(dt)==MM & ...
        (din<QAQC.(dpth).(var){'min_val',MM} | din>QAQC.(dpth).(var){'max_val',MM} | isnan(din)));
    if ~isempty(ifail)
        d(ifail) = 4;
    end
end

end