function WriteNETCDFbuoyFile(buoy, loc, latlon, stnDep, d)
% 
% Create a NETCDF file with buoy data
% 
% Calls WriteNC_BuoyFiles.m
% Called from WriteBuoyDataQAQC.m
% 

meta.Processing_Notes = 'Screened with WriteBuoyDataQAQC.m';
meta.mooring_name = buoy;
meta.lat = latlon(1,1);
meta.lon = latlon(1,2);
meta.water_depth = stnDep;
meta.depth_source = 'Ship range';
meta.PI = 'James O''Donnell, UCONN Marine Sciences & CIRCA';
meta.processed_by = 'James O''Donnell, james.odonnell@uconn.edu';
meta.lab = 'Data from LISICOS moored sensors';
meta.time_zone = 'EST';

% Convert to the expected format
WriteNC_BuoyFiles([buoy '_' loc '.nc'], d, meta);

end