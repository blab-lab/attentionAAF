function [h] = plot_attentionCompPaperFigs(figs2plot)
%PLOT_ATTENTIONCOMPPAPERFIGS Plot figures for attentionComp/Adapt paper.

if nargin < 1 || isempty(figs2plot), figs2plot = 1; end

dataPaths = get_dataPaths_attentionComp;

colors.noShift = [0 0 0];
colors.shiftUp = [0 0 0];
colors.shiftDown = [0 0 0];
colors.noDots = [5 119 204]/255; % blue
colors.dots = [.8 0 0]; % red
colors.adapt = {colors.noDots colors.dots};
colors.shading = [.9 .9 .9];

pageWidth = 33.5722;
pageHeight = 13.1939;

%% Figure 1

[bPlot,ifig] = ismember(1,figs2plot);
if bPlot

    markerSize = 1.5;

    h(ifig) = figure('Position',[25 350 1500 420]);
    tiledlayout(4,3);

    %% compensation
    nexttile(2,[2 1]);
    dataPath = dataPaths{1}; % sp...
    load(fullfile(dataPath,'expt.mat'),'expt');
    ntrials2plot = expt.ntrials;
    stem(expt.inds.conds.noShift,0*ones(1,length(expt.inds.conds.noShift)),'MarkerEdgeColor',colors.noShift,'MarkerFaceColor',colors.noShift,'Color',colors.noShift,'MarkerSize',markerSize)
    hold on;
    stem(expt.inds.conds.shiftAE,125*ones(1,length(expt.inds.conds.shiftAE)),'MarkerEdgeColor',colors.shiftUp,'MarkerFaceColor',colors.shiftUp,'Color',colors.shiftUp,'MarkerSize',markerSize)
    stem(expt.inds.conds.shiftIH,-125*ones(1,length(expt.inds.conds.shiftIH)),'MarkerEdgeColor',colors.shiftDown,'MarkerFaceColor',colors.shiftDown,'Color',colors.shiftDown,'MarkerSize',markerSize)
    ylim([-150 150]);
    set(gca,'YTick',-125:125:125)
    xlabel('trial')
    ylabel({'F1 perturbation' '(mels)'})

    ax = axis; ylims = ax([3 4]);
    axis([0 ntrials2plot ylims]);
    blocklength = 36;
    blockstart = 100;
    nblocks = 4;
    for b = 1:nblocks
        blockstop = blockstart+blocklength;
        h_fill = fill([blockstart blockstop blockstop blockstart],[ylims(1) ylims(1) ylims(2) ylims(2)],colors.shading,'EdgeColor','none');
        uistack(h_fill,'bottom');
        blockstart = blockstart+blocklength*2;
    end
    box off;

    %% adaptation
    holdMag = 125;
    for tilenum = [8 11]
        nexttile(tilenum);
        hold on;
        hl = plot([0 1.5 2.5 10.5 10.5 10.5 12],[0 0 holdMag holdMag NaN 0 0],'Color',colors.noDots,'LineWidth',2);
        axlim = [0 12 -15 150];
        axis(axlim);
        set(gca,'YTick',[0 125])
        hline(0,'k','--');
        vline(1.5,'k',':');
        vline(2.5,'k',':');
        vline(10.5,'k',':');
        vline(11.5,'k',':');
        % ylabel('perturbation')
        ylabel({'F1 perturbation' '(mels)'})

        ypos = 60; fontsize = 7; rot = 55;
        text(.75,ypos,'baseline','FontSize',fontsize,'HorizontalAlignment','center','Rotation',rot)
        text(2,ypos,'ramp','FontSize',fontsize,'HorizontalAlignment','center','Rotation',rot)
        text(3,ypos,'hold','FontSize',fontsize,'HorizontalAlignment','center','Rotation',rot)
        text(11,ypos,'washout','FontSize',fontsize,'HorizontalAlignment','center','Rotation',rot)
        text(12,ypos,'retention','FontSize',fontsize,'HorizontalAlignment','center','Rotation',rot)

    end
    xlabel('block number (40 trials/block)')

    ax = axis; xlims = ax([1 2]); ylims = ax([3 4]);
    hl.Color = colors.dots;
    h_fill = fill([xlims(1) xlims(2) xlims(2) xlims(1)],[ylims(1) ylims(1) ylims(2) ylims(2)],colors.shading,'EdgeColor','none');
    uistack(h_fill,'bottom');

end

%% Fig 2: compensation

[bPlot,ifig] = ismember(2,figs2plot);
if bPlot
    %% load data
    dataPath = get_acoustLoadPath('attentionComp');
    dataFile = 'compensation_26s.mat';
    load(fullfile(dataPath,dataFile));
    plotParams.jitterFrac = 0.2;
    
    %% A: group fmtTrack comp
    h2(1) = plot_fmtMatrix_attentionComp([],[],[],[],colors);
    xlabel('time from vowel onset (ms)');
    makeFig4Printing;
    makeOpaque;

    %% B, C: paired plots
    pp.ylimMin = -12;
    pp.ylimMax = 38;
    
    compMeans.early = orderfields(compMeans.early,{'noDots','dots'});
    compMeans.late = orderfields(compMeans.late,{'noDots','dots'});

    h2(2) = plot_pairedData(compMeans.early,[colors.noDots; colors.dots],plotParams);
    ylabel({'compensation (mels)'})
    ylim([pp.ylimMin pp.ylimMax])
    set(gca,'YTick',-10:10:30,'XTickLabel',{'single' 'dual'});
    h_line = hline(0,'k',':');
    h_line.HandleVisibility = 'off';
    title('200-300 ms')
    makeFig4Printing;
    makeOpaque;

    h2(3) = plot_pairedData(compMeans.late,[colors.noDots; colors.dots],plotParams);
    ylim([pp.ylimMin pp.ylimMax])
    set(gca,'YTick',[],'XTickLabel',{'single' 'dual'});
    h_line = hline(0,'k',':');
    h_line.HandleVisibility = 'off';
    title('300-400 ms')
    makeFig4Printing;
    makeOpaque;

    %% D: paired plots off differences
    plotParams.jitterFrac = 0.2;
    diffMeans.early = compMeans.early.noDots-compMeans.early.dots;
    diffMeans.late= compMeans.late.noDots-compMeans.late.dots;
    h2(4) = plot_pairedData(diffMeans,[],plotParams);
    ylabel({'single-task advantage (mels)'})
    set(gca,'XTickLabel',{'200-300ms' '300-400ms'});
    h_line = hline(0,'k',':');
    h_line.HandleVisibility = 'off';
    makeFig4Printing;
    makeOpaque;
    
    %% ALL
    figpos_cm = [1 25 pageWidth pageHeight];
    h(ifig) = figure('Units','centimeters','Position',figpos_cm);
    copy_fig2subplot(h2,h(ifig),1,5,...
        {[1 2],3,4,5},1);            % paired
    
end

%% Fig 3: adaptation
[bPlot,ifig] = ismember(3,figs2plot);
if bPlot
    %% load data
    dataPaths = get_dataPaths_attentionAdapt;
    loadPath = fileparts(dataPaths{1});
    nSubs = length(dataPaths);
    load(fullfile(loadPath,sprintf('dataTable_20s.mat',nSubs)))
    load(fullfile(loadPath,sprintf('plotData_20s.mat',nSubs)))
    
    %% A: group fmtTrack comp
    tasks = fieldnames(plotData.f1);
    h3(1) = figure;
    hold on
    for s = 1:length(tasks)
        task = tasks{s};
        dat = plotData.f1.(task);
        clear plotDat
        for b = 1:length(dat)/10 %bin data in bins of 10 trials
            plotDat(:,b) = mean(dat(:,(b-1)*10+1:b*10),2,'omitnan');
        end
        xvals = 1:length(plotDat);
        errorbar(xvals,mean(plotDat,'omitnan')*-1,ste(plotDat),'o-','Color',colors.(task),'MarkerFaceColor',colors.(task),'LineWidth',2)
    end
    ylabel({'adaptation (mels)'})
    ylim([-15 60])
    xlim([0.5 21.5]);
    % set(gca,'YTick',[0 36 44])
    set(gca,'XTick',[2 9.5 17 20],'XTickLabels',{'baseline','hold','washout','reten.'});
    phaselims = [3 15 18]+.5;
    nPhaselims = length(phaselims);
    for p = 1:nPhaselims
        vline(phaselims(p),'k','-');
    end
    hline(0,'k',':');
    box off

    makeFig4Printing;

    %% B, C: paired plots
    plotParams.jitterFrac = 0.2;
        
    temp.noDots = -1*plotData.paired.hold.f1.noDots;
    temp.dots = -1*plotData.paired.hold.f1.dots;
    h3(2) = plot_pairedData(temp,[colors.noDots; colors.dots],plotParams);
    set(gca,'XTickLabels',{'single','dual'});
    ylabel({'adaptation (mels)'})
    ylim([-30 130])
    hline(0,'k',':');
    title('End of hold')
    makeFig4Printing;

    temp.noDots = -1*plotData.paired.washout.f1.noDots;
    temp.dots = -1*plotData.paired.washout.f1.dots;
    h3(3) = plot_pairedData(temp,[colors.noDots; colors.dots],plotParams);
    set(gca,'YTick',[],'XTickLabels',{'single','dual'});
    ylim([-30 130])
    hline(0,'k',':');
    title('Washout')
    makeFig4Printing;
    
    %% D: paired plots off differences
    diffMeans.hold = -1*plotData.paired.hold.f1.noDots - -1*plotData.paired.hold.f1.dots;
    diffMeans.washout = -1*plotData.paired.washout.f1.noDots - -1*plotData.paired.washout.f1.dots;
    h3(4) = plot_pairedData(diffMeans,[],plotParams);
    set(gca,'XTickLabels',{'hold','washout'});
    ylabel({'single-task advantage (mels)'})
    hline(0,'k',':');
    makeFig4Printing;
    
    %% ALL
    figpos_cm = [1 25 pageWidth pageHeight];
    h(ifig) = figure('Units','centimeters','Position',figpos_cm);
    copy_fig2subplot(h3,h(ifig),1,5,...
        {[1 2],3,4,5},1);            % paired
    
end