function WriteNETCDFbuoyMet(buoy, latlon, stnDep, d)
% 
% Create NETCDF files with buoy MET data
% 
% Calls WriteNC_BuoyMet.m
% 
% Called from WriteBuoyMetQAQC.m
% 

meta.Processing_Notes = 'Screened with WriteBuoyMetQAQC.m';
meta.mooring_name = buoy;
meta.lat = latlon(1,1);
meta.lon = latlon(1,2);
meta.water_depth = stnDep;
meta.depth_source = 'Ship range';
meta.PI = 'James O''Donnell, UCONN Marine Sciences & CIRCA';
meta.processed_by = 'James O''Donnell, james.odonnell@uconn.edu';
meta.lab = 'Data from LISICOS moored sensors';
meta.time_zone = 'EST';

% Write buoy MET data to NC files
WriteNC_BuoyMet([buoy '.nc'], d, meta);

end