function [savefile] = gen_fmtMatrix_attentionComp(dataPath,dataValsStr,bSaveCheck)

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(dataValsStr), dataValsStr = 'dataVals.mat'; end
if nargin < 3 || isempty(bSaveCheck), bSaveCheck = 1; end

load(fullfile(dataPath,dataValsStr));
load(fullfile(dataPath,'expt.mat'),'expt');

conds = {'shiftIH','shiftAE'};
basecond = 'noShift';
nconds = length(conds);
words = expt.words;
nwords = length(words);
taskconds = expt.dots;
ntaskconds = length(taskconds);

%add shift information to expt.mat
if ~isfield(expt,'shifts')
    expt.shifts.mels{1}    = [0 0];
    expt.shifts.mels{2}    = [cos(shiftIH)*shiftMag sin(shiftIH)*shiftMag];
    expt.shifts.mels{3}    = [cos(shiftAE)*shiftMag sin(shiftAE)*shiftMag];
end
save(fullfile(dataPath,'expt.mat'),'expt');

colors.shiftIH.dots = [.2 .6 .8]; %all colors subject to change
colors.shiftIH.noDots = [.2 .8 .8];
colors.shiftAE.dots = [.8 0 0];
colors.shiftAE.noDots = [1 0 0];
colors.noShift = [.5 .5 .5];

for c = 1:nconds
    cond = conds{c};
    for w = 1:nwords
        word = words{w};
        for t = 1:ntaskconds
            taskcond = taskconds{t};
            shiftnum = (c-1)*(nwords+3) + (w-1)*ntaskconds + t;
            
            indShift(shiftnum).name = sprintf('%s%s%s',cond,word,taskcond);
            wordandcondIntersect = intersect(expt.inds.conds.(cond),expt.inds.words.(word));
            indShift(shiftnum).inds = intersect(wordandcondIntersect,expt.inds.dots.(taskcond));
            indShift(shiftnum).shiftind = c;
            indShift(shiftnum).linecolor = colors.(cond).(taskcond);
            
            indBase(shiftnum).name = sprintf('%s%s%s',basecond,word,taskcond);
            wordandbasecondIntersect = intersect(expt.inds.conds.(basecond),expt.inds.words.(word));
            indBase(shiftnum).inds = intersect(wordandbasecondIntersect,expt.inds.dots.(taskcond));
            indBase(shiftnum).linecolor = colors.(basecond);
            
        end
    end
end

savefile = gen_fmtMatrixByCond_attentionComp(dataPath,indBase,indShift,dataValsStr,1,1,bSaveCheck);
