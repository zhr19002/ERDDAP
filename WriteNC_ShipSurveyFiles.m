function WriteNC_ShipSurveyFiles(ncfile, d, meta)
% 
% Write ship survey data to NC files
% 
% Called from WriteNETCDFshipSurveyFile.m
% 

QAQCnote = '1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range';

% Make NC file
ncid = netcdf.create(ncfile,'64BIT_OFFSET');

% GLOBAL ATTRIBUTES
varid = netcdf.getConstant('NC_GLOBAL');
netcdf.putAtt(ncid,varid,'Processing_Notes',meta.Processing_Notes);
netcdf.putAtt(ncid,varid,'cruise_name',meta.cruise_name);
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

tempid = netcdf.defVar(ncid,'temp','NC_FLOAT',burstid);
netcdf.putAtt(ncid,tempid,'units','degC');
netcdf.putAtt(ncid,tempid,'long_name','sea_water_temperature');

tempQid = netcdf.defVar(ncid,'temp_status','NC_INT',burstid);
netcdf.putAtt(ncid,tempQid,'long_name','temperature_status_flag');
netcdf.putAtt(ncid,tempQid,'note',QAQCnote);

saltid = netcdf.defVar(ncid,'salt','NC_FLOAT',burstid);
netcdf.putAtt(ncid,saltid,'units','psu');
netcdf.putAtt(ncid,saltid,'long_name','sea_water_salinity');
netcdf.putAtt(ncid,saltid,'note','constant used, not measured');

saltQid = netcdf.defVar(ncid,'salt_status','NC_INT',burstid);
netcdf.putAtt(ncid,saltQid,'long_name','salinity_status_flag');
netcdf.putAtt(ncid,saltQid,'note',QAQCnote);

DOid = netcdf.defVar(ncid,'DO','NC_FLOAT',burstid);
netcdf.putAtt(ncid,DOid,'units','mg/L');
netcdf.putAtt(ncid,DOid,'long_name','oxygen_concentration_in_sea_water');

DOQid = netcdf.defVar(ncid,'DO_status','NC_INT',burstid);
netcdf.putAtt(ncid,DOQid,'long_name','DO_status_flag');
netcdf.putAtt(ncid,DOQid,'note',QAQCnote);

presid = netcdf.defVar(ncid,'pres','NC_FLOAT',burstid);
netcdf.putAtt(ncid,presid,'units','dbar');
netcdf.putAtt(ncid,presid,'long_name','sea_water_pressure');
netcdf.putAtt(ncid,presid,'note','pressure at transducer, relative to 1 atm.');

presQid = netcdf.defVar(ncid,'pres_status','NC_INT',burstid);
netcdf.putAtt(ncid,presQid,'long_name','sea_water_pressure_status_flag');
netcdf.putAtt(ncid,presQid,'note',QAQCnote);

condid = netcdf.defVar(ncid,'cond','NC_FLOAT',burstid);
netcdf.putAtt(ncid,condid,'units','S/m');
netcdf.putAtt(ncid,condid,'long_name','sea_water_electrical_conductivity');

condQid = netcdf.defVar(ncid,'cond_status','NC_INT',burstid);
netcdf.putAtt(ncid,condQid,'long_name','sea_water_conductivity_status_flag');
netcdf.putAtt(ncid,condQid,'note',QAQCnote);

pHid = netcdf.defVar(ncid,'pH','NC_FLOAT',burstid);
netcdf.putAtt(ncid,pHid,'units','none');
netcdf.putAtt(ncid,pHid,'long_name','pH - acidity');

pHQid = netcdf.defVar(ncid,'pH_status','NC_INT',burstid);
netcdf.putAtt(ncid,pHQid,'long_name','pH_status_flag');
netcdf.putAtt(ncid,pHQid,'note',QAQCnote);

rhoid = netcdf.defVar(ncid,'rho','NC_FLOAT',burstid);
netcdf.putAtt(ncid,rhoid,'units','kg/m^3');
netcdf.putAtt(ncid,rhoid,'long_name','sea_water_density');
netcdf.putAtt(ncid,rhoid,'note','computed from salinity and temp');

rhoQid = netcdf.defVar(ncid,'rho_status','NC_INT',burstid);
netcdf.putAtt(ncid,rhoQid,'long_name','sea_water_density_status_flag');
netcdf.putAtt(ncid,rhoQid,'note',QAQCnote);

DOsatid = netcdf.defVar(ncid,'DOsat','NC_FLOAT',burstid);
netcdf.putAtt(ncid,DOsatid,'units','none (%)');
netcdf.putAtt(ncid,DOsatid,'long_name','fractional_saturation_of_oxygen_in_sea_water');

DOsatQid = netcdf.defVar(ncid,'DOsat_status','NC_INT',burstid);
netcdf.putAtt(ncid,DOsatQid,'long_name','DO_sat_status_flag');
netcdf.putAtt(ncid,DOsatQid,'note',QAQCnote);

netcdf.endDef(ncid);

% Put into data mode
netcdf.putVar(ncid, timeid, days(d.time(:)-datetime(1970,1,1,0,0,0)));
netcdf.putVar(ncid, tempid, d.T.data);
netcdf.putVar(ncid, saltid, d.S.data);
netcdf.putVar(ncid, DOid, d.DO.data);
netcdf.putVar(ncid, presid, d.P.data);
netcdf.putVar(ncid, condid, d.C.data);
netcdf.putVar(ncid, pHid, d.pH.data);
netcdf.putVar(ncid, rhoid, d.rho.data);
netcdf.putVar(ncid, DOsatid, d.DOsat.data);

% Write Flags
netcdf.putVar(ncid, tempQid, d.T.check);
netcdf.putVar(ncid, saltQid, d.S.check);
netcdf.putVar(ncid, DOQid, d.DO.check);
netcdf.putVar(ncid, presQid, d.P.check);
netcdf.putVar(ncid, condQid, d.C.check);
netcdf.putVar(ncid, pHQid, d.pH.check);
netcdf.putVar(ncid, rhoQid, d.rho.check);
netcdf.putVar(ncid, DOsatQid, d.DOsat.check);

netcdf.close(ncid);

end