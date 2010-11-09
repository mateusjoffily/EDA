function varargout = vhdr2mat(vhdrfile, vhdrpath)
% VHDR2MAT Convert BrainAmp Vis. Rec. (.vhdr) to Matlab (.mat) file format.
%   VHDR2MAT(vhdrfile, vhdrpath)
%
% Optional input arguments:
%   vhdrfile - VHDR file name 
%   vhdrpath - VHDR path name 
%
% Optional output arguments:
%   data   - m-by-n matrix of data (m channels by n samples)
%   fs     - sampling rate (Hz)
%   event  - struture array of EEG.event from .vhdr file
%
% Requirements:
%   - EEGLAB software installed (http://sccn.ucsd.edu/eeglab/)
% _________________________________________________________________________

% Last modified 09-11-2010 Mateus Joffily

% Display data? 1=yes; 0=no
dispout=1;

if nargin == 0
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Select VHDR file to convert
    [vhdrfile, vhdrpath] = uigetfile('*.vhdr', 'Select VHDR file');
end

% Read .vhdr data
[EEG, com] = pop_loadbv(vhdrpath, vhdrfile);

% Get dataset and sampling rate
data = EEG.data;     % data
fs = EEG.srate;      % Sampling freq.

% Save triggers: combine all events
% data(end+1, [EEG.event(:).latency]) = 1;

% Show data graphs
if dispout
    Nchans=size(data, 1);
    figure('Name', vhdrfile);
    for n=1:Nchans
        ax(n)=subplot(Nchans,1,n);
        plot((0:size(data,2)-1)/fs, data(n,:));
        title(sprintf('Channel %d', n));
    end
    linkaxes(ax, 'x');
end

% Rename EEG event
event = EEG.event;

% Save data to .mat file
[matpath,matfile,ext,versn] = fileparts(fullfile(vhdrpath, vhdrfile));

fmat = fullfile(matpath, [matfile '.mat']);
if exist(fmat, 'file')
    answer=questdlg(sprintf('%s.mat already exists! Do you want to replace it?', matfile), ...
        'Yes', 'No');
    if strcmp(answer, 'Yes')
        save(fmat, 'data', 'fs', 'event');
    end
else
    save(fmat, 'data', 'fs', 'event');
end

% Set outputs
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
end
