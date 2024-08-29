function WriteWaveNETCDF(buoy, latlon, stnDep, d)
% 
% Write wave QAQC data to NC files
% 
% Called from WriteWaveDataQAQC.m
% 

meta.Processing_Notes = 'Screened with WriteBuoyMetQAQC.m';
meta.mooring_name = buoy;
meta.lat = latlon(1,1);
meta.lon = latlon(1,2);
meta.water_depth = stnDep;
meta.depth_source = 'Ship range';
meta.PI = 'James O''Donnell, UCONN Marine Sciences & CIRCA';
meta.processed_by = 'James O''Donnell, james.odonnell@uconn.edu';
meta.lab = 'Data from LISICOS moored sensors';
meta.time_zone = 'EST';

QAQCnote = '1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range';

% Make NC file
ncid = netcdf.create([buoy '_Wave.nc'],'64BIT_OFFSET');

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

Hsigid = netcdf.defVar(ncid,'Hsig','NC_FLOAT',burstid);
netcdf.putAtt(ncid,Hsigid,'units','m');
netcdf.putAtt(ncid,Hsigid,'long_name','significant_wave_height');

HsigQid = netcdf.defVar(ncid,'HsigQ','NC_INT',burstid);
netcdf.putAtt(ncid,HsigQid,'long_name','significant_wave_height_flag');
netcdf.putAtt(ncid,HsigQid,'note',QAQCnote);

Hmaxid = netcdf.defVar(ncid,'Hmax','NC_FLOAT',burstid);
netcdf.putAtt(ncid,Hmaxid,'units','m');
netcdf.putAtt(ncid,Hmaxid,'long_name','max_wave_height');

HmaxQid = netcdf.defVar(ncid,'HmaxQ','NC_INT',burstid);
netcdf.putAtt(ncid,HmaxQid,'long_name','max_wave_height_flag');
netcdf.putAtt(ncid,HmaxQid,'note',QAQCnote);

Tdomid = netcdf.defVar(ncid,'Tdom','NC_FLOAT',burstid);
netcdf.putAtt(ncid,Tdomid,'units','s');
netcdf.putAtt(ncid,Tdomid,'long_name','dominant_wave_period');

TdomQid = netcdf.defVar(ncid,'TdomQ','NC_INT',burstid);
netcdf.putAtt(ncid,TdomQid,'long_name','dominant_wave_period_flag');
netcdf.putAtt(ncid,TdomQid,'note',QAQCnote);

Tavgid = netcdf.defVar(ncid,'Tavg','NC_FLOAT',burstid);
netcdf.putAtt(ncid,Tavgid,'units','s');
netcdf.putAtt(ncid,Tavgid,'long_name','average_wave_period');

TavgQid = netcdf.defVar(ncid,'TavgQ','NC_INT',burstid);
netcdf.putAtt(ncid,TavgQid,'long_name','average_wave_period_flag');
netcdf.putAtt(ncid,TavgQid,'note',QAQCnote);

DP1id = netcdf.defVar(ncid,'DP1','NC_FLOAT',burstid);
netcdf.putAtt(ncid,DP1id,'units','xxx');
netcdf.putAtt(ncid,DP1id,'long_name','xxx');

DP1Qid = netcdf.defVar(ncid,'DP1Q','NC_INT',burstid);
netcdf.putAtt(ncid,DP1Qid,'long_name','xxx_flag');
netcdf.putAtt(ncid,DP1Qid,'note',QAQCnote);

DP2id = netcdf.defVar(ncid,'DP2','NC_FLOAT',burstid);
netcdf.putAtt(ncid,DP2id,'units','xxx');
netcdf.putAtt(ncid,DP2id,'long_name','xxx');

DP2Qid = netcdf.defVar(ncid,'DP2Q','NC_INT',burstid);
netcdf.putAtt(ncid,DP2Qid,'long_name','xxx_flag');
netcdf.putAtt(ncid,DP2Qid,'note',QAQCnote);

waveDirid = netcdf.defVar(ncid,'waveDir','NC_FLOAT',burstid);
netcdf.putAtt(ncid,waveDirid,'units','degrees');
netcdf.putAtt(ncid,waveDirid,'long_name','principal_wave_direction');
netcdf.putAtt(ncid,waveDirid,'note','convert angle value to cos value');

waveDirQid = netcdf.defVar(ncid,'waveDirQ','NC_INT',burstid);
netcdf.putAtt(ncid,waveDirQid,'long_name','principal_wave_direction_flag');
netcdf.putAtt(ncid,waveDirQid,'note',QAQCnote);

meanDirid = netcdf.defVar(ncid,'meanDir','NC_FLOAT',burstid);
netcdf.putAtt(ncid,meanDirid,'units','degrees');
netcdf.putAtt(ncid,meanDirid,'long_name','mean_wave_direction');
netcdf.putAtt(ncid,meanDirid,'note','convert angle value to cos value');

meanDirQid = netcdf.defVar(ncid,'meanDirQ','NC_INT',burstid);
netcdf.putAtt(ncid,meanDirQid,'long_name','mean_wave_direction_flag');
netcdf.putAtt(ncid,meanDirQid,'note',QAQCnote);

rmsTiltid = netcdf.defVar(ncid,'rmsTilt','NC_FLOAT',burstid);
netcdf.putAtt(ncid,rmsTiltid,'units','xxx');
netcdf.putAtt(ncid,rmsTiltid,'long_name','xxx');

rmsTiltQid = netcdf.defVar(ncid,'rmsTiltQ','NC_INT',burstid);
netcdf.putAtt(ncid,rmsTiltQid,'long_name','xxx_flag');
netcdf.putAtt(ncid,rmsTiltQid,'note',QAQCnote);

maxTiltid = netcdf.defVar(ncid,'maxTilt','NC_FLOAT',burstid);
netcdf.putAtt(ncid,maxTiltid,'units','xxx');
netcdf.putAtt(ncid,maxTiltid,'long_name','xxx');

maxTiltQid = netcdf.defVar(ncid,'maxTiltQ','NC_INT',burstid);
netcdf.putAtt(ncid,maxTiltQid,'long_name','xxx_flag');
netcdf.putAtt(ncid,maxTiltQid,'note',QAQCnote);

GNid = netcdf.defVar(ncid,'GN','NC_FLOAT',burstid);
netcdf.putAtt(ncid,GNid,'units','xxx');
netcdf.putAtt(ncid,GNid,'long_name','xxx');

GNQid = netcdf.defVar(ncid,'GNQ','NC_INT',burstid);
netcdf.putAtt(ncid,GNQid,'long_name','xxx_flag');
netcdf.putAtt(ncid,GNQid,'note',QAQCnote);

chksumid = netcdf.defVar(ncid,'chksum','NC_FLOAT',burstid);
netcdf.putAtt(ncid,chksumid,'units','xxx');
netcdf.putAtt(ncid,chksumid,'long_name','xxx');

chksumQid = netcdf.defVar(ncid,'chksumQ','NC_INT',burstid);
netcdf.putAtt(ncid,chksumQid,'long_name','xxx_flag');
netcdf.putAtt(ncid,chksumQid,'note',QAQCnote);

netcdf.endDef(ncid);

% Put into data mode
netcdf.putVar(ncid, timeid, days(d.time(:)-datetime(1970,1,1,0,0,0)));
netcdf.putVar(ncid, Hsigid, d.Hsig_m.data);
netcdf.putVar(ncid, Hmaxid, d.Hmax_m.data);
netcdf.putVar(ncid, Tdomid, d.Tdom_s.data);
netcdf.putVar(ncid, Tavgid, d.Tavg_s.data);
netcdf.putVar(ncid, DP1id, d.DP1.data);
netcdf.putVar(ncid, DP2id, d.DP2.data);
netcdf.putVar(ncid, waveDirid, d.waveDir.data);
netcdf.putVar(ncid, meanDirid, d.meanDir.data);
netcdf.putVar(ncid, rmsTiltid, d.rmsTilt.data);
netcdf.putVar(ncid, maxTiltid, d.maxTilt.data);
netcdf.putVar(ncid, GNid, d.GN.data);
netcdf.putVar(ncid, chksumid, d.chksum.data);

% Write Flags
netcdf.putVar(ncid, HsigQid, d.Hsig_m.check);
netcdf.putVar(ncid, HmaxQid, d.Hmax_m.check);
netcdf.putVar(ncid, TdomQid, d.Tdom_s.check);
netcdf.putVar(ncid, TavgQid, d.Tavg_s.check);
netcdf.putVar(ncid, DP1Qid, d.DP1.check);
netcdf.putVar(ncid, DP2Qid, d.DP2.check);
netcdf.putVar(ncid, waveDirQid, d.waveDir.jumpCheck);
netcdf.putVar(ncid, meanDirQid, d.meanDir.jumpCheck);
netcdf.putVar(ncid, rmsTiltQid, d.rmsTilt.check);
netcdf.putVar(ncid, maxTiltQid, d.maxTilt.check);
netcdf.putVar(ncid, GNQid, d.GN.check);
netcdf.putVar(ncid, chksumQid, d.chksum.check);

netcdf.close(ncid);

end