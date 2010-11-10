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
%    measurement. Use File > Load conditions menu for loading conditions
%    *.mat file. Conditions (shaded area) displayed in the GUI may 
%    correspond the EDR onset latency criterion used by eda.conditions.m to 
%    relate EDR to specific events or the duration of the event itself. 
%    Use Data > Coditions > Shade menu to select between these two display 
%    modes.
% _________________________________________________________________________

% Last modified 10-11-2010 Mateus Joffily

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

% Last Modified by GUIDE v2.5 09-Nov-2010 11:55:10

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

% Check varargin
if numel(varargin) < 3
    error('Missing input variables: help eda_gui');
end

% Initialize variables 
eda = varargin{1};
fs  = varargin{2};
edr = varargin{3};

% Initialize Data structure
data = handles;
data.eda = eda;
data.fs = fs;
data.edr.old = edr;
data.edr.new = edr;
data.conds = struct('name', [], 'onsets', [], 'durations', [], ...
              'latency_wdw', [], 'iEDR', [], 'N', [], ...
              'edl', struct('v', [], 't', []));

% Set EDA axes
%--------------------------------------------------------------------------
hold(data.axes_eda, 'on');

% Axes Y limits
v3=min(data.eda)-0.1*(max(data.eda)-min(data.eda));
v4=max(data.eda)+0.1*(max(data.eda)-min(data.eda));

% Plot Conditions
%----------------------------------------------------------------------
h = area(NaN, NaN, ...
     'Tag', 'plot_conds', ...
     'FaceColor', [0.8 1 0.8], ...
     'EdgeColor', [0.8 1 0.8], ...
     'Visible', 'off');
data.plot_conds = h;

% Plot EDL
%----------------------------------------------------------------------
max_edl = 200;  % Allow for up to max_edl EDLs to be displayed
h = line(repmat(NaN,2,max_edl), repmat(NaN,2,max_edl), ...
    'Tag', 'plot_edl', ...
    'LineStyle', '-', ...
    'Color', 'r', ...
    'Visible', 'off');
data.plot_edl = h;   

% Plot EDA
%--------------------------------------------------------------------------
h = line('Tag','plot_eda', ...
    'LineStyle', '-', ...
    'Color', 'k', ...
    'EraseMode', 'normal', ...
    'YData', data.eda, ...
    'XData', (0:length(data.eda)-1) / data.fs, ...
    'ButtonDownFcn', 'eda_gui(''mouseclick'')');
data.plot_eda = h;

% Plot EDR peaks
%----------------------------------------------------------------------
h = line('Tag', 'plot_peak', ...
    'LineStyle', 'none', ...
    'Marker', '.', ...
    'Color', 'r', ...
    'EraseMode', 'normal', ...
    'YData', data.eda(data.edr.new.iPeaks), ...
    'XData', (data.edr.new.iPeaks-1) / data.fs, ...
    'ButtonDownFcn', 'eda_gui(''mouseclick'')');
data.plot_peak = h;

% Plot EDR valleys
%----------------------------------------------------------------------
h = line('Tag','plot_valley', ...
    'LineStyle', 'none', ...
    'Marker', '.', ...
    'Color', 'b', ...
    'EraseMode', 'normal', ...
    'YData', data.eda(data.edr.new.iValleys), ...
    'XData', (data.edr.new.iValleys-1) / data.fs, ...
    'ButtonDownFcn', 'eda_gui(''mouseclick'')');
data.plot_valley = h;

% Fix axes
%----------------------------------------------------------------------
axis tight; v=axis; axis([v(1) v(2) v3 v4]);

xlabel('Time (seconds)');
ylabel('EDA (microSiemens)');

% Store Data structure
guidata(hObject, data); 

% UIWAIT makes eda_gui wait for user response (see UIRESUME)
% uiwait(handles.fig_eda);

% --- Outputs from this function are returned to the command line.
function varargout = eda_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes during object creation, after setting all properties.
function axes_eda_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes_eda (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes_eda


% --- Executes during object deletion, before destroying properties.
function axes_eda_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to axes_eda (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on mouse press over axes background.
function axes_eda_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes_eda (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_file_export_variables_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_export_variables (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get data
data = guidata(hObject);

% Check data consistency
if eda_gui('valid_edr')
    msg = 'Variable ''edr'' will be exported to MATLAB workspace. Confirm?';
    qtitle = 'Export variables';
    resp = questdlg(msg, qtitle, 'Yes', 'No', 'No');
    if strcmp(resp, 'Yes')
        assignin('base', 'edr', data.edr.new);
    end
end


% --------------------------------------------------------------------
function menu_file_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function show_conds(nC)
% Perform action when mouse click over figure's object
%----------------------------------------------------------------------

% Get data
data = guidata(gcbf);

if nargin == 0
    % Use last condition index
    nC = data.nC;
    
else
    % Save current condition index
    data.nC = nC;
    
    % Update data structure
    guidata(gcbf, data);
    
end

% Get axis dimensions
v = axis;  

% Update Conditions plot
durationON = get(data.menu_data_conds_shade_duration, 'Checked');
if strcmp(durationON, 'on')
    latency_wdw = repmat(data.conds(nC).onsets, 2, 1) + ...
          [zeros(size(data.conds(nC).durations)); data.conds(nC).durations];
else
    latency_wdw = data.conds(nC).latency_wdw;
end
x = sort([latency_wdw(:); latency_wdw(:)])';
y = repmat([0 v(4) v(4) 0], 1, length(x)/4);
set(data.plot_conds, 'XData', x, 'YData', y);

% Update EDL plot
nE = size(data.conds(nC).edl.t,2);
for iP = 1:length(data.plot_edl)
    if iP <= nE
        set(data.plot_edl(iP), 'XData', data.conds(nC).edl.t(:,iP), ...
                         'YData', repmat(data.conds(nC).edl.v(iP),2,1));
    else
        set(data.plot_edl(iP), 'XData', [NaN NaN]', 'YData', [NaN NaN]');
        
    end
end


function mouseclick
% Perform action when mouse click over figure's object
%----------------------------------------------------------------------

% Returns previously stored data
data = guidata(gcbf);

% Get mouse click coordinates
pt = get(data.axes_eda, 'CurrentPoint');

% Get mouse selection type
seltype = get(data.fig_eda, 'SelectionType');

% Get calling object tag
gcotag = get(gco, 'Tag');

if strcmp(gcotag, 'plot_eda')
    % Click was over eda plot
    %------------------------------------------------------------------
    if strcmp(seltype, 'normal')
        % It was a left mouse button click

        % Add EDR at mouse location
        eda_gui('eda_add_peak_valley', gcbf, pt(1,1));
        
        % Update plot
        eda_gui('plot_update', gcbf);
        
    end

elseif strcmp(gcotag, 'plot_peak') || ...
       strcmp(gcotag, 'plot_valley')
    % Click was over a valley or a peak point
    %------------------------------------------------------------------

    if strcmp(seltype, 'normal')
        % It was a left mouse button click
        %--------------------------------------------------------------

        % Remove valley or peak from mouse location
        eda_gui('eda_remove_peak_valley', gcbf, pt(1,1));
        
        % Update plot
        eda_gui('plot_update', gcbf);
        
    elseif strcmp(seltype, 'alt')
        % It was a right mouse button click
        %--------------------------------------------------------------

        eda_gui('edr_info', gcbf, pt(1,1));
    end
    
end

function eda_add_peak_valley(hObject, pt)
% Add new valley or peak index
%--------------------------------------------------------------------------

% Get data
data = guidata(hObject);

% Get x coordinate
x = round( pt * data.fs ) + 1;

% Ask if it is a EDR valley or peak
resp=menu('Selection type:', {'Peak' 'Valley' 'Cancel'});

% Update EDA peak/valley vector
if resp == 1
    [data.edr.new.iPeaks, i, j] = unique([data.edr.new.iPeaks x]);
    % Set EDR type to manual
    type = [data.edr.new.type.p 4];
    data.edr.new.type.p = type(i);
    
elseif resp == 2
    [data.edr.new.iValleys, i, j] = unique([data.edr.new.iValleys x]);
    % Set EDR type to manual
    type = [data.edr.new.type.v 4];
    data.edr.new.type.v = type(i);
    
else
    % If cancel, return
    return
end

% Update Data structure
guidata(hObject, data); 



function eda_remove_peak_valley(hObject, pt)
% Remove valley or peak index
%--------------------------------------------------------------------------

% Get data
data = guidata(hObject);

% Get x coordinate
x = round( pt * data.fs ) + 1;

% Closest peak to selected point
[mp,ip]=min(abs(data.edr.new.iPeaks-x));
% Closest valley to selected point
[mv,iv]=min(abs(data.edr.new.iValleys-x));

if mv <= mp
    % If selected point is closer to valley, remove the valley
    pt_selection(1) = data.edr.new.iValleys(iv);
    data.edr.new.iValleys(iv) = [];
    data.edr.new.type.v(iv) = [];
else
    % If selected point is closer to peak, remove the peak
    pt_selection(1) =  data.edr.new.iPeaks(ip);
    data.edr.new.iPeaks(ip) = [];
    data.edr.new.type.p(ip) = [];
end

% Update Data structure
guidata(hObject, data); 


function plot_update(hObject)

% Get data
data = guidata(hObject);

% update plots
set(data.plot_peak, 'YData', data.eda(data.edr.new.iPeaks), ...
    'XData', (data.edr.new.iPeaks-1)/data.fs);
set(data.plot_valley, 'YData', data.eda(data.edr.new.iValleys), ...
    'XData', (data.edr.new.iValleys-1)/data.fs);

function edr_info(hObject, pt)
% Display EDR info
%--------------------------------------------------------------------------

% Get data
data = guidata(hObject);

% Get x coordinate
x = round( pt * data.fs ) + 1;

% Find closest peak to selected point
[mp,ip] = min(abs( data.edr.new.iPeaks - x ));
% Find closest valley to selected point
[mv,iv] = min(abs( data.edr.new.iValleys - x ));

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
edr_stats = eda_edr_stats(data.eda, data.fs, data.edr.new, i(1));

info = sprintf('ID = %d\n', i(1));
info = [info sprintf('EDR type = %d\n', edr_stats.type)];
info = [info sprintf('Valley time = %0.03f s\n', edr_stats.valleyTime)];
info = [info sprintf('Peak time = %0.03f s\n', edr_stats.peakTime)];
info = [info sprintf('Amplitude = %0.03f uS\n', edr_stats.amplitude)];
info = [info sprintf('Rise time = %0.03f s\n', edr_stats.riseTime)];
info = [info sprintf('Slope = %0.03f uS/s\n', edr_stats.slope)];
msgbox(info, 'EDR Info');

function edrOK = valid_edr
%Check for missing valley-peak pairs
%--------------------------------------------------------------------------

% Get data
data = guidata(gcbf);

% Initialize edrOK
edrOK = false;

[c,iv,ii] = intersect(sort([data.edr.new.iValleys data.edr.new.iPeaks]), data.edr.new.iValleys);
[c,ip,ii] = intersect(sort([data.edr.new.iValleys data.edr.new.iPeaks]), data.edr.new.iPeaks);
if ( ~isempty(data.edr.new.iValleys) || ~isempty(data.edr.new.iPeaks) ) && ...
        ( ( length(data.edr.new.iValleys) ~= length(data.edr.new.iPeaks) ) || ...
        any((ip-iv) ~= 1) )

    n = min(length(iv),length(ip));
    dipv = find((ip(1:n)-iv(1:n)) ~= 1);

    msg =[];
    if ip(dipv(1)) - iv(dipv(1)) < 1
        msg = sprintf('Missing VALLEY around time %0.02f s.\n', ...
            data.edr.new.iPeaks(dipv(1)) / data.fs);
    else
        msg = sprintf('Missing PEAK around time %0.02f s.\n', ...
            data.edr.new.iValleys(dipv(1)) / data.fs);
    end

    msg = sprintf('%s\nFix it before exporting data...', msg);
    warndlg(msg, 'Warning');

    return;
else
    edrOK = true;
end


% --------------------------------------------------------------------
function menu_view_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_view_conds_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_conds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get stored data
data = guidata(hObject);

% Toggle Conditions view state
eda_gui('toggle_state', data.menu_view_conds, data.plot_conds);



% --------------------------------------------------------------------
function menu_view_edl_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_edl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get stored data
data = guidata(hObject);

% Toggle EDL view state
eda_gui('toggle_state', data.menu_view_edl, data.plot_edl);



% --------------------------------------------------------------------
function menu_view_edr_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_edr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get stored data
data = guidata(hObject);

% Toggle EDR view state
eda_gui('toggle_state', data.menu_view_edr, ...
                        [data.plot_peak data.plot_valley]);



% --------------------------------------------------------------------
function menu_file_conds_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_conds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get stored data
data = guidata(hObject);

[fcond, pcond] = uigetfile('*.mat', 'Select conditions file');
fcond = fullfile(pcond, fcond);

% If conditions file doesn't exist, return
if ~exist(sprintf('%s', fcond), 'file')
    return
end

% Load conditions
data.conds = eda_conditions(data.eda, data.fs, fcond, data.edr.new);

% Create context menu for conditions plot
data.menu_context_conds = uicontextmenu;   % Define a context menu

% Update data structure
guidata(hObject, data);

% Add conditions to contextmenu
for nC = 1:length(data.conds)
    hcb = sprintf('eda_gui(''show_conds'',%d)', nC);
    uimenu(data.menu_context_conds, ...
           'Label', data.conds(nC).name, ...
           'Callback', hcb);
end

% Attach the context menu to conditions plot
set(data.plot_conds, 'uicontextmenu', data.menu_context_conds);

% Enable Conditions and EDL menus
set(data.menu_view_conds, 'Enable', 'on');
set(data.menu_data_conds, 'Enable', 'on');
set(data.menu_view_edl, 'Enable', 'on');

% Show first condition
eda_gui('show_conds', 1);

% Toggle Conditions and EDL view state
eda_gui('toggle_state', data.menu_view_conds, data.plot_conds);
eda_gui('toggle_state', data.menu_view_edl, data.plot_edl);


% --------------------------------------------------------------------
function menu_data_Callback(hObject, eventdata, handles)
% hObject    handle to menu_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_data_edr_Callback(hObject, eventdata, handles)
% hObject    handle to menu_data_edr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_data_edr_restore_Callback(hObject, eventdata, handles)
% hObject    handle to menu_data_edr_restore (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get stored data
data = guidata(hObject);

% Restore old data
data.edr.new = data.edr.old;

% Update Data structure
guidata(hObject, data);

% update plots
eda_gui('plot_update', hObject)

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


% --------------------------------------------------------------------
function toolbar_save_figure_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to toolbar_save_figure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get stored data
data = guidata(hObject);

[fname, fpath] = uiputfile('*.fig', 'Save as');
saveas(data.fig_eda, fullfile(fpath, fname));


% --------------------------------------------------------------------
function menu_data_conds_Callback(hObject, eventdata, handles)
% hObject    handle to menu_data_conds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_data_conds_shade_Callback(hObject, eventdata, handles)
% hObject    handle to menu_data_conds_shade (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_data_conds_shade_duration_Callback(hObject, eventdata, handles)
% hObject    handle to menu_data_conds_shade_duration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get stored data
data = guidata(hObject);

eda_gui('toggle_state', data.menu_data_conds_shade_duration);
eda_gui('toggle_state', data.menu_data_conds_shade_latency);

eda_gui('show_conds');




% --------------------------------------------------------------------
function menu_data_conds_shade_latency_Callback(hObject, eventdata, handles)
% hObject    handle to menu_data_conds_shade_latency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get stored data
data = guidata(hObject);

eda_gui('toggle_state', data.menu_data_conds_shade_duration);
eda_gui('toggle_state', data.menu_data_conds_shade_latency);

eda_gui('show_conds');


% --------------------------------------------------------------------
function menu_file_close_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_close (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

close(gcbf);


