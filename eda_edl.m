function edl = eda_edl(eda, fs, t)
% EDA_EDL Measure Electrodermal Level (EDL).
%   edl = EDA_EDL(eda, fs, t)
%
% Input arguments:
%   eda - 1-by-n vector of EDA samples
%   fs  - sampling rate (Hz) 
%   t   - 2-by-k matrix of k time intervals 
%
% Output arguments:
%   edl.v - 1-by-k vector of measured EDL during each time interval
%   edl.t - 2-by-k matrix of k time intervals (same as input)
% 
% References:
%   Boucsein (1992) Electrodermal Activity, Plenum Press (Ed.), New York.
% _________________________________________________________________________

% Last modified 09-11-2010 Mateus Joffily

% Initialize variables
edl = struct('v', [], 't', []);

% Loop over time periods
for i = 1:size(t,2)
    n = round(1+t(:,i)*fs);
    edl.v(i) = mean(eda(n(1):n(2)));
    edl.t(:,i) = t(:,i);
end