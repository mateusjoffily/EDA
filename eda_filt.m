function varargout = eda_filt(edain, fs, filtin, opendlg, plotOK)
% EDA_FILT Electrodermal Activity (EDA) filters
%   [edaout filtout] = EDA_FILT(edain, fs, filtin, plotOK)
%
% Required input arguments:
%    edain - 1-by-n vector of EDA samples
%    fs    - samplig frequency (Hz)
%
% Optional input arguments:
%    filtin  - (1) 'default' - use defalut SC filter params
%              (2) structure array containing pre-defined filter parameters 
%                  (see filt_main.m)
%    opendlg - open dialog box (boolean)
%    plotOK  - display results (boolean)
%
% Optional output arguments:
%    edaout  - 1-by-n vector of EDA samples filtered
%    filtout - structure array containing EDA specific filter parameters
%              (see filt_main.m)
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

% Default filter parameters for EDA: Butterworth low-pass
% filter with cut-off frequency at 0.5Hz
filtdef.name = 'butter';  % Butterworth filter
filtdef.type = 'low';     % low-pass filter
filtdef.n = 5;            % filter order
filtdef.fc = 1;         % cutoff frequency (Hz)

% Display frequence response and filtered signal
if nargin < 5, plotOK = false; end

if nargin < 4, opendlg = false; end

if nargin < 3 || isempty(filtin) || ...
   ischar(filtin) && strcmp(filtin, 'default')
    clear filtin;
    % Set filterin to default
    filtin = filtdef;
    
end

if isempty(fs)
    % return filter parameters
    varargout{1} = filtin;
    return
end

if opendlg 
    % Open GUI
    prompt={'Name', ...
            'Type', ...
            'Order', ...
            'Cutoff frequency (Hz)'};
     def={sprintf('%s', filtin(1).name), ...
          sprintf('%s', filtin(1).type), ...
          sprintf('%d', filtin(1).n), ...
          sprintf('%.04f', filtin(1).fc)};
    dlgTitle='Set filter parameters';
    lineNo=1;
    answer=inputdlg(prompt,dlgTitle,lineNo,def);

    if ~isempty(answer) && ~( isempty(answer{1}) || ...
            isempty(answer{2}) || isempty(answer{3}) || isempty(answer{4}))
        % user defined threshold values
        filtin(1).name = answer{1};
        filtin(1).type = answer{2};
        filtin(1).n = str2double(answer{3});
        filtin(1).fc = str2double(answer{4});
        
    else
        % Set varargout
        if nargout >= 1
            varargout{1} = [];
        end
        if nargout == 2
            varargout{2} = [];
        end
        return
    end
end

% Filter EDA
[edaout filtout] = filt_main(edain, fs, filtin, plotOK);

% Residual
noise = edain - edaout;

% Plot filtered signal
if plotOK
    t=(0:length(edain)-1)/fs;
    
    % Plot EDA raw power spectrum
    figure('Color', 'w');
    pwelch(edain-mean(edain),[],[],[],fs);
    title('Welch Power Spectral Density Estimate (EDA Raw)');
   
    % Plot EDA filtered + noise
    figure('Color', 'w');
    hold on;
    p1=plot(t,edain);
    p2=plot(t,edaout);
    set(p1, 'Color', [0.5 0.5 1], 'LineWidth', 1);
    set(p2, 'Color', [0 0 1], 'LineWidth', 2);
    ylabel('uSiemens');
    xlabel('seconds');
    s=sprintf('EDA(M=%0.4f; SD=%0.4f) / NOISE(M=%0.4f; SD=%0.4f)',...
               mean(edaout), std(edaout), mean(noise), std(noise));
    title(s);
    legend('EDA Raw', 'EDA Filtered');
end

% Set varargout
if nargout >= 1
    varargout{1} = edaout;
end
if nargout == 2
    varargout{2} = filtout;
end

 

% Goodbye message
disp([mfilename ': done.']);