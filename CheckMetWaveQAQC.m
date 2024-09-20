function [QAQCTests, FailedTestsCount] = CheckMetWaveQAQC(d, QAQC, av)
% 
% Identify and flag failed QAQC tests of buoy met/wave data
% 
% Calls ImplementJumpLimTest.m
% Calls ImplementGapTest.m
% Calls ImplementSpikeTest.m
% 
% Called from WriteMetDataQAQC.m
% Called from WriteWaveDataQAQC.m
% 

% Run the threshold test
c = ones(size(d,1), 1);
c(d.(av)<QAQC.(av)('min_val') | d.(av)>QAQC.(av)('max_val') | isnan(d.(av))) = 4;
d.('QAQCTests') = 1000*c;
d.('FailedTestsCount') = (c~=1);

% Check if the variable is angle
if contains(av, 'Dir')
    d.(av) = cos(d.(av)*pi/180);
end

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