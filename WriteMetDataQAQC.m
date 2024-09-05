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
tVars = [{'TmStamp'}, metVars,{'longitude','latitude','station','mooring_site_desc','depth'}];

% Read meteorology QAQC parameters
QAQC = readtable('QAQC_Para_Met.csv', ReadRowNames=true);

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','provLNDB','PortNumber',5432);

% tbldata = sqlfind(conn,"")

% Extract tables from PostgreSQL
switch buoy
    case 'ARTG'
        dbname = '"ARTG_pb2_metDat"';
        dT = sqlread(conn, dbname);
    case 'CLIS1'
        dbname = '"clis_cr1xPB4_metDat"';
        dT = sqlread(conn, dbname);
        dT = renamevars(dT,'windSpd_kts','windSpd_Kts');
    case 'CLIS2'
        dbname = '"clis_cr1xPB4_metRO"';
        dT = sqlread(conn, dbname);
        dT = renamevars(dT,'windSpd_kts','windSpd_Kts');
    case 'EXRX'
        dbname1 = '"EXRX_pb2_metDat_arch1"';
        buoyMet1 = sqlread(conn, dbname1);
        dbname2 = '"EXRX_pb1_metRO"';
        buoyMet2 = sqlread(conn, dbname2);
        buoyMet2 = renamevars(buoyMet2,'dewPt_Avg','dewPT_Avg');
        dT = [buoyMet1(:,tVars); buoyMet2(:,tVars)];
    case 'WLIS'
        dbname = '"WLIS_pb1_metDat"';
        dT = sqlread(conn, dbname);
end

dT = dT(:, tVars);
dT = sortrows(dT, 'TmStamp');
close(conn);

% Eliminate outliers for specific columns
dT.depth(:) = mode(dT.depth);
dT.latitude(:) = mode(dT.latitude);
dT.longitude(:) = mode(dT.longitude);
dT.station(:) = mode(categorical(dT.station));
dT.mooring_site_desc(:) = mode(categorical(dT.mooring_site_desc));

% Create the "MetQAQC" table
MetQAQC = table();
MetQAQC.TmStamp = dT.TmStamp;
for av = metVars
    % Clean meteorology data
    dT.(av{1})(dT.(av{1}) < -1000) = NaN;
    % Run QAQC tests
    MetQAQC.(av{1}) = dT.(av{1});
    if ismember(av{1}, "windDir_M")
        % Jump limit test
        d_tmp = cos(dT.(av{1})*pi/180);
        MetQAQC.([av{1} '_jumpQ']) = ImplementJumpLimTest(d_tmp);
    else
        d_tmp = dT.(av{1});
        MetQAQC.([av{1} '_Q']) = ones(size(dT.TmStamp));
        % Threshold test
        iu = find(d_tmp<QAQC.(av{1})('min_val') | d_tmp>QAQC.(av{1})('max_val') | isnan(d_tmp));
        if ~isempty(iu)
            MetQAQC.([av{1} '_Q']) = 4;
        end
        % Jump limit test
        if ismember(av{1}, "windSpd_Kts")
            MetQAQC.([av{1} '_jumpQ']) = ImplementJumpLimTest(d_tmp);
        end
    end
end
MetQAQC.depth = dT.depth;
MetQAQC.latitude = dT.latitude;
MetQAQC.longitude = dT.longitude;
MetQAQC.station = dT.station;
MetQAQC.mooring_site_desc = dT.mooring_site_desc;

% Save the updated "MetQAQC" table to a CSV file
writetable(MetQAQC, [buoy '_Met_QAQC.csv']);

%%
% Read the CSV file into a table
tbl = [buoy '_Met_QAQC'];
opts = detectImportOptions([tbl '.csv']);
opts = setvaropts(opts,'TmStamp','InputFormat','dd-MMM-yyyy HH:mm:ss');
MetQAQC = readtable([tbl '.csv'], opts);

% Quoted to preserve case sensitivity
tblName = strcat('"',tbl,'"');
colNames = strcat('"',MetQAQC.Properties.VariableNames,'"');
MetQAQC.Properties.VariableNames = colNames;

% Write the table to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);
try
    batchSize = 10000;
    for i = 1:ceil(height(MetQAQC)/batchSize)
        startRow = (i-1)*batchSize + 1;
        endRow = min(i*batchSize, height(MetQAQC));
        batchData = MetQAQC(startRow:endRow, :);
        % Write the batch to PostgreSQL
        sqlwrite(connQ, tblName, batchData);
        disp(['Row ' num2str(startRow) '-' num2str(endRow) ' written to PostgreSQL successfully.']);
    end
catch ME
    disp(ME.message);
end

% % Check the table in PostgreSQL
% tbldata = sqlfind(connQ, "");
% dT = sqlread(connQ, tblName);
% % Drop the table from PostgreSQL
% execute(connQ, strcat("DROP TABLE ",tblName));

close(connQ);

%%
opts = detectImportOptions([buoy '_Met_QAQC.csv']);
opts = setvaropts(opts,'TmStamp','InputFormat','dd-MMM-yyyy HH:mm:ss');
d = readtable([buoy '_Met_QAQC.csv'], opts);

% Create the "MetQAQC" struct
MetQAQC = struct();
MetQAQC.time = d.TmStamp;
for av = metVars
    MetQAQC.(av{1}).data = d.(av{1});
    if ismember(av{1}, "windDir_M")
        MetQAQC.(av{1}).jumpCheck = d.([av{1} '_jumpQ']);
    else
        MetQAQC.(av{1}).check = d.([av{1} '_Q']);
        if ismember(av{1}, "windSpd_Kts")
            MetQAQC.(av{1}).jumpCheck = d.([av{1} '_jumpQ']);
        end
    end
end

% Save the updated "MetQAQC" struct to a .mat file
save(['Buoy_' buoy '_Met_QAQC.mat'], 'MetQAQC');

%%
% Save all the data plotted in a structure that can be exported to NETCDF
latlon = [d.latitude(1), d.longitude(1)];
stnDep = d.depth(1);
WriteMetNETCDF(buoy, latlon, stnDep, MetQAQC);