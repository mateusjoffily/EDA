function varargout = eda_gui(varargin)
% EDA_GUI EDA Graphical User Interface (GUI)
%
% Formats:
%   (1) EDA_GUI(eda, fs, edr)
%
% Required Input arguments:
%   eda - 1-by-n vector of EDA samples
%   fs  - EDA sampling rate (Hz) 
%   edr - electrodermal response (EDR) structure array (see eda_edr.m)
% 
% Description:
%    Allows for detected EDRs to be manually edited by the user. Each EDR 
%    is defined by a pair of valley (blue dot) and peak (red dot) in the 
%    plot. The EDR amplitude is measured as peak-valley. Left-click with  
%    the mouse over the EDA plot to add/remove EDRs. Right-click over  
%    detected EDRs for a summary of EDR parameters. Use the File > 
%    Export variables menu in the top of the window to export changes to 
%    MATLAB environment, before exiting. Conditions file (see
%    eda_conditions.m) can also be loaded for inspection in the GUI and EDL
%    measurement. Use the menu "File > Import from File > Conditions" to load
%    conditions *.mat file. Conditions (shaded area) displayed in the GUI may 
%    correspond the EDR onset latency criterion used by eda.conditions.m to 
%    relate EDR to specific events or the duration of the event itself. 
%    Use Data > Coditions > Shade menu to select between these two display 
%    modes.
% _________________________________________________________________________

% Last modified 18-11-2010 Mateus Joffily

% EDA_GUI M-file for eda_gui.fig
%      EDA_GUI, by itself, creates a new EDA_GUI or raises the existing
%      singleton*.
%
%      H = EDA_GUI returns the handle to a new EDA_GUI or the handle to
%      the existing singleton*.
%
%      EDA_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EDA_GUI.M with the given input arguments.
%
%      EDA_GUI('Property','Value',...) creates a new EDA_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before eda_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to eda_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Last Modified by GUIDE v2.5 15-Nov-2010 10:47:02

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

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @eda_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @eda_gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end

% --- Executes just before eda_gui is made visible.
function eda_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to eda_gui (see VARARGIN)

% Choose default command line output for eda_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Initialize variables 
if length(varargin) < 2
    eda = [];
    fs  = NaN;
    
else
    eda = varargin{1};
    fs  = varargin{2};
end

if length(varargin) > 2
    edr = varargin{3};

else
    edr = eda_edr;

end

% Initialize data structure
data.handles  = handles;
data.new      = struct('eda', eda, 'fs', fs, 'filt', [], 'edr', edr);
data.old      = data.new ;
data.conds    = eda_conditions;
data.nCond    = 1;

if length(varargin) >= 2
    % Toggle EDA and EDR data menu state
    set(data.handles.menu_file_export_workspace_eda, 'Enable', 'on');
    set(data.handles.menu_file_export_workspace_edr, 'Enable', 'on');
    set(data.handles.menu_file_export_file_data, 'Enable', 'on');
    set(data.handles.menu_file_export_file_results_edr, 'Enable', 'on');
    set(data.handles.menu_file_import_file_conds, 'Enable', 'on');
    set(data.handles.menu_data_eda,   'Enable', 'on');
    set(data.handles.menu_data_edr,   'Enable', 'on');
    set(data.handles.menu_view_edr,   'Enable', 'on');
end

% Set EDA axes
%--------------------------------------------------------------------------
hold(data.handles.axes_eda, 'on');

% Axes Y limits
v3 = min(data.new.eda) - 0.1 * ( max(data.new.eda) - min(data.new.eda) );
v4 = max(data.new.eda) + 0.1 * ( max(data.new.eda) - min(data.new.eda) );

% Plot Conditions
%----------------------------------------------------------------------
h = area(NaN, NaN, ...
     'Tag', 'plot_conds', ...
     'FaceColor', [0.8 1 0.8], ...
     'EdgeColor', [0.8 1 0.8], ...
     'Visible', 'off');
data.handles.plot_conds = h;

% Create context menu
data.handles.menu_context_conds = uicontextmenu;

% Attach context menu to conditions plot
set(data.handles.plot_conds, 'uicontextmenu', data.handles.menu_context_conds);

% Plot EDL
%----------------------------------------------------------------------
max_edl = 200;  % Allow for up to max_edl EDLs to be displayed
h = line(repmat(NaN,2,max_edl), repmat(NaN,2,max_edl), ...
    'Tag', 'plot_edl', ...
    'LineStyle', '-', ...
    'Color', 'r', ...
    'Visible', 'off');
data.handles.plot_edl = h;   

% Plot EDA
%--------------------------------------------------------------------------
h = line('Tag','plot_eda', ...
    'LineStyle', '-', ...
    'Color', 'k', ...
    'EraseMode', 'normal', ...
    'YData', data.new.eda, ...
    'XData', (0:length(data.new.eda)-1) / data.new.fs, ...
    'ButtonDownFcn', 'eda_gui(''mouseclick'')');
data.handles.plot_eda = h;

% Plot EDR peaks
%----------------------------------------------------------------------
h = line('Tag', 'plot_peak', ...
    'LineStyle', 'none', ...
    'Marker', '.', ...
    'Color', 'r', ...
    'EraseMode', 'normal', ...
    'YData', data.new.eda(data.new.edr.iPeaks), ...
    'XData', (data.new.edr.iPeaks-1) / data.new.fs, ...
    'ButtonDownFcn', 'eda_gui(''mouseclick'')');
data.handles.plot_peak = h;

% Plot EDR valleys
%----------------------------------------------------------------------
h = line('Tag','plot_valley', ...
    'LineStyle', 'none', ...
    'Marker', '.', ...
    'Color', 'b', ...
    'EraseMode', 'normal', ...
    'YData', data.new.eda(data.new.edr.iValleys), ...
    'XData', (data.new.edr.iValleys-1) / data.new.fs, ...
    'ButtonDownFcn', 'eda_gui(''mouseclick'')');
data.handles.plot_valley = h;

% Fix axes
%----------------------------------------------------------------------
axis tight; 
v=axis; 
if ~isempty(data.new.eda)
    axis([v(1) v(2) v3 v4]);
end

xlabel('Time (seconds)');
ylabel('EDA (microSiemens)');

% Store Data structure
guidata(hObject, data); 

% UIWAIT makes eda_gui wait for user response (see UIRESUME)
% uiwait(handles.fig_eda);
end

% --- Outputs from this function are returned to the command line.
function varargout = eda_gui_OutputFcn(hObject, eventdata, data) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% data    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = data.handles.output;
end

% --- Executes during object creation, after setting all properties.
function axes_eda_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes_eda (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes_eda

end

% --- Executes during object deletion, before destroying properties.
function axes_eda_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to axes_eda (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end

% --- Executes on mouse press over axes background.
function axes_eda_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes_eda (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end

% --------------------------------------------------------------------
function menu_file_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end

%----------------------------------------------------------------------
function conds_plot_update(nCond)
% Perform action when mouse click over figure's object

% Get data
data = guidata(gcbf);

% If conditions is empty, just clear the plots and return
if isempty(data.conds)
    set(data.handles.plot_conds, 'XData', NaN, 'YData', NaN);
    for iP = 1:length(data.handles.plot_edl)
        set(data.handles.plot_edl(iP), 'XData', [NaN NaN]', ...
                                       'YData', [NaN NaN]');
    end
    return
end

if nargin == 0
    % Use last condition index
    nCond = data.nCond;
    
else
    % Save current condition index
    data.nCond = nCond;
    
    % Update data structure
    guidata(gcbf, data);
    
end

% Update Conditions plot
durationON = get(data.handles.menu_data_conds_shade_duration, 'Checked');
if strcmp(durationON, 'on')
    latency_wdw = repmat(data.conds(nCond).onsets, 2, 1) + ...
          [zeros(size(data.conds(nCond).durations)); data.conds(nCond).durations];
else
    latency_wdw = data.conds(nCond).latency_wdw;
end
x = sort([latency_wdw(:); latency_wdw(:)])';
y = repmat([0 100 100 0], 1, length(x)/4);
set(data.handles.plot_conds, 'XData', x, 'YData', y);

% Update EDL plot
nE = size(data.conds(nCond).edl.t,2);
for iP = 1:length(data.handles.plot_edl)
    if iP <= nE
        set(data.handles.plot_edl(iP), 'XData', data.conds(nCond).edl.t(:,iP), ...
                         'YData', repmat(data.conds(nCond).edl.v(iP),2,1));
    else
        set(data.handles.plot_edl(iP), 'XData', [NaN NaN]', 'YData', [NaN NaN]');
        
    end
end

end

%----------------------------------------------------------------------
function mouseclick
% Perform action when mouse click over figure's object

% Returns previously stored data
data = guidata(gcbf);

% Get mouse click coordinates
pt = get(data.handles.axes_eda, 'CurrentPoint');

% Get mouse selection type
seltype = get(data.handles.fig_eda, 'SelectionType');

% Get calling object tag
gcotag = get(gco, 'Tag');

if strcmp(gcotag, 'plot_eda')
    % Click was over eda plot
    %------------------------------------------------------------------
    if strcmp(seltype, 'normal')
        % It was a left mouse button click

        % Add EDR at mouse location
        eda_gui('eda_add_peak_valley', pt(1,1));
        
        % Update plot
        eda_gui('edr_plot_update');
        
    end

elseif strcmp(gcotag, 'plot_peak') || ...
       strcmp(gcotag, 'plot_valley')
    % Click was over a valley or a peak point
    %------------------------------------------------------------------

    if strcmp(seltype, 'normal')
        % It was a left mouse button click
        %--------------------------------------------------------------

        % Remove valley or peak from mouse location
        eda_gui('eda_remove_peak_valley', pt(1,1));
        
        % Update plot
        eda_gui('edr_plot_update');
        
    elseif strcmp(seltype, 'alt')
        % It was a right mouse button click
        %--------------------------------------------------------------

        eda_gui('edr_info', pt(1,1));
    end
    
end

end

%--------------------------------------------------------------------------
function eda_add_peak_valley(pt)
% Add new valley or peak index

% Get data
data = guidata(gcbf);

% Get x coordinate
x = round( pt * data.new.fs ) + 1;

% Ask if it is a EDR valley or peak
resp=menu('Selection type:', {'Peak' 'Valley' 'Cancel'});

% Update EDA peak/valley vector
if resp == 1
    [data.new.edr.iPeaks, i, j] = unique([data.new.edr.iPeaks x]);
    % Set EDR type to manual
    type = [data.new.edr.type.p 4];
    data.new.edr.type.p = type(i);
    
elseif resp == 2
    [data.new.edr.iValleys, i, j] = unique([data.new.edr.iValleys x]);
    % Set EDR type to manual
    type = [data.new.edr.type.v 4];
    data.new.edr.type.v = type(i);
    
else
    % If cancel, return
    return
end

% Update Data structure
guidata(gcbf, data);

end

%--------------------------------------------------------------------------
function eda_remove_peak_valley(pt)
% Remove valley or peak index

% Get data
data = guidata(gcbf);

% Get x coordinate
x = round( pt * data.new.fs ) + 1;

% Closest peak to selected point
[mp,ip]=min(abs(data.new.edr.iPeaks-x));
% Closest valley to selected point
[mv,iv]=min(abs(data.new.edr.iValleys-x));

if mv <= mp
    % If selected point is closer to valley, remove the valley
    pt_selection(1) = data.new.edr.iValleys(iv);
    data.new.edr.iValleys(iv) = [];
    data.new.edr.type.v(iv) = [];
else
    % If selected point is closer to peak, remove the peak
    pt_selection(1) =  data.new.edr.iPeaks(ip);
    data.new.edr.iPeaks(ip) = [];
    data.new.edr.type.p(ip) = [];
end

% Update Data structure
guidata(gcbf, data); 

end

%--------------------------------------------------------------------------
function edr_plot_update
% Update EDR plot

% Get data
data = guidata(gcbf);

% Update edr plots
set(data.handles.plot_peak, 'YData', data.new.eda(data.new.edr.iPeaks), ...
    'XData', (data.new.edr.iPeaks-1)/data.new.fs);
set(data.handles.plot_valley, 'YData', data.new.eda(data.new.edr.iValleys), ...
    'XData', (data.new.edr.iValleys-1)/data.new.fs);

end

%--------------------------------------------------------------------------
function eda_plot_update
% Update EDA plot

% Get data
data = guidata(gcbf);

% Update eda plot
set(data.handles.plot_eda, ...
    'YData', data.new.eda, 'XData', (0:length(data.new.eda)-1) / data.new.fs);

end

%--------------------------------------------------------------------------
function edr_info(pt)
% Display EDR info

% Get data
data = guidata(gcbf);

% Get x coordinate
x = round( pt * data.new.fs ) + 1;

% Find closest peak to selected point
[mp,ip] = min(abs( data.new.edr.iPeaks - x ));
% Find closest valley to selected point
[mv,iv] = min(abs( data.new.edr.iValleys - x ));

if isempty(mv) || isempty(mp)
    return
end

if mv <= mp
    % If selected point is closer to valley,
    % show info of EDR with valley
    i = iv(1);  % EDR index
else
    % If selected point is closer to peak,
    % show info of EDR with peak
    i = ip(1);  % EDR index
end

% Get EDR statistics
edr_stats = eda_edr_stats(data.new.eda, data.new.fs, data.new.edr, i(1));

info = sprintf('ID = %d\n', i(1));
info = [info sprintf('EDR type = %d\n', edr_stats.type)];
info = [info sprintf('Valley time = %0.03f s\n', edr_stats.valleyTime)];
info = [info sprintf('Peak time = %0.03f s\n', edr_stats.peakTime)];
info = [info sprintf('Amplitude = %0.03f uS\n', edr_stats.amplitude)];
info = [info sprintf('Rise time = %0.03f s\n', edr_stats.riseTime)];
info = [info sprintf('Slope = %0.03f uS/s\n', edr_stats.slope)];
msgbox(info, 'EDR Info');

end

%--------------------------------------------------------------------------
function edrOK = valid_edr
%Check for missing valley-peak pairs

% Get data
data = guidata(gcbf);

% Initialize edrOK
edrOK = false;

[c,iv,ii] = intersect(sort([data.new.edr.iValleys data.new.edr.iPeaks]), data.new.edr.iValleys);
[c,ip,ii] = intersect(sort([data.new.edr.iValleys data.new.edr.iPeaks]), data.new.edr.iPeaks);
if ( ~isempty(data.new.edr.iValleys) || ~isempty(data.new.edr.iPeaks) ) && ...
        ( ( length(data.new.edr.iValleys) ~= length(data.new.edr.iPeaks) ) || ...
        any((ip-iv) ~= 1) )

    n = min(length(iv),length(ip));
    dipv = find((ip(1:n)-iv(1:n)) ~= 1);

    msg =[];
    if ip(dipv(1)) - iv(dipv(1)) < 1
        msg = sprintf('Missing VALLEY around time %0.02f s.\n', ...
            data.new.edr.iPeaks(dipv(1)) / data.new.fs);
    else
        msg = sprintf('Missing PEAK around time %0.02f s.\n', ...
            data.new.edr.iValleys(dipv(1)) / data.new.fs);
    end

    msg = sprintf('%s\nFix it before exporting data...', msg);
    warndlg(msg, 'Warning');

    return;
else
    edrOK = true;
end

end

% --------------------------------------------------------------------
function menu_view_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end

% --------------------------------------------------------------------
function menu_view_conds_Callback(hObject, eventdata, data)
% hObject    handle to menu_view_conds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% data       structure with handles and user data (see GUIDATA)

% Toggle Conditions view state
eda_gui('toggle_state', data.handles.menu_view_conds, data.handles.plot_conds);

end

% --------------------------------------------------------------------
function menu_view_edl_Callback(hObject, eventdata, data)
% hObject    handle to menu_view_edl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% data       structure with handles and user data (see GUIDATA)

% Toggle EDL view state
eda_gui('toggle_state', data.handles.menu_view_edl, data.handles.plot_edl);

end

% --------------------------------------------------------------------
function menu_view_edr_Callback(hObject, eventdata, data)
% hObject    handle to menu_view_edr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% data       structure with handles and user data (see GUIDATA)

% Toggle EDR view state
eda_gui('toggle_state', data.handles.menu_view_edr, ...
                        [data.handles.plot_peak data.handles.plot_valley]);
end

% --------------------------------------------------------------------
function menu_data_Callback(hObject, eventdata, handles)
% hObject    handle to menu_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end

% --------------------------------------------------------------------
function menu_data_edr_Callback(hObject, eventdata, handles)
% hObject    handle to menu_data_edr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end

% --------------------------------------------------------------------
function menu_data_edr_restore_Callback(hObject, eventdata, data)
% hObject    handle to menu_data_edr_restore (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% data       structure with handles and user data (see GUIDATA)

axesOK = true;

if data.new.fs ~= data.old.fs || any(data.new.eda(:) ~= data.old.eda(:))
    % If EDA data has changed, restore all old structure
    data.new  = data.old;
    
    axesOK = false;
    
else
    % Otherwise, restore only old EDRs
    data.new.edr = data.old.edr;

end

% Update Data structure
guidata(hObject, data);

% Update conditions
conds_update;

% update all plots
eda_gui('all_plot_update');

if ~axesOK
    % Set axes
    eda_gui('set_axes');
end
    
end

function toggle_state(omenu, oplot, state)
% Toggle state of object view
%--------------------------------------------------------------------------

if nargin < 3
    % If no state is requested, toggle current state
    if strcmp(get(omenu, 'Checked'), 'on')
        state = 'off';
    else
        state = 'on';
    end
end

if nargin < 2
    oplot = [];
end

set(omenu, 'Checked', state);

for i = 1:numel(oplot)
    set(oplot(i), 'Visible', state);
end

end

% --------------------------------------------------------------------
function toolbar_save_figure_ClickedCallback(hObject, eventdata, data)
% hObject    handle to toolbar_save_figure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% data       structure with handles and user data (see GUIDATA)

[fname, fpath] = uiputfile({'*.fig', 'MATLAB Figure (*.fig)'; ...
                            '*.*', 'All Files (*.*)'}, 'Save as');

if isequal(fname,0)
   return
end

saveas(data.handles.fig_eda, fullfile(fpath, fname));

end

% --------------------------------------------------------------------
function menu_data_conds_Callback(hObject, eventdata, handles)
% hObject    handle to menu_data_conds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end

% --------------------------------------------------------------------
function menu_data_conds_shade_Callback(hObject, eventdata, handles)
% hObject    handle to menu_data_conds_shade (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end

% --------------------------------------------------------------------
function menu_data_conds_shade_duration_Callback(hObject, eventdata, data)
% hObject    handle to menu_data_conds_shade_duration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% data       structure with handles and user data (see GUIDATA)

eda_gui('toggle_state', data.handles.menu_data_conds_shade_duration);
eda_gui('toggle_state', data.handles.menu_data_conds_shade_latency);

eda_gui('conds_plot_update');

end

% --------------------------------------------------------------------
function menu_data_conds_shade_latency_Callback(hObject, eventdata, data)
% hObject    handle to menu_data_conds_shade_latency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% data       structure with handles and user data (see GUIDATA)

eda_gui('toggle_state', data.handles.menu_data_conds_shade_duration);
eda_gui('toggle_state', data.handles.menu_data_conds_shade_latency);

eda_gui('conds_plot_update');

end

% --------------------------------------------------------------------
function menu_file_close_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_close (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

close(gcbf);

end

% --------------------------------------------------------------------
function menu_data_edr_detect_Callback(hObject, eventdata, data)
% hObject    handle to menu_data_edr_detect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% data       structure with handles and user data (see GUIDATA)

% Auto-detect new EDRs
data.new.edr = eda_edr(data.new.eda, data.new.fs, ...
                       data.new.edr.thresh, true);

% Update Data structure
guidata(hObject, data);

% update plots
eda_gui('edr_plot_update');

end

% --------------------------------------------------------------------
function menu_help_Callback(hObject, eventdata, handles)
% hObject    handle to menu_help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end

% --------------------------------------------------------------------
function menu_help_online_Callback(hObject, eventdata, handles)
% hObject    handle to menu_help_online (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

web('https://github.com/mateusjoffily/EDA/wiki');

end

% --------------------------------------------------------------------
function menu_help_about_Callback(hObject, eventdata, handles)
% hObject    handle to menu_help_about (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

msg = [];
msg = [msg 'EDA Toolbox has been developed by Mateus Joffily '];
msg = [msg 'with support from '];
msg = [msg 'Federal University of Rio de Janeiro (UFRJ, Brazil), '];
msg = [msg 'National Council of Scientific and Technological Development (CNPq, Brazil), '];
msg = [msg 'Cognitive Neuroscience Centre (CNC, France), '];
msg = [msg 'National Center for Scientific Research (CNRS, France) and '];
msg = [msg 'Center for Mind/Brain Sciences (CIMeC, Italy).'];

msg = sprintf('%s\n\nCopyright (C) 2002, 2007, 2010 Mateus Joffily, mateusjoffily@gmail.com.', msg);

disc = [];
disc = [disc 'This program is free software: you can redistribute it '];
disc = [disc 'and/or modify it under the terms of the GNU General Public'];
disc = [disc 'License as published by the Free Software Foundation, '];
disc = [disc 'either version 3 of the License, or (at your option) any later version. '];
disc = [disc 'This program is distributed in the hope that it will be'];
disc = [disc 'useful, but WITHOUT ANY WARRANTY; without even the implied '];
disc = [disc 'warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR '];
disc = [disc 'PURPOSE.  See the GNU General Public License for more '];
disc = [disc 'details. You should have received a copy of the GNU '];
disc = [disc 'General Public License along with this program.  If not, '];
disc = [disc 'see <http://www.gnu.org/licenses/>.'];

msg = sprintf('%s\n\n%s', msg, disc);
msg = sprintf('%s\n\nSee <https://github.com/mateusjoffily/EDA/wiki>.', msg);

uiwait(msgbox(msg, 'About EDA Toolbox'));

end

% --------------------------------------------------------------------
function conds_update(fconds)

% Get data
data = guidata(gcbf);

% Update conditions
if nargin == 0
    % If conditions file is not available as input, update current 
    % conditions structure
    data.conds = eda_conditions(data.new.eda, data.new.fs, ...
                                data.conds, data.new.edr);
                            
else
    % Otherwise import new conditions from file
    data.conds = eda_conditions(data.new.eda, data.new.fs, ...
                                fconds, data.new.edr, [], true);
end

% Update data structure
guidata(gcbf, data);

% Delete current childrens from conditions plot context menu
delete(get(data.handles.menu_context_conds, 'Children'));

% Add new conditions to conditions plot context menu
for nCond = 1:length(data.conds)
    hcb = sprintf('eda_gui(''conds_plot_update'',%d)', nCond);
    uimenu(data.handles.menu_context_conds, ...
           'Label', data.conds(nCond).name, ...
           'Callback', hcb);
end

if isempty(data.conds)
    state = 'off';
    eda_gui('toggle_state', data.handles.menu_view_conds, ...
                            data.handles.plot_conds, state);
    eda_gui('toggle_state', data.handles.menu_view_edl, ...
                            data.handles.plot_edl, state);
else
    state = 'on';
end

% Enable Conditions and EDL menus
set(data.handles.menu_view_conds, 'Enable', state);
set(data.handles.menu_data_conds, 'Enable', state);
set(data.handles.menu_file_export_workspace_conds, 'Enable', state);
set(data.handles.menu_file_export_file_results_conditions, 'Enable', state);
set(data.handles.menu_view_edl,   'Enable', state);
   
end

% --------------------------------------------------------------------
function menu_file_import_file_conds_Callback(hObject, eventdata, data)
% hObject    handle to menu_file_import_file_conds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% data       structure with handles and user data (see GUIDATA)

[fcond, pcond] = uigetfile({'*.mat', 'MATLAB File (*.mat)'; ...
                            '*.*', 'All Files (*.*)'}, ...
                            'Select conditions file');
fcond = fullfile(pcond, fcond);

% If conditions file doesn't exist, return
if ~exist(sprintf('%s', fcond), 'file')
    return
end

% Update conditions
conds_update(fcond);

% Update conditions plot
eda_gui('conds_plot_update');

% Get updated data
data = guidata(gcbf);

% If conditions structure array not empty
if ~isempty(data.conds)
    eda_gui('toggle_state', data.handles.menu_view_conds, ...
                            data.handles.plot_conds, 'on');
    eda_gui('toggle_state', data.handles.menu_view_edl, ...
                            data.handles.plot_edl, 'on');
end

end

% --------------------------------------------------------------------
function menu_data_eda_Callback(hObject, eventdata, handles)
% hObject    handle to menu_data_eda (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end

% --------------------------------------------------------------------
function menu_data_eda_filter_Callback(hObject, eventdata, data)
% hObject    handle to menu_data_eda_filter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% data       structure with handles and user data (see GUIDATA)

% filter EDA
[data.new.eda data.new.filt] = eda_filt(data.new.eda, data.new.fs, data.new.filt, true);

if isempty(data.new.eda)
    % Discard changes and return
    return
end

% Auto-detect new EDRs
data.new.edr = eda_edr(data.new.eda, data.new.fs, data.new.edr.thresh);

% Update data structure
guidata(hObject, data);
    
% Update conditions
conds_update;

% Update EDA, EDR, EDL, Conditions 
eda_gui('all_plot_update');

end

% --------------------------------------------------------------------
function all_plot_update
% Update all plots

% Get data
data = guidata(gcbf);

% Update conditions plot
eda_gui('conds_plot_update');

% update eda plots
eda_gui('eda_plot_update');

% update edr plots
eda_gui('edr_plot_update');

end

% --------------------------------------------------------------------
function menu_data_eda_restore_Callback(hObject, eventdata, data)
% hObject    handle to menu_data_eda_restore (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% data       structure with handles and user data (see GUIDATA)

% Restore old data
data.new.eda  = data.old.eda;
data.new.filt = data.old.filt;
data.new.fs   = data.old.fs;

% Auto-detect new EDRs
data.new.edr = eda_edr(data.new.eda, data.new.fs, data.new.edr.thresh);

% Update Data structure
guidata(hObject, data);

% Update conditions
conds_update;

% Update EDA, EDR and Conditions plots
eda_gui('all_plot_update');

% Set axes
eda_gui('set_axes');

end

% --------------------------------------------------------------------
function menu_file_export_workspace_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_export_workspace (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end

% --------------------------------------------------------------------
function menu_data_eda_psd_Callback(hObject, eventdata, data)
% hObject    handle to menu_data_eda_psd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% data       structure with handles and user data (see GUIDATA)

figure('Name', 'Power Spectral Density', 'NumberTitle', 'off', 'Color', 'w');

pwelch(data.new.eda - mean(data.new.eda), [], [], [], data.new.fs);

end

% --------------------------------------------------------------------
function menu_data_eda_downsample_Callback(hObject, eventdata, data)
% hObject    handle to menu_data_eda_downsample (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% data       structure with handles and user data (see GUIDATA)

[data.new.eda fs] = eda_downsample(data.new.eda, data.new.fs);

if data.new.fs == fs
    % If sampling rate didn't change, return
    return

end

% Save new sampling rate
data.new.fs = fs;

% Auto-detect new EDRs
data.new.edr = eda_edr(data.new.eda, data.new.fs, data.new.edr.thresh);

% Update data structure
guidata(hObject, data);

% Update conditions
conds_update;

% Update EDA, EDR, and Conditions plots
eda_gui('all_plot_update');

end

% --------------------------------------------------------------------
function menu_file_import_file_data_Callback(hObject, eventdata, data)
% hObject    handle to menu_file_import_file_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% data       structure with handles and user data (see GUIDATA)

% Select file to import
[fname, pname] = uigetfile({'*.vhdr;*.acq;*.mat', 'All File formats (*.vhdr, *.acq, *.mat)'; ...
                            '*.vhdr', 'BrainAmp Vis. Rec. File (*.vhdr)'; ...
                            '*.acq',  'BIOPAC Acknowledge File (*.acq)';
                            '*.mat',  'MATLAB File (*.mat)'; ...
                            '*.*', 'All Files (*.*)'}, 'Select Data file');

if isequal(fname,0)
   % If cancelled, return
   return
end

 % Select channel
 prompt   = {'Select EDA channel or row of data matrix to import'};
 def      = {'1'};
 dlgTitle = 'Data channel';
 lineNo   = 1;
 while true
     answer   = inputdlg(prompt,dlgTitle,lineNo,def);
     if ~isempty(answer)
         Chan = str2double(answer{1});
         if ~isnan(Chan)
            Chan = int8(Chan(1));
            if Chan > 0
                break
            end
         end
     else
         % If cancelled, return
         return
     end
 end

% Initialize new data and conditions struture
data.new.eda  = [];
data.new.fs   = NaN;
data.new.filt = [];
data.new.edr  = eda_edr;
data.conds    = eda_conditions;

% Check file extension
[p f ext] = fileparts(fname);

% Import Data file...
switch (ext)
    case '.vhdr'
        [data.new.eda data.new.fs] = vhdr2mat(fname, pname, [], Chan, ...
                                              false, false);
        data.new.eda = data.new.eda(1,:);
        
    case '.acq'
        [data.new.eda data.new.fs] = acq2mat(fname, pname, Chan, ...
                                             false, false);        
    case '.mat'
        vars = whos('-file', fullfile(pname, fname));
                                     
        if any(strcmp({vars.name}, 'fs'))
            d = load(fullfile(pname, fname), 'fs');
            data.new.fs = d.fs;
        else
            return
        end
        
        if any(strcmp({vars.name}, 'eda'))
            d = load(fullfile(pname, fname), 'eda');
            data.new.eda = d.eda(Chan,:);
            
        elseif any(strcmp({vars.name}, 'data'))
            d = load(fullfile(pname, fname), 'data');
            data.new.eda = d.data(Chan,:);
            
        else
            return
        end
        
        if any(strcmp({vars.name}, 'filt'))
            d = load(fullfile(pname, fname), 'filt');
            data.new.filt = d.filt;
        end
        
        if any(strcmp({vars.name}, 'edr'))
            d = load(fullfile(pname, fname), 'edr');
            data.new.edr = d.edr;
        end
        
        if any(strcmp({vars.name}, 'conds'))
            d = load(fullfile(pname, fname), 'conds');
            data.conds = d.conds;
        end
end

% If old data structure was empty, save new data to it
if isempty(data.old.eda)
    data.old = data.new;
end

% Update data structure
guidata(hObject, data);

% Update conditions
conds_update;

% Update EDA, EDR and Conditions plots
eda_gui('all_plot_update')

% Set axes
eda_gui('set_axes');

% Enable menus
set(data.handles.menu_data_eda, 'Enable', 'on');
set(data.handles.menu_data_edr, 'Enable', 'on');
set(data.handles.menu_view_edr, 'Enable', 'on');
set(data.handles.menu_file_export_workspace_eda, 'Enable', 'on');
set(data.handles.menu_file_export_workspace_edr, 'Enable', 'on');
set(data.handles.menu_file_export_file_data, 'Enable', 'on');
set(data.handles.menu_file_export_file_results_edr, 'Enable', 'on');
set(data.handles.menu_file_import_file_conds, 'Enable', 'on');

% If conditions structure array is not empty, show condition plots
if ~isempty(data.conds)
    eda_gui('toggle_state', data.handles.menu_view_conds, ...
                            data.handles.plot_conds, 'on');
    eda_gui('toggle_state', data.handles.menu_view_edl, ...
                            data.handles.plot_edl, 'on');
end

end

% --------------------------------------------------------------------
function menu_file_export_file_data_Callback(hObject, eventdata, data)
% hObject    handle to menu_file_export_file_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% data       structure with handles and user data (see GUIDATA)

% Select file to save Data
[fname, pname] = uiputfile({'*.mat',  'MATLAB File (*.mat)'; ...
                            '*.*', 'All Files (*.*)'}, 'Save Data as');

if isequal(fname,0)
   return
end

eda   = data.new.eda;
fs    = data.new.fs;
filt  = data.new.filt;
edr   = data.new.edr;
conds = data.conds;

save(fullfile(pname, fname), 'eda', 'fs', 'filt', 'edr', 'conds');

end

% --------------------------------------------------------------------
function menu_file_export_workspace_eda_Callback(hObject, eventdata, data)
% hObject    handle to menu_file_export_workspace_eda (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% data       structure with handles and user data (see GUIDATA)

% Check data consistency
if eda_gui('valid_edr')
    msg = '''eda'', ''fs'' and ''filt'' variables will be exported to MATLAB workspace. Confirm?';
    qtitle = 'Export EDA';
    resp = questdlg(msg, qtitle, 'Yes', 'No', 'No');
    if strcmp(resp, 'Yes')
        assignin('base', 'eda', data.new.eda);
        assignin('base', 'fs', data.new.fs);
        assignin('base', 'filt', data.new.filt);
    end
end

end

% --------------------------------------------------------------------
function menu_file_export_workspace_edr_Callback(hObject, eventdata, data)
% hObject    handle to menu_file_export_workspace_edr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% data       structure with handles and user data (see GUIDATA)

% Check data consistency
if eda_gui('valid_edr')
    msg = '''edr'' structure array will be exported to MATLAB workspace. Confirm?';
    qtitle = 'Export EDR';
    resp = questdlg(msg, qtitle, 'Yes', 'No', 'No');
    if strcmp(resp, 'Yes')
        assignin('base', 'edr', data.new.edr);
    end
end

end

% --------------------------------------------------------------------
function menu_file_export_workspace_conds_Callback(hObject, eventdata, data)
% hObject    handle to menu_file_export_workspace_conds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% data       structure with handles and user data (see GUIDATA)

msg = '''conds'' structure array will be exported to MATLAB workspace. Confirm?';
qtitle = 'Export CONDITIONS';
resp = questdlg(msg, qtitle, 'Yes', 'No', 'No');
if strcmp(resp, 'Yes')
    assignin('base', 'conds', data.conds);
end

end

% --------------------------------------------------------------------
function menu_file_import_file_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_import_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end

% --------------------------------------------------------------------
function menu_file_export_file_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_export_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end

% --------------------------------------------------------------------
function menu_file_export_file_results_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_export_file_results (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end

% --------------------------------------------------------------------
function menu_file_export_file_results_edr_Callback(hObject, eventdata, data)
% hObject    handle to menu_file_export_file_results_edr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% data       structure with handles and user data (see GUIDATA)

[ftxt, ptxt] = uiputfile({'*.txt', 'Text File (*.txt)'; ...
                            '*.*', 'All Files (*.*)'}, 'Save results as...');

if isequal(ftxt,0)
   return
end

eda_save_text(fullfile(ptxt, ftxt), data.new.eda, data.new.fs, ...
              data.new.edr);

end

% --------------------------------------------------------------------
function menu_file_export_file_results_conditions_Callback(hObject, eventdata, data)
% hObject    handle to menu_file_export_file_results_conditions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% data       structure with handles and user data (see GUIDATA)

[ftxt, ptxt] = uiputfile({'*.txt', 'Text File (*.txt)'; ...
                          '*.*', 'All Files (*.*)'}, 'Save results as...');

if isequal(ftxt,0)
   return
end

eda_save_text(fullfile(ptxt, ftxt), data.new.eda, data.new.fs, ...
              data.new.edr, data.conds);

end

% --------------------------------------------------------------------
function set_axes

% Get data
data = guidata(gcbf);

% Axes Y limits
axis tight; 
v3 = min(data.new.eda) - 0.1 * ( max(data.new.eda) - min(data.new.eda) );
v4 = max(data.new.eda) + 0.1 * ( max(data.new.eda) - min(data.new.eda) );
v=axis; 
axis([v(1) v(2) v3 v4]);

end
