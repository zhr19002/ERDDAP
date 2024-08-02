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
netcdf.putAtt(ncid,windSpdid,'long_name','windSpd_Kts');

windSpdQid = netcdf.defVar(ncid,'windSpd_status','NC_INT',burstid);
netcdf.putAtt(ncid,windSpdQid,'long_name','windSpd_Kts_status_flag');
netcdf.putAtt(ncid,windSpdQid,'note',QAQCnote);

windDirMid = netcdf.defVar(ncid,'windDirM','NC_FLOAT',burstid);
netcdf.putAtt(ncid,windDirMid,'units','degrees');
netcdf.putAtt(ncid,windDirMid,'long_name','windDir_M');

windDirMQid = netcdf.defVar(ncid,'windDirM_status','NC_INT',burstid);
netcdf.putAtt(ncid,windDirMQid,'long_name','windDir_M_status_flag');
netcdf.putAtt(ncid,windDirMQid,'note',QAQCnote);

windDirSTDid = netcdf.defVar(ncid,'windDirSTD','NC_FLOAT',burstid);
netcdf.putAtt(ncid,windDirSTDid,'units','none');
netcdf.putAtt(ncid,windDirSTDid,'long_name','windDir_STD');

windDirSTDQid = netcdf.defVar(ncid,'windDirSTD_status','NC_INT',burstid);
netcdf.putAtt(ncid,windDirSTDQid,'long_name','windDir_STD_status_flag');
netcdf.putAtt(ncid,windDirSTDQid,'note',QAQCnote);

windSpdMaxid = netcdf.defVar(ncid,'windSpdMax','NC_FLOAT',burstid);
netcdf.putAtt(ncid,windSpdMaxid,'units','kts');
netcdf.putAtt(ncid,windSpdMaxid,'long_name','windSpd_Max');

windSpdMaxQid = netcdf.defVar(ncid,'windSpdMax_status','NC_INT',burstid);
netcdf.putAtt(ncid,windSpdMaxQid,'long_name','windSpd_Max_status_flag');
netcdf.putAtt(ncid,windSpdMaxQid,'note',QAQCnote);

windDirSMMid = netcdf.defVar(ncid,'windDirSMM','NC_FLOAT',burstid);
netcdf.putAtt(ncid,windDirSMMid,'units','degrees');
netcdf.putAtt(ncid,windDirSMMid,'long_name','windDir_SMM');

windDirSMMQid = netcdf.defVar(ncid,'windDirSMM_status','NC_INT',burstid);
netcdf.putAtt(ncid,windDirSMMQid,'long_name','windDir_SMM_status_flag');
netcdf.putAtt(ncid,windDirSMMQid,'note',QAQCnote);

fiveSecAvgid = netcdf.defVar(ncid,'fiveSecAvg','NC_FLOAT',burstid);
netcdf.putAtt(ncid,fiveSecAvgid,'units','kts');
netcdf.putAtt(ncid,fiveSecAvgid,'long_name','fiveSecAvg_Max');

fiveSecAvgQid = netcdf.defVar(ncid,'fiveSecAvg_status','NC_INT',burstid);
netcdf.putAtt(ncid,fiveSecAvgQid,'long_name','fiveSecAvg_Max_flag');
netcdf.putAtt(ncid,fiveSecAvgQid,'note',QAQCnote);

airTempid = netcdf.defVar(ncid,'airTemp','NC_FLOAT',burstid);
netcdf.putAtt(ncid,airTempid,'units','degC');
netcdf.putAtt(ncid,airTempid,'long_name','airTemp_Avg');

airTempQid = netcdf.defVar(ncid,'airTemp_status','NC_INT',burstid);
netcdf.putAtt(ncid,airTempQid,'long_name','airTemp_Avg_status_flag');
netcdf.putAtt(ncid,airTempQid,'note',QAQCnote);

relHumidid = netcdf.defVar(ncid,'relHumid','NC_FLOAT',burstid);
netcdf.putAtt(ncid,relHumidid,'units','percent');
netcdf.putAtt(ncid,relHumidid,'long_name','relHumid_Avg');

relHumidQid = netcdf.defVar(ncid,'relHumid_status','NC_INT',burstid);
netcdf.putAtt(ncid,relHumidQid,'long_name','relHumid_Avg_status_flag');
netcdf.putAtt(ncid,relHumidQid,'note',QAQCnote);

baroPressid = netcdf.defVar(ncid,'baroPress','NC_FLOAT',burstid);
netcdf.putAtt(ncid,baroPressid,'units','millibars');
netcdf.putAtt(ncid,baroPressid,'long_name','baroPress_Avg');

baroPressQid = netcdf.defVar(ncid,'baroPress_status','NC_INT',burstid);
netcdf.putAtt(ncid,baroPressQid,'long_name','baroPress_Avg_status_flag');
netcdf.putAtt(ncid,baroPressQid,'note',QAQCnote);

dewPTid = netcdf.defVar(ncid,'dewPT','NC_FLOAT',burstid);
netcdf.putAtt(ncid,dewPTid,'units','degC');
netcdf.putAtt(ncid,dewPTid,'long_name','dewPT_Avg');

dewPTQid = netcdf.defVar(ncid,'dewPT_status','NC_INT',burstid);
netcdf.putAtt(ncid,dewPTQid,'long_name','dewPT_Avg_status_flag');
netcdf.putAtt(ncid,dewPTQid,'note',QAQCnote);

netcdf.endDef(ncid);

% Put into data mode
netcdf.putVar(ncid, timeid, days(d.time(:)-datetime(1970,1,1,0,0,0)));
netcdf.putVar(ncid, windSpdid, d.windSpd_Kts.data);
netcdf.putVar(ncid, windDirMid, d.windDir_M.data);
netcdf.putVar(ncid, windDirSTDid, d.windDir_STD.data);
netcdf.putVar(ncid, windSpdMaxid, d.windSpd_Max.data);
netcdf.putVar(ncid, windDirSMMid, d.windDir_SMM.data);
netcdf.putVar(ncid, fiveSecAvgid, d.fiveSecAvg_Max.data);
netcdf.putVar(ncid, airTempid, d.airTemp_Avg.data);
netcdf.putVar(ncid, relHumidid, d.relHumid_Avg.data);
netcdf.putVar(ncid, baroPressid, d.baroPress_Avg.data);
netcdf.putVar(ncid, dewPTid, d.dewPT_Avg.data);

% Write Flags
netcdf.putVar(ncid, windSpdQid, d.windSpd_Kts.check);
netcdf.putVar(ncid, windDirMQid, d.windDir_M.check);
netcdf.putVar(ncid, windDirSTDQid, d.windDir_STD.check);
netcdf.putVar(ncid, windSpdMaxQid, d.windSpd_Max.check);
netcdf.putVar(ncid, windDirSMMQid, d.windDir_SMM.check);
netcdf.putVar(ncid, fiveSecAvgQid, d.fiveSecAvg_Max.check);
netcdf.putVar(ncid, airTempQid, d.airTemp_Avg.check);
netcdf.putVar(ncid, relHumidQid, d.relHumid_Avg.check);
netcdf.putVar(ncid, baroPressQid, d.baroPress_Avg.check);
netcdf.putVar(ncid, dewPTQid, d.dewPT_Avg.check);

netcdf.close(ncid);

end