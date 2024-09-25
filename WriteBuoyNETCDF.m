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

% Make NC files
ncid = netcdf.create([buoy '_' loc '.nc'],'64BIT_OFFSET');

% Global attributes
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

% Define variables
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

avars = {'T','S','DO','P','C','pH','rho','DOsat'};
units = {'celsius','psu','mg/L','dBars','S/m','none','kg/m^3','percent'};
names = {'sea_water_temperature','sea_water_salinity', ...
         'oxygen_concentration_in_sea_water','sea_water_pressure', ...
         'sea_water_conductivity','pH','sea_water_density','percent_saturation'};

id = cell(1,length(avars)); idQ = cell(1,length(avars));
for i = 1:length(avars)
    id{i} = netcdf.defVar(ncid, avars{i}, 'NC_FLOAT', burstid);
    netcdf.putAtt(ncid, id{i}, 'units', units{i});
    netcdf.putAtt(ncid, id{i}, 'long_name', names{i});
    idQ{i} = netcdf.defVar(ncid, [avars{i} '_Q'], 'NC_INT', [burstid,QAQCid]);
    netcdf.putAtt(ncid, idQ{i}, 'long_name', [names{i} '_flag']);
    netcdf.putAtt(ncid, idQ{i}, 'note', QAQCnote);
end

netcdf.endDef(ncid);

% Put into data mode
netcdf.putVar(ncid,timeid,days(d.time(:)-datetime(1970,1,1,0,0,0)));
netcdf.putVar(ncid, depthid, d.depth);
for i = 1:length(avars)
    netcdf.putVar(ncid, id{i}, d.(avars{i}).data);
    netcdf.putVar(ncid, idQ{i}, [d.(avars{i}).QAQC,d.(avars{i}).FailedCount]);
end

netcdf.close(ncid);

end