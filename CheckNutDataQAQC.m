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

avNut = struct('PAR','PAR','Adjusted_PAR','PAR', ...
               'CHLA','Corrected_Chl','Adjusted_CHLA','Corrected_Chl', ...
               'TSS','TSS','Adjusted_TSS','TSS', ...
               'NO3','NOX_LC','Adjusted_NO3','NOX_LC');

% Run the threshold test
if ismember(av, {'PAR','Adjusted_PAR','CHLA','Adjusted_CHLA'})
    dpth = 'depth_0_5';
else
    dpth = 'S';
end
c = ImplementThresholdTest(d.(av), d.TmStamp, QAQC, dpth, avNut.(av));
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