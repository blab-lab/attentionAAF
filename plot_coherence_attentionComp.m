function plot_coherence_attentionComp(dataPaths)

if nargin < 1 || isempty(dataPaths), dataPaths = get_dataPaths_attentionComp;
end

nSubs = length(dataPaths);

for i = 1:nSubs
    load(fullfile(dataPaths{i},'expt.mat'),'expt')
    data = get_acoustLocalPath(expt.snum,expt.coherence);
end

%plot
h = figure;
line(nSubs,'expt.coherence')
%plot(trialTracksUp,'Color',[.7 1 .7])
ylabel('coherence threshold')
xlabel('participant')
ylim([0 1])
set(gca,'XTick',[],'FontSize',20)

makeFig4Screen
