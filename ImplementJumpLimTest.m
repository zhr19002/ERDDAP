function d = ImplementJumpLimTest(din)
% 
% Implement sample to sample difference test
% Set 1 for pass, 4 for fail, and 3 for suspicious
% 
% Called from CheckBuoyDataQAQC.m
% 

d = ones(size(din));  % Set QAQC code to 1
dd = abs(diff(din));
dd = dd([1 1:end]);   % The first and second are treated the same

isus = find(dd>prctile(dd,99));
if ~isempty(isus)
    d(isus) = 3;
end

ifail = find(dd>prctile(dd,99.9) | isnan(din));
if ~isempty(ifail)
    d(ifail) = 4;
end

end