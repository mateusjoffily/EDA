function edr_stats = eda_edr_stats(eda, fs, edr, iEDR)
% EDA_EDR_STATS Electrodermal response (EDR) statistics
%   edl = EDA_EDR_STATS(eda, fs, edr, iEDR)
%
% Input arguments:
%   eda  - 1-by-n vector of EDA samples
%   fs   - sampling rate (Hz) 
%   edr  - structure array of electrodermal response (EDR) (see eda_edr.m)
%   iEDR - 1-by-n vector of EDR indexes in edr structure array
%
% Output arguments:
%   edr_stats - structure array with fields:
%       valleyTime    - 1-by-n vector of EDR valley time
%       peakTime      - 1-by-n vector of EDR peak time
%       amplitude     - 1-by-n vector of EDR amplitude
%       riseTime      - 1-by-n vector of EDR rise time
%       slope         - 1-by-n vector of EDR slope
%       type          - 1-by-n vector of EDR type (see eda_edr.m)
%       amplitudeMin  - min EDR amplitude (see eda_edr.m)
%       amplitudeMax  - max EDR amplitude (see eda_edr.m)
%       amplitudeMean - mean EDR amplitude (see eda_edr.m)
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

% Initialize edr_stats structure array
edr_stats = struct('valleyTime', {}, 'peakTime', {}, 'amplitude', {}, ...
                   'riseTime', {}, 'slope', {}, 'type', {}, ...
                   'amplitudeMin', {}, 'amplitudeMax', {}, ...
                   'amplitudeMean', {});

% Number of EDRs
nEDR = length(iEDR);

% Single EDR statistic
for iE = 1:nEDR
    edr_stats(1).valleyTime(iE) = edr.iValleys(iEDR(iE)) / fs;
    edr_stats(1).peakTime(iE) = edr.iPeaks(iEDR(iE)) / fs;
    
    edr_stats(1).amplitude(iE) = eda(edr.iPeaks(iEDR(iE))) - ...
                        eda(edr.iValleys(iEDR(iE)));
    edr_stats(1).riseTime(iE) = ( edr.iPeaks(iEDR(iE)) - ...
                               edr.iValleys(iEDR(iE)) ) / fs;
    edr_stats(1).slope(iE) = edr_stats.amplitude(iE) / edr_stats.riseTime(iE);
    
    edr_stats(1).type(iE) = max([edr.type.v(iE) edr.type.p(iE)]);
end

% Grouped EDR statistic
if nEDR > 0
    edr_stats(1).amplitudeMax  = nanmax(edr_stats.amplitude);
    edr_stats(1).amplitudeMin  = nanmin(edr_stats.amplitude);
    edr_stats(1).amplitudeMean = nanmean(edr_stats.amplitude);
end

