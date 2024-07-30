% 
% Calls WriteNETCDFbuoyMet.m
% 

clc; clear;
buoys = {'ARTG1','CLIS1','EXRX1','EXRX2','EXRX3','WLIS1','WLIS2','clis2','clis3'};
metVars = {'windSpd_Kts','windDir_M','windDir_STD','windSpd_Max','windDir_SMM', ...
           'fiveSecAvg_Max','airTemp_Avg','relHumid_Avg','baroPress_Avg','dewPT_Avg'};
by_nm = struct('ARTG1',"_pb2_metDat",'CLIS1',"_pb1_metDat",'EXRX1',"_pb1_metRO", ...
               'EXRX2',"_pb2_metDat",'EXRX3',"_pb2_metDat_arch1", ...
               'WLIS1',"_pb1_metDat",'WLIS2',"_pb4_metRO", ...
               'clis2',"_cr1xPB4_metDat",'clis3',"_cr1xPB4_metRO");

% Set up parameters
buoy = buoys{1};
% Read QAQC parameters
MET_QAQC = readtable('MET_QAQC_Para.csv', ReadRowNames=true);

% Connect to database
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','provLNDB','PortNumber',5432);

% tbldata = sqlfind(conn,"")

% Extract tables from database
dbname = append(buoy(1:end-1), by_nm.(buoy));
buoyMet = sqlread(conn, append('"', dbname, '"'));
buoyMet = sortrows(buoyMet, 'TmStamp');
close(conn);

% Make variable names consistent
varNames = buoyMet.Properties.VariableNames;
if ismember('windSpd_kts', varNames)
    buoyMet = renamevars(buoyMet, 'windSpd_kts', 'windSpd_Kts');
end
if ismember('dewPt_Avg', varNames)
    buoyMet = renamevars(buoyMet, 'dewPt_Avg', 'dewPT_Avg');
end
tbvars = categorical(buoyMet.Properties.VariableNames);

BuoyQAQC.time = buoyMet.TmStamp;
for av = metVars
    if iscategory(tbvars, av{1})
        % Clean MET data
        buoyMet.(av{1})(buoyMet.(av{1}) < -1000) = NaN;
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
stnDep = mode(buoyMet.depth);
WriteNETCDFbuoyMet(buoy, latlon, stnDep, BuoyQAQC);