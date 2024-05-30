function [expt] = run_attentionAdapt_audapter(expt,conds2run, bNoise, micThresh, inputDeviceID, outputDeviceID)
% Audapter trial engine for attentionAdapt (based on adaptRetest)
% 
% JLK Sept 2021

dbstop if error

if nargin < 1, expt = []; end
if nargin < 2 || isempty(conds2run), conds2run = expt.conds; end



%% Assign folder

if ~exist(expt.dataPath,'dir')
    mkdir(expt.dataPath)
end

if isfield(expt,'dataPath')
    outputdir = expt.dataPath;
else
    warning('Setting output directory to current directory: %s\n',pwd);
    outputdir = pwd;
end

% assign folder for saving trial data
% create output directory if it doesn't exist
trialdirname = 'temp_trials';
trialdir = fullfile(outputdir,trialdirname);
if ~exist(trialdir,'dir')
    mkdir(outputdir,trialdirname)
end

%set RMS threshold for deciding if a trial is good or not
rmsThresh = 0.04;

%% set up stimuli
% set experiment-specific fields (or pass them in as 'expt')
%stimtxtsize = 200;

% set missing expt fields to defaults
expt = set_exptDefaults(expt);

%% define trials to run based on conditions
trials2run = [];
for c = 1:length(conds2run)
    condname = conds2run{c};
    trials2run = [trials2run expt.inds.conds.(condname)]; %#ok<AGROW>
end

%% set up audapter
audioInterfaceName = 'Focusrite USB'; %SMNG default for Windows 10
Audapter('deviceName', audioInterfaceName);
Audapter('ost', '', 0);  % nullify online status tracking
Audapter('pcf', '', 0);  % pert config files (use pert field instead)
% ostList = get_ost(expt.trackingFileLoc, expt.trackingFileName,'list'); % For later use when recording the OST values for each trial   BP TODO: do we need this? seems like we aren't currently using it.

% set audapter params
p = getAudapterDefaultParams(expt.gender); % get default params

% overwrite selected params with experiment-specific values:
p.bShift = 1;
p.bRatioShift = 0;
p.bMelShift = 1;

% set noise
w = get_noiseSource(p);
Audapter('setParam', 'datapb', w, 1);
p.fb = 3;          % set feedback mode to 3: speech + noise
p.fb3Gain = 0.02;   % gain for noise waveform

%% initialize Audapter
AudapterIO('init', p);

%% intialize parameters
% for testing, can change these values.
% Chris at home [-20, 0]. Jenna [-11, -7]. Waisman (Burnham) [0, 0]
dots.xPos = 0;
dots.yPos = 0;

dots.nDots = 100;            % number of dots
dots.color = [255,255,255];  % color of the dots
dots.size = 10;              % size of dots (pixels)
dots.center = [dots.xPos, dots.yPos];      % originally [0,0]
dots.apertureSize = [5,5];   % size of rectangular aperture [w,h] in degrees
dots.speed = 3;
dots.lifetime = 12;
listDirections = [90 270];

KbName('UnifyKeyNames');
moveLeft = KbName('LeftArrow');
moveRight = KbName('RightArrow');
escapeKey = KbName('ESCAPE');
pKey = KbName('p');
spaceKey = KbName('space');

deviceList = PsychPortAudio('GetDevices');
if nargin < 3 || isempty(bNoise),bNoise = 0; end
if nargin < 4 || isempty(micThresh), micThresh = 0.06; end
if nargin < 5 || isempty(inputDeviceID) || length(deviceList) <= inputDeviceID || deviceList(inputDeviceID + 1).NrInputChannels < 1
    warning(['Using default microphone. Call PsychPortAudio(''GetDevices'') ' ...
        'to see a list of mics if you prefer a different one.']);
    inputDeviceID = [];
end
if nargin < 6 || isempty(outputDeviceID) || length(deviceList) <= outputDeviceID || deviceList(outputDeviceID+1).NrOutputChannels < 1
    warning(['Using default speakers. Call PsychPortAudio(''GetDevices'') ' ...
        'to see a list of speakers if you prefer a different one.']);
    outputDeviceID = [];
end

%% Psychtoolbox setup
% audio setup
InitializePsychSound(1);

% Screen setup
sca;
Screen('Preference', 'VisualDebuglevel', 1);
if expt.bTestMode
    Screen('Preference', 'WindowShieldingLevel', 2000);
end
if ismac
    Screen('Preference', 'SkipSyncTests', 1);
end

% TODO clean up duplicate variables (screenNumber vs display)
% figures using those variable names.
stimPTB = 1; dupPTB = 2;
screens = Screen('Screens');
screenNumber(stimPTB) = max(screens);
black = BlackIndex(screenNumber(stimPTB));
white = WhiteIndex(screenNumber(stimPTB));
PsychDebugWindowConfiguration(0, 0.25); % 2nd param is opacity, [0-1]

tmp = Screen('resolution', screenNumber(stimPTB));
display.resolution = [tmp.width,tmp.height];
display.width = Screen('DisplaySize',0)/10; %screen width in cm
display.dist = expt.dist;
display.center = display.resolution/2;
display.bDebug = 1; % turn to 1 if you need to debug PsychToolBox issues
display.text.color = 255;
display.text.size = 85; % originally 70, TODO: ask about this
%Screen('TextSize', display, 60);
display.screenNum = screenNumber(stimPTB);

% PTB setup for microphone. Needed for vocal onset trigger.
inputDevice = PsychPortAudio('Open', inputDeviceID, 2, [], [], 2);
PsychPortAudio('GetAudioData', inputDevice, expt.timing.stimdur*2); % preallocate buffer

%% run experiment
% setup figures, display screen
try
    h_fig = setup_exptFigs;
    get_figinds_audapter; % names figs: stim = 1, ctrl = 2, dup = 3;
    h_sub = get_subfigs_audapter(h_fig(ctrl),1);
    
    % give instructions and wait for keypress
    display = OpenWindow(display);
    
    % give instructions and wait for keypress
    if expt.bDots == 0  % no dots in this session
        display = drawText(display,[dots.xPos, dots.yPos + 3],'Read each word out loud as it appears.');
        display = drawText(display,[dots.xPos, dots.yPos + 1],'Press the space bar to continue when ready');
    else    % dots presented in this session
        display = drawText(display,[dots.xPos, dots.yPos + 3],'Read each word out loud as it appears.');
        display = drawText(display,[dots.xPos, dots.yPos + 1.5],'When moving dots appear, ');
        display = drawText(display,[dots.xPos, dots.yPos + 0],'press the left arrow key for leftward moving dots, ');
        display = drawText(display,[dots.xPos, dots.yPos - 1.5],'and the right arrow key for rightward moving dots.');
        display = drawText(display,[dots.xPos, dots.yPos - 5], 'Press the space bar to continue when ready');
        
        dots.coherence = expt.coherence;
     
    end
    Screen(display.windowPtr,'Flip');
    KbWait;
    Screen(display.windowPtr,'Flip')
    % run trials
    pause(1)
    if expt.isRestart
        trials2run = trials2run(trials2run >= expt.startTrial);
        display = OpenWindow(display);
    end
    GetSecs; %ping mex
    for itrial = 1:length(trials2run)  % for each trial
        
        bGoodTrial = 0;
        while ~bGoodTrial
            [~,~,keyCode] = KbCheck(-1);
            keyCode = find(keyCode, 1);
            % pause if 'p' is pressed
            if keyCode == pKey
                display = drawText(display,[dots.xPos, dots.yPos],'trial paused');
                display = drawText(display,[dots.xPos, dots.yPos+1.5],'press spacebar to continue');
                Screen(display.windowPtr,'Flip');
                WaitSecs(0.25);
                KbWaitForKey(spaceKey);
                WaitSecs(0.25);
            end
            
            % set trial index
            trial_index = trials2run(itrial);
            
            % plot trial number in experimenter view
            cla(h_sub(1))
            ctrltxt = sprintf('trial: %d/%d, cond: %s',trial_index,expt.ntrials,expt.listConds{trial_index});
            h_trialn = text(h_sub(1),0,0.5,ctrltxt,'Color','black', 'FontSize',30, 'HorizontalAlignment','center');
            
             % set text
            txt2display = expt.listStimulusText{trial_index};
            color2display = expt.colorvals{expt.allColors(trial_index)};
          
            % set new perturbation
            p.pertAmp = expt.shiftMags(trial_index) * ones(1, 257);
            p.pertPhi = expt.shiftAngles(trial_index) * ones(1, 257);
            Audapter('setParam','pertAmp',p.pertAmp)
            Audapter('setParam','pertPhi',p.pertPhi)
            
            % run trial in Audapter
            Audapter('reset'); %reset Audapter
            fprintf('starting trial %d\n',trial_index)
            Audapter('start'); %start trial
            fprintf('Audapter started for trial %d\n',trial_index)
            
            % display stimulus (for participant)
            display = drawText(display,[dots.xPos, dots.yPos-1],txt2display);
            Screen('Flip', display.windowPtr);
           
            % display stimulus (for experimenter)
            h_text(1) = draw_exptText(h_fig(3),.5,.5,txt2display, 'Color',color2display,'FontSize',display.text.size, 'HorizontalAlignment','center');

            % capture audio data
            tCaptureStart = PsychPortAudio('Start', inputDevice, 0, 0, 1);
            level = 0;
            tMaxEnd = tCaptureStart + expt.timing.stimdur;
            
            while level < micThresh && GetSecs < tMaxEnd
                % Fetch current audiodata:
                [audiodata]= PsychPortAudio('GetAudioData', inputDevice);
                % Compute maximum signal amplitude in this chunk of data:
                if ~isempty(audiodata)
                    level = max(abs(sum(audiodata)));
                else
                    level = 0;
                end
                if level < micThresh
                    WaitSecs(0.002);
                end
            end
            
            tVoiceOnset = GetSecs;
            if level > micThresh && expt.bDots == 1 % If voice onset occurred, do stuff
                % Display the dots
                expt.dot_direction(trial_index) = listDirections(randi(length(listDirections)));
                dots.direction = expt.dot_direction(trial_index);
                
                display.fixation.size = 0;
                display = drawFixation(display);
                
                tDots = GetSecs;
                movingDots(display,dots,expt.stimDur)
                
                while 1
                    [~,~,keyCode] = KbCheck;
                    if keyCode(moveLeft)
                        keyPress = moveLeft;
                        break
                    elseif keyCode(moveRight)
                        keyPress = moveRight;
                        break
                    end
                end
                keyPressLag = GetSecs - tDots; % time between dots and key
                if (keyCode(moveRight) && dots.direction == 90) || (keyCode(moveLeft) && dots.direction == 270)
                    bCorrectPress = 1;
                else
                    bCorrectPress = 0;
                end
                fprintf('Trial %i: %s --> Triggered at %.3f sec. bCorrectPress = %d\n', ...
                    trial_index, txt2display, tVoiceOnset-tCaptureStart, bCorrectPress);

            elseif level > micThresh && expt.bDots == 0
                fprintf('Trial %i: %s --> Triggered at %.3f sec. No dots shown.\n', ...
                    trial_index, txt2display, tVoiceOnset-tCaptureStart);
            else
                fprintf('Trial %i: %s --> [No trigger detected]\n', ...
                    trial_index, txt2display);
            end
            % No new commands until the end of the trial duration
            if GetSecs < tMaxEnd
                WaitSecs('UntilTime', tMaxEnd);
            end
            
            % Stop capturing audio
            PsychPortAudio('Stop', inputDevice);
            audiodata = PsychPortAudio('GetAudioData', inputDevice); %Clear buffer
            
            % stop trial in Audapter
            Audapter('stop');
            fprintf('Audapter ended for trial %d\n',trial_index)
            % get data
            data = AudapterIO('getData');
            if expt.bDots == 1
                data.keyPress = keyPress;
                data.bCorrectPress = bCorrectPress;
                data.keyPressLag = keyPressLag;
            end
            
            % plot shifted spectrogram
            subplot_expt_spectrogram(data, p, h_fig, h_sub);
            
            % check if good trial (amplitude)
            bGoodTrial = check_rmsThresh(data,rmsThresh,h_sub(3));
            %bGoodTrial = 1; %for testing, can use this instead
            
            % clear screen
            Screen('Flip',display.windowPtr);
            delete_exptText(h_fig, h_text)
            clear h_text

            if ~bGoodTrial
                display = drawText(display,[dots.xPos, -dots.yPos],'Please speak a little louder');
                pause(1)
                Screen('Flip',display.windowPtr);
            end
            
            % add intertrial interval + jitter
            pause(expt.timing.interstimdur + rand*expt.timing.interstimjitter);
            
            % save trial
            trialfile = fullfile(trialdir,sprintf('%d.mat',trial_index));
            save(trialfile,'data')
            
            %clean up data
            clear data
        end
        
        if itrial == length(trials2run) && ismember(expt.listConds{itrial},{'washout','pre'})
            breaktext = sprintf('Thank you!\n\nPlease wait.');
            display = drawText(display,[dots.xPos, -dots.yPos],breaktext);
            Screen('Flip',display.windowPtr);
            pause(2.75)
            Screen('Flip',display.windowPtr);
            
        elseif any(expt.breakTrials == trial_index)
            display.text.size = 80;
            display = drawText(display,[dots.xPos, dots.yPos + 3],'Time for a break!');
            breaktext = sprintf('%d of %d trials done.\n\nPress the space bar to continue.',trials2run(itrial),expt.ntrials);
            display = drawText(display,[dots.xPos, -dots.yPos],breaktext);
            Screen(display.windowPtr,'Flip');
            display.text.size = 85;
            KbWait;
        end
        Screen(display.windowPtr,'Flip');        
        WaitSecs(0.5);
    end
catch ME
    Screen('CloseAll');
    rethrow(ME)
end

Screen('CloseAll');

%% Close audio devices
if bNoise
    PsychPortAudio('Stop', outputDevice);
    PsychPortAudio('Close', outputDevice);
end
PsychPortAudio('Close', inputDevice);

%% write experiment data and metadata
% collect trials into one variable
if trial_index == expt.ntrials
    alldata = struct;
    fprintf('Processing data\n')
    for i = 1:trials2run(end)
        load(fullfile(trialdir,sprintf('%d.mat',i)))
        names = fieldnames(data);
        for j = 1:length(names)
            alldata(i).(names{j}) = data.(names{j});
        end
    end

    % save data
    fprintf('Saving data... ')
    clear data
    data = alldata;
    save(fullfile(outputdir,'data.mat'), 'data')
    fprintf('saved.\n')

    % remove temp trial directory
    fprintf('Removing temp directory... ')
    rmdir(trialdir,'s');
    fprintf('done.\n')
    
    close(h_fig)
    Screen('CloseAll')
end
