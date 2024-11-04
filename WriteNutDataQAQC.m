% 
% Identify and flag buoy nutrient data outliers
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 
% Calls CheckNutDataQAQC.m
% 

clc; clear;

buoy = 'ARTG'; % {'ARTG','CLIS'}
var = 'PAR'; % {'PAR','FL','NTU','NO3'}

% Fixed parameters
nutVars = {'PAR','Corrected_Chl','TSS','NO3conc','NNO3'};

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
            dT = sqlread(conn, '"ARTG_pb1_PARdenDat"');
            dT = renamevars(dT,'PAR_Raw','PAR');
        else
            dbname = strcat('"',[buoy '_pb1_sbeECO' var],'"');
            dT = sqlread(conn, dbname);
            if ismember('chl_ug/L', dT.Properties.VariableNames)
                dT = renamevars(dT,'chl_ug/L','Corrected_Chl');
            else
                dT = renamevars(dT,'turbidity_NTU','TSS');
            end
            dT(:, {'Date','EST'}) = [];
        end
        QAQC = load('QAQC_Para_WStations.mat');
    case 'CLIS'
        dT = sqlread(conn, '"CLIS_pb4_SunaNO3"');
        
        QAQC = load('QAQC_Para_CNutrients.mat');

end

dT(:, {'RecNum','CR1XBatt','CR1XTemp'}) = [];
dT = sortrows(dT, 'TmStamp');
QAQC = QAQC.QAQC;
close(conn);

% Create the "NutQAQC" table
NutQAQC = table();
for i = 1:width(dT)
    col = dT.Properties.VariableNames{i};
    NutQAQC.(col) = dT.(col);
    if ismember(col, nutVars)
        % Run QAQC tests
        [dQ, dC] = CheckNutDataQAQC(dT, QAQC, col);
        NutQAQC.([col '_Q']) = dQ;
        NutQAQC.([col '_FailedCount']) = dC;
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
writetable(NutQAQC, [buoy '_' var '_QAQC.csv']);
fprintf('%s   %s   %s\n', min(NutQAQC.TmStamp), max(NutQAQC.TmStamp), NutQAQC.TmStamp.TimeZone);

%%
% Read the CSV file into a table
tbl = [buoy '_' var '_QAQC'];
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