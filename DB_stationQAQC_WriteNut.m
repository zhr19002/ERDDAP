clc; clear;

% {'A2','A4','B3','C1','C2','D3','E1','09','15'}
% {'F2','F3','H2','H4','H6'}
% {'I2','J2','K2','M3'}
Astn = 'A2';

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
QAQC = load(['QAQC_' stnGroup '_Nutrient.mat']);
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
if ~iscell(NutQAQC.Comment)
    NutQAQC.Comment = strings(height(NutQAQC), 1);
end
if ismember(Astn, {'09','15'})
    NutQAQC.Station_Name = ...
    arrayfun(@(x) sprintf('%02d',x),NutQAQC.Station_Name,'UniformOutput',false);
end

% Quoted to preserve case sensitivity
tblName = strcat('"',tbl,'"');
colNames = strcat('"',NutQAQC.Properties.VariableNames,'"');
NutQAQC.Properties.VariableNames = colNames;

% Define data type for each column
query = ['CREATE TABLE ' tblName ' (' ...
         '"Lab_ID" VARCHAR, "cruise" VARCHAR, "Station_Name" VARCHAR, "time" TIMESTAMP, ' ...
         '"latitude" FLOAT, "longitude" FLOAT, "Depth_Code" VARCHAR, "Sample_Depth" FLOAT, ' ...
         '"Detection_Limit" FLOAT, "Dilution_Factor" FLOAT, "PQL" FLOAT, "Parameter" VARCHAR, ' ...
         '"Result" FLOAT, "Result_Q" INTEGER, "Units" VARCHAR, "Comment" VARCHAR, ' ...
         '"Month" VARCHAR, "Start_Date" TIMESTAMP, "End_Date" TIMESTAMP, ' ...
         '"Time_ON_Station" VARCHAR, "Time_OFF_Station" VARCHAR);'];

% Write the table to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','stationQAQC','PortNumber',5432);
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

%%
% Write the "QAQC_(W/C/E)Stations_Nutrient" table to PostgreSQL
clc; clear;

dir = 'West'; % {'West','Center','East'}
QAQC = load(['QAQC_' dir(1) 'Stations_Nutrient.mat']);
QAQC = QAQC.QAQC;

% Specify row and column names
rows = {'count';'mean';'std';'median';'upper';'lower';'bd99';'bd84';'bd16';'bd1'};
cols = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};

% Prepare data for the table
dps = fieldnames(QAQC)';
vars = fieldnames(QAQC.S)';
col1 = cell(length(dps)*length(vars)*10, 1);
data = zeros(length(dps)*length(vars)*10, 12);
for i = 1:length(dps)
    for j = 1:length(vars)
        for k = 1:10
            index = (i-1)*length(vars)*10 + (j-1)*10 + k;
            col1{index} = [dps{i} '_' vars{j} '_' rows{k}];
            data(index, :) = table2array(QAQC.(dps{i}).(vars{j})(k,:));
        end
    end
end

% Generate the table
col1T = table(col1, 'VariableNames', {'Stats'});
dataT = array2table(data, 'VariableNames', cols);
qaqcT = [col1T, dataT];

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','stationQAQC','PortNumber',5432);

% Write the table to PostgreSQL
tblName = strcat('"',['QAQC_' dir '_Stations_Nutrient'],'"');
qaqcT.Properties.VariableNames = strcat('"',qaqcT.Properties.VariableNames,'"');
sqlwrite(connQ, tblName, qaqcT);

close(connQ);