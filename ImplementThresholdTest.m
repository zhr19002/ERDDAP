function d = ImplementThresholdTest(din, dt, QAQC, dpth, var)
% 
% Threshold data or Gross Range Test in QARTOD and missing value test
% Set 1 for pass, 4 for fail, and 3 for suspicious
% 
% Called from CheckBuoyDataQAQC.m
% Called from CheckNutDataQAQC.m
% Called from WriteStationDataQAQC.m
% Called from WriteCruiseDataQAQC.m
% Called from WriteStationNutQAQC.m
% 

d = ones(size(din));  % Set QAQC code to 1

% Check if the "dpth" field exists
if ischar(dpth)
    QAQC = QAQC.(dpth);
end

% Check QAQC thresholds for each month
for MM = 1:12
    isus = find(month(dt)==MM & ...
        (din<QAQC.(var){'bd1',MM} | din>QAQC.(var){'bd99',MM}));
    if ~isempty(isus)
        d(isus) = 3;
    end

    ifail = find(month(dt)==MM & ...
        (din<QAQC.(var){'lower',MM} | din>QAQC.(var){'upper',MM} | isnan(din)));
    if ~isempty(ifail)
        d(ifail) = 4;
    end
end

end