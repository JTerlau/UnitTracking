
%% wrapper to run unit tracking 

% INPUT
    % sessions: #sessions x 1 cell array, each cell contains 
    % a table of size n x 5 (n = number of recorded units in this session)
    % table variables:
        % unitID     (string, unit identifier assigned after spike sorting)
        % elecID     (string, can usually be extracted from unitID)
        % waveform   (n units x 1 cell array, each cell contains a 
        %             k x t matrix containg k spike waveforms with t timepoints)
        % spikeTimes (n units x 1 cell array, each cell contains a
        %             k x 1 matrix containing k spike times (contiguous!!)
        % recDay     (integer, recording date in format yyyymmdd) 

% OUTPUT
    % simData: 1 x m electrode structure. Each field contains information 
        % about all recorded units on that electrode:
        % average waveform per unit
        % the recording day per unit
        % unitIDs
        % similarity features (vectorized; shape, slope, amp, width)
        % confidence matrix (posterior probabilities == P(match))
        % label matrix (P(match) > threshold (default 0.85))
    % id: m x 1 cell array containing the unique unit identifiers per
        % electrode to track units across sessions

function [simData,id] = runUnitTracking(sessions)

% split each session at temporal halfpoint and compute waveform average
for iSession = 1:numel(sessions)

    sessionSplits{iSession} = halfSplit(sessions{iSession});

end
 
% match units (compute similarity scores across sessions)
simData = matchUnits(sessionSplits);

% track units based on pairwise similarity scores and assign unique
% identifiers
id = trackUnits(simData);
    