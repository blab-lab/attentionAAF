function [] = gen_fdata_attentionAdapt(dataPath,condtype,dataValsStr,bSaveCheck)
%GEN_FDATA  Calculate formant averages on a dataVals object.
%   GEN_FDATA(DATAPATH,CONDTYPE,DATAVALSSTR) loads a subject's expt and
%   dataVals objects from DATAPATH and calls CALC_FDATA to calculate
%   formant, pitch, amplitude and duration averages.  The output is saved
%   to DATAPATH/fdata_[CONDTYPE].mat, where CONDTYPE is 'vowel' (to group
%   by vowel) or 'cond' (to group by condition, e.g. pitch).

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(condtype), condtype = 'cond'; end
if nargin < 3 || isempty(dataValsStr), dataValsStr = 'dataVals'; end
if nargin < 4 || isempty(bSaveCheck), bSaveCheck = 1;end

loadPath = get_acoustLoadPath('attentionAdapt');
if isfile(fullfile(dataPath, 'fdata_condnoDots.mat')) || isfile(fullfile(dataPath, 'fdata_condDots.mat'))
    load(fullfile(dataPath,'session2','expt.mat'),'expt');
    load(fullfile(dataPath,'session2',dataValsStr),'dataVals');
else
    load(fullfile(dataPath,'session1','expt.mat'),'expt');
    load(fullfile(dataPath,'session1',dataValsStr),'dataVals');
end

[fmtdata,f0data,ampldata,durdata,~,trialinds] = calc_fdata(expt,dataVals,condtype);

 phases.baseline = expt.inds.conds.baseline;
 phases.hold = expt.inds.conds.hold;
 phases.washout = expt.inds.conds.washout;
 phases.retention = expt.inds.conds.retention;

 phaseNames = fieldnames(phases);
 nPhases = length(phaseNames);

for phaseIx = 1:nPhases 
    phase = phaseNames{phaseIx};
    addNaNs = find([dataVals(expt.inds.conds.(phase)).bExcl]); % find trial #s where bExcl is 1 during this phase
    if addNaNs
        formantNames = {'f1' 'f2'};
        for fIx = 1:length(formantNames)
            formant = formantNames{fIx};
            oldArr = fmtdata.mels.(phase).first50ms.rawavg.(formant); % get current values
            newArr = NaN(1, length(expt.inds.conds.(phase))); % new vector that will replace oldArr, but will have NaNs in it on bad trials
            oldArr_ix = 1:length(oldArr);
            
            % every time there ought to be a NaN, increase array indeces by 1.
            % That index will be skipped and will remain NaN
            for i = 1:length(addNaNs)
                oldArr_ix(addNaNs(i):end) = oldArr_ix(addNaNs(i):end) + 1;
            end
            
            % restore old values to their real trial index
            newArr(oldArr_ix) = oldArr;
            
            %apply new values to fmtdata structure
            fmtdata.mels.(phase).first50ms.rawavg.(formant) = newArr;
        end
    end
end


if expt.bDots == 1 
    savefile = fullfile(dataPath,sprintf('fdata_%s%s%s.mat',condtype,'dots', dataValsStr(9:end)));
else
    savefile = fullfile(dataPath,sprintf('fdata_%s%s%s.mat',condtype,'noDots', dataValsStr(9:end)));
end
if bSaveCheck
    bSave = savecheck(savefile);
else
    bSave = 1;
end
if bSave
    save(savefile,'fmtdata','f0data','ampldata','durdata','trialinds');
    fprintf('fdata saved to %s.\n',savefile)
end
