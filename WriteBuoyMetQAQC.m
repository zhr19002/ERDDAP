% 
% Calls WriteNETCDFbuoyMet.m
% 

clc; clear;
buoy = 'ARTG'; % {'ARTG','CLIS1','CLIS2','EXRX','WLIS'}
metVars = {'windSpd_Kts','windDir_M','windDir_STD','windSpd_Max','windDir_SMM', ...
           'fiveSecAvg_Max','airTemp_Avg','relHumid_Avg','baroPress_Avg','dewPT_Avg'};
tVars = [{'TmStamp','RecNum'}, metVars, {'longitude','latitude','depth'}];

% Read QAQC parameters
MET_QAQC = readtable('MET_QAQC_Para.csv', ReadRowNames=true);

% Connect to database
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','provLNDB','PortNumber',5432);

% tbldata = sqlfind(conn,"")

% Extract tables from database
switch buoy
    case 'ARTG'
        dbname = "ARTG_pb2_metDat";
        buoyMet = sqlread(conn, append('"', dbname, '"'));
        buoyMet.('windDir_STD') = NaN(height(buoyMet),1);
    case 'CLIS1'
        dbname = "clis_cr1xPB4_metDat";
        buoyMet = sqlread(conn, append('"', dbname, '"'));
        buoyMet = renamevars(buoyMet,'windSpd_kts','windSpd_Kts');
    case 'CLIS2'
        dbname = "clis_cr1xPB4_metRO";
        buoyMet = sqlread(conn, append('"', dbname, '"'));
        buoyMet = renamevars(buoyMet,'windSpd_kts','windSpd_Kts');
    case 'EXRX'
        dbname1 = "EXRX_pb2_metDat_arch1";
        buoyMet1 = sqlread(conn, append('"', dbname1, '"'));
        buoyMet1.('windDir_STD') = NaN(height(buoyMet1),1);
        dbname2 = "EXRX_pb1_metRO";
        buoyMet2 = sqlread(conn, append('"', dbname2, '"'));
        buoyMet2 = renamevars(buoyMet2,'dewPt_Avg','dewPT_Avg');
        buoyMet = [buoyMet1(:,tVars); buoyMet2(:,tVars)];
    case 'WLIS'
        dbname = "WLIS_pb1_metDat";
        buoyMet = sqlread(conn, append('"', dbname, '"'));
end

buoyMet = buoyMet(:,tVars);
buoyMet = sortrows(buoyMet, 'TmStamp');
close(conn);

MetQAQC.time = buoyMet.TmStamp;
for av = metVars
    % Clean MET data
    buoyMet.(av{1})(buoyMet.(av{1}) < -1000) = NaN;
    % Form QAQC structure
    MetQAQC.(av{1}).data = buoyMet.(av{1});
    MetQAQC.(av{1}).check = ones(size(buoyMet.TmStamp));
    % Check max-min thresholds
    d_tmp = MetQAQC.(av{1}).data;
    iu1 = find(d_tmp < MET_QAQC.(av{1})('Min_Value') | ...
               d_tmp > MET_QAQC.(av{1})('Max_Value') | ...
               isnan(d_tmp));
    if ~isempty(iu1)
        MetQAQC.(av{1}).check(iu1) = 4;
    end
end

% Save QAQC results
save([buoy '_MET_QAQC.mat'], 'MetQAQC');

%%
% Save all the data plotted in a structure that can be exported to NETCDF
latlon = [mode(buoyMet.latitude), mode(buoyMet.longitude)];
stnDep = mode(buoyMet.depth);
WriteNETCDFbuoyMet(buoy, latlon, stnDep, MetQAQC);