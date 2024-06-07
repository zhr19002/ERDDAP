function d = ImplementPresIntvTestQAQC(din, Para, loc)
% 
% Apply IOOS QARTOD gap test on data level
% 
% Find anomalous pressure out of range
% Set 1 for pass, 4 for fail, and 3 for suspicious
% 
% Called from CheckBuoyDataQAQC.m
% 

switch loc
    case 'sfc'
        ptop = Para.PresIntvTest(1,1);
        pbot = Para.PresIntvTest(1,2);
    case 'mid'
        ptop = Para.PresIntvTest(2,1);
        pbot = Para.PresIntvTest(2,2);
    case {'btm','btm1','btm2'}
        ptop = Para.PresIntvTest(3,1);
        pbot = Para.PresIntvTest(3,2);
end

d = ones(size(din));  % Set QAQC code to 1

ifail = find(din<ptop | din>pbot | isnan(din));
if ~isempty(ifail)
    d(ifail) = 4;
end

end