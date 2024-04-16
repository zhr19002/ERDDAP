function d = ImplementSpikeTestQAQC(din, Para, ainst)
% 
% Apply IOOS QARTOD Spike on data  
% 
% Set 1 for pass, 4 for fail and 3 for suspious
% 
% Called from MakeDataArchive.m
% 

if contains(ainst, 'btm')
    ptop = Para.THRSHLD(2,2);      % Select thresholds for the bottom
    pbot = Para.THRSHLD(2,1);
else
    ptop = Para.THRSHLD(1,2);      % Select thresholds for the surface
    pbot = Para.THRSHLD(1,1);
end

d = ones(size(din));               % Set QAQC code to 1
SPK_REF = (din(1:end-2) + din(3:end))/2;
SPK_REF = SPK_REF([1 1:end end]);
SPK = abs(din-SPK_REF);

ifail = find(SPK>ptop);            % Find big spikes
if ~isempty(ifail)
    d(ifail) = 4;
end

isus = find(SPK>pbot & SPK<ptop, 1);  % Find minor spikes
if ~isempty(isus)
    d(ifail) = 3;
end

end