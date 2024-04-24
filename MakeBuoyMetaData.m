function meta = MakeBuoyMetaData(atype, Anotes, nn)
% 
% Create Metadata Files for buoy records
% 
% Called from Proc2021_pH_data.m
% 

if strcmpi(atype,'SUNA') | strcmpi(atype,'SBE_ECO_NTUFL') | strcmpi(atype,'hcpH')
    meta.Processing_Notes = Anotes;
    meta.PI = 'James O''Donnell, UConn Marine Sciences';
    meta.processed_by = 'odonnell@uconn.edu';
    meta.time_zone = 'UCT';
    
    if nn == 1
        meta.mooring_name = 'ARTG';
        meta.lat =	41 + 0.6/60;
        meta.lon = -(73 + 17.29/60);    % lat/lon unit: decimal degree
        meta.water_depth = 18.25;       % water_depth unit: m
        meta.depth_source = 'Chart (m)';
    else
        disp('Error in MakeMetaData - nn not found');
    end
end

end