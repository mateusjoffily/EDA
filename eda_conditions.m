function conds = eda_conditions(eda, fs, xconds, edr)
% EDA_CONDITIONS Event related EDR and EDL
%   conds = EDA_CONDITIONS(eda, fs, xconds, edr)
%
% Required input arguments:
%    eda   - 1-by-n vector of EDA samples
%    fs    - samplig frequency (Hz)
%    xconds - Can be the fullpath for a *.mat file or a pre-filled conds
%            structure array (see below).
%            The *.mat file must include the following cell arrays (each
%            1xn): names, onsets and durations. e.g. names=cell(1,5),
%            onsets=cell(1,5), durations=cell(1,5), then names{2}='cond2',
%            onsets{2}=[10 40 70 100 130], durations{2}=[0 0 0 0 0].
%            contain the required details of the second condition. The
%            duration vectors can contain a single entry if the durations
%            are identical for all events.
%    edr   - structure array  of electrodermal response (EDR) (see eda_edr.m)
%
% Output arguments:
%    conds  - structure array of EDR and EDL grouped by conditions
%
% Event related EDR criteria: 
%    (1) if event duration is zero, event-related EDRs onset latency is
%        between latency_def(1) and latency_def(2); 
%    (2) if event duration is greater than zero, event-related EDRs onset 
%        latency is between latency_def(1) and 'duration'. 
%
% See below for latency_def definition. Default latency_def is [1 3].
% EDR onset latency is measured as the difference between 'valley time' 
% and 'event onset time'.
% _________________________________________________________________________

% Last modified 16-11-2010 Mateus Joffily

% Copyright (C) 2002, 2007, 2010 Mateus Joffily, mateusjoffily@gmail.com.
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

% Default EDR onset latency window (seconds)
latency_def = [1 3];

% Initialize conds structure
conds = struct('name', {}, 'onsets', {}, 'durations', {}, ...
              'latency_wdw', {}, 'iEDR', {}, 'N', [], ...
              'edl', struct('v', [], 't', []));

if nargin < 3
    return
end

if nargin < 4
    % Initialize edr, if it hasn't been provided
    edr = eda_edr;
end

if ischar(xconds)     % If xconds is a string, probably a filename
    % save a copy of filename
    fcond = xconds;
    
    % If conditions file doesn't exist, return
    if ~exist(sprintf('%s', fcond), 'file')
        return
    end

    % Load 'names', 'onsets' and 'conditions'
    load(fcond, 'names', 'onsets', 'durations');
    
    xconds = struct('name', names, 'onsets', onsets, 'durations', durations);
end

% Loop over conditions
for nC = 1:length(xconds)
    
    % Set name, onsets and durations for condition
    conds(nC).name      = xconds(nC).name;
    conds(nC).onsets    = xconds(nC).onsets;
    conds(nC).durations = xconds(nC).durations;
    
    % If the durations are identical for all events
    if length(conds(nC).durations) == 1
        conds(nC).durations = repmat(conds(nC).durations, size(conds(nC).onsets));
    end

    % Loop over onsets
    for nE = 1:length(conds(nC).onsets)
        
        % EDR
        %------------------------------------------------------------------
        % Set analysis window for current event
        conds(nC).latency_wdw(1,nE) = conds(nC).onsets(nE) + latency_def(1);
        if conds(nC).durations(nE) == 0 
            conds(nC).latency_wdw(2,nE) = conds(nC).onsets(nE) + latency_def(2);
        else
            conds(nC).latency_wdw(2,nE) = conds(nC).onsets(nE) + ...
                                 conds(nC).durations(nE);
        end

        % Find EDRs within onset latency window (i.e. event-related EDRs)
        iEDR = find( [edr.iValleys] / fs >= conds(nC).latency_wdw(1,nE) & ...
                     [edr.iValleys] / fs <= conds(nC).latency_wdw(2,nE) );
        conds(nC).iEDR{nE} = iEDR;         % er-EDR indexes in edr struct
        conds(nC).N(nE) = length(iEDR);    % Number of er-EDR found
        
        % EDL
        %------------------------------------------------------------------
        if conds(nC).durations(nE) > 0 
            t = conds(nC).onsets(nE) + [0; conds(nC).durations(nE)];
            edl = eda_edl(eda, fs, t);
            conds(nC).edl.v(:,nE) = edl.v;
            conds(nC).edl.t(:,nE) = edl.t;
            
        else
            conds(nC).edl.v(:,nE) = NaN;
            conds(nC).edl.t(:,nE) = [NaN NaN]';
            
        end
          
    end
end