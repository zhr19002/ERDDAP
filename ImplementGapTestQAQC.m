function d = ImplementGapTestQAQC(din, Para)
% 
% Apply IOOS QARTOD gap test on data time
% 
% Find anomalous time seperations
% Set 1 for pass, 4 for fail and 3 for suspious
% 
% Called from MakeDataArchive.m
% 

TINC = Para.ExpectedTimeIncr;
rngTINC = Para.TolExpectedTimeIncr;

d = ones(size(din));  % Set QAQC code to 1
dt = diff(din);       % Find anomalous time spacing
dt = dt([1 1:end]);   % Assume first point is the same as the second to keep arrays even
adt = abs(dt);             

ifail = find(dt<0 | adt>TINC+rngTINC);

if ~isempty(ifail)
    d(ifail) = 4;
end

end