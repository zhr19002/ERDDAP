function d = ImplementPresIntvTestQAQC(din, Para, ainst)
% 
% Apply IOOS QARTOD gap test on data level
% 
% Find anomalous pressure out of range
% Set 1 for pass, 4 for fail and 3 for suspious
% 
% Called from CheckBuoyDataQAQC.m
% 

if contains(ainst, 'btm')
    ptop = Para.PresIntvTest(2,1);
    pbot = Para.PresIntvTest(2,2);
else
    ptop = Para.PresIntvTest(1,1);
    pbot = Para.PresIntvTest(1,2);
end

d = ones(size(din));                  % Set QAQC code to 1
ifail = find(din<ptop | din>pbot);    % Find anomalous time spacing

if ~isempty(ifail)
    d(ifail) = 4;
end

end