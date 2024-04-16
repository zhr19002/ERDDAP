function WriteNETCDFbuoyfile(anm, av, latlon, sd, S, T, DO, P, C, pH)
% 
% Create a NETCDF file with buoy data
% 
% Calls WriteNC_BuoyfilesV2.m
% Called from PlotARTG_2018_21_S_T_DO_summary.m
% 

ncfile = anm;
StnNames = anm;
StnDat = latlon;
StnDeps = sd;
meta.Processing_Notes = 'Screened with RunBUOYQAQC.m (April 14, 2022)';
meta.mooring_name = StnNames;
meta.lat = StnDat(1,1);
meta.lon = StnDat(1,2);
meta.water_depth = StnDeps(1);
meta.depth_source = 'ship range';
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
    d.prdMq      = P.(aObslev).prdM.data;
    d.sbeopoxMgq = DO.(aObslev).sbeopoxMg.data;
    d.rhoq       = sw_dens(d.sal00q, d.tv290Cq, d.prdMq) - 1000;
    sat          = o2sat(d.sal00q, d.tv290Cq)*32/1000; % Weiss, converted to mg/l
    d.DOsatq     = 100*d.sbeopoxMgq./sat;
    
    d.tv290CQAQC    = T.(aObslev).tv290C.QAQC;
    d.sal00QAQC     = S.(aObslev).sal00.QAQC;
    d.prdMQAQC      = P.(aObslev).prdM.QAQC;
    d.rhoQAQC       = S.(aObslev).sal00.QAQC;
    d.DOsatQAQC     = S.(aObslev).sal00.QAQC;
    d.sbeopoxMgQAQC = DO.(aObslev).sbeopoxMg.QAQC;
    
    d.pH     = pH.(aObslev).pH.data;
    d.pHQAQC = pH.(aObslev).pH.QAQC;
    
    WriteNC_BuoyfilesV2([ncfile aObslev '.nc'], d , meta, []);
    clear d;
end

end