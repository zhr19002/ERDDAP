function d = ImplementPresRngTest(din, QAQC, loc)
% 
% Apply IOOS QARTOD gap test on data level
% 
% Find anomalous pressure out of range
% Set 1 for pass, 4 for fail, and 3 for suspicious
% 
% Called from CheckBuoyDataQAQC.m
% 

if contains(loc,'fc')
    ptop = QAQC.PresRng(1,1);
    pbot = QAQC.PresRng(1,2);
elseif contains(loc,'id')
    ptop = QAQC.PresRng(2,1);
    pbot = QAQC.PresRng(2,2);
else
    ptop = QAQC.PresRng(3,1);
    pbot = QAQC.PresRng(3,2);
end

d = ones(size(din));  % Set QAQC code to 1

ifail = find(din<ptop | din>pbot | isnan(din));
if ~isempty(ifail)
    d(ifail) = 4;
end

end