function d = OutputARTG2022_pH_NCFILE(ncfile, d, meta, gb_range)
% 
% Make NCFILE of the pH data from ArtG 2021
% 
% Called from Proc2021_pH_data.m
% 

QAQCnote = ['QAQC tests: (1) Threshold, (2) first difference, (3)time gap, '...
            '(4) pressure range (5) spike; 0= not applied/implemented; 1=pass; '...
            '3=questionable; 4=fail.Last column is number of tests applied.'];

ncid = netcdf.create(ncfile,'64BIT_OFFSET');
d.UCT = datetime(d.TIMESTAMP) - datetime(1970,1,1); % Convert to UCT

% Check ens3 range
if isempty(gb_range)
    gb_range=[1 length(d.UCT)];
end

% DIMENSIONS (number of sample times and QAQC checks)
burstid = netcdf.defDim(ncid,'burst',length(d.UCT(gb_range(1):gb_range(2))));
QAQCid = netcdf.defDim(ncid,'QAQC',size(d.pHpHQAQC,2));

% GLOBAL ATTRIBUTES
varid = netcdf.getConstant('NC_GLOBAL');
netcdf.putAtt(ncid,varid,'Processing_Notes',meta.Processing_Notes);
netcdf.putAtt(ncid,varid,'mooring_name',meta.mooring_name);
% netcdf.putAtt(ncid,varid,'deployment_date',meta.depdate-day0);
% netcdf.putAtt(ncid,varid,'recovery_date',meta.recdate-day0);
netcdf.putAtt(ncid,varid,'latitude',meta.lat);
netcdf.putAtt(ncid,varid,'longitude',meta.lon);
netcdf.putAtt(ncid,varid,'latitude_units','decimal degrees');
netcdf.putAtt(ncid,varid,'longitude_units','decimal degrees');
netcdf.putAtt(ncid,varid,'water_depth',meta.water_depth);
netcdf.putAtt(ncid,varid,'water_depth_units','m');
netcdf.putAtt(ncid,varid,'water_depth_method',meta.depth_source);
netcdf.putAtt(ncid,varid,'PI',meta.PI);
netcdf.putAtt(ncid,varid,'processed_by',meta.processed_by);
ad = string(datetime(datetime('now'), 'Format', 'yyyy/MM/dd HH:mm:SS'));
netcdf.putAtt(ncid,varid,'CreationDate',ad);
netcdf.putAtt(ncid,varid,'institution','UConn, Marine Sciences');
netcdf.putAtt(ncid,varid,'source','LISICOS-NERACOOS Observations');
% netcdf.putAtt(ncid,varid,'title',meta.lab);

% DEFINE VARIABLES
timeid = netcdf.defVar(ncid,'time','double',burstid);
netcdf.putAtt(ncid,timeid,'standard_name','time');
netcdf.putAtt(ncid,timeid,'units','days since midnight January 1, 1970');
netcdf.putAtt(ncid,timeid,'calendar','julian');
netcdf.putAtt(ncid,timeid,'time_zone',meta.time_zone);
netcdf.putAtt(ncid,timeid,'axis','T');

pHid = netcdf.defVar(ncid,'pHpH','float',burstid);
netcdf.putAtt(ncid,pHid,'units','none');
netcdf.putAtt(ncid,pHid,'long_name','pH');

pHQid = netcdf.defVar(ncid,'pHpHQAQC','byte',[burstid,QAQCid]); 
netcdf.putAtt(ncid,pHQid,'long_name','pHpHQAQC_status_flag');
netcdf.putAtt(ncid,pHQid,'note',QAQCnote); 
 
netcdf.endDef(ncid);

% Put into data mode
data = d.UCT(gb_range(1):gb_range(2)) - datetime(1970,1,1);
netcdf.putVar(ncid,timeid,data);

data = d.pHpH(gb_range(1):gb_range(2));
netcdf.putVar(ncid,pHid,data);

% Write Flags
data = d.pHpHQAQC(gb_range(1):gb_range(2),:);
netcdf.putVar(ncid,pHQid,data);

% Wrap up
netcdf.close(ncid);

end