function [compensation,sigComp,sortOrder,compStd] = plot_responses_by_participant_attentionComp(dataPaths,sortOrder,params)
%dataPaths = dataPathsNormal or dataPathsNoisy
% inds2use = [1:24 26:28 30:40];
% dataPaths = dataPaths(inds2use);
if nargin < 1 || isempty(dataPaths), dataPaths = get_dataPaths_attentionComp; end
if nargin < 2 || isempty(sortOrder), sortOrder = []; end
if nargin < 3 || isempty(params), params = struct; end

% set defaults
defaults.startTimeMs = .3;
defaults.endTimeMs = .4;
defaults.endTimeBaseMs = .1;
defaults.measSel = 'proj';
defaults.shift2use = 'all';
defaults.byTrialMeans = 0; % 0 = create an average response trial first, then average within a window; 1 = average within window for each trial, then average across trials
defaults.avgType = 'mean';
params = set_missingFields(params,defaults,0);
measSel = params.measSel;

nSubs = length(dataPaths);
compensation.dots = nan(1,nSubs);
compensation.nodots = nan(1,nSubs);
%compensation = nan(1,nSubs);
compStd.dots = nan(1,nSubs);
compStd.nodots = nan(1,nSubs);
sigComp = nan(1,nSubs);
sigCompHighA = nan(1,nSubs);
errs = nan(1,nSubs);

trialTracksIHdots = NaN(100,nSubs);
trialTracksIHnodots = NaN(100,nSubs);
trialTracksAEdots = NaN(100,nSubs);
trialTracksAEnodots = NaN(100,nSubs);
for i = 1:nSubs
     plot_fmtMatrix_attentionComp(dataPaths{i},'fmtMatrix_shiftIHdotsshiftIHnodotsshiftAEdotsshiftAEnodots_merged.mat','proj')
     set(gcf,'Units','Normalized','position',[0.1 0.5 0.4 0.4])
     ylim([-50 50]);
     xlim([0.2 0.35]);
     pause;
     close all;
    
    % get data and time axis
    load(fullfile(dataPaths{i},'fmtMatrix_shiftIHdotsshiftIHnodotsshiftAEdotsshiftAEnodots_merged.mat'));
    if ~exist('tstep','var')
        load(fullfile(dataPath,'dataVals.mat'),'dataVals');
        goodtrials = find(~[dataVals.bExcl]);
        tstep = mean(diff(dataVals(goodtrials(1)).ftrack_taxis));
    end
    
    % set time windows
	startTime = floor(params.startTimeMs/tstep); %0.2
    endTime = floor(params.endTimeMs/tstep); %0.4
    maxEndTime = min([size(fmtMatrix.(measSel).shiftIHdots,1) size(fmtMatrix.(measSel).shiftIHnodots,1)...
        size(fmtMatrix.(measSel).shiftAEdots,1) size(fmtMatrix.(measSel).shiftAEnodots,1)]);
    %maxEndTime = min([find(percNaN.shiftIH <= 50, 1, 'last') find(percNaN.shiftAE <= 50, 1, 'last')]);
    endTime = min(endTime,maxEndTime);
    
    
    % get average compensation in time window
    
%             trialMeans = [-1.*nanmedian(fmtMatrix.(measSel).shiftIH(startTime:endTime,:)) ...
%                 nanmedian(fmtMatrix.(measSel).shiftAE(startTime:endTime,:))];
            if params.byTrialMeans
                trialMeansIHdots = avgFcn(fmtMatrix.(measSel).shiftIHdots(startTime:endTime,:),[],params);
                trialMeansAEdots = avgFcn(fmtMatrix.(measSel).shiftAEdots(startTime:endTime,:),[],params);
                trialMeansIHnodots = avgFcn(fmtMatrix.(measSel).shiftIHnodots(startTime:endTime,:),[],params);
                trialMeansAEnodots = avgFcn(fmtMatrix.(measSel).shiftAEnodots(startTime:endTime,:),[],params);
            else
                trialMeansIHdots = avgFcn(fmtMatrix.(measSel).shiftIHdots(startTime:endTime,:),2,params);
                trialMeansAEdots = avgFcn(fmtMatrix.(measSel).shiftAEdots(startTime:endTime,:),2,params);
                trialMeansIHnodots = avgFcn(fmtMatrix.(measSel).shiftIHnodots(startTime:endTime,:),2,params);
                trialMeansAEnodots = avgFcn(fmtMatrix.(measSel).shiftAEnodots(startTime:endTime,:),2,params);
            end
            
            trialTracksIHdots(1:length(fmtMatrix.(measSel).shiftIHdots),i) = avgFcn(fmtMatrix.(measSel).shiftIHdots,2,params);
            trialTracksAEdots(1:length(fmtMatrix.(measSel).shiftAEdots),i) = avgFcn(fmtMatrix.(measSel).shiftAEdots,2,params);
            trialTracksIHnodots(1:length(fmtMatrix.(measSel).shiftIHnodots),i) = avgFcn(fmtMatrix.(measSel).shiftIHnodots,2,params);
            trialTracksAEnodots(1:length(fmtMatrix.(measSel).shiftAEnodots),i) = avgFcn(fmtMatrix.(measSel).shiftAEnodots,2,params);

    switch params.shift2use
        case 'shiftIHdots'
            trialMeans = trialMeansIHdots;
        case 'shiftIHnodots'
            trialMeans = trialMeansIHnodots;
        case 'shiftAEdots'
            trialMeans = trialMeansAEdots;
        case 'shiftAEnodots'
            trialMeans = trialMeansAEnodots;
        case 'all'
            if params.byTrialMeans
                trialMeans = [trialMeansIHdots trialMeansIHnodots trialMeansAEdots trialMeansAEnodots];         
            else
               trialMeans.dots = nanmean([trialMeansIHdots trialMeansAEdots],2);
                trialMeans.nodots = nanmean([trialMeansIHnodots trialMeansAEnodots],2);
            %    trialMeans = nanmean([trialMeansIHdots trialMeansIHnodots trialMeansAEdots trialMeansAEnodots],2);
            end
    end
    
    compensation.dots(i) = nanmean(trialMeans.dots);
    compensation.nodots(i) = nanmean(trialMeans.nodots);
    
    %save compensation.dots and compensation.nodots into a matrix with
    %average of all trials for each participant
        if ~isfile(fullfile(get_acoustLocalPath('attentionComp'),'compensation.mat'))
            filename = 'compensation';
            filename = [filename '.mat'];
        end
            filename = 'compensation.mat';
            save(filename,'compensation')
   
    compStd.dots(i) = nanstd(trialMeans.dots);
    compStd.nodots(i) = nanstd(trialMeans.nodots);
    
   % compensation(i) = nanmean(trialMeans);
  %  compStd(i) = nanstd(trialMeans);
    sigComp(i) = ttest(trialMeans.dots,trialMeans.nodots,'Tail','both');
    if params.byTrialMeans
        errs(i) = get_errorbars(trialMeans,'se');
    end
    clear trialMeans
end
sigComp = logical(sigComp);

end
function avgVal = avgFcn(data,dim,params)
    if nargin < 2 || isempty(dim)
        dim = 1;
    end
    if nargin < 3 || isempty(params)
        params.avgType = 'mean';
    end
    switch params.avgType
        case 'mean'
            avgVal = nanmean(data,dim);
        case 'median'
            avgVal = nanmedian(data,dim);
    end
end
