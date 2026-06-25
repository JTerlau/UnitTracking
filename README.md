%% Waveform-Based Unit Tracking Toolbox
%
% This toolbox tracks individual units (SU/MU) across recording sessions by
% comparing waveform similarity within and across sessions. It adapts the
% UnitMatch approach (van Beest et al., 2025, Nat Methods) to multi-session
% recordings on multi-electrode arrays such as the Utah array.
%
% Spike sorting must be performed prior to tracking to generate unit
% identifiers within each session.
%
%
% -------------------------------------------------------------------------
% PIPELINE OVERVIEW
% -------------------------------------------------------------------------
%
% Step 1 — Half-split averaging (halfSplit)
%   Each session is split at its temporal midpoint. For each unit, two
%   average waveforms are computed — one per half — to obtain a stable
%   waveform estimate while capturing within-session variability.
%
% Step 2 — Classifier training & cross-session matching (trainClassifier, matchUnits)
%   Four waveform features are extracted for all unit pairs:
%     - Shape similarity     (correlation of mean waveforms)
%     - Slope similarity     (correlation of first derivatives)
%     - Amplitude similarity (peak-to-peak amplitude difference, max-normalised)
%     - Width similarity     (peak-to-peak width difference)
%   An SVM classifier is trained on within-session pairs (ground-truth
%   matches) and across-session pairs (ground-truth non-matches) to learn
%   the decision boundary. It is then applied to all cross-session unit
%   pairs on each electrode, yielding P(match) for every pair.
%
% Step 3 — Unit tracking (trackUnits)
%   Units are linked across sessions by greedy merging of the highest-
%   confidence pairs, subject to the constraint that no identity may contain
%   two units from the same recording day. Each group of linked units is
%   assigned a unique integer identifier.
%
%
% -------------------------------------------------------------------------
% QUICK START
% -------------------------------------------------------------------------
%
% 1. Load NWB files and extract unit tables (one call per session):
%
%      session = getNWBunits(nwbFiles);  % nwbFiles: cell array of nwb objects
%
% 2. Collect session tables into a cell array:
%
%      sessions = {session1, session2, session3, ...};
%
% 3. Run the tracking pipeline:
%
%      [simData, id] = runUnitTracking(sessions);
%
%
% -------------------------------------------------------------------------
% INPUTS
% -------------------------------------------------------------------------
%
% sessions : #sessions x 1 cell array
%   Each cell contains a session table with one row per unit and variables:
%     unitID     - string; unit identifier from spike sorting
%     elecID     - string; electrode identifier
%     waveform   - cell; k x t matrix of k spike waveforms (t timepoints)
%     spikeTimes - cell; k x 1 vector of spike times (contiguous seconds)
%     recDay     - integer; recording date (yyyymmdd)
%
%
% -------------------------------------------------------------------------
% OUTPUTS
% -------------------------------------------------------------------------
%
% simData : 1 x #electrodes struct
%   One entry per electrode. Fields:
%     elecID   - electrode identifier
%     wf       - #units x t matrix of mean waveforms
%     days     - #units x 1 vector of recording days
%     unitID   - #units x 1 cell array of spike-sorting unit labels
%     simFeat  - vectorised, normalised feature matrix (#units^2 x 4)
%     confMat  - #units x #units matrix of P(match) scores
%
% id : #electrodes x 1 cell array
%   Each cell contains a #units x 1 integer vector. Units sharing the same
%   identifier across sessions are considered the same cell.
%
%
% -------------------------------------------------------------------------
% OPTIONAL ARGUMENTS (runUnitTracking / trackUnits)
% -------------------------------------------------------------------------
%
%   'thresh'  - P(match) decision threshold (default: 0.85)
%               Increase to require stronger evidence before linking units.
%
%   'type'    - Tracking continuity constraint (default: 'intermittent')
%               'intermittent' : units may be re-identified after gaps
%               'continuous'   : units must appear in consecutive sessions
%
% Example:
%   id = trackUnits(simData, 'thresh', 0.90, 'type', 'continuous');
%
%
% -------------------------------------------------------------------------
% FUNCTIONS
% -------------------------------------------------------------------------
%
%   runUnitTracking   - wrapper; runs the full pipeline
%   getNWBunits       - extracts unit tables from NWB files
%   halfSplit         - computes per-unit half-split waveform averages
%   trainClassifier   - trains SVM on labeld different/same unit pairs within sessions 
%   getSimFeatures    - extracts waveform similarity features
%   matchUnits        - applies classifier to cross-session unit pairs
%   trackUnits        - assigns unique identifiers via greedy merging
%   exciseGaps        - corrects non-monotonic spike times across recordings
%
