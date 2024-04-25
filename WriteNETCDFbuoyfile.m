function WriteNETCDFbuoyfile(StnName, av, latlon, StnDep, S, T, DO, P, C, pH)
% 
% Create a NETCDF file with buoy data
% 
% Calls WriteNC_Buoyfiles.m
% Called from PlotARTG_2018_21_S_T_DO_summary.m
% 

meta.Processing_Notes = 'Screened with RunBUOYQAQC.m';
meta.mooring_name = StnName;
meta.lat = latlon(1,1);
meta.lon = latlon(1,2);
meta.water_depth = StnDep;
meta.depth_source = 'Ship range';
meta.PI = 'James ODonnell, UCONN Marine Sciences & CIRCA';
meta.processed_by = 'James ODonnell odonnell@uconn.edu';
meta.lab = 'Data from LISICOS moored sensors';
meta.time_zone = 'EST';

% Convert to the format expected
% Assume all the data times are the same
for nlev = 1:length(av)
    aObslev = av{nlev};
    
    d.EST        = S.(aObslev).EST;
    d.sal00q     = S.(aObslev).sal00.data;
    d.tv290Cq    = T.(aObslev).tv290C.data;
    d.sbeopoxMgq = DO.(aObslev).sbeopoxMg.data;
    d.prdMq      = P.(aObslev).prdM.data;
    d.cond0mSq   = C.(aObslev).cond0mS.data;
    d.pH         = pH.(aObslev).pH.data;
    d.rhoq       = sw_dens(d.sal00q, d.tv290Cq, d.prdMq) - 1000; 
    sat          = sw_satO2(d.sal00q, d.tv290Cq)*32/1000; % Converted to mg/l
    d.DOsatq     = 100*d.sbeopoxMgq./sat;
    
    d.sal00QAQC     = S.(aObslev).sal00.QAQC;
    d.tv290CQAQC    = T.(aObslev).tv290C.QAQC;
    d.sbeopoxMgQAQC = DO.(aObslev).sbeopoxMg.QAQC;
    d.prdMQAQC      = P.(aObslev).prdM.QAQC;
    d.cond0mSQAQC   = C.(aObslev).cond0mS.QAQC;
    d.rhoQAQC       = S.(aObslev).sal00.QAQC;
    d.DOsatQAQC     = S.(aObslev).sal00.QAQC;
    d.pHQAQC        = pH.(aObslev).pH.QAQC;
    
    WriteNC_Buoyfiles([StnName aObslev '.nc'], d, meta, []);
    clear d;
end

end