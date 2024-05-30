function expPath = restart_attentionComp_expt(expt)
%RESTART_ATTENTIONCOMP_EXPT  Restart attentionComp after a crash.
%
% NOTE: Use only if the crash occurred during the main phase of the
% experiment. If crash occurred during pretest block, just call
% run_attentionComp_expt again.

if nargin < 1, expt = []; end

if ~isfield(expt,'name'), expt.name = input('Enter experiment name (e.g. varModIn or vsaAdapt2): ','s'); end
if ~isfield(expt,'snum'), expt.snum = get_snum; end

expFun = @run_attentionComp_audapter;

% find all temp trial dirs
subjPath = get_acoustSavePath(expt.name,expt.snum);
tempdirs = regexp(genpath(subjPath),'[^;]*temp_trials','match')';
if isempty(tempdirs)
    fprintf('No unfinished experiments to restart.\n')
    expPath = [];
    return;
end

% prompt for restart
for d = 1:length(tempdirs)
    %find last trial saved
    trialnums = get_sortedTrials(tempdirs{d});
    lastTrial = trialnums(end);
    
    %check to see if experiment completed. only prompt to rerun if
    %incomplete.
    dataPath = fileparts(strip(tempdirs{d},'right',filesep));
    load(fullfile(dataPath,'expt.mat'),'expt') % get expt file 
    if lastTrial ~= expt.ntrials
        startName = regexp(dataPath,expt.snum);
        expName = dataPath(startName:end);
        q = sprintf('Restart experiment "%s" at trial %d? [y/n] ', expName, lastTrial+1);
        q = strrep(q,'\','\\'); %add extra \ to string to display correctly in "input" command
        response = input(q, 's');
        if strcmp(strip(response),'y')
            % prep expt file
            expt.startTrial = lastTrial+1;      % set starting trial
            expt.isRestart = 1;
            if ~isfield(expt,'crashTrials')
                expt.crashTrials = [];
            end
            expt.crashTrials = [expt.crashTrials expt.startTrial];
            save(fullfile(dataPath,'expt.mat'),'expt')            
            
            trials2run = expt.startTrial:expt.ntrials;

            %% run it
            expt = expFun(expt, trials2run, [], [], 7, 6);
            
            save(expt.dataPath, 'expt')
            fprintf('Saved expt file: %s.\n', expt.dataPath);
            
            %% Update ptHistory
            
            %load in/set up
            ptHistory.dataPath = get_acoustSavePath('attentionComp');
            if ~isfile(fullfile(ptHistory.dataPath,'ptHistory.mat'))
                ptHistory.next_bDotsFirst = 1;
                ptHistory.subjects = [];
            else
                load(fullfile(ptHistory.dataPath, 'ptHistory.mat'), 'ptHistory');
            end

            % update it
            if ~expt.bTestMode
                ptIx = length(ptHistory.subjects) + 1;
                ptHistory.subjects(ptIx).snum         = expt.snum;
                ptHistory.subjects(ptIx).bDotsFirst   = expt.bDotsFirst;
                ptHistory.subjects(ptIx).coherence    = expt.coherence;
                
                if expt.bDotsFirst
                    ptHistory.next_bDotsFirst = 0;
                else
                    ptHistory.next_bDotsFirst = 1;
                end
                ptHistory.coherence = expt.coherence;
                
                %save it
                assignmentfile = fullfile(ptHistory.dataPath,'ptHistory.mat');
                save(assignmentfile, 'ptHistory');
                fprintf('Saved data files for: %s.\n',expt.snum);
            else
                fprintf('\n Experiment ran in test mode. ptHistory.mat was not updated.\n');
            end
            
            
            %dataPath = fileparts(strip(tempdirs{d},'right',filesep));
            %expPath = fileparts(strip(dataPath,'right',filesep));
            expPath = fileparts(strip(tempdirs{d},'right',filesep));
            break;
        else
            fprintf('Restart canceled.\n')
        end
    end
    fprintf('All %d trials completed. Restart canceled.\n',expt.ntrials)
    expPath = [];
end



end

