function [hPhase] = plot_attentionAdapt_pairedData(session,plotParams)
%function [hPhase] = plot_vsaSentence_pairedData(T,isTransfer)
%function [dataMeansByCond] = plot_vsaSentence_pairedData(T,isTransfer)

% This function creates a structure that can be read to plot_pairedData.
% It creates a number of plots based on the phases you wish to look at.

if nargin < 1 || isempty(session)
    session.dots = [.4 .7 .06];
    session.noDots = [.8 0 .4];
end
if nargin < 3 || isempty(plotParams) 
    plotParams.Marker = '.';
    plotParams.MarkerSize = 8;
    plotParams.MarkerAlpha = .25;
    plotParams.LineWidth = .6;
    plotParams.LineColor = [.7 .7 .7 .5];
    plotParams.avgMarker = 'o';
    plotParams.avgMarkerSize = 4;
    plotParams.avgLineWidth = 1.25;
    plotParams.jitterFrac = .25;
    plotParams.FontSize = 13;
end
 
%condition = categorical(cond);
%phase = categorical(phase);
%vow = categorical(T.vow);
participant = categorical(cond);
participant_cat = categories(participant);

conds = {'dots','noDots'};
%vowels = {'IY','IH','EH','AE','AA','AH','OW','UW','EY','UH','ER','AO','AW','AY'};
vowels = {'ih'};
phases = {'hold','washout','retention'};

for i=1:length(conds)
    for v=1:length(vowels)
        rfx(1).(conds{i}).centdistdiff.(vowels{v}) = struct('hold',[],'washout',[],'retention',[]);
    end
end

% structure name: dataMeansByCond

%% Create a data struct that can be read by plot_pairedData

for part=1:length(participant_cat)
    subject = char(participant_cat(part));
    for c=1:length(conds)
        cond = conds{c};
        for p=1:length(phases)
            phas = phases{p};
            for v=1:length(vowels)
                vowel = vowels{v};
                meanBySubject = mean(table2array(participant==subject & phase==phas & vow==vowel & condition==cond,4));
                rfx.(cond).centdistdiff.(vowel).(phas)(part) = meanBySubject;
            end
        end
    end
end

%% Begin plotting
YLim = [-150 150];
ylab = 'norm. distance to center (mels)';
hlineColor = [.25 .25 .25];
for p=1:length(phases)
    phas = phases{p};
    for v=1:length(vowels)
        vow = vowels{v};
        dataMeansByCond.adapt = rfx.adapt.centdistdiff.(vow).(phas);
        dataMeansByCond.control = rfx.null.centdistdiff.(vow).(phas);
        colorSpec(1,:) = session.(vow);
        colorSpec(2,:) = get_desatcolor(get_darkcolor(session.(vow)));
        h.(phas)(v) = plot_pairedData(dataMeansByCond,colorSpec,plotParams);
        text(1.5,YLim(1)+25,arpabet2ipa(vow,'/'),'HorizontalAlignment','center','FontSize',13)
        set(gca,'YLim',YLim)
        set(gca,'XTickLabelRotation',30)
        if v > 1
            set(gca,'YTickLabel','');
        else
            ylabel(ylab)
        end
        hl = hline(0,hlineColor,'--');
        uistack(hl,'bottom');
    end
    hPhase(p) = figure;

    xpos = 1000;
    ypos = 1000 - 550*(p-1);
    hPhase(p).Position = [xpos ypos 560 420];

    copy_fig2subplot(h.(phas),hPhase(p),1,4,[],1);
    supertitle(phas)
end