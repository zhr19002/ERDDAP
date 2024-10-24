% 
% Decode ADCP dataset
% 
% Calls DecodeADCP.m
% 

clc; clear;

buoy = 'CLIS'; % {'CLIS','EXRX','WLIS'}

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','provLNDB','PortNumber',5432);

% Extract ADCP dataset from PostgreSQL
switch buoy
    case 'CLIS'
        dT = sqlread(conn, '"clis_cr1xPB4_adcpDat"');
    otherwise
        dT = sqlread(conn, strcat('"',[buoy '_pb1_adcpDat'],'"'));
end
dT = sortrows(dT, 'TmStamp');
close(conn);

% Create the "result" structure to store values of each field
result = struct();
for i = 1:height(dT)
    try
        res = DecodeADCP(dT.adcpString_RDI_PD12{i});
        for field = fieldnames(res)'
            result(i).(field{1}) = res.(field{1});
        end
    catch ME
        disp(['Error decoding row ' num2str(i) ': ' ME.message]);
        for field = fieldnames(result)'
            result(i).(field{1}) = [];
        end
    end
    % Monitor decoding progress
    if ~mod(i,10000)
        disp(['Successfully decoded rows ' num2str(i-9999) '-' num2str(i)]);
    elseif i == height(dT)
        disp(['Successfully decoded rows ' num2str(i-mod(i,10000)+1) '-' num2str(i)]);
    end
end

% Assign values to the "ADCP" table
ADCP = struct2table(result);
ADCP.TmStamp = dT.TmStamp;
ADCP = movevars(ADCP, 'TmStamp', 'Before', 1);

% Remove empty rows
ADCP = ADCP(~cellfun('isempty', ADCP.ID), :);

% Convert columns to a specific format
ADCP.vels = cellfun(@(x) mat2str(x), ADCP.vels, 'UniformOutput', false);
ADCP.mtime = datetime(string(ADCP.mtime));

% Save the updated "ADCP" table to a CSV file
writetable(ADCP, [buoy '_ADCP.csv'], 'QuoteStrings', true);
fprintf('%s   %s   %s\n', min(ADCP.TmStamp), max(ADCP.TmStamp), ADCP.TmStamp.TimeZone);

%%
% Read the CSV file into a table
tbl = [buoy '_ADCP'];
opts = detectImportOptions([tbl '.csv']);
opts = setvaropts(opts,'TmStamp','InputFormat','dd-MMM-yyyy HH:mm:ss');
opts = setvaropts(opts,'mtime','InputFormat','dd-MMM-yyyy HH:mm:ss');
ADCP = readtable([tbl '.csv'], opts);

% Quoted to preserve case sensitivity
tblName = strcat('"',tbl,'"');
colNames = strcat('"',ADCP.Properties.VariableNames,'"');
ADCP.Properties.VariableNames = colNames;

% Define data type for each column
query = ['CREATE TABLE ' tblName ' (' ...
         '"TmStamp" TIMESTAMP, "ID" VARCHAR, "ens_size" INTEGER, "ens_num" INTEGER, ' ...
         '"unit_ID" INTEGER, "FW_Vers_CPU" INTEGER, "FW_Rev_CPU" INTEGER, ' ...
         '"year" INTEGER, "month" INTEGER, "day" INTEGER, "hour" INTEGER, ' ... 
         '"min" INTEGER, "sec" INTEGER, "Hsec" INTEGER, "heading" FLOAT, ' ...
         '"pitch" FLOAT, "roll" FLOAT, "temp" FLOAT, "press" FLOAT, ' ...
         '"components" VARCHAR, "start_bin" INTEGER, "N_bins" INTEGER, ' ...
         '"vels" VARCHAR, "chksum" INTEGER, "mtime" TIMESTAMP);'];

% Write the table to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);
execute(connQ, query);
try
    batchSize = 10000;
    for i = 1:ceil(height(ADCP)/batchSize)
        startRow = (i-1)*batchSize + 1;
        endRow = min(i*batchSize, height(ADCP));
        batchData = ADCP(startRow:endRow, :);
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