function d = GetCTDEEP_CTD_Data(Astn, Acrs)
% 
% Get CTD data from station (Astn) on cruise (Acrs)
% Return a structure with salinity, temperature, and density
% 
% Called from GetCTDEEP_CTD_Stats.m
% 

wopts = weboptions; wopts.Timeout = 120;

% Define the URL template
a1 = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_WQ.mat?cruise_name%2Cstation_name' ...
      '%2Ctime%2Clatitude%2Clongitude%2Cdepth%2Csea_water_pressure%2Csea_water_electrical_conductivity' ...
      '%2Csea_water_temperature%2CPAR%2CChlorophyll%2CCorrected_Chlorophyll%2CpH%2Csea_water_salinity' ...
      '%2Coxygen_concentration_in_sea_water%2Cpercent_saturation%2Csea_water_density%2CStart_Date' ...
      '&cruise_name=%22XX%22&station_name=%22YY%22'];
aurl = strrep(a1, 'XX', Acrs);
aurl = strrep(aurl, 'YY', Astn);

afile = ['DEEP_CTD_' Astn '_' Acrs '.mat'];
if ~exist(afile, 'file')
    disp(['Getting CTD data from ERDDAP at ' Astn ' on ' Acrs]);
    try
        af = websave(afile, aurl, wopts);
        dt = load(af);
    catch
        disp(['No data at ' Astn ' on ' Acrs]);
        dt = {};
    end
else
    disp(['Loading local ' afile]);
    if ~isempty(dir(afile)) & dir(afile).bytes>0
        dt = load(afile);
    else
        dt = {};
    end
end

if ~isempty(dt)
    dt = dt.DEEP_WQ;
    fields = fieldnames(dt);
    for nn = 1:size(fields,1)
        d.(fields{nn}) = mat2cell(dt.(fields{nn}), ones(1,size(dt.(fields{1}),1)));
        if sum(strcmp(fields{nn}, {'time','Start_Date','End_Date'}))
            for mm = 1:size(dt.(fields{1}),1)
                if isnan(d.(fields{nn}){mm})
                    d.(fields{nn}){mm} = NaN;
                else
                    d.(fields{nn}){mm} = d.(fields{nn}){mm}/(24*3600) + datetime(1970,1,1);
                end
            end
        end
    end
else
    d = {};
end

end