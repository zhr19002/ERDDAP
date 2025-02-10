function [QAQCTests, FailedTestsCount] = CheckNutDataQAQC(d, loc, QAQC, av)
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
    ZT = 5*floor((d.depth-0.01)/5);
    ZT(ZT<0 | ZT>40 | isnan(ZT)) = mode(ZT);
    uZT = unique(ZT);
    c = ones(size(d,1), 1);
    for i = 1:length(uZT)
        % Determine the depth range ZT to ZB
        dpth = ['depth_' num2str(uZT(i)) '_' num2str(uZT(i)+5)];
        % Locate rows of a specific depth range
        iu = find(ZT==uZT(i));
        c(iu) = ImplementThresholdTest(d.(av)(iu), d.TmStamp(iu), QAQC, dpth, avNut.(av));
    end
else
    if strcmp(loc, 'sfc')
        dpth = 'S';
    else
        dpth = 'B';
    end
    c = ImplementThresholdTest(d.(av), d.TmStamp, QAQC, dpth, avNut.(av));
end
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