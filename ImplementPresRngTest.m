function d = ImplementPresRngTest(din, loc)
% 
% Apply IOOS QARTOD pressure range test
% 
% Find anomalous pressure out of range
% Set 1 for pass, 4 for fail, and 3 for suspicious
% 
% Called from WriteBuoyDataQAQC.m
% 

if contains(loc, 'sfc', 'IgnoreCase', true)
    ptop = 0; pbot = 5;
elseif contains(loc, 'mid', 'IgnoreCase', true)
    ptop = 5; pbot = 15;
else
    ptop = 15; pbot = 45;
end

d = ones(size(din));  % Set QAQC code to 1

ifail = find(din<ptop | din>pbot | isnan(din));
if ~isempty(ifail)
    d(ifail) = 4;
end

end