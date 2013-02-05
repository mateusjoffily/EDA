function eda_save_text(eda, fs, edr, conds, ftxt)
% EDA_SAVE_TEXT Save EDA results in text file format
%   EDA_SAVE_TEXT(eda, fs, edr, conds, ftxt)
%
% Required input arguments:
%   eda   - 1-by-n vector of EDA samples
%   fs    - sampling rate (Hz) 
%   edr   - structure array of electrodermal response (EDR) (see eda_edr.m)
%
% Optional input arguments:
%   conds - structure array of EDR and EDL grouped by conditions (see 
%           eda_conditions.m)
%   ftxt  - output text file name
% _________________________________________________________________________

% Last modified 22-11-2010 Mateus Joffily

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

if nargin < 3
    error('Missing inputs');
end

if nargin < 4
    conds = [];
end
    
if nargin < 5
    [ftxt, ptxt] = uiputfile({'*.txt', 'Text File (*.txt)'; ...
        '*.*', 'All Files (*.*)'}, 'Save results as...');

    if isequal(ftxt,0)
        return
    end
    
    ftxt = fullfile(ptxt, ftxt);
end

if isempty(conds)
    % Save EDR raw results
    save_raw(eda, fs, edr, ftxt);

    % Goodbye message
    disp([mfilename ': EDR raw results, done.']);
    
else
    % Save EDR grouped by conditions
    save_grouped(eda, fs, edr, conds, ftxt);
    
    % Goodbye message
    disp([mfilename ': EDR/EDL grouped by conditions, done.']);
    
end


function save_raw(eda, fs, edr, ftxt)
%--------------------------------------------------------------------------

% Get EDR statistics
nEDR = numel(edr.iPeaks);
edr_stats = eda_edr_stats(eda, fs, edr, 1:nEDR);

% Open file
fid = fopen(ftxt, 'w');

% Write statistics to file
fprintf(fid, 'ValleyTime\tPeakTime\tAmplitude\tRiseTime\tSlope\tEDRtype\n');
fprintf(fid, '%0.03f\t%0.03f\t%0.03f\t%0.03f\t%0.03f\t%d\n', ...
    [edr_stats.valleyTime; edr_stats.peakTime; edr_stats.amplitude; ...
    edr_stats.riseTime; edr_stats.slope; edr_stats.type]);

% Close file
fclose(fid);


function save_grouped(eda, fs, edr, conds, ftxt)

% Open file
fid = fopen(ftxt, 'w');

% Write header
fprintf(fid, 'Condition\tOnset\tDuration\tLatencyWindow\tIndexEDR\t');
fprintf(fid, 'NumberEDR\tMinEDR\tMaxEDR\tMeanEDR\tEDL\n');

% Loop over Conditions
for iC = 1:numel(conds)
    for iE = 1:numel(conds(iC).onsets)
        
        fprintf(fid, '%s\t%0.2f\t%0.2f\t', conds(iC).name, ...
            conds(iC).onsets(iE), conds(iC).durations(iE));
       
        fprintf(fid, '%0.2f;%0.2f\t', conds(iC).latency_wdw(:,iE));
       
        if isempty(conds(iC).iEDR{iE})
            IndexEDR = ';';
            NumEDR   = 0;
            MinEDR   = NaN;
            MaxEDR   = NaN;
            MeanEDR  = NaN;
            
        else
            edr_stats = eda_edr_stats(eda, fs, edr, conds(iC).iEDR{iE});
        
            IndexEDR = sprintf('%d;', conds(iC).iEDR{iE});
            NumEDR   = length(conds(iC).iEDR{iE});
            MinEDR   = edr_stats.amplitudeMin;
            MaxEDR   = edr_stats.amplitudeMax;
            MeanEDR  = edr_stats.amplitudeMean;
            
        end
        
        EDL = conds(iC).edl.v(iE);
        
        % Write to file
        fprintf(fid, '%s\t',    IndexEDR);
        fprintf(fid, '%d\t',    NumEDR);
        fprintf(fid, '%0.4f\t', MinEDR);
        fprintf(fid, '%0.4f\t', MaxEDR);
        fprintf(fid, '%0.4f\t', MeanEDR);
        fprintf(fid, '%0.4f\n', EDL);
    end
end

% Close file
fclose(fid);