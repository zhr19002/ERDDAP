% 
% Calls GetCTDEEP_Nut_Data.m
% 

clc; clear;

% {'A2','A4','B3','C1','C2','D3','E1','09','15'}
% {'F2','F3','H2','H4','H6'}
% {'I2','J2','K2','M3'}
Astn = 'E1';

% Fixed parameters
paras = {'BIOSI-LC','CHLA','DIP','DOC','NH#-LC','NOX-LC', ...
         'PC','PN','PP-LC','SIO2-LC','TDN-LC','TDP','TSS'};

% Get station nutrient data
d = GetCTDEEP_Nut_Data(Astn, 1);
if ~isempty(d)
    for field = fieldnames(d)'
        if ischar(d.(field{1}))
            d.(field{1}) = cellstr(d.(field{1}));
        end
    end
    nut.latitude = mode(d.latitude);
    nut.longitude = mode(d.longitude);
    % Seperate data based on depth_code
    for dp = {'S','M','B'}
        if dp{1} == 'S'
            iu1 = startsWith(d.Depth_Code, 'S');
        else
            iu1 = strcmp(d.Depth_Code, dp{1});
        end
        for field = fieldnames(d)'
            dd.(dp{1}).(field{1}) = d.(field{1})(iu1);
        end
        % Seperate data based on parameters
        for para = paras
            iu2 = strcmp(dd.(dp{1}).Parameter, para{1});
            var = replace(para{1},'#-','_');
            var = replace(var,'-','_');
            nut.(dp{1}).(var).time = dd.(dp{1}).time(iu2)/(24*3600)+datetime(1970,1,1);
            dpth = [dp{1} '_Sample_Depth'];
            nut.(dp{1}).(var).depth = cellfun(@str2double, dd.(dp{1}).(dpth)(iu2));
            nut.(dp{1}).(var).data = cellfun(@str2double, dd.(dp{1}).Result(iu2));
        end
    end
else
    nut = {};
end