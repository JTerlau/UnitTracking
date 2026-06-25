
%% excise gaps in spikeTimes
% spikeTimes is a n unit x 1 cell array containing the spike times per unit

function spikeTimes = exciseGaps(spikeTimes)

for iUnit = 1:numel(spikeTimes)

    spikes_in = spikeTimes{iUnit};
    spikes_out = spikes_in;

    % Detect starts of new segments (where time decreases)
    newStartIdx = find(diff(spikes_in) < 0)+1;
   
    for i = 1:length(newStartIdx)
        idx = newStartIdx(i):length(spikes_in);
        % set to 0
        spikes_out(idx) = spikes_out(idx) - spikes_out(idx(1));
        % add offset (last spike time from preceding recording
        spikes_out(idx) = spikes_out(idx) + spikes_out(newStartIdx(i)-1);
    end

    % remove duplicates
    spikes_out(diff(spikes_out)==0) = [];

    % replace spikes_in in cell array
    spikeTimes{iUnit} = spikes_out;

end