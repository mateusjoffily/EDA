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

% Last modified 09-11-2010 Mateus Joffily

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
    end
else
    ip = [];
    iv = [];
end


