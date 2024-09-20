function d = ImplementGapTest(din)
% 
% Apply IOOS QARTOD gap test
% 
% Find anomalous time seperations
% Set 1 for pass, 4 for fail, and 3 for suspicious
% 
% Called from WriteBuoyDataQAQC.m
% 

TMIN = 1/12/24;
TINC = 0.25/24;    % Expected time increase (days)
rngTINC = 0.25/48; % Tolerance in expected time increase (days)

d = ones(size(din));  % Set QAQC code to 1
dt = diff(din);       % Find anomalous time spacing
dt = dt([1 1:end]);   % The first and second are treated the same           

ifail = find(dt<TMIN | dt>TINC+rngTINC | isnat(din));
if ~isempty(ifail)
    d(ifail) = 4;
end

end