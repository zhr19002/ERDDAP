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

% Predefined ranges
switch var
    case 'T'
        rng = [-5 30];
    case 'S'
        rng = [5 35];
    case 'DO'
        rng = [0 20];
    case 'P'
        rng = [0 50];
    case 'C'
        rng = [0 50];
    case 'pH'
        rng = [6 10];
    case 'rho'
        rng = [16 25];
    case 'PAR'
        rng = [0 5000];
    otherwise
        rng = [0 150];
end

% Check QAQC thresholds for each month
for MM = 1:12
    isus = (month(dt) == MM) & ...
        (din < QAQC.(dpth).(var){'lower',MM} | ...
         din > QAQC.(dpth).(var){'upper',MM});
    if ~isempty(isus)
        d(isus) = 3;
    end
end

ifail = (din < rng(1)) | (din > rng(2)) | isnan(din);
if ~isempty(ifail)
    d(ifail) = 4;
end

end