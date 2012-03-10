function [iv, ip] = peak_detect(data, fs)
% PEAK_DETECT Automatic peak-valley detection in data.
%
% Format:
%   [iv, ip] = PEAK_DETECT(data, fs)
%   
% Required Input arguments:
%   data - 1-by-n vector of EDA data 
%   fs   - sampling rate (Hz) 
%
% Output arguments:
%   iv   - valleys index into eda input vector 
%   ip   - peaks index into data input vector 
%
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

deriv1 = diff(data) / (1/fs);       % data first time-derivative
sign_deriv1 = sign(deriv1); 
sign_deriv1(sign_deriv1 == 0) = 1;
d1sign_deriv1 = diff(sign_deriv1);  

iv = find(d1sign_deriv1>0) + 1;       % valleys index into data vector
ip = find(d1sign_deriv1<0) + 1;       % peaks index into data vector

% Match peaks and valleys
[iv ip] = vpmatch(iv, ip);


%==========================================================================
function [iv ip] = vpmatch(iv, ip)
% Match peaks and valleys

if ~isempty(ip) && ~isempty(iv)
    %Select only the peaks that occur after the first valley
    idx = find(ip > iv(1));
    if ~isempty(idx)
        ip = ip(idx);
        
        %Select only the valleys that occur before a peak
        idx = find(iv<ip(end));
        if ~isempty(idx)
            iv = iv(idx);
        else
            iv = [];
        end
    else
        ip = [];
        iv = [];
    end
else
    ip = [];
    iv = [];
end


