
% simType = 'same'|'different' (units)
% output is feature matrix X (observations x features)

function X = getSimFeatures(sessionSplits,simType)

for iSession = 1:numel(sessionSplits)

    sessionSplit = sessionSplits{iSession};

    if strcmp(simType,'same')

        %% waveform shape similarity
        shape_sim = cell2mat(cellfun(@(x) corr(x(1,:)',x(2,:)'),sessionSplit.waveform,'un',0));

        %% waveform dynamics similarity
        slope_sim = cell2mat(cellfun(@(x) corr(diff(x(1,:))',diff(x(2,:))'),sessionSplit.waveform,'un',0));

        %% peak to peak height & time difference
        [p1,minT] = cellfun(@(x) min(x,[],2),sessionSplit.waveform,'un',0);
        [p2,maxT] = cellfun(@(x,y) max(x(:,y:end),[],2),sessionSplit.waveform,minT,'un',0);
        maxT      = cellfun(@(x,y) x+y,maxT,minT,'un',0);

        ptpA      = abs(cell2mat(p2')-cell2mat(p1'));
        ptpA_diff = 1-abs((ptpA(1,:)-ptpA(2,:))./max(ptpA))';

        ptpW      = (cell2mat(maxT')-cell2mat(minT'));
        ptpW_diff = 1-abs(ptpW(1,:)-ptpW(2,:))';

    elseif strcmp(simType,'different')

        wf_avg = cell2mat(cellfun(@mean,sessionSplit.waveform,'un',0));
       
        %% ----------
        
        s      = size(wf_avg,1);

        elec = string([sessionSplit.elecID{:}]');

        % one random partner per unit, on a different electrode
        partner = nan(s,1);
        for iUnit = 1:s
            cand = find(elec ~= elec(iUnit));
            if isempty(cand), continue, end
            partner(iUnit) = cand(randi(numel(cand)));
        end
        iU = find(~isnan(partner));
        jU = partner(iU);

        % all four features from the SAME pair (iU,jU)
        cShape = corr(wf_avg');
        cSlope = corr(diff(wf_avg,1,2)');
        lin    = sub2ind([s s], iU, jU);
        shape_sim = cShape(lin);
        slope_sim = cSlope(lin);

        [p1,minT] = cellfun(@(x) min(mean(x),[],2), sessionSplit.waveform, 'un', 0);
        [p2,maxT] = cellfun(@(x,y) max(mean(x(:,y:end)),[],2), sessionSplit.waveform, minT, 'un', 0);
        maxT      = cellfun(@(x,y) x+y, maxT, minT, 'un', 0);
        ptpA = abs(cell2mat(p2) - cell2mat(p1));
        ptpW = abs(cell2mat(maxT) - cell2mat(minT));

        ptpA_diff = 1 - abs(ptpA(iU) - ptpA(jU)) ./ max(ptpA(iU), ptpA(jU));
        ptpW_diff = 1 - abs(ptpW(iU) - ptpW(jU));

        %% -------------
        %% waveform shape similarity
%         cMat = corr(wf_avg');
% 
%         % remove diagonal
%         s = size(cMat,1);
%         cMat_offD = reshape(cMat(~eye(s)),s-1,s); % each column contains the cross-unit pairs of one unit
% 
%         shape_sim = [];
% 
%         % pick random unit pairs
%         for iUnit = 1:size(cMat_offD,2)
% 
%             randIdx               = randperm(s-1,1);
%             shape_sim{iUnit}(:,1) = cMat_offD(randIdx,iUnit)';
% 
%         end
%         shape_sim = cell2mat(shape_sim(:));
% 
%         %% waveform slope similarity
%         cMat = corr(diff(wf_avg,1,2)');
% 
%         % remove diagonal
%         s = size(cMat,1);
%         cMat_offD = reshape(cMat(~eye(s)),s-1,s); % each column contains the cross-unit pairs of one unit
% 
%         slope_sim = [];
%         % pick random unit pairs
%         for iUnit = 1:size(cMat_offD,2)
% 
%             randIdx               = randperm(s-1,1);
%             slope_sim{iUnit}(:,1) = cMat_offD(randIdx,iUnit)';
% 
%         end
%         slope_sim = cell2mat(slope_sim(:));
% 
%         %% peak to peak height & time difference
%         [p1,minT] = cellfun(@(x) min(mean(x),[],2),sessionSplit.waveform,'un',0);
%         [p2,maxT] = cellfun(@(x,y) max(mean(x(:,y:end)),[],2),sessionSplit.waveform,minT,'un',0);
%         maxT      = cellfun(@(x,y) x+y,maxT,minT,'un',0);
% 
%         ptpA = abs(cell2mat(p2) - cell2mat(p1));
%         ptpW = abs(cell2mat(maxT) - cell2mat(minT));
% 
%         unitIdx = (1:s)';
%         randIdx = randperm(s,s)';
% 
%         ptpA_diff = 1-arrayfun(@(x,y) abs(ptpA(x)-ptpA(y))/max([ptpA(x),ptpA(y)]),unitIdx,randIdx);
%         ptpW_diff = 1-arrayfun(@(x,y) abs(ptpW(x)-ptpW(y)),unitIdx,randIdx);


    end

    feature_mat{iSession} = [shape_sim,slope_sim,ptpA_diff,ptpW_diff];

end

X = cell2mat(feature_mat(:));




