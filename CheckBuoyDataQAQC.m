function [QAQC, buoydataQAQC] = CheckBuoyDataQAQC(d, loc, avar, avar_buoy)

% Read QAQC parameters
QAQC_para = readtable('QAQC_Para.csv', ReadRowNames=true);

QAQC.Thesholds = [QAQC_para.(avar)('Min_Value') QAQC_para.(avar)('Max_Value')];
QAQC.Delta = [QAQC_para.(avar)('Min_Jump') QAQC_para.(avar)('Max_Jump')];
QAQC.THRSHLD = [QAQC_para.(avar)('SPK_sfc_bot') QAQC_para.(avar)('SPK_sfc_top');
                QAQC_para.(avar)('SPK_btm_bot') QAQC_para.(avar)('SPK_btm_top')];
QAQC.ExpectedTimeIncr = 0.25/24;    % Expected data sample period (days)
QAQC.TolExpectedTimeIncr = 0.25/48; % Tolerance in sample period (days)
QAQC.PresIntvTest = [0 3; 20 30];   % Expected depth range for surface and bottom

d.('QAQCTest1') = ImplementThresoldQAQC(d.(avar_buoy.(avar)),d.TmStamp,QAQC);
d.('QAQCTest2') = ImplementDeltaQAQC(d.(avar_buoy.(avar)),QAQC);
d.('QAQCTest3') = ImplementGapTestQAQC(d.TmStamp,QAQC);
d.('QAQCTest4') = ImplementPresIntvTestQAQC(d.depth,QAQC,loc);
d.('QAQCTest5') = ImplementSpikeTestQAQC(d.(avar_buoy.(avar)),QAQC,loc);

buoydataQAQC = d;

end