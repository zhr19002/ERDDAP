% 
% Identify and flag buoy meteorology data outliers
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 
% Calls ImplementJumpLimTest.m
% Calls WriteMetNETCDF.m
% 

clc; clear;
buoy = 'ARTG'; % {'ARTG','CLIS1','CLIS2','EXRX','WLIS'}
metVars = {'windSpd_Kts','windSpd_Max','fiveSecAvg_Max','windDir_M', ...
           'airTemp_Avg','relHumid_Avg','baroPress_Avg','dewPT_Avg'};
tVars = [{'TmStamp','RecNum'}, metVars, {'longitude','latitude','depth'}];

% Read meteorology QAQC parameters
QAQC = readtable('QAQC_Para_Met.csv', ReadRowNames=true);

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
        dT = sqlread(conn, append('"', dbname, '"'));
    case 'CLIS1'
        dbname = "clis_cr1xPB4_metDat";
        dT = sqlread(conn, append('"', dbname, '"'));
        dT = renamevars(dT,'windSpd_kts','windSpd_Kts');
    case 'CLIS2'
        dbname = "clis_cr1xPB4_metRO";
        dT = sqlread(conn, append('"', dbname, '"'));
        dT = renamevars(dT,'windSpd_kts','windSpd_Kts');
    case 'EXRX'
        dbname1 = "EXRX_pb2_metDat_arch1";
        buoyMet1 = sqlread(conn, append('"', dbname1, '"'));
        dbname2 = "EXRX_pb1_metRO";
        buoyMet2 = sqlread(conn, append('"', dbname2, '"'));
        buoyMet2 = renamevars(buoyMet2,'dewPt_Avg','dewPT_Avg');
        dT = [buoyMet1(:,tVars); buoyMet2(:,tVars)];
    case 'WLIS'
        dbname = "WLIS_pb1_metDat";
        dT = sqlread(conn, append('"', dbname, '"'));
end

dT = dT(:,tVars);
dT = sortrows(dT, 'TmStamp');
close(conn);

MetQAQC.time = dT.TmStamp;
for av = metVars
    % Clean meteorology data
    dT.(av{1})(dT.(av{1}) < -1000) = NaN;
    % Form QAQC structure
    MetQAQC.(av{1}).data = dT.(av{1});
    if ismember(av{1}, "windDir_M")
        % Jump limit test
        d_tmp = cos(dT.(av{1})*pi/180);
        MetQAQC.(av{1}).jumpCheck = ImplementJumpLimTest(d_tmp);
    else
        d_tmp = MetQAQC.(av{1}).data;
        MetQAQC.(av{1}).check = ones(size(dT.TmStamp));
        % Threshold test
        iu = find(d_tmp<QAQC.(av{1})('min_val') | d_tmp>QAQC.(av{1})('max_val') | isnan(d_tmp));
        if ~isempty(iu)
            MetQAQC.(av{1}).check(iu) = 4;
        end
        % Jump limit test
        if ismember(av{1}, "windSpd_Kts")
            MetQAQC.(av{1}).jumpCheck = ImplementJumpLimTest(d_tmp);
        end
    end
end

% Save QAQC results
save(['Buoy_' buoy '_Met_QAQC.mat'], 'MetQAQC');

%%
% Save all the data plotted in a structure that can be exported to NETCDF
latlon = [mode(dT.latitude), mode(dT.longitude)];
stnDep = mode(dT.depth);
WriteMetNETCDF(buoy, latlon, stnDep, MetQAQC);