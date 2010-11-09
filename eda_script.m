% Example script for processing and analyising Electrodemal Activity (EDA)
% _________________________________________________________________________

% Last modified 09-11-2010 Mateus Joffily

% Matlab data file (.mat) must contain 'data' and 'fs' variables:
% data - m-by-n matrix of EDA data (m channels by n samples)
% fs   - EDA sampling rate (Hz)
%
% Two scripts are available for converting data from commercial systems:
% - acq2mat.m (Biopac ACQ format)
% - vhdr2mat.m (BrainAmp VHDR format) 
%--------------------------------------------------------------------------
% Select *.mat data file
[fdata, pdata] = uigetfile('*.mat', 'Select data file');
load(fullfile(pdata, fdata), 'data', 'fs');    % load data
eda = data(1,:);      % select data

% Filter EDA signal (default: low-pass filter @ 0.5Hz) (help eda_filt)
%--------------------------------------------------------------------------
[eda filt] = eda_filt(eda, fs, 'default');

% Downsample EDA. Only if EDA has been acquired with very high sampling 
% rate (e.g. like inside the MR scanner). (help eda_downsample)
%--------------------------------------------------------------------------
if fs > 1000, [eda fs] = eda_downsample(eda, fs, ceil(fs/30)); end;

% Detect Electrodermal Responses (EDR). (help eda_edr)
%--------------------------------------------------------------------------
edr = eda_edr(eda, fs);

% Review EDR/EDL/Conditions and remove artifacts (GUI). (help eda_gui)
%--------------------------------------------------------------------------
uiwait(eda_gui(eda, fs, edr));

% Save results
%--------------------------------------------------------------------------
[pname, fname] = fileparts(fullfile(pdata, fdata));

% Matlab format (*.mat)
fmat = fullfile(pname, [fname '_res.mat']);
save(fmat, 'eda', 'fs', 'filt', 'edr');

% Text format (*.txt)
ftxt = fullfile(pname, [fname '_res.txt']);
eda_save_text(ftxt, eda, fs, edr);

% Results averaged by conditions. (help eda_conditions)
%--------------------------------------------------------------------------
% Select *.mat conditions file
[fcond, pcond] = uigetfile('*.mat', 'Select conditions file');
conds = eda_conditions(eda, fs, fullfile(pcond, fcond), edr);

% Save results averaged by conditions
%--------------------------------------------------------------------------
[pname, fname] = fileparts(fullfile(pdata, fdata));

% Matlab format (*.mat)
fmat = fullfile(pname, [fname '_res.mat']);
save(fmat, 'conds', '-APPEND');

% Text format (*.txt)
ftxt = fullfile(pname, [fname '_res_cond.txt']);
eda_save_text(ftxt, eda, fs, edr, conds);
