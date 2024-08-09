clc; clear;

Astn = {'E1','F3'};
av_stn = struct('T','sea_water_temperature','S','sea_water_salinity', ...
                'DO','oxygen_concentration_in_sea_wat','pH','pH', ...
                'P','sea_water_pressure','C','sea_water_electrical_conductivi', ...
                'rho','sea_water_density','DOsat','percent_saturation');

% Download station climatology data in the depth range ZT to ZB
for ZT = 0:5:10
    ZB = ZT+5;
    % Get station climatology data
    d = GetDEEPWQClimData(Astn, ZT, ZB);
    % Check each variable in station climatology data
    for av = {'T','S','DO','P','C','pH','rho','DOsat'}
        if isfield(d, av_stn.(av{1}))
            % Shorten field names
            dpth = ['depth_' num2str(ZT) '_' num2str(ZB)];
            % Form QAQC structure
            clim.(dpth).(av{1}).data = d.(av_stn.(av{1}));
        end
    end
end

%%
d = d.StationQAQC;

dp_rng = fieldnames(d);
for i = 1:length(dp_rng)
    for av = {'T','S','DO','P','C','pH','rho','DOsat'}
        for nm = 1:12
            iu = find(month(d.(dp_rng{i}).time)==nm);
            if ~isempty(iu)
                d_tmp = d.(dp_rng{i}).(av{1}).data(iu);
            else
                d_tmp = 0;
            end
            QAQC_para.(dp_rng{i}).(av{1}).nu(nm) = length(iu);
            QAQC_para.(dp_rng{i}).(av{1}).bd_1(nm) = prctile(d_tmp,1);
            QAQC_para.(dp_rng{i}).(av{1}).bd_99(nm) = prctile(d_tmp,99);
            QAQC_para.(dp_rng{i}).(av{1}).bd_min1(nm) = prctile(d_tmp,0.01);
            QAQC_para.(dp_rng{i}).(av{1}).bd_max1(nm) = prctile(d_tmp,99.99);
            QAQC_para.(dp_rng{i}).(av{1}).bd_min2(nm) = min(d_tmp);
            QAQC_para.(dp_rng{i}).(av{1}).bd_max2(nm) = max(d_tmp);
        end
    end
end

%%
clc; clear;
wopts = weboptions; wopts.Timeout = 120;
% Astn = {'E1','F3'};
Astn = 'E1';
Nstn = Astn;
aurl = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_WQ.mat?' ...
         'station_name%2Ctime%2Cdepth%2Csea_water_pressure' ...
         '&station_name=%22C1%22&depth%3E=0&depth%3C=3'];
%aurl = strrep(aurl, 'XX', Astn);
afile = ['CTDEEP_' Nstn '_0_3.mat'];
if ~exist(afile, 'file')
    disp(['Getting data from ERDDAP at ' Nstn ' (0m-3m)']);
    try
        af = websave(afile, aurl, wopts);
        d = load(af);
        d = d.DEEP_WQ;
    catch
        disp(['No data at ' Nstn ' (0m-3m)']);
        d = {};
    end
else
    if ~isempty(dir(afile)) & dir(afile).bytes>0
        d = load(afile);
        d = d.DEEP_WQ;
    else
        d = {};
    end
end