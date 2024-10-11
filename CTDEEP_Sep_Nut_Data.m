function [ds, db] = CTDEEP_Sep_Nut_Data(d)
% 
% Seperate the dataset "d" base on vars and locations (surface/bottom)
% 
% "d" only contains data for a single station in a single month
% 
% Called from GetCTDEEP_Nut_Data.m
% 

vars = {'BIOSI_LC','CHLA','DIP','DOC','NH_LC','NOX_LC', ...
        'PC','PN','PP_LC','SIO2_LC','TDN_LC','TDP','TSS'};

for dp = {'dsurf','dbot'}
    fields = fieldnames(d);
    % Seperate data based on locations
    for i = 1:length(fields)
        iu = d.Depth_Code(:,1) == upper(dp{1}(2));
        dd.(dp{1}).(fields{i}) = d.(fields{i})(iu,:);
    end
    
    % Seperate data based on vars
    for i = 1:length(vars)
        nvar = 0;
        for j = 1:length(dd.(dp{1}).time)
            para = replace(dd.(dp{1}).Parameter(j,:),'#-','_');
            para = replace(para,'-','_');
            if contains(para, vars{i})
                nvar = nvar + 1;
                for k = 1:length(fields)
                    res.(dp{1}).(vars{i}).(fields{k})(nvar,:) = dd.(dp{1}).(fields{k})(j,:);
                end
                res.(dp{1}).(vars{i}).result(nvar,:) = str2double(dd.(dp{1}).Result(j,:));
                res.(dp{1}).(vars{i}).depth(nvar,:) = str2double(dd.(dp{1}).([upper(dp{1}(2)) '_Sample_Depth'])(j,:));
                res.(dp{1}).(vars{i}).start_date(nvar,:) = dd.(dp{1}).Start_Date;
                res.(dp{1}).(vars{i}).end_date(nvar,:) = dd.(dp{1}).End_Date;
            end
        end
    end
end

ds = res.dsurf;
db = res.dbot;

end