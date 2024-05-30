function [dataTable, plotData] = analyze_attentionAdapt(dataPaths,bPlot)
%analyze data from the attentionAdapt experiment. Returns a table for running
%stats ('statTable') as well as a matrix for plotting data ('plotData').

dbstop if error

if nargin < 1 || isempty(dataPaths); dataPaths = get_dataPaths_attentionAdapt; end
if nargin < 2 || isempty(bPlot); bPlot = 0; end

loadPath = fileparts(dataPaths{1});
nSubs = length(dataPaths);
if isfile(fullfile(loadPath,sprintf('dataTable_%ds.mat',nSubs)))
    load(fullfile(loadPath,sprintf('dataTable_%ds.mat',nSubs)))
    load(fullfile(loadPath,sprintf('plotData_%ds.mat',nSubs)))
else
    taskNames = {'dots','noDots'};
    nTask = length(taskNames);
    
    nSubj = length(dataPaths);
    
    stab = cell(1,nSubj);
    for s = 1:nSubj
        dataPath = dataPaths{s};
        fprintf('Processing subject %d: %s \n',s,dataPath);
        
        ttab = cell(1,nTask);
        for t = 1:nTask
            task = taskNames{t};
            
            if t == 1
                load(fullfile(dataPath,'fdata_conddots.mat'))
            else
                load(fullfile(dataPath,'fdata_condnoDots.mat'))
            end
            %  note: these files were generated with gen_fdata_attentionAdapt(dataPath)
            
              % load(fullfile(dataPath,'session1','expt.mat'),'expt')
          %   load(fullfile(dataPath,'session2','expt.mat'),'expt')
%              phases.baseline = expt.inds.conds.baseline;
%              phases.hold = expt.inds.conds.hold;
%              phases.washout = expt.inds.conds.washout;
%              phases.retention = expt.inds.conds.retention;

             % using this instead of expt.inds because it removes bad trials
             phases.baseline = length(fmtdata.mels.baseline.mid50ms.rawavg.f1);
             phases.hold = length(fmtdata.mels.hold.mid50ms.rawavg.f1);
             phases.washout = length(fmtdata.mels.washout.mid50ms.rawavg.f1);
             phases.retention = length(fmtdata.mels.retention.mid50ms.rawavg.f1);
             
            phaseNames = fieldnames(phases);
            nPhases = length(phaseNames);
            
            ptab = cell(1,nPhases);
            for p = 1:nPhases
                phase = phaseNames{p};
                if strcmp(phase,'washout') || strcmp(phase,'retention')
                %    phaseBeg = phases.(phase)(1);
                    phaseBeg = 1;
                    phaseI = phaseBeg:phaseBeg+9;
                else
                    phaseEnd = phases.(phase)(end);
                    phaseI = phaseEnd-9:phaseEnd;
                end
                
                baseEnd = phases.baseline(end);
                baseI = baseEnd-9:baseEnd;
                
                if p == 1 %aggregate all trials into a big matrix for potting
                    plotData.f1.(task)(s,:) = [fmtdata.mels.baseline.first50ms.rawavg.f1 fmtdata.mels.hold.first50ms.rawavg.f1...
                        fmtdata.mels.washout.first50ms.rawavg.f1 fmtdata.mels.retention.first50ms.rawavg.f1]...
                        - mean(fmtdata.mels.baseline.first50ms.rawavg.f1(baseI),'omitnan');
                    
                    plotData.f2.(task)(s,:) = [fmtdata.mels.baseline.first50ms.rawavg.f2 fmtdata.mels.hold.first50ms.rawavg.f2...
                        fmtdata.mels.washout.first50ms.rawavg.f2 fmtdata.mels.retention.first50ms.rawavg.f2]...
                        - mean(fmtdata.mels.baseline.first50ms.rawavg.f2(baseI),'omitnan');
                    nTrials = size(plotData.f2.(task),2);
                    for i = 1:nTrials
                        plotData.proj.(task)(s,i) = dot([plotData.f1.(task)(s,i) plotData.f2.(task)(s,i)],-expt.shifts.mels{1})./expt.shiftMag;
                    end
                end
                
                %get means in phase for stats
                dat.f1 = mean(fmtdata.mels.(phase).first50ms.rawavg.f1(phaseI),'omitnan')-mean(fmtdata.mels.baseline.first50ms.rawavg.f1(baseI),'omitnan');
                dat.f2 = mean(fmtdata.mels.(phase).first50ms.rawavg.f2(phaseI),'omitnan')-mean(fmtdata.mels.baseline.first50ms.rawavg.f2(baseI),'omitnan');
                
                dat.proj = dot([dat.f1 dat.f2],-expt.shifts.mels{1})./expt.shiftMag;

                %create paired plot data structure
                plotData.paired.(phase).f1.(task)(s) = dat.f1;
                plotData.paired.(phase).f2.(task)(s) = dat.f2;       
                plotData.paired.proj.(task)(s) = dat.proj;

                fact.task = task;
                fact.phase = phase;
                fact.subj = s;
                ptab{p} = get_datatable(dat,fact);
            end
            ttab{t} = vertcat(ptab{:});
        end
        stab{s} = vertcat(ttab{:});
    end
    dataTable = vertcat(stab{:});
    
    [savePath] = fileparts(dataPaths{1});
    save(fullfile(savePath,sprintf('dataTable_%ds.mat',nSubs)),'dataTable');
    % writetable(dataTable,fullfile(savePath,'dataTable'))
    save(fullfile(savePath,sprintf('plotData_%ds.mat',nSubs)),'plotData');
end

%% stats
%remove baseline and retention for anova analysis. subject is random factor
miniTable = dataTable(~ismember(dataTable.phase,'baseline')&~ismember(dataTable.phase,'retention'),:);
[p,tbl,stats] = anovan(miniTable.f1,{miniTable.task miniTable.phase miniTable.subj},...
   'model',[1 0 0; 0 1 0; 0 0 1; 1 1 0;],'varnames',{'task','phase','subj'},'random',3);

%eta squared
eta.task = 946.5 ./ (946.5 + 43273);
eta.phase = 2863 ./ (2863+ 43273);
eta.interaction = 6.2 ./ (6.2 + 43273);

%t-tests against 0 for measuring adaptation
phases = {'hold','washout'};
nP = length(phases);
conds = {'noDots','dots'}
nC = length(conds);
for p = 1:nP
    for c = 1:nC
        ind = ismember(dataTable.phase,phases{p})&ismember(dataTable.task,conds{c});
        dat = dataTable.f1(ind);
        m = mean(dat,'omitnan');
        s = ste(dat);
        [h,pval,ci,stats] = ttest(dat);
        dtable = meanEffectSize(dat,Effect="cohen");
        d = dtable{1,1};
        fprintf('phase: %s; cond: %s; mean %.2f; ste %.2f; p %.5f; t %.2f; df: %.2f; d %.2f\n',....
            phases{p},conds{c},m,s,pval,stats.tstat, stats.df, d)

    end
end

%retention comparison
%t-tests against 0 for measuring adaptation
phases = {'retention'};
nP = length(phases);
conds = {'noDots','dots'};
nC = length(conds);
for p = 1:nP
    for c = 1:nC
        ind = ismember(dataTable.phase,phases{p})&ismember(dataTable.task,conds{c});
        dat = dataTable.f1(ind);
        m = mean(dat,'omitnan');
        s = ste(dat);
        [h,pval,ci,stats] = ttest(dat);
        dtable = meanEffectSize(dat,Effect="cohen");
        d = dtable{1,1};
        fprintf('phase: %s; cond: %s; mean %.2f; ste %.2f; p %.5f; t %.2f; df: %.2f; d %.2f\n',....
            phases{p},conds{c},m,s,pval,stats.tstat, stats.df, d)
    end
end

% compare conditions in whole hold phase, post-hoc t-tests
hold.dots = mean(plotData.f1.dots(:,51:150),2,'omitnan');
hold.noDots = mean(plotData.f1.noDots(:,51:150),2,'omitnan');
[h,p,ci,stats] = ttest2(hold.dots,hold.noDots);
diffAdapt = hold.dots-hold.noDots;
mean(diffAdapt) / std(diffAdapt); %Cohen's d

for b = 6:15
    hold.dots = mean(plotData.f1.dots(:,b*10-9:b*10),2,'omitnan');
    hold.noDots = mean(plotData.f1.noDots(:,b*10-9:b*10),2,'omitnan');   
    [h(b-5),p(b-5)] = ttest2(hold.dots,hold.noDots);
end

%% get vowel durations
nsubs = length(dataPaths);
for n = 1:nsubs
    load(fullfile(dataPaths{1},'session1','dataVals.mat'))
    durs = [dataVals(:).dur];
    load(fullfile(dataPaths{1},'session2','dataVals.mat'))
    durs = [durs [dataVals(:).dur]];
    meandur(n) = mean(durs,'omitnan');
end

%% plotting (not used for final plots...see plot_attentionComp_paperfigs.m)
if bPlot
    
    colors.noDots = [5 119 204]/255; % blue
    colors.dots = [.8 0 0]; % red

    plotColors = [colors.noDots;colors.dots];

    pageWidth = 33.5722;
    pageHeight = 13.1939;
    
    params.jitterFrac = 0.2;

    tasks = fieldnames(plotData.f1);
    h1(1) = figure;
    hold on
    for s = 1:length(tasks)
        task = tasks{s};
        dat = plotData.f1.(task);
        clear plotDat
        for b = 1:length(dat)/10
            plotDat(:,b) = mean(dat(:,(b-1)*10+1:b*10),2,'omitnan');
        end
        xvals = 1:length(plotDat);
        %     plot(xvals,mean(plotDat,'omitnan'),'Color',shiftColors(s,:),'LineWidth',2)
        %     plot_filled_err(xvals,mean(plotDat,'omitnan'),ste(plotDat),shiftColors(s,:));
        errorbar(xvals,mean(plotDat,'omitnan')*-1,ste(plotDat),'o-','Color',colors.(task),'MarkerFaceColor',colors.(task),'LineWidth',2)
    end
    ylabel('normalized F1')
    ylim([-15 60])
    xlim([0.5 21.5]);
    set(gca,'YTick',[0 36 44])
    set(gca,'XTick',[2 9.5 17 20],'XTickLabels',{'baseline','hold','washout','reten.'});
    phaselims = [3 15 18]+.5;
    nPhaselims = length(phaselims);
    for p = 1:nPhaselims
        vline(phaselims(p),'k','-');
    end
    hline(0,'k',':');
    box off
    makeFig4Printing;

    temp.noDots = -1*plotData.paired.hold.f1.noDots;
    temp.dots = -1*plotData.paired.hold.f1.dots;
    h1(2) = plot_pairedData(temp,plotColors,params);
%     set(gca,'XTickLabels',{'dual-task','single-task'});
    ylabel({'adaptation (mels)'})
    ylim([-30 130])
    hline(0,'k',':');
    title('End of hold')
    makeFig4Printing;

    temp.noDots = -1*plotData.paired.washout.f1.noDots;
    temp.dots = -1*plotData.paired.washout.f1.dots;
    h1(3) = plot_pairedData(temp,plotColors,params);
%     set(gca,'XTickLabels',{'dual-task','single-task'});
    ylim([-30 130])
    hline(0,'k',':');
    title('Washout')
    makeFig4Printing;

    diffMeans.hold = -1*plotData.paired.hold.f1.noDots - -1*plotData.paired.hold.f1.dots;
    diffMeans.washout = -1*plotData.paired.washout.f1.noDots - -1*plotData.paired.washout.f1.dots;
    h1(4) = plot_pairedData(diffMeans,[],params);
    set(gca,'XTickLabels',{'hold','washout'});
    ylabel({'single-task advantage (mels)'})
%     ylim([-130 30])
    hline(0,'k',':');
    makeFig4Printing;
%     corrParams.Markercolor = 'k';
%     corrParams.MarkerFaceColor = 'k';
%     corrParams.MarkerFaceAlpha = .2;
%     corrParams.markersize = 80;
    % h1(4) = plot_corr(plotData.paired.hold.f1.dots,plotData.paired.hold.f1.noDots,corrParams);
%     h1(4) = plot_corr(plotData.paired.proj.dots,plotData.paired.proj.noDots,corrParams);
% 
%     xlim([-150 150])
%     ylim([-150 150])
%     set(gca,'YTick',[-150 0 150],'XTick',[-150 0 150])
%     hline(0,'k',':');
%     vline(0,'k',':');
%     title('F1 dots v F1 no dots')
%     xlabel('F1 dots')
%     h_yLab = ylabel('F1 no dots');
%     h_yLab.Position(1) = h_yLab.Position(1)-10;
%     set(h1(4).Children,'XColor',shiftColors(1,:))
%     set(h1(4).Children,'YColor',shiftColors(2,:))
%     makeFig4Printing;
% 
    figpos_cm = [1 25 pageWidth pageHeight];
    h_all = figure('Units','centimeters','Position',figpos_cm);
    copy_fig2subplot(h1,h_all,1,5,{[1 2] 3 4 5},1);
end
