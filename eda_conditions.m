function conds = eda_conditions(eda, fs, fcond, edr)
% EDA_CONDITIONS Event related EDR and EDL
%   conds = EDA_CONDITIONS(eda, fs, fcond, edr)
%
% Required input arguments:
%    eda   - 1-by-n vector of EDA samples
%    fs    - samplig frequency (Hz)
%    fcond - This *.mat file must include the following cell arrays (each
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
%    (1) if event duration is zero, event related EDRs latency is
%        between def_latency(1) and def_latency(2); 
%    (2) if event duration is greater than zero, event related EDRs 
%        latency is between def_latency(1) and 'duration'. 
%
% See below for def_latency definition. Default def_latency is [1 3];
% 
%    EDR latency is measured as 'valley time' minus 'event onset time'.
% _________________________________________________________________________

% Last modified 09-11-2010 Mateus Joffily

% Default EDR latency range (seconds)
def_latency = [1 3];

if nargin < 4
    % Initialize edr, if it hasn't been provided
    edr = struct('iPeaks', [], 'iValleys', [], ...
                 'type', struct('v', [], 'p', []), 'thresh', []);
end

% If conditions file doesn't exist, return
if ~exist(sprintf('%s', fcond), 'file')
    conds = [];
    return
end

% Load 'names', 'onsets' and 'conditions'
load(fcond, 'names', 'onsets', 'durations');

% Initialize conds structure
conds = struct('name', names, 'onsets', onsets, 'durations', durations, ...
              'edr_latency', [], 'iEDR', [], 'N', [], ...
              'edl', struct('v', [], 't', []));

% Loop over conditions
for nC = 1:length(conds)

    % If the durations are identical for all events
    if length(conds(nC).durations) == 1
        conds(nC).durations = repmat(conds(nC).durations, size(conds(nC).onsets));
    end

    % Loop over onsets
    for nE = 1:length(conds(nC).onsets)
        
        % EDR
        %------------------------------------------------------------------
        % Set analysis window for current event
        conds(nC).edr_latency(1,nE) = conds(nC).onsets(nE) + def_latency(1);
        if conds(nC).durations(nE) == 0 
            conds(nC).edr_latency(2,nE) = conds(nC).onsets(nE) + def_latency(2);
        else
            conds(nC).edr_latency(2,nE) = conds(nC).onsets(nE) + ...
                                 conds(nC).durations(nE);
        end

        % Find EDRs inside anlysis with (i.e. Event Related EDR (ER-EDR))
        iEDR = find( [edr.iValleys] / fs >= conds(nC).edr_latency(1,nE) & ...
                     [edr.iValleys] / fs <= conds(nC).edr_latency(2,nE) );
        conds(nC).iEDR{nE} = iEDR;         % ER-EDR indexes in edr struct
        conds(nC).N(nE) = length(iEDR);    % Number of ER-EDR
        
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