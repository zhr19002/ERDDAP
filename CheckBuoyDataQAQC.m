function dQ = CheckBuoyDataQAQC(d, stns, av_by, av)
% 
% Identify and flag failed QAQC tests of buoy data
% 
% Calls ImplementThresholdTest.m
% Calls ImplementJumpLimTest.m
% Calls ImplementSpikeTest.m
% 
% Called from WriteBuoyDataQAQC.m
% 

% Read station group QAQC parameters
QAQC = load(['QAQC_Para_' stns '.mat']);
QAQC = QAQC.QAQC;

% Run the threshold test
c = ones(size(d,1), 1);
udepth = unique(d.depth);
for i = 1:length(udepth)
    % Determine the depth range ZT to ZB
    ZT = 5*floor((udepth(i)-0.1)/5);
    ZB = ZT + 5;
    dpth = ['depth_' num2str(ZT) '_' num2str(ZB)];
    % Locate rows of a specific depth
    iu = find(d.depth==udepth(i));
    c(iu) = ImplementThresholdTest(d.(av_by.(av))(iu), d.TmStamp(iu), QAQC, dpth, av);
end
d.('QAQCTests') = 100*c;
d.('FailedTestsCount') = (c~=1);

% Run the jump limit test
c = ImplementJumpLimTest(d.(av_by.(av)));
d.('QAQCTests') = 10*c + d.('QAQCTests');
d.('FailedTestsCount') = (c~=1) + d.('FailedTestsCount');

% Run the spike test
c = ImplementSpikeTest(d.(av_by.(av)));
d.('QAQCTests') = c + d.('QAQCTests');
d.('FailedTestsCount') = (c~=1) + d.('FailedTestsCount');

% Form QAQC structure
dQ.data = d.(av_by.(av));
dQ.QAQCTests = d.QAQCTests;
dQ.FailedTestsCount = d.FailedTestsCount;

end