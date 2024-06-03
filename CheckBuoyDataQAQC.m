function [QAQC, buoydataQAQC] = CheckBuoyDataQAQC(d, loc, avar, avar_buoy)
% 
% Identify and flag failed QAQC tests of buoy data
% 
% Calls ImplementThresoldQAQC.m
% Calls ImplementDeltaQAQC.m
% Calls ImplementGapTestQAQC.m
% Calls ImplementPresIntvTestQAQC.m
% Calls ImplementSpikeTestQAQC.m
% 
% Called from WriteBuoyDataQAQC.m
% 

% Read QAQC parameters
QAQC_para = readtable('QAQC_Para.csv', ReadRowNames=true);
QAQC.Thesholds = [QAQC_para.(avar)('Min_Value') QAQC_para.(avar)('Max_Value')];
QAQC.Delta = [QAQC_para.(avar)('Min_Jump') QAQC_para.(avar)('Max_Jump')];
QAQC.THRSHLD = [QAQC_para.(avar)('SPK_sfc_bot') QAQC_para.(avar)('SPK_sfc_top');
                QAQC_para.(avar)('SPK_mid_bot') QAQC_para.(avar)('SPK_mid_top');
                QAQC_para.(avar)('SPK_btm_bot') QAQC_para.(avar)('SPK_btm_top')];
QAQC.ExpectedTimeIncr = 0.25/24;        % Expected data sample period (days)
QAQC.TolExpectedTimeIncr = 0.25/48;     % Tolerance in sample period (days)
QAQC.PresIntvTest = [0 3; 5 15; 20 30]; % Expected depth range

% Run QAQC tests
d_tmp = ImplementThresoldQAQC(d.(avar_buoy.(avar)),QAQC);
d.('QAQCTests') = 10000*d_tmp;
d.('FailedTestsCount') = (d_tmp~=1);

d_tmp = ImplementDeltaQAQC(d.(avar_buoy.(avar)),QAQC);
d.('QAQCTests') = 1000*d_tmp + d.('QAQCTests');
d.('FailedTestsCount') = (d_tmp~=1) + d.('FailedTestsCount');

d_tmp = ImplementGapTestQAQC(d.TmStamp,QAQC);
d.('QAQCTests') = 100*d_tmp + d.('QAQCTests');
d.('FailedTestsCount') = (d_tmp~=1) + d.('FailedTestsCount');

d_tmp = ImplementPresIntvTestQAQC(d.depth,QAQC,loc);
d.('QAQCTests') = 10*d_tmp + d.('QAQCTests');
d.('FailedTestsCount') = (d_tmp~=1) + d.('FailedTestsCount');

d_tmp = ImplementSpikeTestQAQC(d.(avar_buoy.(avar)),QAQC,loc);
d.('QAQCTests') = d_tmp + d.('QAQCTests');
d.('FailedTestsCount') = (d_tmp~=1) + d.('FailedTestsCount');

buoydataQAQC = d;

end