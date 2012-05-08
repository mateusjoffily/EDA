function varargout = vhdr2mat(vhdrfile, vhdrpath, srange, chans, plotOK, saveOK)
% VHDR2MAT Convert BrainAmp Vis. Rec. (.vhdr) to Matlab (.mat) file format.
%   VHDR2MAT(vhdrfile, vhdrpath)
%
% Optional inputs:
%   vhdrfile - VHDR file name 
%   vhdrpath - VHDR path name 
%   srange   - scalar first sample to read (up to end of file) or
%              vector first and last sample to read (e.g., [7 42];
%              default: all)
%   chans    - vector channels to read (e.g., [1:2 4];
%              default: all). Might be required to very large data
%              matrix (Avoid 'Out of memory' error).
%   plotOK   - plot data (boolean)
%   saveOK   - save data to file (boolean)
%
% Optional outputs:
%   data   - m-by-n matrix of data (m channels by n samples)
%   fs     - sampling rate (Hz)
%   event  - struture array of EEG.event from .vhdr file
%
% Requirements:
%   - EEGLAB software installed (http://sccn.ucsd.edu/eeglab/)
% _________________________________________________________________________

% Last modified 16-06-2011 Mateus Joffily

% Copyright (C) 2002, 2007, 2010, 2011 Mateus Joffily, mateusjoffily@gmail.com.
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

if ~exist('vhdrfile', 'var') || isempty(vhdrfile) || ...
   ~exist('vhdrpath', 'var') || isempty(vhdrpath)
    % Select VHDR file to convert
    [vhdrfile, vhdrpath] = uigetfile( ...
        {'*.vhdr', 'BrainAmp Vis. Rec. File (*.vhdr)'; ...
         '*.*', 'All Files (*.*)'}, ...
        'Select BrainAmp Vis. Rec. File');
    
    if isequal(vhdrfile,0)
        % If cancelled, return
        return
    end
end

if ~exist('srange', 'var') || isempty(srange)
    srange = [];
end
if ~exist('chans', 'var') || isempty(chans)
    chans = [];
end
if ~exist('plotOK', 'var') || isempty(plotOK)
    plotOK = true;
end
if ~exist('saveOK', 'var') || isempty(saveOK)
    saveOK = true;
end

% Read .vhdr data
%--------------------------------------------------------------------------
EEG = pop_loadbv(vhdrpath, vhdrfile, srange, chans);

% Allocate memory space for data
nChans = size(EEG.data,1);
data = zeros(nChans+1, size(EEG.data,2));

% Get dataset and sampling rate
data(1:nChans,:) = EEG.data;     % data
fs               = EEG.srate;      % sampling rate

% Free memory space (important for too large data matrix)
EEG.data = [];

% Add trigger events at the last row of data matrix
%--------------------------------------------------------------------------
% Check for overlapping events
[B,i,j] = unique([EEG.event(:).latency]);
if length(i) ~= length(j)
    idx = find(diff([0 i]) > 1);
    disp('Warning: events onset conflict: events overlapped in events channel.');
    disp(strcat('event', num2str(i(idx)'), ':', ...
                char({EEG.event(idx).type}), ' <-> ', ...
                char({EEG.event(idx+1).type})));
end

% Unique events
event_names = unique({EEG.event(:).type});
nE = length(event_names);
event = struct('name', event_names, ...
               'onsets', cell(1,nE));
% Loop over events
for iE = 1:nE
    eOK = strcmp({EEG.event(:).type}, event(iE).name);
    data(end, [EEG.event(eOK).latency]) = iE; % Each event has a unique ID
    event(iE).onsets = [EEG.event(eOK).latency] / fs;
end

% Plot data
%--------------------------------------------------------------------------
if plotOK
    nChans = size(data, 1);
    figure('Name', vhdrfile);
    ax = zeros(1, nChans);
    for n = 1:nChans
        ax(n)=subplot(nChans,1,n);
        plot((0:size(data,2)-1)/fs, data(n,:));
        title(sprintf('Channel %d', n));
    end
    linkaxes(ax, 'x');
end

% Save data to .mat file
%--------------------------------------------------------------------------
if saveOK
    [matpath, matfile] = fileparts(fullfile(vhdrpath, vhdrfile));

    % Rename EEG event
%     event = EEG.event;

    fmat = fullfile(matpath, [matfile '.mat']);
    if exist(fmat, 'file')
        answer = questdlg( ...
           sprintf('%s.mat already exists! Do you want to append data to it?', ...
                matfile), 'Yes', 'No');
        if strcmp(answer, 'Yes')
            save(fmat, 'data', 'fs', 'event', '-APPEND');
        else
            saveOK = false;
        end
    else
        save(fmat, 'data', 'fs', 'event');
    end
else
    fmat = '';
end

% Set output variables
%--------------------------------------------------------------------------
switch nargout 
    case 1
        varargout{1} = data;
    case 2
        varargout{1} = data;
        varargout{2} = fs;
    case 3
        varargout{1} = data;
        varargout{2} = fs;
        varargout{3} = event;
    case 4
        varargout{1} = data;
        varargout{2} = fs;
        varargout{3} = event;
        varargout{4} = fmat;
    case 5
        varargout{1} = data;
        varargout{2} = fs;
        varargout{3} = event;
        varargout{4} = fmat;
        varargout{5} = saveOK;
end
