function [eda fs] = eda_downsample(eda, fs, M)
% EDA_DOWNSAMPLE EDA downsample
%   [edaout fsout] = EDA_DOWNSAMPLE(edain, fsin, M)
%
% Required input arguments:
%    eda  - 1-by-n vector of EDA samples
%    fs   - orginal samplig frequency (Hz)
%    M    - downsampling factor
%
% Output arguments:
%    eda  - downsampled EDA data
%    fs   - new sampling rate (Hz)
%
% Description: 
%    Use only if EDA has been acquired with very high sampling rate 
%    (e.g. inside the MR scanner). Make sure that the Shannon-Nyquist 
%    sampling theorem criterion is maintained. Use only after low-pass 
%    filtering EDA (see eda_filt.m).
% _________________________________________________________________________

% Last modified 14-11-2010 Mateus Joffily

if nargin < 3 || isempty(M)
    prompt   = {'Enter new sampling rate (Hz)'};
    def      = {sprintf('%.02f', fs)};
    dlgTitle = 'Downsample EDA';
    lineNo   = 1;
    answer   = inputdlg(prompt,dlgTitle,lineNo,def);

    if ~isempty(answer) && ~isempty(answer{1})
        % Calculate downsampling factor
        M = ceil( fs / str2double(answer{1}) );
        
    else
        % Goodbye message
        disp([mfilename ': done.']);
        
        return
    end    
end

if M > 1
    eda = eda(:, 1:M:end);
    fs  = fs / M;
end

% Goodbye message
disp([mfilename ': done.']);