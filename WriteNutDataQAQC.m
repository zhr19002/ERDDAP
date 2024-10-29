% 
% Identify and flag buoy nutrient data outliers
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 
% Calls CheckNutQAQC.m
% 

clc; clear;

buoy = 'ARTG'; % {'ARTG','CLIS'}
var = 'FL'; % {'PARden','PARtot','FL','NTU','NO3'}

% Fixed parameters
nutVars = {'PAR_Raw','PAR_Density_Flux','PAR_Flux_Total', ...
           'Avg_FL','StdDev_FL','Min_FL','Max_FL','chl_ug/L', ...
           'Avg_NTU','StdDev_NTU','Min_NTU','Max_NTU','turbidity_NTU', ...
           'NO3conc','NNO3'};

% Read nutrient QAQC parameters
QAQC = readtable('QAQC_Para_Nut.csv', ReadRowNames=true); %%%%%%

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','provLNDB','PortNumber',5432);

% tbldata = sqlfind(conn,"")

% Extract tables from PostgreSQL
switch buoy
    case 'ARTG'
        if contains(var, 'PAR')
            dbname = strcat('"',[buoy '_pb1_' var 'Dat'],'"');
            dT = sqlread(conn, dbname);
        else
            dbname = strcat('"',[buoy '_pb1_sbeECO' var],'"');
            dT = sqlread(conn, dbname);
        end
    case 'CLIS'
        dT = sqlread(conn, '"CLIS_pb4_SunaNO3"');
end

dT = sortrows(dT, 'TmStamp');
close(conn);

% Create the "NutQAQC" table
NutQAQC = table();
NutQAQC.TmStamp = dT.TmStamp;
for av = nutVars
    if ismember(av{1}, dT.Properties.VariableNames)
        % Run QAQC tests
        [dQ, dC] = CheckNutQAQC(dT, QAQC, av{1}); %%%%%%
        NutQAQC.(av{1}) = dT.(av{1});
        NutQAQC.([av{1} '_Q']) = dQ;
        NutQAQC.([av{1} '_FailedCount']) = dC;
    end
end

% Add specific columns
NutQAQC.depth(:) = mode(dT.depth);
NutQAQC.latitude(:) = mode(dT.latitude);
NutQAQC.longitude(:) = mode(dT.longitude);
NutQAQC.station(:) = mode(categorical(dT.station));
NutQAQC.mooring_site_desc(:) = mode(categorical(dT.mooring_site_desc));

% Save the updated "NutQAQC" table to a CSV file
writetable(NutQAQC, [buoy '_Nut_QAQC.csv']);
fprintf('%s   %s   %s\n', min(NutQAQC.TmStamp), max(NutQAQC.TmStamp), NutQAQC.TmStamp.TimeZone);

%%
% Read the CSV file into a table
tbl = [buoy '_Nut_QAQC'];
opts = detectImportOptions([tbl '.csv']);
opts = setvaropts(opts,'TmStamp','InputFormat','dd-MMM-yyyy HH:mm:ss');
NutQAQC = readtable([tbl '.csv'], opts);

% Quoted to preserve case sensitivity
tblName = strcat('"',tbl,'"');
colNames = strcat('"',NutQAQC.Properties.VariableNames,'"');
NutQAQC.Properties.VariableNames = colNames;

% Define data type for each column
vNames = cell(1, 3*length(nutVars));
for i = 1:length(nutVars)
    vNames{3*i-2} = sprintf('"%s" %s',nutVars{i},'FLOAT');
    vNames{3*i-1} = sprintf('"%s_Q" %s',nutVars{i},'INTEGER');
    vNames{3*i} = sprintf('"%s_FailedCount" %s',nutVars{i},'INTEGER');
end
query = strjoin(vNames, ', ');
query = ['CREATE TABLE ' tblName ' (' ...
         '"TmStamp" TIMESTAMP, ', query, ... 
         ', "depth" FLOAT, "latitude" FLOAT, "longitude" FLOAT, ' ...
         '"station" VARCHAR, "mooring_site_desc" VARCHAR);'];

% Write the table to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);
execute(connQ, query);
try
    batchSize = 10000;
    for i = 1:ceil(height(NutQAQC)/batchSize)
        startRow = (i-1)*batchSize + 1;
        endRow = min(i*batchSize, height(NutQAQC));
        batchData = NutQAQC(startRow:endRow, :);
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