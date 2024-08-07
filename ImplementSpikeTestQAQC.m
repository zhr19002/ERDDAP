function d = ImplementSpikeTestQAQC(din)
% 
% Apply IOOS QARTOD Spike on data  
% Set 1 for pass, 4 for fail, and 3 for suspicious
% 
% Called from CheckBuoyDataQAQC.m
% 

d = ones(size(din));  % Set QAQC code to 1
SPK_REF = (din(1:end-2) + din(3:end))/2;
SPK_REF = SPK_REF([1 1:end end]);
SPK = abs(din-SPK_REF);

isus = find(SPK > prctile(SPK,99));  % Find minor spikes
if ~isempty(isus)
    d(isus) = 3;
end

ifail = find(SPK > prctile(SPK,99.9) | isnan(din));  % Find big spikes
if ~isempty(ifail)
    d(ifail) = 4;
end

end