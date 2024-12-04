% 
% Identify and flag buoy wave data outliers
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 

clc; clear;
buoy = 'WLIS';
waveVars = {'Hsig_m','Hmax_m','Tdom_s','Tavg_s','waveDir','meanDir'};

% Read wave QAQC parameters
QAQC = readtable('QAQC_Para_Wave.csv', ReadRowNames=true);

% Process tables from FTP site
switch buoy
    case 'WLIS'
        % Preprocess the mat file
        d = load('wlis_wv.mat');
        for i = 1:9
            fld = ['wlis' num2str(2005+i)];
            % Convert datenum to datetime
            if isfield(d.(fld), 'dt')
                d.(fld).EST = datetime(d.(fld).dt,'ConvertFrom','datenum');
            else
                d.(fld).EST = datetime(d.(fld).EST,'ConvertFrom','datenum');
            end
            % Convert cell to double
            for subfld = {'Hsig','domPD','avgPD'}
                if iscell(d.(fld).(subfld{1}))
                    d.(fld).(subfld{1}) = cell2mat(d.(fld).(subfld{1}));
                end
            end
        end
        
        % Convert structure to a table
        dT = table();
        for i = 1:14
            fld = ['wlis' num2str(2005+i)];
            d_tmp = table(d.(fld).EST, d.(fld).Hsig, d.(fld).domPD, d.(fld).avgPD);
            dT = [dT; d_tmp];
        end
        dT.Properties.VariableNames = {'TmStamp','Hsig_m','Tdom_s','Tavg_s'};
        dT.('Hmax_m')(:) = NaN;
        dT.('waveDir')(:) = NaN;
        dT.('meanDir')(:) = NaN;
        dT = sortrows(dT, 'TmStamp');
end

% Create the "waveQAQC" table
waveQAQC = table();
waveQAQC.TmStamp = dT.TmStamp;
for av = waveVars
    % Run QAQC tests
    [dQ, dC] = CheckMetWaveQAQC(dT, QAQC, av{1});
    waveQAQC.(av{1}) = dT.(av{1});
    waveQAQC.([av{1} '_Q']) = dQ;
    waveQAQC.([av{1} '_FailedCount']) = dC;
end

% Add specific columns
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);
dTQ = sqlread(connQ, strcat('"',[buoy '_Wave_QAQC'],'"'));
waveQAQC.depth(:) = dTQ.depth(1);
waveQAQC.latitude(:) = dTQ.latitude(1);
waveQAQC.longitude(:) = dTQ.longitude(1);
waveQAQC.station(:) = dTQ.station(1);
waveQAQC.mooring_site_desc(:) = dTQ.mooring_site_desc(1);
close(connQ);

% Save the updated "waveQAQC" table to a CSV file
waveQAQC.TmStamp.TimeZone = 'America/New_York';
writetable(waveQAQC, [buoy '_Wave_QAQC.csv']);
fprintf('%s   %s   %s\n', min(waveQAQC.TmStamp), max(waveQAQC.TmStamp), waveQAQC.TmStamp.TimeZone);

%%
% Read the CSV file into a table
tbl = [buoy '_Wave_QAQC'];
opts = detectImportOptions([tbl '.csv']);
opts = setvaropts(opts,'TmStamp','InputFormat','dd-MMM-yyyy HH:mm:ss');
waveQAQC = readtable([tbl '.csv'], opts);

% Quoted to preserve case sensitivity
tblName = strcat('"',tbl,'"');
colNames = strcat('"',waveQAQC.Properties.VariableNames,'"');
waveQAQC.Properties.VariableNames = colNames;

% Write the table to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);
try
    batchSize = 10000;
    for i = 1:ceil(height(waveQAQC)/batchSize)
        startRow = (i-1)*batchSize + 1;
        endRow = min(i*batchSize, height(waveQAQC));
        batchData = waveQAQC(startRow:endRow, :);
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

close(connQ);