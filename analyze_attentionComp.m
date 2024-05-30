function [compMeans, Vdurss,coherence] = analyze_attentionComp(dataPath,dataFile,analysisType,bGenData)
if nargin < 1 || isempty(dataPath), dataPath = get_acoustLoadPath('attentionComp'); end
if nargin < 2 || isempty(dataFile), dataFile = 'fmtMatrix_dotsnoDots_merged_26s.mat'; end
if nargin < 3 || isempty(analysisType), analysisType = 'proj'; end
if nargin < 4 || isempty(bGenData), bGenData = 0; end

%define participant data paths
dataPaths = get_dataPaths_attentionComp;
nSubs = size(dataPaths,2);

%% Generate or load data
if bGenData
    %load formant matrix data
    load(fullfile(dataPath,dataFile));

    %define analysis windows in ms
    window = [200 300;300 400];
    windowNames = {'early','late'};
    nWindows = size(window,1);
    %convert window to samples
    tWindow = floor(window./tstep/1000);

    %get means
    conds = fieldnames(rfx.(analysisType));
    nConds = length(conds);

    compMeans = struct;
    Vdurss = struct;
    coherence = [];
    for s = 1:nSubs
        disp(s)
        for w = 1:nWindows
            wind = windowNames{w};
            for c = 1:nConds
                cond = conds{c};
                compMeans.(wind).(cond)(s) = mean(rfx.(analysisType).(cond)(tWindow(w,1):tWindow(w,2),s),'omitnan');
            end
        end
        load(fullfile(dataPaths{s},'dataVals'))
        load(fullfile(dataPaths{s},'expt'))
        coherence(s) = expt.coherence(1);
        for t = 1:length(dataVals)
            if dataVals(t).bExcl
                durs(t) = NaN;
            else
                durs(t) = dataVals(t).dur;
            end
        end
        for c = 1:nConds
            cond = conds{c};
            Vdurss.(cond)(s) = mean(durs(expt.inds.dots.(cond)),'omitnan');
        end
    end

    save(fullfile(get_acoustLoadPath('attentionComp'),sprintf('compensation_%ds.mat',nSubs)),"compMeans",'-mat')
    save(fullfile(get_acoustLoadPath('attentionComp'),sprintf('vowelDurations_%ds.mat',nSubs)),"Vdurss",'-mat')
    save(fullfile(get_acoustLoadPath('attentionComp'),sprintf('coherences_%ds.mat',nSubs)),"coherence",'-mat')
else
    load(fullfile(get_acoustLoadPath('attentionComp'),sprintf('compensation_%ds.mat',nSubs)));
    load(fullfile(get_acoustLoadPath('attentionComp'),sprintf('vowelDurations_%ds.mat',nSubs)));
    load(fullfile(get_acoustLoadPath('attentionComp'),sprintf('coherences_%ds.mat',nSubs)));
end

%% means, se, t-tests, effect sizes for compensation
% early window 200-300 ms after vowel onset
disp('early window')
[mean(compMeans.early.noDots) ste(compMeans.early.noDots)] %single-task
[mean(compMeans.early.dots) ste(compMeans.early.dots)] %dual-task
[h,p,~,stats] = ttest(compMeans.early.noDots,compMeans.early.dots,'tail','right') %t-test
diff.means.early = compMeans.early.noDots-compMeans.early.dots;
mean(diff.means.early) / std(diff.means.early) %Cohen's d

% late window 300-400 ms after vowel onset
disp('late window')
[mean(compMeans.late.noDots) ste(compMeans.late.noDots)] %single-task
[mean(compMeans.late.dots) ste(compMeans.late.dots)] %dual-task
[h,p,~,stats] = ttest(compMeans.late.noDots,compMeans.late.dots,'tail','right') %t-test
diff.means.late= compMeans.late.noDots-compMeans.late.dots;
mean(diff.means.late) / std(diff.means.late) %Cohen's d

%% means, se, t-tests, effect sizes for vowel duration
disp('vowel duration')
[mean(Vdurs.noDots) ste(Vdurs.noDots)]*1000 %single-task
[mean(Vdurs.dots) ste(Vdurs.dots)]*1000 %dual-task
[h,p,~,stats] = ttest(Vdurs.noDots,Vdurs.dots) %t-test
diff.means.Vdurs = Vdurs.noDots-Vdurs.dots;
mean(diff.means.Vdurs) / std(diff.means.Vdurs) %Cohen's d

%% means, se, range for coherence
disp('coherence')
[mean(coherence) std(coherence)] 
[min(coherence) max(coherence)]

