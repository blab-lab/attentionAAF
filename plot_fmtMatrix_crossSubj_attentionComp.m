function [hfig] = plot_fmtMatrix_crossSubj_attentionComp(dataPath,plotfile,toPlotList,errtype,bsigbar,fx,linecolors,plotParams)
%PLOT_FMTMATRIX_CROSSSUBJ  Plot magnitude of compensation across subjects.
%   PLOT_FMTMATRIX_CROSSSUBJ(DATAPATH,PLOTFILE,TOPLOTLIST,ERRTYPE,BSIGBAR,FX,LINECOLORS)
%   plots formant tracks per condition across multiple subjects.
%
% cn 11/2014

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 3 || isempty(toPlotList), toPlotList = {'proj'}; end
if nargin < 4 || isempty(errtype), errtype = 'se'; end
if nargin < 5 || isempty(bsigbar), bsigbar = 1; end
if nargin < 6 || isempty(fx)
    fx = {'ffx'};
elseif ~iscell(fx)
    fx = {fx};
end
if nargin < 7, linecolors = []; end
if nargin < 8, plotParams = []; end

% set default plot params
pDefault.lineWidth = 1.5;
pDefault.facealpha = 0.3;
pDefault.xlab = 'time (ms)';
pDefault.bDualAx = 0;
plotParams = set_missingFields(plotParams,pDefault);

% load data
fmtData = load(fullfile(dataPath,plotfile)); % e.g. fmtTraces_10s.mat
ffx = fmtData.ffx;
rfx = fmtData.rfx;
tstep = fmtData.tstep;
analyses = fieldnames(ffx);
if ~isempty(linecolors)
    fmtData.linecolors = linecolors;
end

% calculate mean and errorbars
fprintf('Calculating means and error (%s)...',errtype);
for a = 1:length(analyses)
    anl = analyses{a};
    conds = fieldnames(ffx.(anl));
    for c = 1:length(conds)
        cond = conds{c};
        ffx_mean.(anl).(cond) = nanmean(ffx.(anl).(cond),2);
        rfx_mean.(anl).(cond) = nanmean(rfx.(anl).(cond),2);
        ffx_err.(anl).(cond) = get_errorbars(ffx.(anl).(cond),errtype);
        rfx_err.(anl).(cond) = get_errorbars(rfx.(anl).(cond),errtype);
    end
end
fprintf(' done.\n');
data_mean = struct('ffx',ffx_mean,'rfx',rfx_mean);
data_err = struct('ffx',ffx_err,'rfx',rfx_err);

alltime = 0:tstep*1000:1000;
conds = fieldnames(ffx.rawf1);
stop_ms = 410;
stop = ms2samps(stop_ms,1/tstep)*ones(1,length(conds)); % crop axis to here

% calculate significance at each timepoint (assumes 2 conds)
if bsigbar
    fprintf('Calculating significance...');
    for a = 1:length(analyses)
        anl = analyses{a};
        conds = fieldnames(ffx.(anl))
        for t = 1:stop(1)
            [h.ffx.(anl)(t),p.ffx.(anl)(t)] = ttest2(ffx.(anl).(conds{1})(t,:),ffx.(anl).(conds{2})(t,:),[],'right');
            [h.rfx.(anl)(t),p.rfx.(anl)(t)] = ttest2(rfx.(anl).(conds{1})(t,:),rfx.(anl).(conds{2})(t,:),[],'right');
            [h1.ffx.(anl)(t),p1.ffx.(anl)(t)] = ttest(ffx.(anl).(conds{1})(t,:),[],[],'right');
            [h1.rfx.(anl)(t),p1.rfx.(anl)(t)] = ttest(rfx.(anl).(conds{1})(t,:),[],[],'right');
            [h2.ffx.(anl)(t),p2.ffx.(anl)(t)] = ttest(ffx.(anl).(conds{2})(t,:),[],[],'right');
            [h2.rfx.(anl)(t),p2.rfx.(anl)(t)] = ttest(rfx.(anl).(conds{2})(t,:),[],[],'right');          
        end
    end
    fprintf(' done.\n');
end

%% plot

% plot setup

% set line colors
if ~isfield(fmtData,'linecolors') % if no linecolors loaded or passed in
    linecolors = get_colorStruct(conds);
elseif ~isstruct(fmtData.linecolors) %ismatrix(linecolors)
    linecolors = get_colorStruct(conds,fmtData.linecolors);
else
    linecolors = fmtData.linecolors;
end
linestyles = {'-.',':','-','--'};

% account for short mean traces by decreasing stop point
% for c=1:length(conds) 
%     if length(rfx_mean.diff2d.(conds{c})) < stop(c)
%         stop(c) = length(rfx_mean.diff2d.(conds{c}));
%     end    
% end

% plot
if ischar(toPlotList), toPlotList = {toPlotList}; end
titles = toPlotList;
ylabs = toPlotList;
for f=1:length(fx)
    for fn=1:length(toPlotList)
        toPlot = toPlotList{fn};
        hfig = figure; %axes('Visible','off');
        % plot only means (for legend)
        conds = fieldnames(ffx.(toPlot));
        for c = 1:length(conds)
            cond = conds{c};
            linecolor = linecolors.(cond);
            errcolor = linecolor; %get_lightcolor(linecolor);
            linestyle = linestyles{mod(c,length(linestyles))+1};
            
            if plotParams.bDualAx
                if ~mod(c,2)
                    yyaxis left;
                else
                    yyaxis right;
                end
            end
            
            % plot tracks
            sig = data_mean.(fx{f}).(toPlot).(cond)(1:stop(c));
            hlin(c) = plot(alltime(1:length(sig)), sig', 'LineWidth',3, 'Color',linecolor, 'LineStyle',linestyle); hold on;
            % plot errorbars
            err = data_err.(fx{f}).(toPlot).(cond)(1:stop(c));
            %err = get_errorbars(fmtMatrix.(toPlot).(cnd),errtype,size(fmtMatrix.(toPlot).(cnd),2));
            sig = sig(~isnan(err));
            err = err(~isnan(err));
            t = alltime(~isnan(err));

            hf = plot_filled_err(t,sig',err',errcolor,plotParams.facealpha);
            uistack(hf,'bottom');

            %fill([alltime(1:length(sig)) fliplr(alltime(1:length(sig)))], [sig'+err' fliplr(sig'-err')], errcolor, 'EdgeColor', errcolor, 'FaceAlpha', .5, 'EdgeAlpha', 0);
            %hashalf_s(c) = find(hashalf.(cnd), 1, 'last')*tstep; %#ok<AGROW>
            %hasquart_s(c) = find(hasquart.(cnd), 1, 'last')*tstep; %#ok<AGROW>            
            
        end
        hline(0,'k');

        %vline(mean(hashalf_s),'k','--');
        legend(hlin, conds, 'Location','NorthWest'); legend boxoff;
        xlabel(plotParams.xlab, 'FontSize', 20);
        ylabel(ylabs{fn}, 'FontSize', 20);
        set(gca, 'FontSize', 20);
        set(gca, 'LineWidth', 1);
        %title(sprintf('%s (%s)',titles{fn},fx{f}));
        set(gcf,'Name',sprintf('%s (%s)',titles{fn},fx{f}));
        %title(sprintf('%s %s',slab,toPlot));
        %set(gca,'XTick',(0:.1:alltime(stop(c)))); set(gca, 'TickLength', [0.0 0.0]);

        ymin = -5; %ax(3);
        ymax = 15; %ax(4);
        
        if plotParams.bDualAx
            yyaxis left;
            axis([alltime(1) alltime(stop(c)) ymin ymax])
            haxL = gca;
            %haxL.YColor = [0 0 0];
            haxL.YColor = linecolors.(conds{1});
            
            yyaxis right;
            axis([alltime(1) alltime(stop(c)) ymin ymax])
            haxR = gca;
            %haxR.YColor = [0 0 0];
            haxR.YColor = linecolors.(conds{2});
            axRpos = haxR.Position;
            haxR.YDir = 'reverse';
            haxR.Position = axRpos;
        else
            axis([alltime(1) alltime(stop(c)) ymin ymax])
            box off
        end
        
        if bsigbar
            [h_fdr] = fdr(p.(fx{f}).(toPlot),0.05);
            % [h_fdr,p.fdr]
            h_fdr(h_fdr==0) = NaN;

            [h_fdr10] = fdr(p.(fx{f}).(toPlot),0.10);
            % [h_fdr10, p..fdr10]
            h_fdr10(h_fdr10==0) = NaN;

            h.(fx{f}).(toPlot)(h.(fx{f}).(toPlot)==0) = NaN;
            h1.(fx{f}).(toPlot)(h1.(fx{f}).(toPlot)==0) = NaN;
            h2.(fx{f}).(toPlot)(h2.(fx{f}).(toPlot)==0) = NaN;
            
            plot(t,h.(fx{f}).(toPlot)*(ymax-5),'g','LineWidth',2)
            plot(t,h1.(fx{f}).(toPlot)*(ymax-4),'Color',linecolors.(conds{1}),'LineWidth',2)
            plot(t,h2.(fx{f}).(toPlot)*(ymax-3),'Color',linecolors.(conds{2}),'LineWidth',2)
            
            plot(t,h_fdr*(ymax-2),'m-','LineWidth',2)
            plot(t,h_fdr10*(ymax-1),'c-','LineWidth',2)
        end
    end
end