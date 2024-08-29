% 
% Identify and flag buoy wave data outliers
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 
% Calls ImplementJumpLimTest.m
% Calls WriteWaveNETCDF.m
% 

clc; clear;
buoy = 'CLIS'; % {'CLIS','EXRX','WLIS'}
waveVars = {'Hsig_m','Hmax_m','Tdom_s','Tavg_s','DP1','DP2', ...
            'waveDir','meanDir','rmsTilt','maxTilt','GN','chksum'};

% Read wave QAQC parameters
QAQC = readtable('QAQC_Para_Wave.csv', ReadRowNames=true);

% Connect to database
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','provLNDB','PortNumber',5432);

% tbldata = sqlfind(conn,"")

% Extract tables from database
switch buoy
    case 'CLIS'
        dbname = "clis_cr1xPB4_waveDat";
        dT = sqlread(conn, append('"', dbname, '"'));
        % Covert string values to numeric values
        for av = waveVars
            dT.(av{1}) = str2double(dT.(av{1}));
        end
    case 'EXRX'
        dbname = "EXRX_pb3_svs603hr";
        dT = sqlread(conn, append('"', dbname, '"'));
    case 'WLIS'
        dbname = "WLIS_pb3_svs603HR";
        dT = sqlread(conn, append('"', dbname, '"'));
end

dT = sortrows(dT, 'TmStamp');
close(conn);

waveQAQC.time = dT.TmStamp;
for av = waveVars
    % Form QAQC structure
    waveQAQC.(av{1}).data = dT.(av{1});
    if ismember(av{1}, ["waveDir","meanDir"])
        % Jump limit test
        d_tmp = cos(dT.(av{1})*pi/180);
        waveQAQC.(av{1}).jumpCheck = ImplementJumpLimTest(d_tmp);
    else
        d_tmp = waveQAQC.(av{1}).data;
        waveQAQC.(av{1}).check = ones(size(dT.TmStamp));
        % Threshold test
        iu = find(d_tmp<QAQC.(av{1})('min_val') | d_tmp>QAQC.(av{1})('max_val') | isnan(d_tmp));
        if ~isempty(iu)
            waveQAQC.(av{1}).check(iu) = 4;
        end
    end
end

% Save QAQC results
save(['Buoy_' buoy '_Wave_QAQC.mat'], 'waveQAQC');

%%
% Save all the data plotted in a structure that can be exported to NETCDF
latlon = [mode(dT.latitude), mode(dT.longitude)];
stnDep = mode(dT.depth);
WriteWaveNETCDF(buoy, latlon, stnDep, waveQAQC);