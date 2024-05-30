function expPath = restart_attentionAdapt_expt(expt)
%RESTART_SIMON_EXPT  Restart script for attentionAdapt. Based off
%restart_simon_expt and an old version of restart_coAdapt_expt.

% 2021-11 CWN init.

if nargin < 1 || isempty(expt)
    error('Load expt file that needs to be restarted and include it as an input argument.')
end

if ~isfield(expt,'snum'), expt.snum = get_snum; end

expFun = get_experiment_function(expt.name); % this function will need to be updated!

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
    load(fullfile(dataPath,'expt.mat'), 'expt') % get expt file
    if lastTrial ~= expt.ntrials
        q = sprintf('Restart experiment "%s" at trial %d?', expt.name, lastTrial+1);
        response = askNChoiceQuestion(q, {'y' 'n'});
        if strcmp(response,'y')
            % setup expt
            expt.startTrial = lastTrial+1;      % set starting trial
            expt.startBlock = ceil(expt.startTrial/expt.ntrials_per_block); % get starting block
            expt.isRestart = 1;
            expt.crashTrials = [expt.crashTrials expt.startTrial];
            save(fullfile(dataPath,'expt.mat'),'expt')
            
            %% run experiment
            exptfile = fullfile(expt.dataPath,'expt.mat');
            
            %if crash occurred during non-retention phase, do those conds
            if expt.startTrial <= max(expt.inds.conds.washout)
                conds2run = {'baseline' 'hold' 'washout'};
                expt = expFun(expt, conds2run);
                
                %resave expt file
                save(exptfile, 'expt');
                fprintf('Saved baseline+hold+washout data to expt file: %s.\n', exptfile);
                
                %wait for period between washout and retention
                time = clock;
                starthr = time(4);
                startmin = time(5) + expt.delayMin;
                if startmin > 59
                    startmin = mod(startmin,60);
                    starthr = starthr + 1;
                    while starthr > 12
                        starthr = starthr - 12;
                    end
                end
                fprintf('Pausing for %d minutes. Experiment will resume at %d:%02d.\n',expt.delayMin,starthr,startmin);
                pause(expt.delaySecs);
                fprintf('Starting retention phase.\n');
            end
            
            %run retention phase
            conds2run = {'retention'};
            expt = expFun(expt, conds2run);
            
            %resave expt file
            save(exptfile, 'expt');
            fprintf('Saved retention data to expt file: %s.\n', exptfile);
            break;
        end
    end
    expPath = [];
end



end