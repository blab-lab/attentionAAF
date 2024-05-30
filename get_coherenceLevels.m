function coherence = get_coherenceLevels(dataPaths)
if nargin>1 || isempty(dataPaths)
    dataPaths = get_dataPaths_attentionAdapt;
end

nSubs = length(dataPaths);

for s = 1:nSubs
    load(fullfile(dataPaths{s},'expt.mat'))
    if length(expt.coherence)>1
        coherence(s) = expt.coherence(1);
    else
        coherence(s) = expt.coherence;
    end
end