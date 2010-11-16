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

% Initialize variables
edl = struct('v', [], 't', []);

% Loop over time periods
for i = 1:size(t,2)
    n = round(1+t(:,i)*fs);
    edl.v(i) = mean(eda(n(1):n(2)));
    edl.t(:,i) = t(:,i);
end