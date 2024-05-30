function expt = run_attentionAdapt_expt(expt,bTestMode)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Based off of adaptRetest experiment
% wrapper to run adaptRetest: one adaptation experiment run twice on the same person
% aka adaptAdapt
%
% Perturbation on the words "head", "dead", and "bed". Magnitude and direction determined by pretest phase consisting of 10
% trials each of hid, head, and had; mag/dir is from head to hid. Uniform perturbation regardless of original value (1D
% audapter)
%
% Run standard adaptation experiment on head, dead, and bed, including
% retention phase.
%
% One of the two sessions includes a visual distractor task which is
% counterbalanced for each participant.
%
% last edited Sept 2021 JLK
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dbstop if error

%% Default arguments

if nargin < 1, expt = []; end
if nargin < 2 || isempty(bTestMode), bTestMode = 0; end

%% Set up experiment

expt.name = 'attentionAdapt';
expt.trackingFileLoc = 'experiment_helpers'; % Where the OST/PCF files are kept (for audapter_viewer)
expt.trackingFileName = 'measureFormants'; % What the files are called (does not include Working/Master)
expt.startTrial = 1;

if ~isfield(expt,'snum'), expt.snum = get_snum; end
if ~isfield(expt,'gender'), expt.gender = get_height; end

clear PsychPortAudio        % clear the MEX so current devices are ID'd
InitializePsychSound(1); GetSecs;    % ping the MEX so it's loaded in

%% Get session data folder path

expt.bTestMode = bTestMode;
basePath = get_acoustSavePath(expt.name,expt.snum); %make sure there are separate data paths for each session
if ~exist(basePath,'dir')
    mkdir(basePath)
end

%% Load expt file and get session number

if ~isfile(fullfile(basePath,'session1','expt.mat'))
    mkdir(basePath, 'session1')
    expt.sessionNum = 1;
    expt.dataPath = get_acoustSavePath(expt.name,expt.snum,'session1');
    expt.isRestart = 0;
elseif isfile(fullfile(basePath,'session1','expt.mat')) && ~isfile(fullfile(basePath,'session1','data.mat'))
    %restart session 1
    useExisting = askNChoiceQuestion('Session1 data for this participant already exists. Load in existing expt and continue?');
    if strcmp(useExisting,'y')
        load(fullfile(basePath,'session1','expt.mat'),'expt')
        expt.isRestart = 1;
    else % If you're starting session1 over
        expt.isRestart = 0;
        expt.sessionNum = 1;
        expt.dataPath = get_acoustSavePath(expt.name,expt.snum,'session1');
    end
elseif ~isfile(fullfile(basePath,'session2','expt.mat'))
    mkdir (basePath,'session2')
    load(fullfile(basePath, 'session1', 'expt.mat'),'expt')
    expt.sessionNum = 2;
    if strcmp(expt.sessionOrder(expt.sessionNum), 'dots')
        expt.bDots = 1;
    else
        expt.bDots = 0;
    end
    expt.dataPath = get_acoustSavePath(expt.name,expt.snum,'session2');
elseif isfile(fullfile(basePath,'session2','expt.mat')) && ~isfile(fullfile(basePath,'session2','data.mat'))
    %restart session 2
    useExisting = askNChoiceQuestion('Session2 data for this participant already exists. Load in existing expt and continue?');
    if strcmp(useExisting,'y')
        load(fullfile(basePath,'session2','expt.mat'),'expt')
        expt.isRestart = 1;
    else % If you're starting session2 over
        expt.isRestart = 0;
        expt.sessionNum = 1;
        expt.dataPath = get_acoustSavePath(expt.name,expt.snum,'session2');
    end
else
    fprintf('A complete dataset for this participant already exists. Start over with new participant ID.');
    return
end

%% Session one
if expt.sessionNum == 1 && expt.isRestart == 0
    
    % Set stimuli and timing info
    % timing
    expt.timing.stimdur = 1.5;         % time stim is on screen, in seconds
    expt.timing.interstimdur = .75;    % minimum time between stims, in seconds
    expt.timing.interstimjitter = .75; % maximum extra time between stims (jitter)
    expt.timing.visualfbdur = 0.75;    % time visual feedback is on screen, in seconds
    
    % intialize visual coherence parameters
    expt.startingCoherence = 1;
    expt.stimDur = .4;          %duration of stimulus (sec)
    expt.dist = 71;             %pt's distance from screen, in cm (71cm = 28in)
    expt.responseInterval = .5; %window in time to record the subject's response
    
    % Counterbalancing sessions
    % get session permutation
    permsPath = fileparts(get_acoustLoadPath('attentionAdapt'));
%     permsPath = 'C:\Users\Public\Documents\experiments\attentionAdapt'; % un-comment when testing locally
    if exist(permsPath,'dir')
        fprintf('found it.\n');
        [expt.permIx, expt.sessionOrder] = get_cbPermutation(expt.name, permsPath); % get the words and their index
        if ~bTestMode && ~any(strfind(expt.snum, 'pilot')) && ~any(strfind(expt.snum,'test')) % if "test" or "pilot" in pp name, not a real pp
            set_cbPermutation(expt.name, expt.permIx, permsPath);
        end
    else % If the server is down for some reason
        % Get a random index between 1 and the # of possible permutations
        expt.permIx = randi(2);
        % Then use a local copy of the permutations (counts do not have to be
        % up to date, you just need order of conditions)
        localPermsPath = 'C:\Users\Public\Documents\experiments\attentionAdapt';
        [~, expt.session] = get_cbPermutation(expt.name, localPermsPath, [], expt.permIx);
        
        % save warning.txt file with permIx
        warningFile = fullfile(expt.dataPath,'warning.txt');
        fid = fopen(warningFile, 'w');
        warning('Server did not respond. Using randomly generated permutation index (see warning file)');
        fprintf(fid,'Server did not respond. Random permIx generated: %d', expt.permIx);
        fclose(fid);
    end
    
    if strcmp(expt.sessionOrder(expt.sessionNum), 'dots')
        expt.bDots = 1;
    else
        expt.bDots = 0;
    end
    
    % Calibrate and Set Perturbation Fields
    % refreshWorkingCopy(expt.trackingFileLoc,expt.trackingFileName,'ost');
    % Only run this phase if there isn't already an expt with certain fieldnames in the pre folder
    
    % Run pre-phase to get formant means for I/E
    exptPre = expt;
    exptPre.session = 'pre';
    exptPre.dataPath = fullfile(fileparts(exptPre.dataPath),exptPre.session);
    if ~exist(exptPre.dataPath, 'dir')
        mkdir(exptPre.dataPath)
    end
    
    % set up words and repetitions
    exptPre.conds = {'pre'};
    exptPre.words = {'bid' 'bed' 'bat'};
    if bTestMode
        exptPre.ntrials = 3*length(exptPre.words);
    else
        exptPre.ntrials = 10*length(exptPre.words);
    end
    exptPre.breakTrials = exptPre.ntrials;
    exptPre.allConds = ones(1, exptPre.ntrials);
    exptPre.listConds = exptPre.conds(exptPre.allConds);
    
    exptPre = set_exptDefaults(exptPre); % set missing expt fields to defaults
    
    % This will get the formant measurements. Lets you rerun if necessary
    pertFieldOK = 'no';
         while strcmp(pertFieldOK,'no')
             % Record pretest data
             exptPre = run_measureFormants_audapter(exptPre);

             % Check LPC order
             exptPre = check_audapterLPC(exptPre.dataPath); % check that they're being tracked right
             hGui = findobj('Tag','check_LPC');
             waitfor(hGui);
             exptPre.fmtMeans = calc_vowelMeans(exptPre.dataPath);

             %set lpc order
             load(fullfile(exptPre.dataPath,'nlpc'),'nlpc')
             p.nLPC = nlpc;
             expt.audapterParams = p;

             %calculate shift and assign to expt file
             [shifts] = calc_formantShifts(exptPre.fmtMeans,125,'eh',{'ih'},1,[]);% updated 6/17/2021 to use the shifts input from calc_formantShifts
             expt.shifts.mels = shifts.mels;
             shiftAngIH = shifts.shiftAng(1);

             %check that these values make sense
             h_checkPert = plot_perturbations(exptPre.fmtMeans, expt.shifts.mels, 'eh');
             pertFieldOK = askNChoiceQuestion('Is the perturbation field OK?', {'yes', 'no'});

             try % close the plot_perturbations figure if it's still open
                 close(h_checkPert)
             catch
             end
             if expt.bDots == 1
                 [~] = input('This is the dots session. Press ENTER to move on to finding the visual coherence threshold.', 's');
             else
                 [~] = input('This is the no dots (control) session. Press ENTER to move on to the main experiment.', 's');
             end
         end
   
    % Save all info in the pre, switch back to top level expt
    exptfile = fullfile(exptPre.dataPath,'expt.mat');
    pre.expt = exptPre;
    save(exptfile, '-struct', 'pre');
    
    exptfile = fullfile(expt.dataPath,'expt.mat');
    save(exptfile, 'expt');
    fprintf('Saved expt file with LPC order and shift information\n');
    
    % stimuli list
    expt.words = {'head' 'bed' 'dead'};
    nwords = length(expt.words);
    
    if bTestMode
        testModeReps = 5;
        nBaseline = testModeReps*nwords;
        nHold = testModeReps*nwords;
        nWashout = testModeReps*nwords;
        nRetention = testModeReps*nwords;
        delayMin = .01;
        expt.breakFrequency = testModeReps*nwords;
    else
        nBaseline = 10*nwords;
        nHold = 40*nwords;
        nWashout = 10*nwords;
        nRetention = 10*nwords;
        delayMin = 10;
        expt.breakFrequency = 30;
    end
    delaySecs = delayMin * 60;
    expt.delaySecs = delaySecs;
    expt.delayMin = delayMin;
    expt.ntrials = nBaseline + nHold + nWashout + nRetention;
    expt.breakTrials = expt.breakFrequency:expt.breakFrequency:expt.ntrials-nRetention;
    
    expt.allConds = [1*ones(1,nBaseline) 2*ones(1,nHold) 3*ones(1,nWashout) 4*ones(1,nRetention)];
    expt.conds = {'baseline', 'hold', 'washout', 'retention'};
    expt.listConds = expt.conds(expt.allConds);
    
    % Set up shifts for the expt structure
    expt.shiftMag = 125;
    expt.shiftMags = expt.shiftMag*[zeros(1,nBaseline) ones(1,nHold) zeros(1,nWashout) zeros(1,nRetention)];
%    expt.shiftAngles = shiftAngIH*ones(1,expt.ntrials);
    
    % Set missing expt fields to defaults
    expt = set_exptDefaults(expt);
else %session 2
    if expt.bDots == 1
        [~] = input('This is the dots session. Press ENTER to move on to finding the visual coherence threshold.', 's');
    else
        [~] = input('This is the no dots (control) session. Press ENTER to move on to the main experiment.', 's');
    end
end

exptfile = fullfile(expt.dataPath,'expt.mat');
save(exptfile, 'expt')
fprintf('Saved full expt file: %s.\n',exptfile);

%% Run visual coherence
if bTestMode
    exptThresh.threshold = input('[Test mode only] Enter a coherence [0-1], or leave blank to run coherence testing: ');
end

if ~bTestMode && expt.bDots == 1
    [~,exptThresh] = run_visualCoherence_psychtoolbox_attentionAdapt(expt.snum, [], []);
    prompt_response = input('Enter [y] to move on: ', 's');
    while ~strcmp(prompt_response, 'y')
    prompt_response = input('Please enter [y]: ', 's');
    end
       expt.coherence = exptThresh.threshold;
       exptfile = fullfile(expt.dataPath,'expt.mat');
       save(exptfile, 'expt')
end

%% Run a practice round of words with dots
if ~bTestMode && expt.bDots == 1
    
    exptPract = expt;
    exptPract.coherence = 1;
    exptPract.ntrials = 10;
    exptPract.dots = {'noDots','dots'};
    
    exptPract.shiftMags   = zeros(1,exptPract.ntrials);
    exptPract.shiftAngles = zeros(1,exptPract.ntrials);
    
    exptPract.allWords = mod(0:exptPract.ntrials-1, numel(exptPract.words)) + 1;
    exptPract.listWords = exptPract.words(exptPract.allWords);
    
    exptPract.conds = {'noShift'};
    exptPract.allConds = ones(1, exptPract.ntrials);
    exptPract.listConds = exptPract.conds(exptPract.allConds);
    
    exptPract = set_exptDefaults(exptPract);
    
    trainingConds = {'wordsOnly', 'wordsAndDots'};
    trainIx = 1; %default to run both training modes
    if expt.bTestMode   %in test mode, can choose to skip training
        prompt_response = input('Run practice? [skip/run] ','s');
        if strcmp(prompt_response,'skip')
            trainIx = 3;
        end
    end
    
    while trainIx <= 2
        % run training
        if strcmp(trainingConds{trainIx}, 'wordsOnly')
            exptPract.allDots = ones(1, exptPract.ntrials); %no dots
            exptPract.bDots = 0;
        else
            exptPract.allDots = 2*ones(1, exptPract.ntrials);   % all dots
            exptPract.bDots = 1;
        end
        exptPract.listDots = exptPract.dots(exptPract.allDots);
        exptPract = run_attentionAdapt_audapter(exptPract,[],[],[],7,6);
        
        % decide move on or redo that training
        if strcmp(trainingConds{trainIx}, 'wordsOnly')
            moveOn_next = 'training with dots and words';
        else %words and dots
            moveOn_next = 'the full experiment';
        end
        moveOn_text = sprintf('Move on to %s? [move on/redo] ',moveOn_next);
        prompt_response = input(moveOn_text,'s');
        while ~any(strcmp(prompt_response,{'move on','redo'}))
            prompt_response = input('Please choose [redo/move on]: ','s');
        end
        
        %increment trainIx if decide to move on
        if strcmp(prompt_response,'move on')
            rerun_text = sprintf('Are you sure you want to move on? [yes/no] ');
            prompt_response = input(rerun_text,'s');
            while ~any(strcmp(prompt_response,{'yes','no'}))
                prompt_response = input('Please choose [yes/no]:','s');
            end
            if strcmp(prompt_response,'yes')
                fprintf('Moving on... \n');
                trainIx = trainIx + 1;
            else
                fprintf('Ok, redoing previous condition. \n');
            end
        else
            %redo previous condition
        end
    end
end
%% run adaptation experiment

expt = run_attentionAdapt_audapter(expt,{'baseline' 'hold' 'washout'});

% NOTE: If this code changes, also change ~L60 in restart_attentionAdapt_expt
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

close all
expt = run_attentionAdapt_audapter(expt,{'retention'});

end
