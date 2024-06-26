function WriteNETCDFstationFile(Astn, dp_rng, latlon, stnDep, d)
% 
% Create NETCDF files with station data
% 
% Calls WriteNC_StationFiles.m
% 
% Called from WriteStationDataQAQC.m
% 

meta.Processing_Notes = 'Screened with WriteStationDataQAQC.m';
meta.mooring_name = Astn;
meta.lat = latlon(1,1);
meta.lon = latlon(1,2);
meta.water_depth = stnDep;
meta.depth_source = 'Ship range';
meta.PI = 'James O''Donnell, UCONN Marine Sciences & CIRCA';
meta.processed_by = 'James O''Donnell, james.odonnell@uconn.edu';
meta.lab = 'Data from LISICOS moored sensors';
meta.time_zone = 'EST';

% Write station data to NC files
WriteNC_StationFiles([Astn '_' dp_rng '.nc'], d, meta);

end