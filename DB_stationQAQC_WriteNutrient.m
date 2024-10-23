clc; clear;

% {'A2','A4','B3','C1','C2','D3','E1','09','15'}
% {'F2','F3','H2','H4','H6'}
% {'I2','J2','K2','M3'}
Astn = 'E1';

% Fixed parameters
paras = {'BIOSI-LC','CHLA','DIP','DOC','NH#-LC','NOX-LC', ...
         'PC','PN','PP-LC','SIO2-LC','TDN-LC','TDP','TSS'};

% Read station group QAQC parameters
if ismember(Astn, {'A2','A4','B3','C1','C2','D3','E1','09','15'})
    stnGroup = 'WStations';
elseif ismember(Astn, {'F2','F3','H2','H4','H6'})
    stnGroup = 'CStations';
else
    stnGroup = 'EStations';
end
QAQC = load(['QAQC_Para_' stnGroup(1) 'Nutrients.mat']);
QAQC = QAQC.QAQC;

% Write QAQCed station nutrient files
% Get station nutrient data
d = GetCTDEEP_Nut_Data(Astn, 1);
if ~isempty(d)
    len = length(d.time);
    % Create the "NutQAQC" table
    nut = table(zeros(len,1),zeros(len,1),'VariableNames',{'Sample_Depth','Result_Q'});
    for field = fieldnames(d)'
        if ismember(field{1}, {'time','Start_Date','End_Date'})
            nut.(field{1}) = d.(field{1})/(24*3600) + datetime(1970,1,1);
            nut.(field{1}).TimeZone = 'UTC';
            nut.(field{1}).TimeZone = 'America/New_York';
        elseif ismember(field{1}, {'Detection_Limit','Dilution_Factor','PQL','Result'})
            nut.(field{1}) = cellfun(@str2double, d.(field{1}));
        elseif contains(field{1}, 'Sample_Depth')
            iu1 = find(startsWith(d.Depth_Code, field{1}(1)));
            nut.Sample_Depth(iu1) = cellfun(@str2double, d.(field{1})(iu1));
        else
            nut.(field{1}) = d.(field{1});
        end
    end
    % Perform the threshold test
    for dp = {'S','B'}
        for para = paras
            iu2 = find(startsWith(nut.Depth_Code,dp{1}) & strcmp(nut.Parameter, para{1}));
            var = replace(para{1},'#-','_');
            var = replace(var,'-','_');
            nut.Result_Q(iu2) = ...
                ImplementThresholdTest(nut.Result(iu2), nut.time(iu2), QAQC, dp{1}, var);
        end
    end
end

% Save the updated "NutQAQC" table to a CSV file
NutQAQC = nut;
writetable(NutQAQC, ['DEEP_' Astn '_Nutrient_QAQC.csv']);

%%
% Read the CSV file into a table
tbl = ['DEEP_' Astn '_Nutrient_QAQC'];
NutQAQC = readtable([tbl '.csv']);
NutQAQC.time.Format = 'dd-MMM-yyyy HH:mm:ss';
NutQAQC.Start_Date.Format = 'dd-MMM-yyyy HH:mm:ss';
NutQAQC.End_Date.Format = 'dd-MMM-yyyy HH:mm:ss';
NutQAQC.Time_ON_Station = cellstr(NutQAQC.Time_ON_Station);
NutQAQC.Time_OFF_Station = cellstr(NutQAQC.Time_OFF_Station);

% Quoted to preserve case sensitivity
tblName = strcat('"',tbl,'"');
colNames = strcat('"',NutQAQC.Properties.VariableNames,'"');
NutQAQC.Properties.VariableNames = colNames;

% Define data type for each column
vNames = cell(1, 2*length(avars));
query = ['CREATE TABLE ' tblName ' (' ...
         '"cruise" VARCHAR, "Lab_ID" VARCHAR, "Station_Name" VARCHAR, "Depth_Code" VARCHAR, ' ...
         '"Sample_Depth" FLOAT, "Detection_Limit" FLOAT, "Dilution_Factor" FLOAT, "PQL" FLOAT, ' ...
         '"Parameter" VARCHAR, "Result" FLOAT, "Result_Q" INTEGER, "Units" VARCHAR, ' ...
         '"Comment" VARCHAR, "Month" VARCHAR, "latitude" FLOAT, "longitude" FLOAT, ' ...
         '"Time_ON_Station" VARCHAR, "Time_OFF_Station" VARCHAR, "time" TIMESTAMP, ' ...
         '"Start_Date" TIMESTAMP, "End_Date" TIMESTAMP);'];

% Write the table to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','stationQAQC','PortNumber',5432);
execute(connQ, query);
try
    batchSize = 10000;
    for i = 1:1%ceil(height(StationQAQC)/batchSize)
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