function eda_save_text(ftxt, eda, fs, edr, conds)
% EDA_SAVE_TEXT Save EDA results in text file format
%   EDA_SAVE_TEXT(ftxt, eda, fs, edr, conds)
%
% Input arguments:
%   eda   - 1-by-n vector of EDA samples
%   fs    - sampling rate (Hz) 
%   edr   - structure array of electrodermal response (EDR) (see eda_edr.m)
%   conds - structure array of EDR and EDL grouped by conditions (see 
%           eda_conditions.m)
% _________________________________________________________________________

% Last modified 09-11-2010 Mateus Joffily

if nargin == 4
    % Save EDR raw results
    save_raw(ftxt, eda, fs, edr);

elseif nargin == 5
    % Save EDR grouped by conditions
    save_grouped(ftxt, eda, fs, edr, conds);
    
else
    error('Unknown inputs');
end

% Goodbye message
disp([mfilename ': done.']);

function save_raw(ftxt, eda, fs, edr)
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


function save_grouped(ftxt, eda, fs, edr, conds)

% Open file
fid = fopen(ftxt, 'w');

% Write header
fprintf(fid, 'Condition\tOnset\tDuration\tIndexEDR\t');
fprintf(fid, 'NumberEDR\tMinEDR\tMaxEDR\tMeanEDR\tEDL\n');

% Loop over Conditions
for iC = 1:numel(conds)
    for iE = 1:numel(conds(iC).onsets)
        
        fprintf(fid, '%s\t%0.2f\t%0.2f\t', conds(iC).name, ...
            conds(iC).onsets(iE), conds(iC).durations(iE));
       
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