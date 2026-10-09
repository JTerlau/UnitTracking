

%% compute each unit's average waveform per session half split (temporal midpoint)

% INPUT
    % session is a table of size n x 5 
    % (n = number of recorded units in this session)
    % table variables:
        % unitID     (string, unit identifier assigned after spike sorting)
        % elecID     (string)
        % waveform   (n units x 1 cell array, each cell contains a 
        %             k x t matrix containg k spike waveforms with t timepoints)
        % spikeTimes (n units x 1 cell array, each cell contains a
        %             k x 1 matrix containing k spike times (contiguous!!)
        % recDay     (integer, recording date in format yyyymmdd) 


% OUTPUT
    % sessionSplit is a table of size k x 4
    % (k = number of recorded units in this session with >= 500 spikes per split)
    % table variables:
        % unitID     (string, unit identifier assigned after spike sorting)
        % elecID     (string)
        % waveform   (n units x 1 cell array, each cell contains a 
        %             2 x t matrix containg the average waveform per session half split)      
        % recDay     (integer, recording date in format yyyymmdd) 

function [sessionSplit,percExcl] = halfSplit(session)


%% find temporal midpoint
% check wether spike times are contiguous and excise gaps 
if any(cell2mat(cellfun(@(x) any(diff(x)<0),session.spikeTimes,'un',0)))
    session.spikeTimes = exciseGaps(session.spikeTimes);
end

%% split whole recording day at temporal midpoint
midpoint = max(cell2mat(cellfun(@max,session.spikeTimes,'un',0)))/2;
%midpoint_cat = num2cell(repelem(midpoint,numel(session.waveform)))'; % match dimensions to unit cell array


%% keep only units with > 500 spikes per split
s1 = cell2mat(cellfun(@(x) sum(x <= midpoint),session.spikeTimes ,'un',0));
s2 = cell2mat(cellfun(@(x) sum(x > midpoint),session.spikeTimes ,'un',0));
rm_idx            = any([s1 < 500,s2 < 500],2);
session(rm_idx,:) = [];

percExcl = mean(rm_idx);

% waveforms
wf_splitIdx   = cellfun(@(x) dsearchn(x,midpoint),session.spikeTimes,'un',0);

wf_avg   = cellfun(@(x,i) [nanmean(x(1:i,:),1);...
    nanmean(x(i+1:end,:),1)],session.waveform,wf_splitIdx,'un',0);

%% create output table
sessionSplit            = session;
sessionSplit.waveform   = wf_avg;
sessionSplit.spikeTimes = []; % remove spike times (not needed downstream)






