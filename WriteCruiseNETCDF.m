function WriteCruiseNETCDF(cruise, Astn, dp_rng, latlon, stnDep, d)
% 
% Write cruise QAQC data to NC files
% 
% Called from WriteCruiseDataQAQC.m
% 

meta.Processing_Notes = 'Screened with WriteCruiseDataQAQC.m';
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

QAQCnote = '1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range';

% Make NC files
ncid = netcdf.create([cruise '_' Astn '_' dp_rng '.nc'],'64BIT_OFFSET');

% Global attributes
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

% Define variables
burstid = netcdf.defDim(ncid,'burst',size(d.time,1));

timeid = netcdf.defVar(ncid,'time','NC_DOUBLE',burstid);
netcdf.putAtt(ncid,timeid,'standard_name','time');
netcdf.putAtt(ncid,timeid,'units','days since midnight January 1, 1970');
netcdf.putAtt(ncid,timeid,'calendar','julian');
netcdf.putAtt(ncid,timeid,'time_zone',meta.time_zone);
netcdf.putAtt(ncid,timeid,'axis','T');
netcdf.endDef(ncid);
netcdf.putVar(ncid,timeid,days(d.time(:)-datetime(1970,1,1,0,0,0)));

avars = {'T','S','DO','P','C','pH','rho','DOsat'};
units = {'celsius','psu','mg/L','dBars','S/m','none','kg/m^3','percent'};
names = {'sea_water_temperature','sea_water_salinity', ...
         'oxygen_concentration_in_sea_water','sea_water_pressure', ...
         'sea_water_conductivity','pH','sea_water_density','percent_saturation'};

for i = 1:length(avars)
    % Define variable
    id = netcdf.defVar(ncid, avars{i}, 'NC_FLOAT', burstid);
    netcdf.putAtt(ncid, id, 'units', units{i});
    netcdf.putAtt(ncid, id, 'long_name', names{i});
    idQ = netcdf.defVar(ncid, [avars{i} '_Q'], 'NC_INT', burstid);
    netcdf.putAtt(ncid, idQ, 'long_name', [names{i} '_flag']);
    netcdf.putAtt(ncid, idQ, 'note', QAQCnote);
    netcdf.endDef(ncid);
    % Put into data mode
    netcdf.putVar(ncid, id, d.(avars{i}).data);
    % Write flag
    netcdf.putVar(ncid, idQ, d.(avars{i}).check);
end

netcdf.close(ncid);

end