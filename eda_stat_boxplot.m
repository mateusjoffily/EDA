function eda_stat_boxplot(eda, fs, edr, conds)
% EDA_STAT_BOXPLOT Plot EDA results
%   EDA_STAT_BOXPLOT(eda, fs, edr, conds)
%
% Required input arguments:
%   eda   - 1-by-n vector of EDA samples
%   fs    - sampling rate (Hz) 
%   edr   - structure array of electrodermal response (EDR) (see eda_edr.m)
%   conds - structure array of EDR and EDL grouped by conditions (see 
%           eda_conditions.m)
%
% _________________________________________________________________________

% Last modified 13-01-2011 Mateus Joffily

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

if nargin < 4
    error('Missing inputs');
end

EDR = struct('valleyTime', {}, 'amplitude', {}, 'magnitude', {}, 'riseTime', {}, ...
             'slope', {}, 'cond', {}, 'cond_mag', {});
EDL = struct('value', {}, 'cond', {});

% Loop over Conditions
for iC = 1:numel(conds)
    for iE = 1:numel(conds(iC).onsets)
        if ~isempty(conds(iC).iEDR{iE})
            edr_stats = eda_edr_stats(eda, fs, edr, conds(iC).iEDR{iE});
        
            EDR(1).valleyTime = [EDR.valleyTime ...
                               edr_stats.valleyTime(1)-conds(iC).onsets(iE)];
            EDR(1).amplitude  = [EDR.amplitude edr_stats.amplitude(1)];
            EDR(1).magnitude  = [EDR.magnitude edr_stats.amplitude(1)];
            EDR(1).riseTime   = [EDR.riseTime edr_stats.riseTime(1)];
            EDR(1).slope      = [EDR.slope edr_stats.slope(1)];
            EDR(1).cond = [EDR.cond; ....
                            cellstr(repmat(conds(iC).name,length(iE),1))];
            EDR(1).cond_mag = [EDR.cond_mag; ....
                               cellstr(repmat(conds(iC).name,length(iE),1))];
        else
            EDR(1).magnitude  = [EDR.magnitude 0];
            EDR(1).cond_mag = [EDR.cond_mag; ....
                               cellstr(repmat(conds(iC).name,length(iE),1))];
        end
    end
    
    EDL(1).value = [EDL.value conds(iC).edl.v];
    EDL(1).cond  = [EDL.cond; ...
               cellstr(repmat(conds(iC).name,length(conds(iC).edl.v),1))];
end

figure('Name',  'Results grouped by conditions', ...
       'Color', 'w');

% EDR Amplitude
subplot(2,3,1)
boxplot(EDR.amplitude, EDR.cond)
xlabel('Conditions');
ylabel('EDR Amplitude (microSiemens)');

% EDR Magnitude
subplot(2,3,2)
boxplot(EDR.magnitude, EDR.cond_mag)
xlabel('Conditions');
ylabel('EDR Magnitude (microSiemens)');

% EDR Onset time
subplot(2,3,3)
boxplot(EDR.valleyTime, EDR.cond)
xlabel('Conditions');
ylabel('EDR Onset Time (seconds)');

% EDR Rise time
subplot(2,3,4)
boxplot(EDR.riseTime, EDR.cond)
xlabel('Conditions');
ylabel('EDR Rise Time (seconds)');

% EDR Slope
subplot(2,3,5)
boxplot(EDR.slope, EDR.cond)
xlabel('Conditions');
ylabel('EDR Slope (microSiemens/seconds)');

% EDL
subplot(2,3,6)
boxplot(EDL.value, EDL.cond)
xlabel('Conditions');
ylabel('EDL (microSiemens)');

