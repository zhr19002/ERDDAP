function WriteNETCDFshipSurveyFile(cruise, Astn, dp_rng, latlon, stnDep, d)
% 
% Create NETCDF files with ship survey data
% 
% Calls WriteNC_ShipSurveyFiles.m
% 
% Called from WriteShipSurveyDataQAQC.m
% 

meta.Processing_Notes = 'Screened with WriteShipSurveyDataQAQC.m';
meta.cruise_name = cruise;
meta.mooring_name = Astn;
meta.lat = latlon(1,1);
meta.lon = latlon(1,2);
meta.water_depth = stnDep;
meta.depth_source = 'Ship range';
meta.PI = 'James O''Donnell, UCONN Marine Sciences & CIRCA';
meta.processed_by = 'James O''Donnell, james.odonnell@uconn.edu';
meta.lab = 'Data from LISICOS moored sensors';
meta.time_zone = 'EST';

% Convert to the expected format
WriteNC_ShipSurveyFiles([cruise '_' Astn '_' dp_rng '.nc'], d, meta);

end