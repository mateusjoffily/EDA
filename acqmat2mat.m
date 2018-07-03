function varargout = acqmat2mat(acqmatfile, acqmatpath, chans, plotOK, saveOK)
% ACQMAT2MAT Convert Acknowledge Matlab (.mat) to EDA Toolbox Matlab (.mat) 
%            file format.
%   ACQMAT2MAT(acqmatfile, acqmatpath)
%
% Optional input arguments:
%   acqmatfile - ACQ file name
%   acqmatpath - ACQ path name
%   chans      - vector channels to read (e.g., [1:2 4];
%                default: all). Might be required to very large data
%                matrix (Avoid 'Out of memory' error).
%   plotOK     - plot data (boolean)
%   saveOK     - save data to file (boolean)
%
% Optional output arguments:
%   data       - m-by-n matrix of data from m channels and n samples
%   fs         - sampling rate (Hz)
% _________________________________________________________________________


% Last modified 03-07-2018 Mateus Joffily

% Copyright (C) 2018 Mateus Joffily, mateusjoffily@gmail.com.
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

if ~exist('acqmatfile', 'var') || isempty(acqmatfile) || ...
   ~exist('acqmatpath', 'var') || isempty(acqmatpath)
    [acqmatfile, acqmatpath] = uigetfile(...
        {'*.mat',  'BIOPAC Matlab File (*.mat)'; ...
         '*.*', 'All Files (*.*)'}, ...
        'Select BIOPAC Matlab File');
    
    if isequal(acqmatfile,0)
        % If cancelled, return
        return
    end
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

% Read .mat data
%--------------------------------------------------------------------------
acq = load( fullfile(acqmatpath, acqmatfile) );

if isempty(chans)
    chans = 1:size(acq.data, 2);
end

% Get dataset and sampling rate
data = acq.data(:,chans)';  % transpose data
switch acq.isi_units
    case 'ms' 
        fs = 1 / (acq.isi*10^-3);
    otherwise
        fprintf(1,'Unknown isi_units : %s.\n', acq.isi_units);
        return
end

% Free memory space (important for too large data matrix)
acq.data = [];

% Plot data
%--------------------------------------------------------------------------
if plotOK
    nChans = size(data, 1);
    figure('Name', acqmatfile);
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
    [matpath, matfile] = fileparts(fullfile(acqmatpath, acqmatfile));

    fmat = fullfile(matpath, [matfile '_eda.mat']);
    if exist(fmat, 'file')
        answer = questdlg( ...
           sprintf('%s.mat already exists! Do you want to replace it?', ...
                matfile), 'Yes', 'No');
        if strcmp(answer, 'Yes')
            save(fmat, 'data', 'fs');
        end
    else
        save(fmat, 'data', 'fs');
    end
end

% Set output variables
%--------------------------------------------------------------------------
switch nargout
    case 1
        varargout{1} = data;
    case 2
        varargout{1} = data;
        varargout{2} = fs;
end

end
