function d = ImplementThresoldQAQC(din, Para)
% 
% Threshold data or Gross Range Test in QARTOD and missing value test
% Set 1 for pass, 4 for fail and 3 for suspicious
% 
% Called from CheckBuoyDataQAQC.m
% 

d = ones(size(din));  % Set QAQC code to 1

ifail = find(din<Para.Thesholds(1) | din>Para.Thesholds(2) | isnan(din));
if ~isempty(ifail)
    d(ifail) = 4;
end

end