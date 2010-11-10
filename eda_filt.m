function [edaout filtout] = eda_filt(edain, fs, filtin, plotOK)
% EDA_FILT Electrodermal Activity (EDA) filters
%   [edaout filtout] = EDA_FILT(edain, fs, filtin, plotOK)
%
% Required input arguments:
%    edain - 1-by-n vector of EDA samples
%    fs    - samplig frequency (Hz)
%
% Optional input arguments:
%    filtin - (1) 'default' - use defalut SC filter params
%             (2) structure array containing pre-defined filter parameters 
%                 (see filt_main.m)
%    plotOK - display results (boolean)
%
% Output arguments:
%    edaout  - 1-by-n vector of EDA samples filtered
%    filtout - structure array containing EDA specific filter parameters
%              (see filt_main.m)
% _________________________________________________________________________

% Last modified 10-11-2010 Mateus Joffily

% Display frequence response and filtered signal
if nargin < 4, plotOK = false; end

if nargin >= 3 && isempty(filtin)
    filtin(1).name = 'none';
    
elseif nargin < 3 || ischar(filtin) && strcmp(filtin, 'default')
    clear filtin;
    % Default filter parameters for EDA: Butterworth low-pass 
    % filter with cut-off frequency at 0.5Hz
    filtin(1).name = 'butter';  % Butterworth filter 
    filtin(1).type = 'low';     % low-pass filter 
    filtin(1).n = 5;            % filter order
    filtin(1).fc = 1;         % cutoff frequency (Hz)
end

% Filter EDA
[edaout filtout] = filt_main(edain, fs, filtin, plotOK);

% Noise
noise = edain - edaout;

% Plot filtered signal
if plotOK
    t=(0:length(edain)-1)/fs;
    
    % Plot EDA raw power spectrum
    figure('Color', 'w');
    [PSin,fin] = pwelch(edain-mean(edain),[],[],[],fs);
    plot(fin,PSin);
    xlabel('Frequency (Hz)');
    ylabel('Power Spectrum');
    set(gca, 'XLim', [0 0.25]);
    title('EDA Raw');
   
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

% Goodbye message
disp([mfilename ': done.']);