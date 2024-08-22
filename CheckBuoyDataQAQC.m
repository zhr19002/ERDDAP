function dQ = CheckBuoyDataQAQC(d, stns, loc, av_by, av)
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

% Read station group QAQC parameters
QAQC = load(['QAQC_Para_' stns '.mat']);
QAQC = QAQC.QAQC;
QAQC.ExpectedTimeIncr = 0.25/24;    % Expected data sample period (days)
QAQC.TolExpectedTimeIncr = 0.25/48; % Tolerance in sample period (days)
QAQC.PresRng = [0 3; 5 15; 15 30];  % Expected depth range

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
d.('QAQCTests') = 10000*c;
d.('FailedTestsCount') = (c~=1);

% Run other QAQC tests
c = ImplementJumpLimTest(d.(av_by.(av)));
d.('QAQCTests') = 1000*c + d.('QAQCTests');
d.('FailedTestsCount') = (c~=1) + d.('FailedTestsCount');

c = ImplementGapTest(d.TmStamp, QAQC);
d.('QAQCTests') = 100*c + d.('QAQCTests');
d.('FailedTestsCount') = (c~=1) + d.('FailedTestsCount');

c = ImplementPresRngTest(d.depth, QAQC, loc);
d.('QAQCTests') = 10*c + d.('QAQCTests');
d.('FailedTestsCount') = (c~=1) + d.('FailedTestsCount');

c = ImplementSpikeTest(d.(av_by.(av)));
d.('QAQCTests') = c + d.('QAQCTests');
d.('FailedTestsCount') = (c~=1) + d.('FailedTestsCount');

% Form QAQC structure
dQ.data = d.(av_by.(av));
dQ.QAQCTests = d.QAQCTests;
dQ.FailedTestsCount = d.FailedTestsCount;

end