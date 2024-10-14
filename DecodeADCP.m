function res = DecodeADCP(hexStr)
% 
% Read an ASCII hex string from RDI ADCP embedded PD12 data
% Return a Matlab structure with the converted data
% 
% Calls swapChar: swap bytes due to endian difference
% Called from WriteADCP.m
% 

if length(hexStr) < 4
    error('Not a valid hex string');
end

res.ID = swapChar(hexStr(1:4));
if ~strcmp(res.ID, '7F6E')
    error('Not a PD12 hex string');
end
res.ens_size = hex2dec(swapChar(hexStr(5:8)));
res.ens_num = hex2dec([swapChar(hexStr(13:16)), swapChar(hexStr(9:12))]);
res.unit_ID = hex2dec(hexStr(17:18));
res.FW_Vers_CPU = hex2dec(hexStr(19:20));
res.FW_Rev_CPU = hex2dec(hexStr(21:22));
res.year = hex2dec(swapChar(hexStr(23:26)));
res.month = hex2dec(hexStr(27:28));
res.day = hex2dec(hexStr(29:30));
res.hour = hex2dec(hexStr(31:32));
res.min = hex2dec(hexStr(33:34));
res.sec = hex2dec(hexStr(35:36));
res.Hsec = hex2dec(hexStr(37:38));
res.heading = 0.01*hex2dec(swapChar(hexStr(39:42)));
res.pitch = 0.01*hex2dec(swapChar(hexStr(43:46)));
res.roll = 0.01*hex2dec(swapChar(hexStr(47:50)));
res.temp = 0.01*hex2dec(swapChar(hexStr(51:54)));
res.press = hex2dec([swapChar(hexStr(59:62)), swapChar(hexStr(55:58))]);

% Bits 0-3 contain the velocity component flags of the PO command
% Bits 4-7 contain the bin subsampling parameter of the PB command
% bit 7 6 5 4  3 2 1 0
%     x x x x  1 x x x component 4
%     x x x x  x 1 x x component 3
%     x x x x  x x 1 x component 2
%     x x x x  x x x 1 component 1
%     n n n n  x x x x sub-sampling parameter
res.components = hexStr(63:64);
res.start_bin = hex2dec(hexStr(65:66));
res.N_bins = hex2dec(hexStr(67:68));

% Calculate # of velocities (usually 4) from the size of hexStr and # of bins
N_vels = (length(hexStr)/2-36)/(res.N_bins-(res.start_bin-1))/2;
if N_vels - floor(N_vels) ~= 0
    error('Non-integer value for # of beams/velocities');
end

% Step through velocities and put them into an (N_bins*N_vels) array
for n = res.N_bins:-1:1
    for m = N_vels:-1:1
        idx = 69 + 4*(n-1) + 4*(m-1)*res.N_bins;
        res.vels(n,m) = hex2dec(swapChar(hexStr(idx:idx+3)));
        % The storage format for signed int is wrapped as "uint" at 2^16
        if res.vels(n,m) >= 2^15
            res.vels(n,m) = res.vels(n,m) - 2^16;
        end
    end
end
res.vels = 0.1*res.vels; % Convert unit to cm/s
res.chksum = hex2dec(swapChar(hexStr(end-3:end)));
res.mtime = datetime(res.year, res.month, res.day, res.hour, res.min, res.sec+res.Hsec*.01);
end

%%
% 
% Swap the first two characters with the third and fourth characters
% 
function output = swapChar(input)

output = [input(3:4), input(1:2)];

end