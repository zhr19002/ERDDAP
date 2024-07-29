% 
% Calls WriteNETCDFbuoyMet.m
% 

clc; clear;
% {'ARTG', 'CLIS', 'EXRX', 'WLIS', 'clis_cr1xPB4'}
buoy = 'ARTG';
metVars = {'windSpd_Kts','windDir_M','windDir_STD','windSpd_Max','windDir_SMM', ...
           'fiveSecAvg_Max','airTemp_Avg','relHumid_Avg','baroPress_Avg','dewPT_Avg'};
% Read QAQC parameters
MET_QAQC = readtable('MET_QAQC_Para.csv', ReadRowNames=true);

% Connect to database
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','provLNDB','PortNumber',5432);

% tbldata = sqlfind(conn,"")

% Extract tables from database
dbname = append(buoy, "_pb2_metDat");
buoyMet = sqlread(conn, append('"', dbname, '"'));
buoyMet = sortrows(buoyMet, 'TmStamp');
close(conn);

% Make variable names consistent
tbvars = categorical(buoyMet.Properties.VariableNames);
if iscategory(tbvars, 'windSpd_kts')
    buoyMet = renamevars(buoyMet, 'windSpd_kts', 'windSpd_Kts');
end
if iscategory(tbvars, 'dewPt_Avg')
    buoyMet = renamevars(buoyMet, 'dewPt_Avg', 'dewPT_Avg');
end
tbvars = categorical(buoyMet.Properties.VariableNames);

BuoyQAQC.time = buoyMet.TmStamp;
for av = metVars
    if iscategory(tbvars, av{1})
        % Form QAQC structure
        BuoyQAQC.(av{1}).data = buoyMet.(av{1});
        BuoyQAQC.(av{1}).check = ones(size(buoyMet.TmStamp));
        % Check max-min thresholds
        d_tmp = BuoyQAQC.(av{1}).data;
        iu1 = find(d_tmp < MET_QAQC.(av{1})('Min_Value') | ...
                   d_tmp > MET_QAQC.(av{1})('Max_Value') | ...
                   isnan(d_tmp));
        if ~isempty(iu1)
            BuoyQAQC.(av{1}).check(iu1) = 4;
        end
    end
end

% Save QAQC results
save([buoy '_MET_QAQC.mat'], 'BuoyQAQC');

%%
% Save all the data plotted in a structure that can be exported to NETCDF
latlon = [mode(buoyMet.latitude), mode(buoyMet.longitude)];
stnDep = max(buoyMet.depth);
WriteNETCDFbuoyMet(buoy, latlon, stnDep, BuoyQAQC);