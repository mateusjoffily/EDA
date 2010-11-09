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

% Last modified 09-11-2010 Mateus Joffily

eda = eda(1:M:end);
fs  = fs / M;

% Goodbye message
disp([mfilename ': done.']);