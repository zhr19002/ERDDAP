% 
% Called from GetCTDEEP_Nut_Data.m
% 

clc; clear;

% {'A2','A4','B3','C1','C2','D3','E1','09','15'}
% {'F2','F3','H2','H4','H6'}
% {'I2','J2','K2','M3'}
Astn = 'E1';

% Extract unique depth_code
dp = unique(cellstr(d.Depth_Code));

% Seperate data based on depth_code
for i = 1:length(dp)
    fields = fieldnames(d);
    for j = 1:length(fields)
        iu1 = strcmp(cellstr(d.Depth_Code), dp{i});
        dd.(dp{i}).(fields{j}) = d.(fields{j})(iu1,:);
    end
    
    % Seperate data based on parameters
    for j = 1:length(paras)
        iu2 = strcmp(cellstr(dd.(dp{i}).Parameter), paras{j});
        var = replace(paras{j},'#-','_');
        var = replace(var,'-','_');
        res.(dp{i}).(var) = str2double(dd.(dp{i}).Result(iu2,:));  
    end
    res.(dp{i}).depth = str2double(dd.(dp{i}).([dp{i}(1) '_Sample_Depth']));
end



% Seperate the dataset base on locations (surface/bottom)
ds = cell(12,1); db = cell(12,1);
for nn = 1:12
    if ~isempty(d{nn})
        [ds{nn}, db{nn}] = CTDEEP_Sep_Nut_Data(d{nn});
    else
        ds{nn} = {}; db{nn} = {};
    end
end

%function res = CTDEEP_Sep_Nut_Data(d)
% 
% Seperate data base on depth_code and parameters
% 
% "d" only contains data for a single station in a single month
% 
% Called from GetCTDEEP_Nut_Data.m
% 

for nn = 1:12



% Extract unique parameters
paras = unique(cellstr(d.Parameter));



%end