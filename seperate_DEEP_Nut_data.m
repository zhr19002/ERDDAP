function [ds, db] = seperate_DEEP_Nut_data(d, CruiseDates)
% 
% Extract the data from the structure. All the data is from 
% a single month and a single station. The need is to seperate
% the records by level (S/B) and variable.
% 
% CruiseDates should have the start end and middle data in datenum
% 
% Called from GetCTDEEPDataForComps.m
% 

vars = {'BIOSI-LC',...
        'CHLA'    ,...
        'DIP'     ,...
        'DOC'     ,...
        'NH#-LC'  ,...
        'NOX-LC'  ,...
        'PC'      ,...
        'PN'      ,...
        'PP-LC'   ,...
        'SIO2-LC' ,...
        'TDN-LC'  ,...
        'TDP'     ,...
        'TSS'};

% Make these suitable for variable names
for ii = 1:length(vars)
    vars{ii} = strrep(vars{ii}, '-', '_');
    vars{ii} = strrep(vars{ii}, '#', '_');
end
cvars = deblank(vars);

fields = {'cruise'          ,...
          'Lab_ID'          ,...
          'Station_Name'    ,...
          'Depth_Code'      ,...
          'Detection_Limit' ,...
          'Dilution_Factor' ,...
          'PQL'             ,...
          'Parameter'       ,...
          'Result'          ,...
          'non_detect'      ,...
          'Units'           ,...
          'Comment'         ,...
          'Month'           ,...
          'latitude'        ,...
          'longitude'       ,...
          'Time_ON_Station' ,...
          'Time_OFF_Station',...
          'time'            ,...
          'Start_Date'      ,...
          'End_Date'        ,...
          'B_Sample_Depth'  ,...
          'M_Sample_Depth'  ,...
          'S_Sample_Depth'  ,...
          'NB_Sample_Depth' };

% Sort the data by level first
nsurf = 0; nbot = 0;
for nn = 1:length(d.time)
    if contains(d.Depth_Code(nn,:), 'S')
        nsurf = nsurf + 1;
        for nf = 1:length(fields)
            dsurf.(fields{nf})(nsurf,:) = d.(fields{nf})(nn,:);
        end
    
    elseif contains(d.Depth_Code(nn,:), 'B')
        nbot = nbot + 1;
        for nf = 1:length(fields)
            dbot.(fields{nf})(nbot,:) = d.(fields{nf})(nn,:);
        end
    end
end

% 
% Now need to sort the surf and bottom structures by parameter
% 

% Search for records with data for variable vars(nl) at surface level
if exist('dsurf', 'var')
    for nl = 1:length(cvars)
        nVct = 0;
        for nn = 1:length(dsurf.time)
            if strfind(dsurf.Parameter(nn,:), cvars{nl})
                nVct = nVct + 1;
                for ii = 1:length(fields)
                    ds.(cvars{nl}).(fields{ii})(nVct,:) = dsurf.(fields{ii})(nn,:);
                end
                ds.(cvars{nl}).Conc(nVct,:) = str2double(dsurf.Result(nn,:));
                ds.(cvars{nl}).depth(nVct,:) = str2double(dsurf.S_Sample_Depth(nn,:));
                ds.(cvars{nl}).time(nVct,:) = seconds((CruiseDates{1}(3)-datetime(1970,1,1))*86400);
                
                % Convert CRUISE Start_Date to EST
                % startCruiseday = dsurf.Start_Date(nn)/86400 + datetime(1970,1,1);
                % startCruiseday = datetime(startCruiseday,'Format','yyyy-MM-dd');
                
                % Convert time to EST (the Day Station started)
                astartStationday = dsurf.time(nn)/86400 + datetime(1970,1,1);
                astartStationday = datetime(astartStationday,'Format','yyyy-MM-dd');
                
                % Convert Time_ON_Station
                if isempty(deblank(dsurf.Time_ON_Station(nn,:)))
                    startStationtime = ...
                    datetime(append(string(astartStationday),' ','11:59:59 AM'),'Format','yyyy-MM-dd HH:mm:ss');
                else
                    startStationtime = ...
                    datetime(append(string(astartStationday),' ',dsurf.Time_ON_Station(nn,:)),'Format','yyyy-MM-dd HH:mm:ss');
                end
                ds.(cvars{nl}).Stntime(nVct,:) = startStationtime;                           
            end
        end
    end
else
    ds = [];
end

% Search for records with data for variable vars(nl) at Bottom level
if exist('dbot', 'var')
    for nl = 1:length(cvars)
        nVct = 0; 
        for nn = 1:length(dbot.time)
            if strfind(dbot.Parameter(nn,:), cvars{nl})
                nVct = nVct + 1;           
                for ii = 1:length(fields)
                    db.(cvars{nl}).(fields{ii})(nVct,:) = dbot.(fields{ii})(nn,:);
                end
                db.(cvars{nl}).Conc(nVct,:) = str2double(dbot.Result(nn,:));
                db.(cvars{nl}).depth(nVct,:) = str2double(dbot.B_Sample_Depth(nn,:));
                db.(cvars{nl}).time(nVct,:) = seconds((CruiseDates{1}(3)-datetime(1970,1,1))*86400);

                % Convert CRUISE Start_Date to EST
                % startCruiseday = dbot.Start_Date(nn)/86400 + datetime(1970,1,1);
                % startCruiseday = datetime(startCruiseday,'Format','yyyy-MM-dd');
                
                % Convert time to EST (the Day Station started)
                astartStationday = dbot.time(nn)/86400 + datetime(1970,1,1);
                astartStationday = datetime(astartStationday,'Format','yyyy-MM-dd');
                
                % Convert Time_ON_Station
                if isempty(deblank(dbot.Time_ON_Station(nn,:)))
                    startStationtime = ...
                    datetime(append(string(astartStationday),' ','11:59:59 AM'),'Format','yyyy-MM-dd HH:mm:ss');
                else
                    startStationtime = ...
                    datetime(append(string(astartStationday),' ',dsurf.Time_ON_Station(nn,:)),'Format','yyyy-MM-dd HH:mm:ss');
                end
                db.(cvars{nl}).Stntime(nVct,:) = startStationtime;
            end
        end
    end
else
    db = [];
end

end