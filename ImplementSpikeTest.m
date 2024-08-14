function d = ImplementSpikeTest(din)
% 
% Apply IOOS QARTOD Spike on data  
% Set 1 for pass, 4 for fail, and 3 for suspicious
% 
% Called from CheckBuoyDataQAQC.m
% 

d = ones(size(din));  % Set QAQC code to 1
spk_ref = (din(1:end-2) + din(3:end))/2;
spk_ref = spk_ref([1 1:end end]);
spk = abs(din-spk_ref);

isus = find(spk>prctile(spk,99));  % Find minor spikes
if ~isempty(isus)
    d(isus) = 3;
end

ifail = find(spk>prctile(spk,99.9) | isnan(din));  % Find big spikes
if ~isempty(ifail)
    d(ifail) = 4;
end

end