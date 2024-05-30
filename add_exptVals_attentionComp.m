function add_exptVals_attentionComp(dataPaths)
%add a few things to the expt file for attentionComp that are needed for
%later analysis. 

for p = 1:length(dataPaths)
    load(fullfile(dataPaths{p},'expt.mat'))
    %first check to see if 'shifts' exists. if it doesn't, we need to add
    %some things to the expt file. 
    if ~isfield(expt,'shifts')
        save(fullfile(dataPaths{p},'expt_orig.mat'),'expt')
        %create vectors of shift angels and magnidutes for each condition
        shiftAngles = [unique(expt.shiftAngles(expt.inds.conds.noShift)) ...
            unique(expt.shiftAngles(expt.inds.conds.shiftIH)) ...
            unique(expt.shiftAngles(expt.inds.conds.shiftAE))];
        shiftMags = [unique(expt.shiftMags(expt.inds.conds.noShift)) ...
            unique(expt.shiftMags(expt.inds.conds.shiftIH)) ...
            unique(expt.shiftMags(expt.inds.conds.shiftAE))];
        %translate polar to cartesian coordinates and save in
        %expt.shifts.mels
        for s = 1:length(shiftAngles)
            expt.shifts.mels{s} = [cos(shiftAngles(s))*shiftMags(s) ...
                sin(shiftAngles(s))*shiftMags(s)];
        end
    end
    %check if 'dots' exists. if it doesn't, we need to add it and change
    %expt.listDots to expt.allDots as well as indexes for dot conditions
    if ~isfield(expt,'dots')
        expt.dots = {'dots','noDots'};
        expt.allDots = expt.listDots + 1;
        expt = rmfield(expt,'listDots');
        expt.listDots = expt.dots(expt.allDots);
        expt.inds.dots.dots = find(expt.allDots==2);
        expt.inds.dots.noDots = find(expt.allDots==1);
    end
    if ~isfield(expt,'inds.dots')
        expt.inds.dots.dots = find(expt.allDots==2);
        expt.inds.dots.noDots = find(expt.allDots==1);
    end
    save(fullfile(dataPaths{p},'expt.mat'),'expt')
end