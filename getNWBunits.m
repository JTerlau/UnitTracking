

%% extract necessary unit information from nwbFiles (e.g. all nwb files of one session)

% INPUT
    % nwbFiles is a cell array, where each cell contains an nwb file
% OUTPUT
% session is a table of size n x 4 
    % (n = number of recorded units in this session)
    % table variables:
        % unitID     (string, unit identifier assigned after spike sorting)
        % elecID     (string)
        % waveform   (n units x 1 cell array, each cell contains a 
        %             k x t matrix containg k spike waveforms with t timepoints)
        % spikeTimes (n units x 1 cell array, each cell contains a
        %             k x 1 matrix containing k spike times (contiguous!!)
        % recDay     (integer, recording date in format yyyymmdd) 

function session = getNWBunits(nwbFiles)

for iFile = 1:numel(nwbFiles) 
    
    nwb = nwbFiles{iFile};

    % get units table
    props = properties(nwb);
    if ismember('units',props) && ~isempty(nwb.units)       
        units = nwb.units;        
    elseif ismember('scratch',props) && size(nwb.scratch,1)>0 
        units = nwb.scratch.get('units_table');
    elseif isempty(nwb.units) && isempty(nwb.scratch.keys)
        warning('no units in nwb file')
        continue
    end

    if isempty(units)
        continue
    end

    % accumulative spike times indices
    spikeIdx_cat = units.spike_times_index.data(:); % each entry points to the last spike time of the nth unit
    spikeIdx_cat = [0; double(spikeIdx_cat)];       % add 0 for easier indexing

    % accumulative spike times
    accSpikeTimes = units.spike_times.data(:);

    % get unit labels
    unit_labels = units.vectordata.get('labels').data(spikeIdx_cat(1:end-1)+1);

    % restrict to (single and multi) units
    su_idx    = contains(unit_labels,'su') & ~contains(unit_labels,'atf');
    mu_idx    = contains(unit_labels,'mu') & ~contains(unit_labels,'atf');
    unitIdx   = find(su_idx | mu_idx);
    unitID = unit_labels(unitIdx);

    if isempty(unitIdx)
        warning('no units sorted')
        continue
    end
   
    wf = [];
    spikeTimes = [];

    for iUnit = 1:numel(unitID)

        thisUnit = unitIdx(iUnit);

        %% waveforms
        unit_spikeIdx = spikeIdx_cat(thisUnit)+1 : spikeIdx_cat(thisUnit+1);

        % get spike times of that unit
        spikeTimes{iUnit,1} = accSpikeTimes(unit_spikeIdx);

        % get waveform from waveforms field       
        wf{iUnit,1} = units.waveforms.data(unit_spikeIdx,:);

    end

    %
    spikeTimes = cellfun(@single,spikeTimes,'un',0);

    % get elec labels from unitLabels
    su_labels_split = split(unitID,'-');
    elecID = su_labels_split(:,2);
   
    % get recording day
    recDay = str2double(datestr(datenum(nwb.identifier, 'dd-mmm-yyyy HH:MM:SS'), 'yyyymmdd'));
    recDay = repmat(recDay,numel(unitID),1);


    % put in table
    nwbTbl{iFile} = table(unitID,elecID,recDay,wf,spikeTimes,...
        'VariableNames',{'unitID','elecID','recDay','waveform','spikeTimes'});

end

if ~exist('nwbTbl','var')
    session = [];
    return
end

% concatenate recordings of that day
T = vertcat(nwbTbl{:});

% find identical units across recordings
[unitG,unitID] = findgroups(T.unitID);

% concatenate features of identical units (note: different order of units in wf_cat and wf)
wf_cat         = splitapply(@(x) {int16(vertcat(x{:}))}, T.waveform, unitG);
spikeTimes_cat = splitapply(@(x) {vertcat(x{:})}, T.spikeTimes, unitG);
elecID_cat     = splitapply(@(x) {unique(x)}, T.elecID, unitG);
recDay_cat     = repelem(T.recDay(1,:),max(unitG),1);

% excise gaps in spikeTimes
if any(cell2mat(cellfun(@(x) any(diff(x)<0),spikeTimes_cat,'un',0)))
    spikeTimes_cat = exciseGaps(spikeTimes_cat);
end

% put in table
session = table(unitID,elecID_cat,recDay_cat,wf_cat,spikeTimes_cat,...
    'VariableNames',{'unitID','elecID','recDay','waveform','spikeTimes'});

%% keep only units with > 500 spikes
a                 = cell2mat(cellfun(@numel,session.spikeTimes,'un',0));
rm_idx            = a < 500;
session(rm_idx,:) = [];

