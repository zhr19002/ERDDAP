function WriteNC_BuoyMet(ncfile, d, meta)
% 
% Write buoy MET data to NC files
% 
% Called from WriteNETCDFbuoyMet.m
% 

QAQCnote = '1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range';

% Make NC file
ncid = netcdf.create(ncfile,'64BIT_OFFSET');

% GLOBAL ATTRIBUTES
varid = netcdf.getConstant('NC_GLOBAL');
netcdf.putAtt(ncid,varid,'Processing_Notes',meta.Processing_Notes);
netcdf.putAtt(ncid,varid,'mooring_name',meta.mooring_name);
netcdf.putAtt(ncid,varid,'latitude',meta.lat);
netcdf.putAtt(ncid,varid,'longitude',meta.lon);
netcdf.putAtt(ncid,varid,'latitude_units','decimal degrees');
netcdf.putAtt(ncid,varid,'longitude_units','decimal degrees');
netcdf.putAtt(ncid,varid,'water_depth',meta.water_depth);
netcdf.putAtt(ncid,varid,'water_depth_units','m');
netcdf.putAtt(ncid,varid,'water_depth_method',meta.depth_source);
netcdf.putAtt(ncid,varid,'PI',meta.PI);
netcdf.putAtt(ncid,varid,'processed_by',meta.processed_by)
ad = string(datetime(datetime('now'), 'Format', 'yyyy-MM-dd HH:mm:ss'));
netcdf.putAtt(ncid,varid,'CreationDate',ad);
netcdf.putAtt(ncid,varid,'Institution','UConn, Marine Sciences');
netcdf.putAtt(ncid,varid,'Source','LISICOS-NERACOOS Observations');

% DEFINE VARIABLES
burstid = netcdf.defDim(ncid,'burst',size(d.time,1));

timeid = netcdf.defVar(ncid,'time','NC_DOUBLE',burstid);
netcdf.putAtt(ncid,timeid,'standard_name','time');
netcdf.putAtt(ncid,timeid,'units','days since midnight January 1, 1970');
netcdf.putAtt(ncid,timeid,'calendar','julian');
netcdf.putAtt(ncid,timeid,'time_zone',meta.time_zone);
netcdf.putAtt(ncid,timeid,'axis','T');

windSpdid = netcdf.defVar(ncid,'windSpd','NC_FLOAT',burstid);
netcdf.putAtt(ncid,windSpdid,'units','kts');
netcdf.putAtt(ncid,windSpdid,'long_name','wind_speed');

windSpdQ1id = netcdf.defVar(ncid,'windSpdQ','NC_INT',burstid);
netcdf.putAtt(ncid,windSpdQ1id,'long_name','wind_speed_flag');
netcdf.putAtt(ncid,windSpdQ1id,'note',QAQCnote);

windSpdQ2id = netcdf.defVar(ncid,'windSpdQ_delta','NC_INT',burstid);
netcdf.putAtt(ncid,windSpdQ2id,'long_name','wind_speed_delta_flag');
netcdf.putAtt(ncid,windSpdQ2id,'note',QAQCnote);

windSpdMaxid = netcdf.defVar(ncid,'windSpdMax','NC_FLOAT',burstid);
netcdf.putAtt(ncid,windSpdMaxid,'units','kts');
netcdf.putAtt(ncid,windSpdMaxid,'long_name','wind_speed_max');

windSpdMaxQid = netcdf.defVar(ncid,'windSpdMaxQ','NC_INT',burstid);
netcdf.putAtt(ncid,windSpdMaxQid,'long_name','wind_speed_max_flag');
netcdf.putAtt(ncid,windSpdMaxQid,'note',QAQCnote);

fiveSecAvgid = netcdf.defVar(ncid,'fiveSecAvg','NC_FLOAT',burstid);
netcdf.putAtt(ncid,fiveSecAvgid,'units','kts');
netcdf.putAtt(ncid,fiveSecAvgid,'long_name','five_seconds_average');

fiveSecAvgQid = netcdf.defVar(ncid,'fiveSecAvgQ','NC_INT',burstid);
netcdf.putAtt(ncid,fiveSecAvgQid,'long_name','five_seconds_average_max_flag');
netcdf.putAtt(ncid,fiveSecAvgQid,'note',QAQCnote);

windDirid = netcdf.defVar(ncid,'windDir','NC_FLOAT',burstid);
netcdf.putAtt(ncid,windDirid,'units','degrees');
netcdf.putAtt(ncid,windDirid,'long_name','wind_direction');
netcdf.putAtt(ncid,windDirid,'note','convert angle value to cos value');

windDirQid = netcdf.defVar(ncid,'windDirQ_delta','NC_INT',burstid);
netcdf.putAtt(ncid,windDirQid,'long_name','wind_direction_delta_flag');
netcdf.putAtt(ncid,windDirQid,'note',QAQCnote);

airTempid = netcdf.defVar(ncid,'airTemp','NC_FLOAT',burstid);
netcdf.putAtt(ncid,airTempid,'units','degC');
netcdf.putAtt(ncid,airTempid,'long_name','air_temperature_average');

airTempQid = netcdf.defVar(ncid,'airTempQ','NC_INT',burstid);
netcdf.putAtt(ncid,airTempQid,'long_name','air_temperature_average_flag');
netcdf.putAtt(ncid,airTempQid,'note',QAQCnote);

relHumidid = netcdf.defVar(ncid,'relHumid','NC_FLOAT',burstid);
netcdf.putAtt(ncid,relHumidid,'units','percent');
netcdf.putAtt(ncid,relHumidid,'long_name','relative_humid_average');

relHumidQid = netcdf.defVar(ncid,'relHumidQ','NC_INT',burstid);
netcdf.putAtt(ncid,relHumidQid,'long_name','relative_humidity_average_flag');
netcdf.putAtt(ncid,relHumidQid,'note',QAQCnote);

baroPressid = netcdf.defVar(ncid,'baroPress','NC_FLOAT',burstid);
netcdf.putAtt(ncid,baroPressid,'units','millibars');
netcdf.putAtt(ncid,baroPressid,'long_name','baro_pressure_average');

baroPressQid = netcdf.defVar(ncid,'baroPressQ','NC_INT',burstid);
netcdf.putAtt(ncid,baroPressQid,'long_name','baro_pressure_average_flag');
netcdf.putAtt(ncid,baroPressQid,'note',QAQCnote);

dewPTid = netcdf.defVar(ncid,'dewPT','NC_FLOAT',burstid);
netcdf.putAtt(ncid,dewPTid,'units','degC');
netcdf.putAtt(ncid,dewPTid,'long_name','dew_point_average');

dewPTQid = netcdf.defVar(ncid,'dewPTQ','NC_INT',burstid);
netcdf.putAtt(ncid,dewPTQid,'long_name','dew_point_average_flag');
netcdf.putAtt(ncid,dewPTQid,'note',QAQCnote);

netcdf.endDef(ncid);

% Put into data mode
netcdf.putVar(ncid, timeid, days(d.time(:)-datetime(1970,1,1,0,0,0)));
netcdf.putVar(ncid, windSpdid, d.windSpd_Kts.data);
netcdf.putVar(ncid, windSpdMaxid, d.windSpd_Max.data);
netcdf.putVar(ncid, fiveSecAvgid, d.fiveSecAvg_Max.data);
netcdf.putVar(ncid, windDirid, d.windDir_M.data);
netcdf.putVar(ncid, airTempid, d.airTemp_Avg.data);
netcdf.putVar(ncid, relHumidid, d.relHumid_Avg.data);
netcdf.putVar(ncid, baroPressid, d.baroPress_Avg.data);
netcdf.putVar(ncid, dewPTid, d.dewPT_Avg.data);

% Write Flags
netcdf.putVar(ncid, windSpdQ1id, d.windSpd_Kts.check);
netcdf.putVar(ncid, windSpdQ2id, d.windSpd_Kts.deltaCheck);
netcdf.putVar(ncid, windSpdMaxQid, d.windSpd_Max.check);
netcdf.putVar(ncid, fiveSecAvgQid, d.fiveSecAvg_Max.check);
netcdf.putVar(ncid, windDirQid, d.windDir_M.deltaCheck);
netcdf.putVar(ncid, airTempQid, d.airTemp_Avg.check);
netcdf.putVar(ncid, relHumidQid, d.relHumid_Avg.check);
netcdf.putVar(ncid, baroPressQid, d.baroPress_Avg.check);
netcdf.putVar(ncid, dewPTQid, d.dewPT_Avg.check);

netcdf.close(ncid);

end