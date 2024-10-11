%function res = CTDEEP_Sep_Nut_Data(d)
% 
% Seperate data base on depth_code and parameters
% 
% "d" only contains data for a single station in a single month
% 
% Called from GetCTDEEP_Nut_Data.m
% 

d = d{3};

% Extract unique depth_code
dp = unique(cellstr(d.Depth_Code));

% Extract unique parameters
paras = unique(cellstr(d.Parameter));

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

%end