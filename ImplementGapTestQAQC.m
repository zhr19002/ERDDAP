function d = ImplementGapTestQAQC(din, Para)
%
%  Apply IOOS QARTOD gaptest on data time.
% 
%  find anomalous time seperations
%  set 1 for pass, 4 for fail and 3 for suspious
%
%  Called from PlotARTG_2018_20_summary.m
%
TINC = Para.ExpectedTimeIncr;
rngTINC = Para.TolExpectedTimeIncr;

d = ones(size(din));        % set QAQC code to 1
dt = diff(din);             % find anomalous time spacing
dt = dt([1 1:end]);         % assume first poitn is the same
adt = abs(dt);              % as the second to keep arrays even

ifail = find(dt<0 | adt>TINC+rngTINC);

if ~isempty(ifail)
    d(ifail) = 4;
end

end