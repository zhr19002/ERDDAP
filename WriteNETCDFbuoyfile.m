function WriteNETCDFbuoyfile(buoy, locs, latlon, stnDep, buoy_QAQC)
% 
% Create a NETCDF file with buoy data
% 
% Calls WriteNC_Buoyfiles.m
% Called from WriteBuoyDataQAQC.m
% 

meta.Processing_Notes = 'Screened with RunBUOYQAQC.m';
meta.mooring_name = buoy;
meta.lat = latlon(1,1);
meta.lon = latlon(1,2);
meta.water_depth = stnDep;
meta.depth_source = 'Ship range';
meta.PI = 'James ODonnell, UCONN Marine Sciences & CIRCA';
meta.processed_by = 'James ODonnell odonnell@uconn.edu';
meta.lab = 'Data from LISICOS moored sensors';
meta.time_zone = 'EST';

% Convert to the expected format
for loc = locs
    d = buoy_QAQC.(loc{1});
    WriteNC_Buoyfiles([buoy loc{1} '.nc'], d, meta);
    clear d;
end

end