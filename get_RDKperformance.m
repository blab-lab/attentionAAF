function [RDKperf] = get_RDKperformance(dataPaths,experiment)
if nargin < 2 || isempty(experiment)
    experiment = 'comp'; %can also take 'adapt'
end
nSubj = length(dataPaths);
RDKperf = NaN(1,nSubj);

for dP = 1:nSubj
    dataPath = dataPaths{dP};
    switch experiment
        case 'comp'
            %load(fullfile(dataPath,'expt.mat'),'expt')
            load(fullfile(dataPath,'data.mat'),'data')
            bCorrectPress = [data.bCorrectPress];
        case 'adapt' %adapt has two sessions, figure out which has dots
            path_ses1 = fullfile(dataPath,'session1');
            load(fullfile(path_ses1,'expt.mat'),'expt')
            if strcmp(expt.sessionOrder{1},'dots')
                load(fullfile(path_ses1,'data.mat'),'data')
            else
                path_ses2 = fullfile(dataPath,'session2');
                load(fullfile(path_ses2,'data.mat'),'data')
            end
            bCorrectPress = [data.bCorrectPress];
        otherwise
            error("experiment must be 'comp' or 'adapt'")
    end
    RDKperf(dP) = mean(bCorrectPress);
end
