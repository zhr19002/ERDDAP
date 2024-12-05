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

av_nut = struct('PAR_Raw','PAR','Adjusted_PAR_Raw','PAR', ...
                'chl_ugL','Corrected_Chl','Adjusted_chl_ugL','Corrected_Chl', ...
                'turbidity_NTU','TSS','Adjusted_turbidity_NTU','TSS', ...
                'NNO3','NOX_LC','Adjusted_NNO3','NOX_LC');

% Run the threshold test
if ismember(av, {'PAR_Raw','Adjusted_PAR_Raw','chl_ugL','Adjusted_chl_ugL'})
    dpth = 'depth_0_5';
else
    dpth = 'S';
end
c = ImplementThresholdTest(d.(av), d.TmStamp, QAQC, dpth, av_nut.(av));
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