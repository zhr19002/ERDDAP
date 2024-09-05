function WriteBuoyNETCDF(buoy, loc, latlon, stnDep, d)
% 
% Write buoy QAQC data to NC files
% 
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

QAQCnote = ['QAQC Tests: (1) threshold, (2) jump limit, (3) time gap, ' ...
            '(4) pressure range, (5) spike; 1 = pass; 3 = questionable; ' ...
            '4 = fail. Last column is the number of failed tests.'];

% Make NC file
ncid = netcdf.create([buoy '_' loc '.nc'],'64BIT_OFFSET');

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
QAQCid = netcdf.defDim(ncid,'QAQC',2);

timeid = netcdf.defVar(ncid,'time','NC_DOUBLE',burstid);
netcdf.putAtt(ncid,timeid,'standard_name','time');
netcdf.putAtt(ncid,timeid,'units','days since midnight January 1, 1970');
netcdf.putAtt(ncid,timeid,'calendar','julian');
netcdf.putAtt(ncid,timeid,'time_zone',meta.time_zone);
netcdf.putAtt(ncid,timeid,'axis','T');

depthid = netcdf.defVar(ncid,'depth','NC_FLOAT',burstid);
netcdf.putAtt(ncid,depthid,'units','m');
netcdf.putAtt(ncid,depthid,'long_name','depth');

Tid = netcdf.defVar(ncid,'T','NC_FLOAT',burstid);
netcdf.putAtt(ncid,Tid,'units','degC');
netcdf.putAtt(ncid,Tid,'long_name','sea_water_temperature');

TQid = netcdf.defVar(ncid,'T_status','NC_INT',[burstid,QAQCid]);
netcdf.putAtt(ncid,TQid,'long_name','temperature_status_flag');
netcdf.putAtt(ncid,TQid,'note',QAQCnote);

Sid = netcdf.defVar(ncid,'S','NC_FLOAT',burstid);
netcdf.putAtt(ncid,Sid,'units','psu');
netcdf.putAtt(ncid,Sid,'long_name','sea_water_salinity');
netcdf.putAtt(ncid,Sid,'note','constant used, not measured');

SQid = netcdf.defVar(ncid,'S_status','NC_INT',[burstid,QAQCid]);
netcdf.putAtt(ncid,SQid,'long_name','salinity_status_flag');
netcdf.putAtt(ncid,SQid,'note',QAQCnote);

DOid = netcdf.defVar(ncid,'DO','NC_FLOAT',burstid);
netcdf.putAtt(ncid,DOid,'units','mg/L');
netcdf.putAtt(ncid,DOid,'long_name','oxygen_concentration_in_sea_water');

DOQid = netcdf.defVar(ncid,'DO_status','NC_INT',[burstid,QAQCid]);
netcdf.putAtt(ncid,DOQid,'long_name','DO_status_flag');
netcdf.putAtt(ncid,DOQid,'note',QAQCnote);

Pid = netcdf.defVar(ncid,'P','NC_FLOAT',burstid);
netcdf.putAtt(ncid,Pid,'units','dbar');
netcdf.putAtt(ncid,Pid,'long_name','sea_water_pressure');
netcdf.putAtt(ncid,Pid,'note','pressure at transducer, relative to 1 atm.');

PQid = netcdf.defVar(ncid,'P_status','NC_INT',[burstid,QAQCid]);
netcdf.putAtt(ncid,PQid,'long_name','sea_water_pressure_status_flag');
netcdf.putAtt(ncid,PQid,'note',QAQCnote);

Cid = netcdf.defVar(ncid,'C','NC_FLOAT',burstid);
netcdf.putAtt(ncid,Cid,'units','S/m');
netcdf.putAtt(ncid,Cid,'long_name','sea_water_electrical_conductivity');

CQid = netcdf.defVar(ncid,'C_status','NC_INT',[burstid,QAQCid]);
netcdf.putAtt(ncid,CQid,'long_name','sea_water_conductivity_status_flag');
netcdf.putAtt(ncid,CQid,'note',QAQCnote);

rhoid = netcdf.defVar(ncid,'rho','NC_FLOAT',burstid);
netcdf.putAtt(ncid,rhoid,'units','kg/m^3');
netcdf.putAtt(ncid,rhoid,'long_name','sea_water_density');
netcdf.putAtt(ncid,rhoid,'note','computed from salinity and temp');

rhoQid = netcdf.defVar(ncid,'rho_status','NC_INT',[burstid,QAQCid]);
netcdf.putAtt(ncid,rhoQid,'long_name','sea_water_density_status_flag');
netcdf.putAtt(ncid,rhoQid,'note',QAQCnote);

DOsatid = netcdf.defVar(ncid,'DOsat','NC_FLOAT',burstid);
netcdf.putAtt(ncid,DOsatid,'units','none (%)');
netcdf.putAtt(ncid,DOsatid,'long_name','fractional_saturation_of_oxygen_in_sea_water');

DOsatQid = netcdf.defVar(ncid,'DOsat_status','NC_INT',[burstid,QAQCid]);
netcdf.putAtt(ncid,DOsatQid,'long_name','DO_sat_status_flag');
netcdf.putAtt(ncid,DOsatQid,'note',QAQCnote);

pHid = netcdf.defVar(ncid,'pH','NC_FLOAT',burstid);
netcdf.putAtt(ncid,pHid,'units','none');
netcdf.putAtt(ncid,pHid,'long_name','pH - acidity');

pHQid = netcdf.defVar(ncid,'pH_status','NC_INT',[burstid,QAQCid]);
netcdf.putAtt(ncid,pHQid,'long_name','pH_status_flag');
netcdf.putAtt(ncid,pHQid,'note',QAQCnote);

netcdf.endDef(ncid);

% Put into data mode
netcdf.putVar(ncid, timeid, days(d.time(:)-datetime(1970,1,1,0,0,0)));
netcdf.putVar(ncid, depthid, d.depth);
netcdf.putVar(ncid, Tid, d.T.data);
netcdf.putVar(ncid, Sid, d.S.data);
netcdf.putVar(ncid, DOid, d.DO.data);
netcdf.putVar(ncid, Pid, d.P.data);
netcdf.putVar(ncid, Cid, d.C.data);
netcdf.putVar(ncid, rhoid, d.rho.data);
netcdf.putVar(ncid, DOsatid, d.DOsat.data);
netcdf.putVar(ncid, pHid, d.pH.data);

% Write Flags
netcdf.putVar(ncid, TQid, [d.T.QAQC,d.T.FailedCount]);
netcdf.putVar(ncid, SQid, [d.S.QAQC,d.S.FailedCount]);
netcdf.putVar(ncid, DOQid, [d.DO.QAQC,d.DO.FailedCount]);
netcdf.putVar(ncid, PQid, [d.P.QAQC,d.P.FailedCount]);
netcdf.putVar(ncid, CQid, [d.C.QAQC,d.C.FailedCount]);
netcdf.putVar(ncid, rhoQid, [d.rho.QAQC,d.rho.FailedCount]);
netcdf.putVar(ncid, DOsatQid, [d.DOsat.QAQC,d.DOsat.FailedCount]);
netcdf.putVar(ncid, pHQid, [d.pH.QAQC,d.pH.FailedCount]);

netcdf.close(ncid);

end