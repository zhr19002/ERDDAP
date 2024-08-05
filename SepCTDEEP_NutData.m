function [ds, db] = SepCTDEEP_NutData(d, CruiseDay)
% 
% All data is from a single month and a single station
% The need is to seperate data by the S/B level and vars
% 
% CruiseDay should have the start/end/middle date
% 
% Called from GetCTDEEP_NutDataForComps.m
% 

level = {'S','B'};
dl = {'dsurf','dbot'};

vars = {'BIOSI_LC','CHLA','DIP','DOC','NH_LC','NOX_LC', ...
        'PC','PN','PP_LC','SIO2_LC','TDN_LC','TDP','TSS'};

for i = 1:2
    % Seperate data by the S/B level
    fields = fieldnames(d);
    for ii = 1:length(fields)
        iu = d.Depth_Code(:,1)==level{i};
        dd.(dl{i}).(fields{ii}) = d.(fields{ii})(iu,:);
    end

    % Seperate data by vars at the S/B level
    for nv = 1:length(vars)
        nvar = 0;
        for nn = 1:length(dd.(dl{i}).time)
            d_para = replace(dd.(dl{i}).Parameter(nn,:),'#-','_');
            d_para = replace(d_para,'-','_');
            if contains(d_para, vars{nv})
                nvar = nvar + 1;
                for ii = 1:length(fields)
                    res.(dl{i}).(vars{nv}).(fields{ii})(nvar,:) = dd.(dl{i}).(fields{ii})(nn,:);
                end
                res.(dl{i}).(vars{nv}).result(nvar,:) = str2double(dd.(dl{i}).Result(nn,:));
                res.(dl{i}).(vars{nv}).depth(nvar,:) = str2double(dd.(dl{i}).([level{i} '_Sample_Depth'])(nn,:));
                res.(dl{i}).(vars{nv}).startCruiseDay(nvar,:) = CruiseDay{1}(1);
                res.(dl{i}).(vars{nv}).middleCruiseDay(nvar,:) = CruiseDay{1}(3);
                % Convert station time to EST
                startStationDay = dd.(dl{i}).time(nn)/(24*3600) + datetime(1970,1,1);
                startStationDay = datetime(startStationDay,'Format','yyyy-MM-dd');
                % Convert Time_ON_Station
                if isempty(deblank(dd.(dl{i}).Time_ON_Station(nn,:)))
                    startStationTime = datetime([sprintf('%s',startStationDay),' ','11:59:59 AM'],'Format','yyyy-MM-dd HH:mm:ss');
                else
                    startStationTime = ...
                    datetime([sprintf('%s',startStationDay),' ',dd.(dl{i}).Time_ON_Station(nn,:)],'Format','yyyy-MM-dd HH:mm:ss');
                end
                res.(dl{i}).(vars{nv}).startStationDay(nvar,:) = startStationTime;
            end
        end
    end
end

ds = res.dsurf; db = res.dbot;

end