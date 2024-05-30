function calc_RDKcorrelation

%% adaptation
adaptPath = get_acoustLoadPath('attentionAdapt');

%load adaptation data
load(fullfile(adaptPath,'dataTable_20s.mat'),'dataTable')

%caculate RDK performance
dataPaths = get_dataPaths_attentionAdapt;
RDKperf_adapt = get_RDKperformance(dataPaths,'adapt');

%get single adapt value for each participant
subs = unique(dataTable.subj);
adapt = nan(1,length(subs));
for s = subs
    adapt(s) = dataTable.f1(ismember(dataTable.task,'dots') & ...
        ismember(dataTable.phase,'hold') & ...
        ismember(dataTable.subj, s));
end
    
[r,p]  = corr(RDKperf_adapt',adapt')

%% compensation
compPath = get_acoustLoadPath('attentionComp');

%load adaptation data
load(fullfile(compPath,'compensation_26s.mat'),'compMeans')

%caculate RDK performance
dataPaths = get_dataPaths_attentionComp;
RDKperf_comp = get_RDKperformance(dataPaths,'comp');

    
[r,p]  = corr(RDKperf_comp',compMeans.early.dots')