function d = ImplementPresIntvTestQAQC(din, Para, ainst)
%
%  Apply IOOS QARTOD gaptest on data level
% 
%  find anomalous pressure out of range
%  set 1 for pass, 4 for fail and 3 for suspious
%
%  Called from PlotARTG_2018_20_summary.m
%
if contains(ainst, 'btm')
    ptop = Para.PresIntvTest(2,1);
    pbot = Para.PresIntvTest(2,2);
else
    ptop = Para.PresIntvTest(1,1);
    pbot = Para.PresIntvTest(1,2);
end

d = ones(size(din));                  % set QAQC code to 1
ifail = find(din<ptop | din>pbot);    % find anomalous time spacing

if ~isempty(ifail)
    d(ifail) = 4;
end

end