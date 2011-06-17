function [sigout filtout] = filt_main(sigin, fs, filtin, plot_ok)
% FILT_MAIN Main filtering procedure
%   [sigout filtout] = FILT_MAIN(sigin, fs, filtin, plot_ok)
%
% Required input arguments:
%    sigin - 1-by-n vector of raw data
%    fs - samplig frequency (Hz)
%    filtin - structure array of user defined filter parameters:
%      filtin.name    - filter name: 'none', 'butter', 'notch'
%      filtin.type    - 'butter' filter's type: 
%                            'bandpass, 'low', 'high' or 'stop'
%      filtin.b       - notch filter cut-off rate (0<b<1)
%      filtin.n       - filter order
%      filtin.fc      - filter cutoff frequence
%    plot_ok - display signal plots: true or false
%
% Output arguments:
%    sigout - 1-by-n vector of filtered data
%    filtout - structure array of used filter parameters:
%      filtout.name    - filter name: 'none', 'butter' or 'notch'
%      filtout.type    - 'butter' filter's type: 
%                            'bandpass, 'low', 'high' or 'stop'
%      filtout.b       - 'notch' filter's cut-off rate (0<b<1)
%      filtout.n       - filter order
%      filtout.fc      - filter cutoff frequence
%      filtout.coef_num   - filter coefficients numerator 
%      filtout.coef_den   - filter coefficients denominator 
%
% _________________________________________________________________________

% Last modified 23-11-2010 Mateus Joffily

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

% Display frequence response and filtered signal
if nargin < 4, plot_ok = false; end

% Initialize filtout struct
filtout = struct('name',     {}, ...
                 'type',     {}, ...
                 'b',        {}, ...
                 'n',        {}, ...
                 'fc',       {}, ...
                 'coef_num', {}, ...
                 'coef_den', {});

% Force sigin to double, try to avoid 'Matrix is close to singular or 
% badly scaled' errors.
if ~isa(sigin, 'double')
    sigin = double(sigin);
end

% Initialize sigout
sigout = sigin;

% Loop over filters
for i=1:length(filtin)

    switch char(filtin(i).name)
        case 'butter'
            wn = filtin(i).fc/(fs/2);   % normalized cutoff frequency
            
            % Butterworth filter coefficients
            [B,A] = butter(filtin(i).n, wn, filtin(i).type);
            
            % Adjust filter order, if zeros are too small. It avoids errors
            % like 'Matrix is close to singular or badly scaled.'
            n = filtin(i).n;
            while all(B < 1e-12)
                n = n - 1;
                if n == 0
                    break
                end
                [B,A] = butter(n, wn, filtin(i).type);
            end
            
            if n == 0
                error('Bad Butterworth design.')
            elseif filtin(i).n ~= n
                filtin(i).n = n;
                disp(sprintf('Warning: Butterworth filter order adjusted to n=%d', ...
                    filtin(i).n));
            end
 
%             % Prevent numerical problems due to roundoff errors that may  
%             % occur when forming the transfer function using the [b,a] syntax
%             [Z, P, K] = butter(filtin(i).n, wn, filtin(i).type);
%             [B,A] = zp2tf(Z,P,K);
            
            % Fill-in filtout struct
            filtout(i) = struct( ...
                'name',     filtin(i).name, ...
                'type',     filtin(i).type, ...
                'b',        NaN, ...
                'n',        filtin(i).n, ...
                'fc',       filtin(i).fc, ...
                'coef_num', B, ...
                'coef_den', A);
            
        case 'notch'
            wn = filtin(i).fc/(fs/2);   % normalized cutoff frequency
            
            % Notch filter coefficients
            % remove fc frequency and its harmonics
            % Challis and Kitney (1982) J. Biomed. Eng.
            Wn = wn:wn:1;
            b = filtin(i).b;
            Z = [exp(j*pi*Wn) exp(-j*pi*Wn)]';
            P = b * Z;
            % force unit gain at 0hz
            ko = prod(abs(1 - Z)) / prod(abs(1 - P));
            % filter transfer function
            [B,A] = zp2tf(Z,P,1/ko);
            
            % Fill-in filtout struct
            filtout(i) = struct( ...
                'name',     filtin(i).name, ...
                'type',     '', ...
                'b',        filtin(i).b, ...
                'n',        max(length(B)-1,length(A)-1), ...
                'fc',       filtin(i).fc, ...
                'coef_num', B, ...
                'coef_den', A);
            
        otherwise
            filtout(i).name = 'none';
            continue
    end
    
    if length(sigout) > 3*filtout(i).n
        % Only filters the signal if its length is greater than three 
        % times the filter order
        
        % Zero-phase filter
        sigout = filtfilt(B,A,sigout);

        if plot_ok
            % Plot filter frequence response
            figure('Color', 'w', 'Name', sprintf('Filter %d', i));
            freqz(B,A,fs*4,fs);
            title(sprintf('%s %s (n=%d; Fc=%0.4f)', ...
                filtout(i).name, filtout(i).type, ...
                filtout(i).n, mean(filtout(i).fc)));
            linkaxes;
        end
    else
        sigout = [];
    end

end