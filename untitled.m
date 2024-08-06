clc; clear;
buoy = 'CLIS1'; % {'ARTG','CLIS1','CLIS2','EXRX','WLIS'}

din = load([buoy '_MET_QAQC.mat']);
avar = ["windSpd_Kts";"windDir_M"];

% Jump limit and spike parameters
min_jmp = zeros(length(avar),1); max_jmp = zeros(length(avar),1);
for av = 1:length(avar)
    % Change location
    if av == 1
        d = din.MetQAQC.(avar{av}).data;
    else
        d = din.MetQAQC.(avar{av}).data;
        d = cos(d*pi/180);
    end
    
    % min_jump and max_jump values
    jmp = abs(diff(d));
    jmp = jmp([1 1:end]);
    min_jmp(av) = prctile(jmp,99);
    max_jmp(av) = prctile(jmp,99.9);
end

jmp_spk_tbl = table(avar,min_jmp,max_jmp);
disp(jmp_spk_tbl);