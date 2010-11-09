function edr = eda_edr(varargin)
% EDA_EDR Automatic Electrodermal Response (EDR) detection.
%
% Formats:
%   (1) edr = EDA_EDR(eda, fs)
%   (2) edr = EDA_EDR(eda, fs, opendlg, thrin)
%   (3) edr = EDA_EDR(eda, fs, opendlg, thrin, plotOK)
%
% Required Input arguments:
%   eda - 1-by-n vector of EDA samples
%   fs  - EDA sampling rate (Hz) 
%
% Optional Input arguments:
%   opendlg - open dialog box (boolean)
%   thrin   - structure array with fields:
%       amp      - user defined amplitude threshold (microSiemens) 
%                  'amp' is a struct with fields 'min' and 'max'
%       slope    - user defined slope threshold range (microSiemens/s)
%                  'slope' is a struct with fields 'min' and 'max'
%       risetime - user defined rise time threshold (s)
%                  'risetime' is a struct with fields 'min' and 'max'
%       overlap  - detect overlapping EDRs (boolean)                  
%   plotOK - plot results (boolean)
%
% Output arguments:
%   edr - structure array with fields:
%       edr.iPeaks     - EDR peaks index in EDA vector 
%       edr.iValleys   - EDR valleys index in EDA vector 
%       edr.type - EDR type, according to Bucsein (1992, p.136) terminology:
%             (1) - single response (ideal), it never occurs
%             (2) - response overlaps preceding response during recovery time
%             (3) - response overlaps preceding response during rise time
%             (4) - response manually detected by the user (set only by eda_gui.m)
%       edr.thresh  - EDR detection thresholds used:
%           amp      - [uSiemens] amplitude threshold
%                    'amp' is a struct that contains fields 'min' and 'max'
%           slope    - [uSiemens/s] slope threshold range
%                   'slope' is a struct that contains fields 'min' and 'max'
%           risetime - [s] rise time threshold
%                      'risetime' is a struct that contains fields 'min' and 'max'
%           overlap  - detect overlapping EDRs (boolean)
% 
% References:
%   Dawson, Schell and Filion (2000) The Electrodermal System. 
%     In Cacioppo, Tassinary and Berntson (Eds.), Handbook of
%     Psychophysiology, p.200-223.
%   Boucsein (1992) Electrodermal Activity, Plenum Press (Ed.), New York.
% _________________________________________________________________________

% Last modified 09-11-2010 Mateus Joffily

% Threshold default values
thresh_def.amp.min = 0.02;      % EDR amplitude minimum value
thresh_def.amp.max = Inf;       % EDR amplitude maximum value
thresh_def.slope.min = 0.0;     % EDR slope minimum value
thresh_def.slope.max = Inf;     % EDR slope maximum value
thresh_def.risetime.min = 0;    % EDR risetime minimum value
thresh_def.risetime.max = Inf;  % EDR risetime maximum value
thresh_def.overlap = 1;         % Detect EDRs overlapping

% Initialize edr
edr = struct('iPeaks', [], 'iValleys', [], ...
             'type', struct('v', [], 'p', []), 'thresh', thresh_def);

% Check input arguments
if nargin == 2
    eda = varargin{1};
    fs = varargin{2};
    opendlg = false;
    plotOK = false;
    
elseif nargin > 2
    eda = varargin{1};
    fs = varargin{2};
    
    if ~isempty(varargin{3})
        opendlg = varargin{3};
    else
        opendlg = false;
    end
    
    if ~isempty(varargin{4})
        edr.thresh = varargin{4};
    end
    
    if nargin == 5
        plotOK = varargin{5};
    end
    
else
    edr = [];
    return
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
     def={sprintf('%.04f', edr.thresh.amp.min), ...
          sprintf('%.04f', edr.thresh.amp.max), ...
          sprintf('%.04f', edr.thresh.slope.min), ...
          sprintf('%.04f', edr.thresh.slope.max), ...
          sprintf('%.04f', edr.thresh.risetime.min), ...
          sprintf('%.04f', edr.thresh.risetime.max), ...
          sprintf('%d', edr.thresh.overlap)};
    dlgTitle='Set EDR thresholds';
    lineNo=1;
    answer=inputdlg(prompt,dlgTitle,lineNo,def);

    if ~isempty(answer) && ~( isempty(answer{1}) || ...
            isempty(answer{2}) || isempty(answer{3}) || ...
            isempty(answer{4}) || isempty(answer{5}) || ...
            isempty(answer{6}) || isempty(answer{7}))
        % user defined threshold values
        edr.thresh.amp.min = str2double(answer{1});
        edr.thresh.amp.max = str2double(answer{2});
        edr.thresh.slope.min = str2double(answer{3});
        edr.thresh.slope.max = str2double(answer{4});
        edr.thresh.risetime.min = str2double(answer{5});
        edr.thresh.risetime.max = str2double(answer{6});
        edr.thresh.overlap = str2double(answer{7});
        
        if ~ ( (edr.thresh.amp.min < edr.thresh.amp.max) && ...
                (edr.thresh.slope.min < edr.thresh.slope.max) && ...
                (edr.thresh.risetime.min < edr.thresh.risetime.max) )
            warndlg('Min must be lower than Max', dlgTitle);
            edr.thresh = [];
            return
        end

        if edr.thresh.overlap ~= 0 && edr.thresh.overlap ~= 1
            warndlg('"Split overlapped responses" must be 0 or 1', dlgTitle);
            edr.thresh = [];
            return
        end
    else
        edr.thresh = [];
        return
    end
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
% If accelaratory deflection is found between a reponse's 
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
        type3iap{i} = iap + 1;   % save acceleration points
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
        edr.iPeaks = [edr.iPeaks(1:i-1) edr.iValleys(i)+type3iap{t} edr.iPeaks(i:end)];
        edr.iValleys = [edr.iValleys(1:i)   edr.iValleys(i)+type3iap{t}+1 edr.iValleys(i+1:end)];
        edr.type.v = [edr.type.v(1:i) repmat(3,1,length(type3iap{t})) edr.type.v(i+1:end)];
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
    



