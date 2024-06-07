function d = ImplementGapTestQAQC(din, Para)
% 
% Apply IOOS QARTOD gap test on data time
% 
% Find anomalous time seperations
% Set 1 for pass, 4 for fail, and 3 for suspicious
% 
% Called from CheckBuoyDataQAQC.m
% 

TINC = Para.ExpectedTimeIncr;
rngTINC = Para.TolExpectedTimeIncr;

d = ones(size(din));  % Set QAQC code to 1
dt = diff(din);       % Find anomalous time spacing
dt = dt([1 1:end]);   % The first and second are treated the same           

ifail = find(dt<0 | abs(dt)>TINC+rngTINC | isnat(din));
if ~isempty(ifail)
    d(ifail) = 4;
end

end