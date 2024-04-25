function WriteNC_Buoyfiles(ncfile, d, meta, gb_range)
% 
% Output the buoy data in d, all records at a fixed level, to nc file
% 
% gb_range is the number of time samples to write to nc file
% 
% Called from WriteNETCDFbuoyfile.m
% 

QAQCnote = ['QAQC tests: (1) Threshold, (2) first difference, (3)time gap, '...
            '(4) pressure range (5) spike; 0=not applied/implemented; 1=pass; '...
            '3=questionable; 4=fail.Last column is number of tests applied.'];

% Make nc file
ncid = netcdf.create(ncfile ,'64BIT_OFFSET');

if isempty(gb_range)
    gb_range = [1 length(d.EST)];
end 

% DIMENSIONS (number of sample times and QAQC checks)
burstid = netcdf.defDim(ncid,'burst',length(d.EST(gb_range(1):gb_range(2))));
QAQCid = netcdf.defDim(ncid,'QAQC',size(d.prdMQAQC,2));

% GLOBAL ATTRIBUTES
varid = netcdf.getConstant('NC_GLOBAL');
netcdf.putAtt(ncid,varid,'Processing_Notes',meta.Processing_Notes);
netcdf.putAtt(ncid,varid,'mooring_name',meta.mooring_name);
%netcdf.putAtt(ncid,varid,'deployment_date',meta.depdate-datetime(1970,1,1));
%netcdf.putAtt(ncid,varid,'recovery_date',meta.recdate-datetime(1970,1,1));
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
netcdf.putAtt(ncid,varid,'institution','UConn, Marine Sciences');
netcdf.putAtt(ncid,varid,'source','LISICOS-NERACOOS Observations');
% netcdf.putAtt(ncid,varid,'title',meta.lab);

% DEFINE VARIABLES
timeid = netcdf.defVar(ncid,'time','NC_DOUBLE',burstid);
netcdf.putAtt(ncid,timeid,'standard_name','time');
netcdf.putAtt(ncid,timeid,'units','days since midnight January 1, 1970');
netcdf.putAtt(ncid,timeid,'calendar','julian');
netcdf.putAtt(ncid,timeid,'time_zone',meta.time_zone);
netcdf.putAtt(ncid,timeid,'axis','T');

tempid = netcdf.defVar(ncid,'temp','NC_FLOAT',burstid);
netcdf.putAtt(ncid,tempid,'units','C');
netcdf.putAtt(ncid,tempid,'long_name','water temperature');

saltid = netcdf.defVar(ncid,'salt','NC_FLOAT',burstid);
netcdf.putAtt(ncid,saltid,'units','PSU');
netcdf.putAtt(ncid,saltid,'long_name','salinity');
netcdf.putAtt(ncid,saltid,'note','constant used, not measured');

pressid = netcdf.defVar(ncid,'press','NC_FLOAT',burstid);
netcdf.putAtt(ncid,pressid,'units','10^4 Pascals (or m)');
netcdf.putAtt(ncid,pressid,'long_name','pressure');
netcdf.putAtt(ncid,pressid,'note','pressure at transducer, relative to 1 atm.');

rhoid = netcdf.defVar(ncid,'rho','NC_FLOAT',burstid);
netcdf.putAtt(ncid,rhoid,'units','kg/m^3');
netcdf.putAtt(ncid,rhoid,'long_name','sea_water_density');
netcdf.putAtt(ncid,rhoid,'note','computed from salinity and temp');

DOconcid = netcdf.defVar(ncid,'DOconc','NC_FLOAT',burstid);
netcdf.putAtt(ncid,DOconcid,'units','mg/l');
netcdf.putAtt(ncid,DOconcid,'long_name','mass_concentration_of_oxygen_in_sea_water');
 
DOsatid = netcdf.defVar(ncid,'DOsat','NC_FLOAT',burstid);
netcdf.putAtt(ncid,DOsatid,'units',' none (%)');
netcdf.putAtt(ncid,DOsatid,'long_name','fractional_saturation_of_oxygen_in_sea_water');


if isfield(d, 'pH')
    pHid = netcdf.defVar(ncid,'pH','NC_FLOAT',burstid);
    netcdf.putAtt(ncid,pHid,'units','none');
    netcdf.putAtt(ncid,pHid,'long_name','pH - acidity');
    
    pHQid = netcdf.defVar(ncid,'pH_status','NC_BYTE',[burstid, QAQCid]); 
    netcdf.putAtt(ncid,pHQid,'long_name','pH status_flag');
    netcdf.putAtt(ncid,pHQid,'note',QAQCnote);  
end    

tempQid = netcdf.defVar(ncid,'temp_status','NC_BYTE',[burstid, QAQCid]); 
netcdf.putAtt(ncid,tempQid,'long_name','emperature_status_flag');
netcdf.putAtt(ncid,tempQid,'note',QAQCnote); 
 
saltQid = netcdf.defVar(ncid,'salt_status','NC_BYTE',[burstid, QAQCid]); 
netcdf.putAtt(ncid,saltQid,'long_name','salinity_status_flag');
netcdf.putAtt(ncid,saltQid,'note',QAQCnote);

pressQid = netcdf.defVar(ncid,'press_status','NC_BYTE',[burstid, QAQCid]); 
netcdf.putAtt(ncid,pressQid,'long_name','Seawater_pressure_status_flag');
netcdf.putAtt(ncid,pressQid,'note',QAQCnote);

rhoQid = netcdf.defVar(ncid,'rho_status','NC_BYTE',[burstid, QAQCid]); 
netcdf.putAtt(ncid,rhoQid,'long_name','Seawater_Density_status_flag');
netcdf.putAtt(ncid,rhoQid,'note',QAQCnote);

DOsatQid = netcdf.defVar(ncid,'DOsat_status','NC_BYTE',[burstid, QAQCid]); 
netcdf.putAtt(ncid,DOsatQid,'long_name','DO_sat_status_flag');
netcdf.putAtt(ncid,DOsatQid,'note',QAQCnote);

DOconcQid = netcdf.defVar(ncid,'DOconc_status','NC_BYTE',[burstid, QAQCid]); 
netcdf.putAtt(ncid,DOconcQid,'long_name','DO_conc_status_flag');
netcdf.putAtt(ncid,DOconcQid,'note',QAQCnote);

netcdf.endDef(ncid);

% Put into data mode
data = d.EST(gb_range(1):gb_range(2)) - d.EST(gb_range(1));
netcdf.putVar(ncid,timeid,data);

data = d.tv290Cq(gb_range(1):gb_range(2));
netcdf.putVar(ncid,tempid,data);

data = d.sal00q(gb_range(1):gb_range(2));
netcdf.putVar(ncid,saltid,data);
 
data = d.prdMq(gb_range(1):gb_range(2));
netcdf.putVar(ncid,pressid,data);

data = d.rhoq(gb_range(1):gb_range(2));
netcdf.putVar(ncid,rhoid,data);

data = d.DOsatq(gb_range(1):gb_range(2));
netcdf.putVar(ncid,DOsatid,data);

data = d.sbeopoxMgq(gb_range(1):gb_range(2));
netcdf.putVar(ncid,DOconcid,data);
 
% Write Flags
data = d.tv290CQAQC(gb_range(1):gb_range(2),:);
netcdf.putVar(ncid,tempQid,data);

data = d.sal00QAQC(gb_range(1):gb_range(2),:);
netcdf.putVar(ncid,saltQid,data);
 
data = d.prdMQAQC(gb_range(1):gb_range(2),:);
netcdf.putVar(ncid,pressQid,data);

data = d.rhoQAQC(gb_range(1):gb_range(2),:);
netcdf.putVar(ncid,rhoQid,data);

data = d.DOsatQAQC(gb_range(1):gb_range(2),:);
netcdf.putVar(ncid,DOsatQid,data);

data = d.sbeopoxMgQAQC(gb_range(1):gb_range(2),:);
netcdf.putVar(ncid,DOconcQid,data);

if isfield(d, 'pH')
    data = d.pH(gb_range(1):gb_range(2));
    netcdf.putVar(ncid,pHid,data);
    
    data = d.pHQAQC(gb_range(1):gb_range(2),:);
    netcdf.putVar(ncid,pHQid,data);
end

% Wrap up
netcdf.close(ncid);

end