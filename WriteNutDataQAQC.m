% 
% Identify and flag buoy nutrient data outliers
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 
% Calls CheckNutDataQAQC.m
% Calls ImplementCalibration.m
% 

clc; clear;

tvar = 'PAR'; % {'PAR','FL','NTU','NO3'}

% Fixed parameters
cols = {'PAR_Density_Flux','chl_ugL','turbidity_NTU','NNO3'};
colVar = struct('PAR_Density_Flux','PAR','chl_ugL','CHLA', ...
                'turbidity_NTU','TSS','NNO3','NO3');

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','provLNDB','PortNumber',5432);

% tbldata = sqlfind(conn,"")

% Extract tables from PostgreSQL
switch tvar
    case 'PAR'
        buoy = 'ARTG';
        dT = sqlread(conn, '"ARTG_pb1_PARdenDat"');
        QAQC = load('QAQC_E1_WQ.mat');
    case 'FL'
        buoy = 'ARTG';
        dT = sqlread(conn, '"ARTG_pb1_sbeECOFL"');
        dT = renamevars(dT,'chl_ug/L','chl_ugL');
        dT(:, {'Date','EST'}) = [];
        QAQC = load('QAQC_E1_WQ.mat');
    case 'NTU'
        buoy = 'ARTG';
        dT = sqlread(conn, '"ARTG_pb1_sbeECONTU"');
        dT(:, {'Date','EST'}) = [];
        QAQC = load('QAQC_E1_Nutrient.mat');
    case 'NO3'
        buoy = 'CLIS';
        dT = sqlread(conn, '"CLIS_pb4_SunaNO3"');
        QAQC = load('QAQC_I2_Nutrient.mat');
end

dT(:, {'RecNum','CR1XBatt','CR1XTemp'}) = [];
dT = sortrows(dT, 'TmStamp');
QAQC = QAQC.QAQC;
close(conn);

% Create the "NutQAQC" table
NutQAQC = table();
for i = 1:width(dT)
    col = dT.Properties.VariableNames{i};
    if ismember(col, cols)
        var = colVar.(col);
        NutQAQC.(var) = dT.(col);
        % Run QAQC tests
        [dQ1, dC1] = CheckNutDataQAQC(NutQAQC, 'sfc', QAQC, var);
        NutQAQC.([var '_Q']) = dQ1;
        NutQAQC.([var '_FailedCount']) = dC1;
        % Add calibrated columns
        NutQAQC.(['Adjusted_' var]) = ImplementCalibration(dT.(col), dT.TmStamp, buoy, tvar);
        [dQ2, dC2] = CheckNutDataQAQC(NutQAQC, 'sfc', QAQC, ['Adjusted_' var]);
        NutQAQC.(['Adjusted_' var '_Q']) = dQ2;
        NutQAQC.(['Adjusted_' var '_FailedCount']) = dC2;
    else
        NutQAQC.(col) = dT.(col);
    end
end

% Modify specific columns
if strcmp(buoy, 'ARTG')
    NutQAQC.latitude(:) = mode(dT.latitude);
    NutQAQC.longitude(:) = mode(dT.longitude);
    NutQAQC.station(:) = mode(categorical(dT.station));
    NutQAQC.mooring_site_desc(:) = mode(categorical(dT.mooring_site_desc));
    NutQAQC.depth(:) = mode(dT.depth);
end

% Save the updated "NutQAQC" table to a CSV file
writetable(NutQAQC, [buoy '_' tvar '_QAQC.csv']);
fprintf('%s   %s   %s\n', min(NutQAQC.TmStamp), max(NutQAQC.TmStamp), NutQAQC.TmStamp.TimeZone);

%%
% Read the CSV file into a table
tbl = [buoy '_' tvar '_QAQC'];
opts = detectImportOptions([tbl '.csv']);
opts = setvaropts(opts,'TmStamp','InputFormat','dd-MMM-yyyy HH:mm:ss');
NutQAQC = readtable([tbl '.csv'], opts);

% Quoted to preserve case sensitivity
tblName = strcat('"',tbl,'"');
colNames = strcat('"',NutQAQC.Properties.VariableNames,'"');
NutQAQC.Properties.VariableNames = colNames;

% Write the table to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);
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