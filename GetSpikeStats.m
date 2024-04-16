function [prc] = GetSpikeStats(S, avar, av)
% 
% Look at the time sereis and find the stats of the 
% spikes as defined by the 
% https://cdn.ioos.noaa.gov/media/2020/03/QARTOD_TS_Manual_Update2_200324_final.pdf
% 
% called from PlotARTG_2018_21_S_T_DO_summary
% 
prc = cell(1, length(av));
for nl = 1:length(av)
    if isfield(S.(av{nl}), avar)
        d = S.(av{nl}).(avar).data;
        spk = abs(d(2:end-1) - (d(3:end) + d(1:end-2))/2);
        % get teh 99 and 99.9 percentile
        prc{nl} = prctile(spk, [99.9 99.99]);
    else
        prc{nl} = [];
    end
end

end