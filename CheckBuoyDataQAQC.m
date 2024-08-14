function dQAQC = CheckBuoyDataQAQC(d, buoy, loc, av)
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

% Fixed parameters
av_by = struct('T','degC','S','psu','DO','mg/L','P','dBars','C','S/m', ...
               'pH','none','rho','kg/m^3','DOsat','percent');

% Read station group parameters
QAQC = load([buoy '_para.mat']);
QAQC = QAQC.QAQC_para;
QAQC.ExpectedTimeIncr = 0.25/24;    % Expected data sample period (days)
QAQC.TolExpectedTimeIncr = 0.25/48; % Tolerance in sample period (days)
QAQC.PresRng = [0 3; 5 15; 16 30];  % Expected depth range

% Run five QAQC tests
% Determine the depth range ZT to ZB
if contains(loc{1}, 'sfc')
    ZT = 0; ZB = 3;
elseif contains(loc{1}, 'mid')
    ZT = 5; ZB = 15;
else
    ZT = 16; ZB = 30;
end
dpth = ['depth_' num2str(ZT) '_' num2str(ZB)];
tmp = ImplementThresholdTest(d.(av_by.(av)), d.TmStamp, QAQC, dpth, av);
d.('QAQCTests') = 10000*tmp;
d.('FailedTestsCount') = (tmp~=1);

tmp = ImplementJumpLimTest(d.(av_by.(av)));
d.('QAQCTests') = 1000*tmp + d.('QAQCTests');
d.('FailedTestsCount') = (tmp~=1) + d.('FailedTestsCount');

tmp = ImplementGapTest(d.TmStamp, QAQC);
d.('QAQCTests') = 100*tmp + d.('QAQCTests');
d.('FailedTestsCount') = (tmp~=1) + d.('FailedTestsCount');

tmp = ImplementPresRngTest(d.depth, QAQC, loc);
d.('QAQCTests') = 10*tmp + d.('QAQCTests');
d.('FailedTestsCount') = (tmp~=1) + d.('FailedTestsCount');

tmp = ImplementSpikeTest(d.(av_by.(av)));
d.('QAQCTests') = tmp + d.('QAQCTests');
d.('FailedTestsCount') = (tmp~=1) + d.('FailedTestsCount');

% Form QAQC structure
dQAQC.data = d.(av_by.(av));
dQAQC.QAQCTests = d.QAQCTests;
dQAQC.FailedTestsCount = d.FailedTestsCount;

end