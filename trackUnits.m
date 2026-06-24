
% INPUTS
%   S     : NxN similarity matrix (e.g. SVM margins)
%   dayID : Nx1 vector of recording day labels

% OUTPUT
%   id    : unique unit identifiers

% optional input (name,value): 
%   thresh: P(Match) decision threshold (default = 0.85)
%   type: intermittent (default) | continuous

function id = trackUnits(simData,varargin)

% set default 
thresh = 0.85;
type = 'intermittent';

% check thresh input
idx = find(strcmpi(varargin,'thresh'),1);
if ~isempty(idx)
    thresh = varargin{idx+1};
end

% check type input
idx = find(strcmpi(varargin,'type'),1);
if ~isempty(idx)
    type = varargin{idx+1};
end

disp(['decision threshold = ' num2str(thresh) ', survival type: ' type])

dayVec  = unique(cell2mat({simData.days}'));

for iElec = 1:size(simData,2)
  
    S     = simData(iElec).confMat;
    dayID = simData(iElec).days;

    N = size(S,1);

    % Remove same-day edges completely
    sameDay    = dayID(:) == dayID(:).';
    S(sameDay) = 0;

    % Only use upper triangle
    [i, j, w] = find(triu(S, 1));

    % Sort edges by descending weight (strongest evidence first)
    [~, order] = sort(w, 'descend');
    i = i(order);
    j = j(order);
    w = w(order);

    % initialize IDs
    tmpID = (1:N)';

    %% greedy merging
    for k = 1:numel(i)

        u = i(k);
        v = j(k);

        % Current identities
        id_u = tmpID(u);
        id_v = tmpID(v);

        % if already merged continue
        if id_u == id_v
            continue
        end

        % Units belonging to each identity
        units_u = (tmpID == id_u);
        units_v = (tmpID == id_v);

        % Days represented in each identity
        days_u = unique(dayID(units_u));
        days_v = unique(dayID(units_v));

        % Enforce constraints:
        %   no identity may contain two units from same day
        if ~isempty(intersect(days_u, days_v))
            continue
        end       

        % Candidate merged cluster
        mergedUnits = units_u | units_v;
        idx = find(mergedUnits);

        if numel(idx) > 1

            % Extract internal similarities
            Ssub = S(idx, idx);

            % check minimum similarity per unit
            mask = triu(true(size(Ssub)), 1);
            if sum(Ssub(mask) < thresh) >= 1
                % abort merge
                continue
            end

            % match only possible in subsequent recordings
            if strcmp(type,'continuous')
                dayIdx = sort(find(ismember(dayVec,dayID(idx))));
                if max(diff(dayIdx)) > 1
                    continue % abort merge
                end
            end
        end

        % Accept merge
        tmpID(units_v) = id_u;

    end

% label IDs consecutively
[~,~,tmpID] = unique(tmpID);

id{iElec,1} = tmpID;

end


