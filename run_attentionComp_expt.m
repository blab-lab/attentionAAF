function [] = run_attentionComp_expt(expt,bTestMode)
%RUN_ATTENTIONCOMP_EXPT  Setup script for attentionComp experiment.
%   RUN_ATTENTIONCOMP_EXPT(EXPT,BTESTMODE)
%                   EXPT: parameter file for the experiment, default is to
%                          construct a new one.
%                   BTESTEMODE: boolean for indicating a test mode run,
%
%

if nargin < 1, expt = []; end
if nargin < 2 || isempty(bTestMode), bTestMode = 0; end

%% Set up experiment
expt.name = 'attentionComp';

if ~isfield(expt,'snum'), expt.snum = get_snum; end
if ~isfield(expt,'gender'), expt.gender = get_gender; end

clear PsychPortAudio        % clear the MEX so current devices are ID'd
InitializePsychSound(1); GetSecs;    % ping the MEX so it's loaded in

%% Get session data folder path
expt.bTestMode = bTestMode;
expt.dataPath = get_acoustSavePath(expt.name,expt.snum);

%ptHistory.dataPath = get_acoustLoadPath('attentionComp');
ptHistory.dataPath = get_acoustSavePath('attentionComp');
if ~exist(ptHistory.dataPath, 'dir')
    mkdir(ptHistory.dataPath)
end
if ~isfile(fullfile(ptHistory.dataPath,'ptHistory.mat'))
    ptHistory.next_bDotsFirst = 1;
    ptHistory.subjects = [];
else
    load(fullfile(ptHistory.dataPath, 'ptHistory.mat'), 'ptHistory');
end

if ~isfield(expt,'bDotsFirst')
    if ~bTestMode
        expt.bDotsFirst = ptHistory.next_bDotsFirst;
    else %bTestMode
        expt.bDotsFirst = 0;
    end
else
    % expt.bDotsFirst is already set
end


%% Stimuli and Timing Info
% stimuli
expt.conds = {'noShift' 'shiftIH' 'shiftAE'};
expt.words = {'head' 'bed' 'dead'};
nwords = length(expt.words);

% timing
expt.timing.stimdur = 1.5;         % time stim is on screen, in seconds
expt.timing.visualfbdur = .5;      % time visual feedback is on screen, in seconds
expt.timing.interstimdur = .75;    % minimum time between stims, in seconds
expt.timing.interstimjitter = .75; % maximum extra time between stims (jitter)

% duration tracking parameters
durcalc.min_dur = .4; % set_exptDefaults normally sets to .25
durcalc.max_dur = .65;
durcalc.ons_thresh = 0.15;
durcalc.offs_thresh = 0.4;
expt = set_missingField(expt,'durcalc',durcalc);

% Set to use "default" single syllable, oneword Audapter OST file
expt.trackingFileLoc = 'experiment_helpers';
expt.trackingFileName = 'measureFormants';

%% Use exptpre to set up formant shifts with formantmeans from run_measureformants_audapter
exptpre = expt;
exptpre.dataPath = fullfile(expt.dataPath,'pre');

%Switch to bid/bad/bed for collection of formantmeans
exptpre.words = {'bid' 'bad' 'bed'};
nwordspre = length(exptpre.words);

%Where nblocks is the number of repetitions for each word.
if bTestMode
    exptpre.nblocks = 5; 
else
    exptpre.nblocks = 10;
end


exptpre.ntrials = exptpre.nblocks * nwordspre; % testMode = 3, live = 30;
exptpre.breakFrequency = exptpre.ntrials;
exptpre.breakTrials = exptpre.ntrials;
exptpre.conds = {'noShift'};
exptpre = set_exptDefaults(exptpre); % set missing expt fields to defaults

%% intialize visual coherence parameters
expt.startingCoherence = 1;
expt.stimDur = .4;          %duration of stimulus (sec)
expt.dist = 71;             %pt's distance from screen, in cm (71cm = 28in)
expt.responseInterval = .5; %window in time to record the subject's response
 
%% set up main experiment alteration phase

if bTestMode
    expt.nblocks = 2;
else
    expt.nblocks = 33; %Includes 16 dual task and 16 control
end

% Set up a building-block of conds
expt.ntrials_per_block = 18;

% Set up ntrials, coherence, and direction
expt.ntrials = expt.ntrials_per_block*expt.nblocks;
expt.coherence = [1 nan(1,expt.ntrials-1)];
expt.dot_direction = nan(1,expt.ntrials);
if ~bTestMode
    nBaseline = 18;
else 
    nBaseline = 9;
end

% Pseudorandomize stimuli like this: In each 18-trial block, there are 6
% trials per word, and 6 perturbation trials (3 words * 2 pert conditions).
% No perturbation trials are adjacent, even across blocks.
expt = randomize_stimuli(expt,1,4,nBaseline);

% Set up breaks, expt.ntrials must be divisible by break frequency
breakfrequency = expt.ntrials_per_block * 2;
firstbreak = expt.ntrials_per_block;
expt.breakTrials = firstbreak:breakfrequency:expt.ntrials;  %pp breaks after baseline; then, every 2 blocks

% set missing expt fields to defaults
expt = set_exptDefaults(expt);

% set up expt.listDots, which controls the trial #s where dots will display
expt.dots = {'noDots','dots'};
expt.allDots = zeros(1, expt.ntrials);
bDots = ~expt.bDotsFirst;
for i = 1:length(expt.breakTrials)-1
    expt.allDots(expt.breakTrials(i)+1 : expt.breakTrials(i+1)) = bDots;
    bDots = ~bDots;
end
expt.allDots = expt.allDots + 1;
if bTestMode
    expt.allDots = [ones(1,9), 2*ones(1,9), ones(1,9), 2*ones(1,9)];
end
expt.listDots = expt.dots(expt.allDots);
expt.inds.dots.dots = find(expt.allDots==2);
expt.inds.dots.noDots = find(expt.allDots==1);


%% Set up formant shifts
pertFieldOK = 0;
while ~pertFieldOK
    refreshWorkingCopy('experiment_helpers', 'measureFormants', 'both');
    % exptpre and data are saved to attentionComp/acousticdata/subject/session/pre
    %if ~exist(fullfile(exptpre.dataPath,'data.mat'),'file')
        exptpre = run_measureFormants_audapter(exptpre,3);
    %end
    
    %check LPC order
    check_audapterLPC(exptpre.dataPath)
    hGui = findobj('Tag','check_LPC');
    waitfor(hGui);
    
    %set lpc order
    load(fullfile(exptpre.dataPath,'nlpc'),'nlpc')
    p.nLPC = nlpc;
    expt.audapterParams = p;
    %end
    %expt.audapterParams = add2struct(expt.audapterParams,p);
    
    % save expt
    if ~exist(expt.dataPath,'dir')
        mkdir(expt.dataPath)
    end
    exptfile = fullfile(expt.dataPath,'expt.mat');
    bSave = savecheck(exptfile);
    if bSave
        save(exptfile, 'expt')
        fprintf('Saved expt file: %s.\n',exptfile);
    end
    
    %Get vowel formant means from expt
    exptpre.fmtMeans = calc_vowelMeans(exptpre.dataPath);
    vowelList = fieldnames(exptpre.fmtMeans);
    ih = hz2mel(exptpre.fmtMeans(1).(cell2mat((vowelList(1)))));
    ae = hz2mel(exptpre.fmtMeans(1).(cell2mat((vowelList(2)))));
    eh = hz2mel(exptpre.fmtMeans(1).(cell2mat((vowelList(3)))));
    
    %compute distances between F1/F2
    shiftIHF1 = ih(1) - eh(1);
    shiftIHF2 = ih(2) - eh(2);
    shiftAEF1 = ae(1) - eh(1);
    shiftAEF2 = ae(2) - eh(2);
    
    %Use inverse tangent function to find angle
    shiftIH = atan(shiftIHF2/shiftIHF1);
    shiftAE = atan(shiftAEF2/shiftAEF1);
    shiftMag = 125; %Change shiftmag here, variable is referenced when shiftmagvec is used to construct expt.shiftmags
    
    %Handle cases where direction needs to be flipped.
    if shiftAEF1<0
        shiftAE = shiftAE - pi;
    end
    if shiftIHF1<0
        shiftIH = shiftIH - pi;
    end
    
    shiftAngleValues  = [0 shiftIH shiftAE];
    shiftMagValues    = [0 shiftMag shiftMag];
    expt.shiftAngles  = shiftAngleValues(expt.allConds);
    expt.shiftMags    = shiftMagValues(expt.allConds);
    
    %save shifts in Cartesian coordinates
    expt.shifts.mels{1}    = [0 0];
    expt.shifts.mels{2}    = [cos(shiftIH)*shiftMag sin(shiftIH)*shiftMag];
    expt.shifts.mels{3}    = [cos(shiftAE)*shiftMag sin(shiftAE)*shiftMag];
    for s = 1:length(expt.shifts.mels)
        expt.shifts.hz{s} = mel2hz(expt.shifts.mels{s});
    end
    
    %check that these values make sense
    h_checkPert = plot_perturbations(exptpre.fmtMeans,expt.shifts.mels,'eh');
    pertFieldCheck = '';
    while ~any(strcmp(pertFieldCheck,{'yes','no'}))
        pertFieldCheck = input('Is the perturbation field OK? yes/no: ','s');
    end
    if strcmp(strip(pertFieldCheck),'yes')
        pertFieldOK = 1;
    end
    
    try % close the plot_perturbations figure if it's still open
        close(h_checkPert)
    catch
    end
    
end


%% resave expt
save(exptfile, 'expt')
fprintf('Saved expt file: %s.\n',exptfile);

%% run visual coherence
% Determine threshold of coherence for experiment
if bTestMode
    exptThresh.threshold = input('[Test mode only] Enter a coherence [0-1], or leave blank to run coherence testing: ');
end
if ~bTestMode || isempty(exptThresh.threshold)
    [~,exptThresh] = run_visualCoherence_psychtoolbox(expt.snum, [], []);
end

prompt_response = input('Enter [y] to move on to pretest phase: ', 's');
    while ~strcmp(prompt_response, 'y')
        prompt_response = input('Please enter [y]: ', 's');
    end

%% Set up duration practice
% Data is properly saved to attentionComp/acousticdata/subject/session/dur, saving exptDur retains their successes
exptDur = expt;
exptDur.coherence = 1;                            
%exptDur.stimDur = .5;                              %Retain from expt
%exptDur.dist = 40;                                 %Retain from expt
%exptDur.direction = nan(1,exptDur.ntrials);        %Retain from expt
exptDur.dataPath = fullfile(expt.dataPath,'dur');

exptDur.ntrials = 10; % Number of duration practice trials can be changed here

exptDur.shiftMags   = zeros(1,exptDur.ntrials);
exptDur.shiftAngles = zeros(1,exptDur.ntrials);

exptDur.words = expt.words;
exptDur.allWords = mod(0:exptDur.ntrials-1, numel(expt.words)) + 1;
exptDur.listWords = expt.words(exptDur.allWords);

exptDur.conds = {'noShift'};
exptDur.allConds = ones(1, exptDur.ntrials);
exptDur.listConds = exptDur.conds(exptDur.allConds);

exptDur = set_exptDefaults(exptDur);

%% Run duration practice (first just words, then with dots)
trainingConds = {'wordsOnly', 'wordsAndDots'};
trainIx = 1; %default to run both training modes
if expt.bTestMode   %in test mode, can choose to skip training
    prompt_response = input('Run duration practice? [skip/run] ','s');
    if strcmp(prompt_response,'skip')
        trainIx = 3;
    end
end  

while trainIx <= 2
    % run training
    expt.coherence = 1;
    exptDur.trainSuccess = 0;
    if strcmp(trainingConds{trainIx}, 'wordsOnly')
        exptDur.allDots = ones(1, exptDur.ntrials); %no dots
    else
        exptDur.allDots = 2*ones(1, exptDur.ntrials);   % all dots
    end
    exptDur.listDots = exptDur.dots(exptDur.allDots);
    exptDur = run_attentionComp_audapter(exptDur,[],[],[],7,6);
    
    % decide move on or redo that training
    if strcmp(trainingConds{trainIx}, 'wordsOnly')
        moveOn_next = 'training with dots and words';
    else %words and dots
        moveOn_next = 'the full experiment';
    end 
    moveOn_text = sprintf(['Participant was successful on: %d/%d trials.\n    Move on ' ...
        'to %s? [move on/redo] '], sum(exptDur.trainSuccess), exptDur.ntrials, moveOn_next);
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


%% save exptDur
%should the two duration practices be saved separately?
if ~exist(exptDur.dataPath,'dir')
    mkdir(exptDur.dataPath)
end
exptDurfile = fullfile(exptDur.dataPath,'expt.mat');
bSave = savecheck(exptDurfile);

if bSave
    dur.expt = exptDur;
    save(exptDurfile, '-struct', 'dur')
    fprintf('Saved expt file: %s.\n',exptfile);
end
   

%% run experiment
expt.coherence = exptThresh.threshold;

expt = run_attentionComp_audapter(expt,[],[],[],7,6);

save(exptfile, 'expt')
fprintf('Saved expt file: %s.\n',exptfile);

%% Update ptHistory
if ~bTestMode
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


end