function d = ImplementCalibration(din, buoy, var)
% 
% Calibrate nutrient data based on UConn samples
% 
% Called from WriteNutDataQAQC.m
% 

switch var
    case 'PAR'
        d = din;
    case 'FL'
        d = din;
    case 'NTU'
        file = 'Buoy_TSS.csv';
        opts = detectImportOptions(file);
        opts = setvaropts(opts,'TmStamp','InputFormat','MM/dd/uuuu HH:mm');
        T = readtable(file, opts);
        T = T(startsWith(T.Field, buoy), :);
        d = din;
    case 'NO3'
        file = 'Buoy_NOX.csv';
        opts = detectImportOptions(file);
        opts = setvaropts(opts,3:4,'InputFormat','MM/dd/uuuu');
        T = readtable(file, opts);
        T = T(startsWith(T.FIELD, buoy), :);
        d = din;
end

end