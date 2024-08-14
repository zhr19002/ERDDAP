clc; clear;

% Create a database
dbPath = 'C:\Users\zhr19002\Downloads\ERDDAP-QAQC.db';
dbConn = sqlite(dbPath, 'create');

% Create a table
createTable = [
    'CREATE TABLE IF NOT EXISTS QAQC (' ...
    'id INTEGER PRIMARY KEY AUTOINCREMENT, ' ...
    'filename TEXT, ' ...
    'filedata BLOB)'];
exec(dbConn, createTable);

% Upload files
dirPath = 'C:\Users\zhr19002\Downloads\QAQC-NCfiles';
fileList = dir(fullfile(dirPath, '*.*'));
for i = 1:length(fileList)
    if fileList(i).isdir
        continue;
    end
    
    filePath = fullfile(fileList(i).folder, fileList(i).name);
    fileID = fopen(filePath, 'rb');
    fileData = fread(fileID, '*uint8')'; % Read as binary data
    fclose(fileID);

    fileDataHex = matlab.net.base64encode(fileData');
    insertSQL = sprintf('INSERT INTO QAQC (filename, filedata) VALUES (''%s'', ''%s'')', fileList(i).name, fileDataHex);
    exec(dbConn, insertSQL);
end

close(dbConn);

%%
clc; clear;

% Connect to the database
dbPath = 'C:\Users\zhr19002\Downloads\ERDDAP-QAQC.db';
dbConn = sqlite(dbPath, 'connect');

% Fetch all records from the QAQC table
query = 'SELECT * FROM QAQC';
data = fetch(dbConn, query);

close(dbConn);

% Process the fetched data
for i = 1:5 % size(data, 1)
    filename = data{i,2};
    filedataHex = data{i,3};
    
    % Decode the file data from base64 encoding
    filedata = matlab.net.base64decode(filedataHex);
    
    % Save the file to the disk
    outputFilePath = fullfile('C:\Users\zhr19002\Downloads\Recovered', filename);
    fileID = fopen(outputFilePath, 'wb');
    fwrite(fileID, filedata, 'uint8');
    fclose(fileID);
    
    % Display the filename and path of the saved file
    fprintf('Recovered file: %s\n', outputFilePath);
end