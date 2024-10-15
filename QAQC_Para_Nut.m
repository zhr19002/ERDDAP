% 
% Create QAQC tables for different depth_codes in a region
% Generate the "QAQC_Para_(W/C/E)Nutrients.mat" file
% 
% Calls GetCTDEEP_Nut_Data.m
% 

clc; clear;
stns = 'WStations'; % {'WStations','CStations','EStations'}

% Fixed parameters
fields = {'Station_Name','Depth_Code','Parameter','Result','time'};
paras = {'BIOSI-LC','CHLA','DIP','DOC','NH#-LC','NOX-LC', ...
         'PC','PN','PP-LC','SIO2-LC','TDN-LC','TDP','TSS'};

% Select station group
switch stns
    case 'WStations'
        stnGrp = {'A2','A4','B3','C1','C2','D3','E1','09','15'};  
    case 'CStations'
        stnGrp = {'F2','F3','H2','H4','H6'};
    case 'EStations'
        stnGrp = {'I2','J2','K2','M3'};
end

% Initialize nutrient data structure
d = struct();
for i = 1:length(fields)
    d.(fields{i}) = [];
end

% Get station group nutrient data
for i = 1:length(stnGrp)
    d0 = GetCTDEEP_Nut_Data(stnGrp{i}, 1);
    for j = 1:length(fields)
        if isfield(d0, fields{j})
            if ischar(d0.(fields{j}))
                d0.(fields{j}) = cellstr(d0.(fields{j}));
            end
            d.(fields{j}) = [d.(fields{j}); d0.(fields{j})];
        end
    end
end

% Seperate data based on depth_code
for dp = {'S','B'}
    iu1 = find(startsWith(d.Depth_Code, dp{1}));
    for field = fieldnames(d)'
        dd.(dp{1}).(field{1}) = d.(field{1})(iu1);
    end
    % Seperate data based on parameters
    for para = paras
        iu2 = strcmp(dd.(dp{1}).Parameter, para{1});
        var = replace(para{1},'#-','_');
        var = replace(var,'-','_');
        nut.(dp{1}).(var).time = dd.(dp{1}).time(iu2)/(24*3600)+datetime(1970,1,1);
        nut.(dp{1}).(var).data = cellfun(@str2double, dd.(dp{1}).Result(iu2));
    end
end

%%
for dp = {'S','B'}
    for av = paras
        var = replace(av{1},'#-','_');
        var = replace(var,'-','_');
        para = table('Size', [5,12], ...
                     'VariableTypes', repmat({'double'},1,12), ...
                     'VariableNames', arrayfun(@num2str,1:12,'UniformOutput',false), ...
                     'RowNames',{'count','max_val','min_val','bd_99','bd_1'});
        for nm = 1:12
            iu = find(month(nut.(dp{1}).(var).time)==nm);
            if ~isempty(iu)
                data = nut.(dp{1}).(var).data(iu);
                data = data(~isnan(data));
            else
                data = 0;
            end
            
            para{1,nm} = length(iu);
            para{2,nm} = prctile(data,99.99);
            para{3,nm} = prctile(data,0.01);
            para{4,nm} = prctile(data,99);
            para{5,nm} = prctile(data,1);
        end
        QAQC.(dp{1}).(var) = para;
    end
end

% Save QAQC parameters of staion group nutrients
save(['QAQC_Para_' stns(1) 'Nutrients.mat'], 'QAQC');