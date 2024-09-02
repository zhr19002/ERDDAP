function [QAQCTests, FailedTestsCount] = CheckBuoyDataQAQC(d, loc, QAQC, av_by, av)
% 
% Identify and flag failed QAQC tests of buoy data
% 
% Calls ImplementThresholdTest.m
% Calls ImplementJumpLimTest.m
% Calls ImplementGapTest.m
% Calls ImplementPresRngTest.m
% Calls ImplementSpikeTest.m
% 
% Called from WriteBuoyDataQAQC.m
% 

% Run the threshold test
ZT = 5*floor((d.dBars-0.1)/5);
ZT(ZT<0 | ZT>40 | isnan(ZT)) = mode(ZT);
uZT = unique(ZT);
c = ones(size(d,1), 1);
for i = 1:length(uZT)
    % Determine the depth range ZT to ZB
    dpth = ['depth_' num2str(uZT(i)) '_' num2str(uZT(i)+5)];
    % Locate rows of a specific depth range
    iu = find(ZT==uZT(i));
    c(iu) = ImplementThresholdTest(d.(av_by.(av))(iu), d.TmStamp(iu), QAQC, dpth, av);
end
d.('QAQCTests') = 10000*c;
d.('FailedTestsCount') = (c~=1);

% Run the jump limit test
c = ImplementJumpLimTest(d.(av_by.(av)));
d.('QAQCTests') = 1000*c + d.('QAQCTests');
d.('FailedTestsCount') = (c~=1) + d.('FailedTestsCount');

% Run the gap test
c = ImplementGapTest(d.TmStamp);
d.('QAQCTests') = 100*c + d.('QAQCTests');
d.('FailedTestsCount') = (c~=1) + d.('FailedTestsCount');

% Run the pressure range test
c = ImplementPresRngTest(d.dBars, loc);
d.('QAQCTests') = 10*c + d.('QAQCTests');
d.('FailedTestsCount') = (c~=1) + d.('FailedTestsCount');

% Run the spike test
c = ImplementSpikeTest(d.(av_by.(av)));
d.('QAQCTests') = c + d.('QAQCTests');
d.('FailedTestsCount') = (c~=1) + d.('FailedTestsCount');

% Output the QAQC results
QAQCTests = d.QAQCTests;
FailedTestsCount = d.FailedTestsCount;

end