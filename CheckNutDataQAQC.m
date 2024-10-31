function [QAQCTests, FailedTestsCount] = CheckNutDataQAQC(d, QAQC, av)
% 
% Identify and flag failed QAQC tests of buoy nutrient data
% 
% Calls ImplementThresholdTest.m
% Calls ImplementJumpLimTest.m
% Calls ImplementGapTest.m
% Calls ImplementSpikeTest.m
% 
% Called from WriteNutDataQAQC.m
% 

% Run the threshold test
c = ImplementThresholdTest(d.(av), d.TmStamp, QAQC, 1, av);
d.('QAQCTests') = 1000*c;
d.('FailedTestsCount') = (c~=1);

% Run the jump limit test
c = ImplementJumpLimTest(d.(av));
d.('QAQCTests') = 100*c + d.('QAQCTests');
d.('FailedTestsCount') = (c~=1) + d.('FailedTestsCount');

% Run the gap test
c = ImplementGapTest(d.TmStamp);
d.('QAQCTests') = 10*c + d.('QAQCTests');
d.('FailedTestsCount') = (c~=1) + d.('FailedTestsCount');

% Run the spike test
c = ImplementSpikeTest(d.(av));
d.('QAQCTests') = c + d.('QAQCTests');
d.('FailedTestsCount') = (c~=1) + d.('FailedTestsCount');

% Output the QAQC results
QAQCTests = d.QAQCTests;
FailedTestsCount = d.FailedTestsCount;

end