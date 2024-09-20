function WriteWaveNETCDF(buoy, latlon, stnDep, d)
% 
% Write buoy wave QAQC data to NC files
% 
% Called from WriteWaveDataQAQC.m
% 

meta.Processing_Notes = 'Screened with WriteWaveDataQAQC.m';
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
            '(4) spike; 1 = pass; 3 = questionable; 4 = fail. ' ...
            'Last column is the number of failed tests.'];

% Make NC files
ncid = netcdf.create([buoy '_Wave.nc'],'64BIT_OFFSET');

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
netcdf.putVar(ncid,timeid,days(d.time(:)-datetime(1970,1,1,0,0,0)));

waveVars = {'Hsig_m','Hmax_m','Tdom_s','Tavg_s','waveDir','meanDir'};
units = {'m','m','s','s','degrees','degrees'};
names = {'significant_wave_height','max_wave_height','dominant_wave_period', ...
         'average_wave_period','principal_wave_direction','mean_wave_direction'};

for i = 1:length(waveVars)
    % Define variable
    id = netcdf.defVar(ncid, waveVars{i}, 'NC_FLOAT', burstid);
    netcdf.putAtt(ncid, id, 'units', units{i});
    netcdf.putAtt(ncid, id, 'long_name', names{i});
    idQ = netcdf.defVar(ncid, [waveVars{i} '_Q'], 'NC_INT', [burstid,QAQCid]);
    netcdf.putAtt(ncid, idQ, 'long_name', [names{i} '_flag']);
    netcdf.putAtt(ncid, idQ, 'note', QAQCnote);
    % Put into data mode
    netcdf.putVar(ncid, id, d.(waveVars{i}).data);
    % Write flag
    netcdf.putVar(ncid, idQ, [d.(waveVars{i}).QAQC,d.(waveVars{i}).FailedCount]);
end

netcdf.close(ncid);

end