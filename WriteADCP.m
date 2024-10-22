% 
% Decode ADCP dataset
% 
% Calls DecodeADCP.m
% 

clc; clear;

buoy = 'WLIS'; % {'CLIS','EXRX','WLIS'}

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

% Create the "decodedData" structure to store values of each field
decodedData = struct();
for i = 1:height(dT)
    hexStr = dT.adcpString_RDI_PD12{i};
    try
        res = DecodeADCP(hexStr);
        for field = fieldnames(res)'
            decodedData(i).(field{1}) = res.(field{1});
        end
    catch ME
        disp(['Error decoding row ' num2str(i) ': ' ME.message]);
        for field = fieldnames(decodedData)'
            decodedData(i).(field{1}) = [];
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
ADCP = struct2table(decodedData);
ADCP.TmStamp = dT.TmStamp;
ADCP = movevars(ADCP, 'TmStamp', 'Before', 1);

% Save the "ADCP" table
save([buoy '_ADCP.mat'], 'ADCP');

%%
% Visualize available ADCP data
d = load([buoy '_ADCP.mat']);
d = d.ADCP;

d.validID = zeros(height(d), 1);
for i = 1:height(d)
    if strcmp(d.ID(i), '7F6E')
        d.validID(i) = 1;
    else
        d.validID(i) = 0;
    end
end
d.ID_count = cumsum(d.validID);

figure; hold on; grid on;
plot(d.TmStamp, d.ID_count, 'b.');
title([buoy '\_ADCP']);