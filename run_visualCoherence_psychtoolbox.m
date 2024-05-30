function [data,exptThresh] = run_visualCoherence_psychtoolbox(snum, exptThresh, bTestMode)
if nargin < 1 || isempty(snum)
    snum = 'test';
end
if nargin < 2 || isempty(exptThresh)
    exptThresh.snum = snum; 
    exptThresh.startingCoherence = 1;
    exptThresh.ntrials = [];
    exptThresh.stepSize = [0.5 0.75];
    exptThresh.stimDur = .4;                          %duration of stimulus (sec)
    exptThresh.responseInterval = .5;                 %window in time to record the subject's response
    exptThresh.timing.interstimdur = 1;             %inter-trial-interval (time between the start of each trial)
    exptThresh.timing.interstimjitter = 1;
    exptThresh.dist = 71;   %71 cm = 28 inches
    exptThresh.dataPath = fullfile(get_acoustSavePath('attentionComp',exptThresh.snum), 'coherence');
    if ~exist(exptThresh.dataPath, 'dir')
        mkdir(exptThresh.dataPath)
    end
    exptThresh.coherence = [exptThresh.startingCoherence nan(1,exptThresh.ntrials-1)];
    exptThresh.direction = nan(1,exptThresh.ntrials);
end
if nargin < 3 || isempty(bTestMode), bTestMode = 0; end

%%initialize parameters
Screen('CloseAll');
Screen('Preference', 'VisualDebuglevel', 1);
Screen('Preference', 'WindowShieldingLevel', 0);
PsychDebugWindowConfiguration(0, 1);
tmp = Screen('resolution',2);   % CWN changed from 0 to 2 for Waisman setup
display.screenNum = 2;          % CWN Added this for Waisman setup
display.resolution = [tmp.width,tmp.height];
display.width = Screen('DisplaySize',0)/10; %screen width in cm
display.dist = exptThresh.dist; %need to hard code participant distance to screen
display.center = display.resolution/2;
display.bDebug = 1; % turn to 1 if you need to debug PsychToolBox issues
display.text.color = 255;


% Chris at home [-20, 0]. Jenna [-11, -7]. Waisman (Burnham) [0, 0]
dots.xPos = 0;
dots.yPos = 0;

dots.nDots = 100;            % number of dots
dots.color = [255,255,255];  % color of the dots
dots.size = 10;              % size of dots (pixels)
dots.center = [dots.xPos, dots.yPos];   % changed it to fit screen
dots.apertureSize = [5, 5];   % size of rectangular aperture [w,h] in degrees
dots.speed = 3;
dots.lifetime = 12;

data.correctPress = nan(1,exptThresh.ntrials);

correctInaRow = 0;

bAbort = 0;

%set up key names
KbName('UnifyKeyNames');
moveLeft = KbName('LeftArrow');
moveRight = KbName('RightArrow');
escapeKey = KbName('ESCAPE');

%% run experiment
display.text.color = [255,255,255];
try
    display = OpenWindow(display);
    txt2display = 'Press any key to begin';
    display = drawText(display,[dots.xPos, -dots.yPos-1],txt2display);
    display = drawText(display,[dots.xPos, -dots.yPos],'Press left arrow key for leftward moving dots and right arrow key for rightward moving dots');
    Screen(display.windowPtr,'Flip');
    while KbCheck; end
     KbWait;
    display = drawFixation(display);
    display.fixation.size = 0; 
    pause(1);
    
    dots.coherence = exptThresh.coherence(1);
    
    revDir = false;
    revCounter = 0;
 
    T = 0;

    while revCounter <= 10  %% if total reversals are less than or equal to 10  
        T = T + 1;
        fprintf('\nVisual coherence trial #%d... ', T);
        %exptThresh.ntrials = 1:T;
        exptThresh.ntrials = T;
        
        % Quit if escape key is held. 
        [~,~,keyCode] = KbCheck;
        keyCode = find(keyCode, 1);
        if keyCode == escapeKey
            bAbort = 1;
            break;
        end
        
        direction = randi(2);
            if direction == 1
              exptThresh.direction(T) = 90;
            elseif direction == 2
              exptThresh.direction(T) = 270;
            end
    
        dots.direction = exptThresh.direction(T);
        
        if bTestMode
            if exptThresh.direction(T) == 90, rightAnswer = 'RIGHT'; else, rightAnswer = 'LEFT'; end
            fprintf('%s is the correct answer for trial %d.\n', rightAnswer, T);
        end
        
        movingDots(display,dots,exptThresh.stimDur)
        
        while 1
            [~,~,keyCode] = KbCheck;
            if keyCode(moveLeft)
                data.keyPress(T) = moveLeft;
                break
            elseif keyCode(moveRight)
                data.keyPress(T) = moveRight;
                break
            end
        end
        
        pause(1);
        display.fixation.size = 0.5;
        display = drawFixation(display);
        pause(0.5);
        display.fixation.size = 0;
       
        
        % right answer
        if (keyCode(moveRight) && dots.direction == 90) || (keyCode(moveLeft) && dots.direction == 270)
            data.correctPress(T) = 1;
            correctInaRow = correctInaRow + 1;
            
            if correctInaRow == 3 && revCounter < 4 %4
                exptThresh.coherence(T+1) = dots.coherence*exptThresh.stepSize(1);
                correctInaRow = 0;
                if revDir == true
                    revCounter = revCounter + 1;
                    revDir = false;
                end
            elseif correctInaRow == 3 && revCounter >= 4 %4
                exptThresh.coherence(T+1) = dots.coherence*exptThresh.stepSize(2);
                correctInaRow = 0;
                
                if revDir == true
                    revCounter = revCounter + 1;
                    revDir = false;
                end
            else
                exptThresh.coherence(T+1) = dots.coherence;
            end
            
        % wrong answer
        elseif (keyCode(moveLeft) && dots.direction == 90) || (keyCode(moveRight) && dots.direction == 270)
            data.correctPress(T) = 0;
            if revCounter < 4
                dots.coherence = dots.coherence/exptThresh.stepSize(1);
            elseif revCounter >= 4
                dots.coherence = dots.coherence/exptThresh.stepSize(2);
            end
            exptThresh.coherence(T+1) = min(dots.coherence,1);
            correctInaRow = 0;
            
            if revDir == false
                revCounter = revCounter + 1;
                revDir = true;
            end
            
        else %if they press any other key
            data.correctPress(T) = NaN;
            exptThresh.coherence(T+1) = exptThresh.coherence(T);
        end
        dots.coherence = exptThresh.coherence(T+1);
        
        if bTestMode
            fprintf('  CorrectInaRow is %d\n', correctInaRow);
            fprintf('  revCounter is %d\n', revCounter);
            fprintf('  Coherence is %.3f\n', exptThresh.coherence(T));
        end
        
        % print info to experimenter screen
        if data.keyPress(T) == 37, dirStr = 'Left '; else, dirStr = 'Right'; end
        if data.correctPress(T), bGoodStr = 'O'; else, bGoodStr = 'X'; end
        fprintf('%s (%s). revCounter is %d; coherence is %.3f\n', dirStr, bGoodStr, revCounter, exptThresh.coherence(T))
       
        pause(exptThresh.timing.interstimdur + rand*exptThresh.timing.interstimjitter);

        % first trial to start averaging for threshold
%         if T(revCounter == 4 && revDir == false && (correctInaRow == 0||correctInaRow == 3)) %revCounter == 4
%             exptThresh.firstTrial = T(revCounter == 4 && revDir == false && (correctInaRow == 0||correctInaRow == 3)); %revCounter == 4
%         end
        if revCounter == 4 && revDir == false && (correctInaRow == 0||correctInaRow == 3) %revCounter == 4
           exptThresh.firstTrial = T;
        end
        
    end
        
    
catch ME
    Screen('CloseAll');
    rethrow(ME)
end 
Screen('CloseAll');


% After all data's collected, get threshold from average of last six reversals
if revCounter >= 4 %4
    exptThresh.trialsToAvg = exptThresh.firstTrial:T;
    exptThresh.values = exptThresh.coherence(exptThresh.firstTrial:T);
    exptThresh.threshold = mean(exptThresh.values);
end
 
%% Graph and save data

% Save Data

if ~bAbort %if you quit, don't save data or do any plotting
    exptfile = fullfile(exptThresh.dataPath,'exptThresh.mat');
    bSave = savecheck(exptfile);
    if bSave
        save(fullfile(exptThresh.dataPath,'exptThresh.mat'), 'exptThresh')
        save(fullfile(exptThresh.dataPath,'data.mat'), 'data')
        fprintf('Saved data files to: \n    %s\n',exptThresh.dataPath);
    end
    
% Plot Staircase

    figName = sprintf('staircase_%s.fig', exptThresh.snum);
    figure('Name', figName, 'NumberTitle', 'off');
    stairs(log(exptThresh.coherence));
    
    correctTrials = data.correctPress==1;
    hold on
    plot(find(correctTrials),log(exptThresh.coherence(correctTrials)),'ko','MarkerFaceColor','g');
    
    plot(find(~correctTrials),log(exptThresh.coherence(~correctTrials)),'ko','MarkerFaceColor','r');
    
    set(gca,'YTick',log(2.^[-4:0]))
    logy2raw;

    xlabel('Trial Number');
    ylabel('Coherence');
    
    %save the plot
    savefig(gcf, fullfile(exptThresh.dataPath, figName))

end

%After we're done, close PTB windows
Screen('CloseAll');

end