% Example script for processing and analyising Electrodemal Activity (EDA)
% _________________________________________________________________________

% Last modified 23-11-2010 Mateus Joffily

% Matlab data file (.mat) must contain 'data' and 'fs' variables:
% data - m-by-n matrix of EDA data (m channels by n samples)
% fs   - EDA sampling rate (Hz)
%
% Two scripts are available for converting data from commercial systems:
% - acq2mat.m (Biopac ACQ format)           (see 'help acq2mat')
% - vhdr2mat.m (BrainAmp VHDR format)       (see 'help vhdr2mat')
%--------------------------------------------------------------------------
% Select *.mat data file (see 'help load')
[fdata, pdata] = uigetfile('*.mat', 'Select data file');
load(fullfile(pdata, fdata), 'data', 'fs');    % load data

% Force matrix to be in row format
if size(data,1)>size(data,2)
    data=data';
end

nChan = 1;                % select EDA channel
eda = data(nChan,:);      % EDA signal to be processed

% Downsample EDA. Only if EDA has been acquired with very high sampling 
% rate (e.g. like inside the MR scanner). (see 'help eda_downsample')
%--------------------------------------------------------------------------
if fs > 500 
    filt = struct('name', 'butter', 'type', 'low', 'n', 5, 'fc', 100);
    eda = eda_filt(eda, fs, filt);
    [eda fs] = eda_downsample(eda, fs, 500); 
end

% Filter EDA signal (default: low-pass filter @ 1Hz) (see 'help eda_filt')
%--------------------------------------------------------------------------
[eda filt] = eda_filt(eda, fs, 'default');

% Detect Electrodermal Responses (EDR). (see 'help eda_edr')
%--------------------------------------------------------------------------
edr = eda_edr(eda, fs);

% Review EDR/EDL/Conditions and remove artifacts (GUI). (see 'help eda_gui')
%--------------------------------------------------------------------------
uiwait(eda_gui(eda, fs, edr));

% Save results (EDR only) in TEXT file (see 'eda_save_text')
%--------------------------------------------------------------------------
eda_save_text(eda, fs, edr);

% Load conditions from file (see 'help eda_conditions')
%--------------------------------------------------------------------------
conds = eda_conditions(eda, fs, [], edr);

% Save results (EDR and EDL) grouped by conditions in TEXT file (see
% 'eda_save_text')
%--------------------------------------------------------------------------
eda_save_text(eda, fs, edr, conds);

% Save data and results in MATLAB file (see 'help save')
%--------------------------------------------------------------------------
% Matlab format (*.mat)
[pname, fname] = fileparts(fullfile(pdata, fdata));
fmat = fullfile(pname, [fname '_res.mat']);
if ~exist('conds', 'var')
    save(fmat, 'eda', 'fs', 'filt', 'edr');
else
    save(fmat, 'eda', 'fs', 'filt', 'edr', 'conds');
end
