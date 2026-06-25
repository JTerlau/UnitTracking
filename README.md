# Toolbox UnitTracking


Waveform-based unit UnitTracking

This tracking algorithm compares the cross-session and within-session similarity of waveform features to track individual units (SU/MU).
It adapts the unitMatch approach (van Beest et al., 2025, Nat Methods) to multi-electrode arrays like the Utah array.
You need to run spike sorting first to generate unit identifiers within each session.
For NWB files that contain sorted units, you can use getNWBUnits to generate a session table that contains all necessary information. 
Create a cell array of all session tables to run the wrapping function runUnitTracking. This then performs all three steps of the tracking pipeline:
1. split each session in half and compute waveform averages per split
2. train classifier on within-session similarity and test on cross-session similarity to compute similarity scores for all pairs of compared units (matching)
3. track units by assigning unique identifiers to groups of units whose pairwise similarity scores exceed a pre-defined threshold
This generates two outputs: 
- simData is a table with one row per channel, containing information on all units recorded on that channel across all sessions
- id is a cell array with one cell per channel, For each unitID in simData, it contains the corresponding unique identifier


