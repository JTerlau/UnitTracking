

%% matching: train classifier on within- and across unit similarities within sessions
%% and create similarity matrix between units across sessions for each electrode 

% INPUT:
    % sessionSplits is a #sessions cell array, where each cell contains the
    % sessionSplit table for that session (output of halfSplit)

% OUTPUT:
    % simData contains the data for all identified units per electrode

function simData = matchUnits(sessionSplits)


%% get within-session similarities
[mdl, normTrain] = trainClassifier(sessionSplits);

%% get across-session similarities
for iSession = 1:numel(sessionSplits)

    % elecID
    tmp              = [sessionSplits{iSession}.elecID{:}]';
    elecID{iSession} = cell2mat(cellfun(@(x) str2num(x(5:7)),tmp,'un',0));

    % unitID
    unitID{iSession}  = {sessionSplits{iSession}.unitID{:}}';

    % roi
    tmp   = split([sessionSplits{iSession}.unitID],'-');
    tmp   = tmp(:,1);
    tmp(cell2mat(cellfun(@(x) strcmp(x,'AG'),tmp,'un',0))) = {'ANG'};
       
    wf{iSession}          = cell2mat(cellfun(@mean,sessionSplits{iSession}.waveform,'un',0));    
    recDay{iSession,1}    = sessionSplits{iSession}.recDay;%repmat(dates{iSession},size(sessions{iSession},1),1);
   

end

elecID = cell2mat(elecID(:));
wf     = cell2mat(wf(:));
recDay = cell2mat(recDay(:));
unitID = vertcat(unitID{:});

elecs_unique = unique(elecID);


%% test on single units of each electrode
simData = [];
for iElec = 1:numel(elecs_unique)

    tmpElec = elecs_unique(iElec);
    simData(iElec).elecID = tmpElec;

    elecIdx = find(elecID == tmpElec); % find all units recorded by that electrode

    if ~isempty(elecIdx)

        simData(iElec).wf        = wf(elecIdx,:);       
        simData(iElec).days      = recDay(elecIdx,:);       
        simData(iElec).unitID  = unitID(elecIdx);

        wf_avg   = simData(iElec).wf;        

        %% waveform shape similarity
        shape_sim = corr(wf_avg');

        %% waveform slope similarity
        slope_sim = corr(diff(wf_avg,1,2)');

        %% ptpA & ptpW similarity
        wf_cell = num2cell(wf_avg,2);

        [p1,minT] = cellfun(@(x) min(x,[],2),wf_cell,'un',0);
        [p2,maxT] = cellfun(@(x,y) max(x(:,y:end),[],2),wf_cell,minT,'un',0);
        maxT      = cellfun(@(x,y) x+y,maxT,minT,'un',0);

        ptpA = abs(cell2mat(p2) - cell2mat(p1));
        ptpW = abs(cell2mat(maxT) - cell2mat(minT));

        amp_sim   = 1-abs(ptpA-ptpA')./max(ptpA,ptpA');
        width_sim = 1-abs(ptpW-ptpW');

        x_test      = [shape_sim(:),slope_sim(:),amp_sim(:),width_sim(:)];
    
        %% min-max normalize to training data
        x_test_norm =  (x_test - normTrain.min) ./ (normTrain.max-normTrain.min);

        % store
        simData(iElec).simFeat = x_test_norm;

        %% classification
        [~, score] = predict(mdl, x_test_norm);

        simData(iElec).confMat  = reshape(score(:,1),size(shape_sim,1),size(shape_sim,2));

    end
end

