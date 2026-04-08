% 
% Identify and flag EXRX clim data outliers through 5 QAQC tests
% (1 = pass; 3 = suspect; 4 = fail)
% 

clc; clear;

% Fixed parameters
avars = {'T','S','DO','P','C','pH','rho','DOsat'};
cols = {'EST','degC','sal','do_mgL','depthM','cond'};
cols_new = [{'TmStamp'}, avars(1:5)];

% Read station group QAQC parameters
QAQC = load('QAQC_A4_WQ.mat');
QAQC = QAQC.QAQC;

% Write QAQCed buoy files
for loc = {'btm2','mid','sfc'}
    % Preprocess the mat file
    location = loc{1};
    % d7 = load('exrx2007.mat');
    % dT = d7.(['ex' upper(location(1)) location(2:3)]);
    tbl = ['exrx' upper(location(1)) location(2:3) '2006'];
    opts = detectImportOptions([tbl '.csv']);
    opts = setvaropts(opts,'EST','InputFormat','dd-MMM-yyyy HH:mm:ss');
    dT = readtable([tbl '.csv'], opts);
    
    % Change columns in the original file
    dT = renamevars(dT, cols, cols_new);
    dT = dT(:,cols_new);
    dT = sortrows(dT, 'TmStamp');
    
    % Calculate rho
    dT.('rho') = real(sw_dens(dT.S,dT.T,dT.P)-1000);
    % Calculate DOsat (convert to mg/L)
    dT.('DOsat') = 100*dT.DO ./ (sw_satO2(dT.S,dT.T)*1.33);
    % Replace DOsat values greater than 1000 with NaN
    dT.('DOsat')(dT.('DOsat') > 1000) = NaN;
    % Add the pH column
    dT.('pH')(:) = NaN;
    
    % Clean buoy data
    % d = CleanBuoyData(dT, avars);
    d = dT;
    
    % Create the "BuoyQAQC" table
    BuoyQAQC = table();
    BuoyQAQC.TmStamp = d.TmStamp;
    BuoyQAQC.depth = d.P;
    for av = avars
        % Run QAQC tests
        [dQ, dC] = CheckBuoyDataQAQC(d, loc{1}, QAQC, av{1});
        BuoyQAQC.([av{1} '_data']) = d.(av{1});
        BuoyQAQC.([av{1} '_Q']) = dQ;
        BuoyQAQC.([av{1} '_FailedCount']) = dC;
    end
    
    % Add specific columns
    username = 'lisicos';
    password = 'vncq489';
    connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
         'DatabaseName','buoyQAQC','PortNumber',5432);
    dTQ = sqlread(connQ, strcat('"',['EXRX_' loc{1} '_QAQC'],'"'));
    BuoyQAQC.latitude(:) = dTQ.latitude(1);
    BuoyQAQC.longitude(:) = dTQ.longitude(1);
    BuoyQAQC.station(:) = dTQ.station(1);
    BuoyQAQC.mooring_site_desc(:) = dTQ.mooring_site_desc(1);
    close(connQ);
    
    % Save the updated "BuoyQAQC" table to a CSV file
    BuoyQAQC.TmStamp.Format = 'dd-MMM-yyyy HH:mm:ss';
    BuoyQAQC.TmStamp.TimeZone = 'America/New_York';
    writetable(BuoyQAQC, ['EXRX_' loc{1} '_QAQC.csv']);
    fprintf('%s   %s   %s\n', min(BuoyQAQC.TmStamp), max(BuoyQAQC.TmStamp), BuoyQAQC.TmStamp.TimeZone);
end

%%
% Read the CSV file into a table
tbl = 'EXRX_btm2_QAQC';
opts = detectImportOptions([tbl '.csv']);
opts = setvaropts(opts,'TmStamp','InputFormat','dd-MMM-yyyy HH:mm:ss');
BuoyQAQC = readtable([tbl '.csv'], opts);

% Quoted to preserve case sensitivity
tblName = strcat('"',tbl,'"');
colNames = strcat('"',BuoyQAQC.Properties.VariableNames,'"');
BuoyQAQC.Properties.VariableNames = colNames;

% Write the table to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);
try
    batchSize = 10000;
    for i = 1:ceil(height(BuoyQAQC)/batchSize)
        startRow = (i-1)*batchSize + 1;
        endRow = min(i*batchSize, height(BuoyQAQC));
        batchData = BuoyQAQC(startRow:endRow, :);
        % Write the batch to PostgreSQL
        sqlwrite(connQ, tblName, batchData);
        disp(['Row ' num2str(startRow) '-' num2str(endRow) ' written to PostgreSQL successfully.']);
    end
catch ME
    disp(ME.message);
end

close(connQ);