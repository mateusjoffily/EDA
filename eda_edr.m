function edr = eda_edr(varargin)
% EDA_EDR Automatic Electrodermal Response (EDR) detection.
%
% Formats:
%   (1) edr = EDA_EDR(eda, fs)
%   (2) edr = EDA_EDR(eda, fs, thrin, opendlg)
%   (3) edr = EDA_EDR(eda, fs, thrin, opendlg, plotOK)
%
% Required Input arguments:
%   eda - 1-by-n vector of EDA samples
%   fs  - EDA sampling rate (Hz) 
%
% Optional Input arguments:
%   thrin   - structure array with fields:
%       amp      - user defined amplitude threshold (microSiemens) 
%                  'amp' is a struct with fields 'min' and 'max'
%       slope    - user defined slope threshold range (microSiemens/s)
%                  'slope' is a struct with fields 'min' and 'max'
%       risetime - user defined rise time threshold (s)
%                  'risetime' is a struct with fields 'min' and 'max'
%       overlap  - detect overlapping EDRs (boolean)                  
%   opendlg - open dialog box (boolean)
%   plotOK - plot results (boolean)
%
% Output arguments:
%   edr - structure array with fields:
%       iPeaks     - EDR peaks index in EDA vector 
%       iValleys   - EDR valleys index in EDA vector 
%       type - EDR type, according to Bucsein (1992, p.136) terminology:
%             (1) - single response (ideal), it never occurs
%             (2) - response overlaps preceding response during recovery time
%             (3) - response overlaps preceding/posterior response during rise time
%             (4) - response manually detected by the user (set only by eda_gui.m)
%       thresh  - EDR detection thresholds used:
%           amp      - [uSiemens] amplitude threshold
%                    'amp' is a struct that contains fields 'min' and 'max'
%           slope    - [uSiemens/s] slope threshold range
%                   'slope' is a struct that contains fields 'min' and 'max'
%           risetime - [s] rise time threshold
%                      'risetime' is a struct that contains fields 'min' and 'max'
%           overlap  - detect overlapping EDRs (boolean) (see Bucsein
%           (1992, p.136) methods B and C)
% 
% References:
%   Dawson, Schell and Filion (2000) The Electrodermal System. 
%     In Cacioppo, Tassinary and Berntson (Eds.), Handbook of
%     Psychophysiology, p.200-223.
%   Boucsein (1992) Electrodermal Activity, Plenum Press (Ed.), New York.
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

% Threshold default values
thresh_def.amp.min      = 0.02;  % EDR amplitude minimum value
thresh_def.amp.max      = Inf;   % EDR amplitude maximum value
thresh_def.slope.min    = 0.0;   % EDR slope minimum value
thresh_def.slope.max    = Inf;   % EDR slope maximum value
thresh_def.risetime.min = 0;     % EDR risetime minimum value
thresh_def.risetime.max = Inf;   % EDR risetime maximum value
thresh_def.overlap      = false; % Detect EDRs overlapping

% Empty threshold structure
minmax = struct('min', {}, 'max', {});
thresh_empty = struct('amp', minmax, 'slope', minmax, ...
                      'risetime', minmax, 'overlap', {});

% Initialize edr structure
edr = struct('iPeaks', [], 'iValleys', [], ...
             'type', struct('v', [], 'p', []), 'thresh', thresh_empty);

% Check number of input arguments
if nargin < 2
    return
end

% Set initial values
eda = varargin{1};
eda = eda(:)';      % Force eda to be row vector
fs = varargin{2};
opendlg = false;
plotOK = false;
    
if nargin < 3
    edr.thresh = thresh_def;
else
    if isstruct(varargin{3})
        edr.thresh = varargin{3};
    else
        edr.thresh = thresh_def;
    end
end
    
if nargin >= 4 && ~isempty(varargin{4})
    opendlg = varargin{4};
end
    
if nargin >= 5 && ~isempty(varargin{5})
    plotOK = varargin{5};
end

if opendlg 
    % Open GUI
    prompt={'Amplitude minimum (uSiemens)', ...
            'Amplitude maximum (uSiemens)', ...
            'Slope minimum (uSiemens/s)', ...
            'Slope maximum (uSiemens/s)', ...
            'Risetime minimum (s)', ...
            'Risetime maximum (s)', ...
            'Detect overlapped responses (no = 0, yes = 1)'};
    if isempty(edr.thresh)
        def={sprintf('%.04f', thresh_def.amp.min), ...
            sprintf('%.04f',  thresh_def.amp.max), ...
            sprintf('%.04f',  thresh_def.slope.min), ...
            sprintf('%.04f',  thresh_def.slope.max), ...
            sprintf('%.04f',  thresh_def.risetime.min), ...
            sprintf('%.04f',  thresh_def.risetime.max), ...
            sprintf('%d',     thresh_def.overlap)};
    else
        def={sprintf('%.04f', edr.thresh.amp.min), ...
            sprintf('%.04f',  edr.thresh.amp.max), ...
            sprintf('%.04f',  edr.thresh.slope.min), ...
            sprintf('%.04f',  edr.thresh.slope.max), ...
            sprintf('%.04f',  edr.thresh.risetime.min), ...
            sprintf('%.04f',  edr.thresh.risetime.max), ...
            sprintf('%d',     edr.thresh.overlap)};
    end
    dlgTitle='Set EDR thresholds';
    lineNo=1;
    answer=inputdlg(prompt,dlgTitle,lineNo,def);

    if ~isempty(answer) && ~( isempty(answer{1}) || ...
            isempty(answer{2}) || isempty(answer{3}) || ...
            isempty(answer{4}) || isempty(answer{5}) || ...
            isempty(answer{6}) || isempty(answer{7}))
        % user defined threshold values
        edr.thresh(1).amp.min = str2double(answer{1});
        edr.thresh(1).amp.max = str2double(answer{2});
        edr.thresh(1).slope.min = str2double(answer{3});
        edr.thresh(1).slope.max = str2double(answer{4});
        edr.thresh(1).risetime.min = str2double(answer{5});
        edr.thresh(1).risetime.max = str2double(answer{6});
        edr.thresh(1).overlap = str2double(answer{7});
        
        if ~ ( (edr.thresh.amp.min < edr.thresh.amp.max) && ...
                (edr.thresh.slope.min < edr.thresh.slope.max) && ...
                (edr.thresh.risetime.min < edr.thresh.risetime.max) )
            warndlg('Min must be lower than Max', dlgTitle);
            edr.thresh = thresh_empty;
            return
        end

        if edr.thresh.overlap ~= 0 && edr.thresh.overlap ~= 1
            warndlg('"Split overlapped responses" must be 0 or 1', dlgTitle);
            edr.thresh = thresh_empty;
            return
        end
    end
end

if isempty(edr(1).thresh)
    % If threshold structure is empty, return
    return
end
    
% Detect responses' valleys-peaks
%--------------------------------------------------------------------------

% Detect EDR peaks and valleys
[edr.iValleys, edr.iPeaks] = peak_detect(eda, fs);

% Number of detected EDRs
nEDR = length(edr.iValleys);

% Set all detected responses' type to 2
edr.type.v = repmat(2, 1, nEDR);
edr.type.p = edr.type.v;

% Detect overlapped responses
%--------------------------------------------------------------------------
% If accelerating deflection is found between a reponse's 
% valley-peak pair, treat it as two overlapping responses. 
% Set reponses' type to 3.
type3iap = cell(1, nEDR);
for i = 1:nEDR

    % eda signal between valley-peak pair
    edawin = eda(edr.iValleys(i):edr.iPeaks(i));

    % calculate second derivative
    deriv2 = diff(edawin,2) / ((1/fs)^2);

    % find acceleratory deflection points
    sign_deriv2 = sign(deriv2);
    sign_deriv2( sign_deriv2 == 0 ) = 1;
    d2sign_deriv2 = diff(sign_deriv2);
    iap = find(d2sign_deriv2 > 0);

    if ~isempty(iap)
        % If overlapping responses were found
        edr.type.v(i) = 3;          % change response type to 3
        edr.type.p = edr.type.v;
        type3iap{i} = iap + 1;  % save acceleration points
    end

end

% Split overlapping responses
%--------------------------------------------------------------------------

if edr.thresh.overlap    
    % find overlapping responses
    type3idx = find(edr.type.v == 3);
    
    for t = type3idx  % loop over overlapping EDRs
        % adjust index
        i = t + length([type3iap{1:t-1}]);
        % insert new valley-peak pair
        edr.iPeaks = [edr.iPeaks(1:i-1) edr.iValleys(i)+type3iap{t} ...
                      edr.iPeaks(i:end)];
        edr.iValleys = [edr.iValleys(1:i) edr.iValleys(i)+type3iap{t}+1 ...
                        edr.iValleys(i+1:end)];
        edr.type.v = [edr.type.v(1:i) repmat(3,1,length(type3iap{t})) ...
                      edr.type.v(i+1:end)];
        edr.type.p = edr.type.v;
    end
end

% Threshold EDRs
%--------------------------------------------------------------------------

% Threshold amplitude
amps=eda(edr.iPeaks)-eda(edr.iValleys);
idx=find(amps >= edr.thresh.amp.min & ...
         amps <= edr.thresh.amp.max);
edr.iPeaks=edr.iPeaks(idx);
edr.iValleys=edr.iValleys(idx);
edr.type.v = edr.type.v(idx);
edr.type.p = edr.type.v;

% Threshold slope
slopes=(eda(edr.iPeaks)-eda(edr.iValleys))./((edr.iPeaks-edr.iValleys)./fs);
idx=find(slopes >= edr.thresh.slope.min & ...
         slopes <= edr.thresh.slope.max);
edr.iPeaks=edr.iPeaks(idx);
edr.iValleys=edr.iValleys(idx);
edr.type.v = edr.type.v(idx);
edr.type.p = edr.type.v;

% Threshold risetime
risetimes=(edr.iPeaks-edr.iValleys)./fs;
idx=find(risetimes >= edr.thresh.risetime.min & ...
         risetimes <= edr.thresh.risetime.max);
edr.iPeaks=edr.iPeaks(idx);
edr.iValleys=edr.iValleys(idx);
edr.type.v = edr.type.v(idx);
edr.type.p = edr.type.v;

% Plot data and show detected peaks and valleys
%--------------------------------------------------------------------------
if plotOK
    figure('Color', 'w');
    hold on
    plot((0:length(eda)-1) / fs, eda, 'k');
    plot((edr.iPeaks-1)/fs, eda(edr.iPeaks), 'r.');
    plot((edr.iValleys-1)/fs, eda(edr.iValleys), 'b.');
    xlabel('Time (s)');
    ylabel('EDA (uS)');
    
    text((edr.iPeaks-1)/fs, eda(edr.iPeaks), num2cell(1:length(edr.iPeaks))); 
end

% Goodbye message
disp([mfilename ': done.']);
    



