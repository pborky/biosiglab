function varargout = datagetter(varargin)
% DATAGETTER MATLAB code for datagetter.fig
%      DATAGETTER, by itself, creates a new DATAGETTER or raises the existing
%      singleton*.
%
%      H = DATAGETTER returns the handle to a new DATAGETTER or the handle to
%      the existing singleton*.
%
%      DATAGETTER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DATAGETTER.M with the given input arguments.
%
%      DATAGETTER('Property','Value',...) creates a new DATAGETTER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before datagetter_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to datagetter_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help datagetter

% Last Modified by GUIDE v2.5 16-Apr-2011 23:34:43

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @datagetter_OpeningFcn, ...
                   'gui_OutputFcn',  @datagetter_OutputFcn, ...
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


% --- Executes just before datagetter is made visible.
function datagetter_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to datagetter (see VARARGIN)

% Choose default command line output for datagetter
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes datagetter wait for user response (see UIRESUME)
% uiwait(handles.datagetter);


% --- Outputs from this function are returned to the command line.
function varargout = datagetter_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function classes_Callback(hObject, eventdata, handles)
% hObject    handle to classes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of classes as text
%        str2double(get(hObject,'String')) returns contents of classes as a double


% --- Executes during object creation, after setting all properties.
function classes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to classes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function sequences_Callback(hObject, eventdata, handles)
% hObject    handle to sequences (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sequences as text
%        str2double(get(hObject,'String')) returns contents of sequences as a double


% --- Executes during object creation, after setting all properties.
function sequences_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sequences (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function delays_Callback(hObject, eventdata, handles)
% hObject    handle to text10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text10 as text
%        str2double(get(hObject,'String')) returns contents of text10 as a double


% --- Executes during object creation, after setting all properties.
function text10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in start.
function start_Callback(hObject, eventdata, handles)
% hObject    handle to start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    if get(hObject,'Value')
        process = get(handles.datagetter, 'UserData');
        if isempty(process) || (isfield(process, 'finished') && process.finished)
            process = struct;
            process.classes = eval(['{' get(handles.classes,'String') '}']);
            process.sequences = eval(['[' get(handles.sequences,'String') ']']);
            process.delays = eval(['[' get(handles.delays,'String') ']']);
            process.equip = eval(['[' get(handles.equip,'String') ']']);
            process.it = 1;
            process.finished = 0;
            process.server = struct('host', get(handles.host,'String'), 'port', str2double(get(handles.port,'String')));
            process.dataset= cell(0);
            set(handles.datagetter, 'UserData', process);
        end
        while (1)
            inst = process.classes{process.sequences(process.it)};
            if (inst(1)=='+'), 
                color = double(inst(2:4))./255;
                set(handles.instructions, 'ForeGroundColor', color);
                inst = inst(5:end);
            else
                set(handles.instructions, 'ForeGroundColor', [0 0 0]);
            end;
            set(handles.instructions, 'String', inst);
            
            guidata(hObject, handles);
            
            %process.server = neuroclient(process.server, []);
            %process.server = edfstatus(process.server); 
            [ process.server, data ] = edfdata( process.server, process.delays(process.it), process.equip );
            for i = 1:length(data),
                if length(process.dataset) >= i && ~isempty(process.dataset{i}),
                    x = process.dataset{i};
                else
                    x.classes = process.classes;
                    x.edf = cell(0);
                    x.class = zeros(0);
                    x.X = zeros(0);
                    x.y = zeros(0);
                end;
                x.edf{end+1} = data{i};
                x.class(end+1) = process.it;
                data = data{i}.data;
                [siz,dim] = size(data);
                x.X(end+1:end+siz,1:dim) = data;
                x.y(end+1:end+siz,1) = process.sequences(process.it); 
                process.dataset{i} = x;
            end;
            
            process.it = process.it+1;
            set(handles.datagetter, 'UserData', process);
            if process.it>length(process.sequences), process.finished = 1; end;
            if ~get(hObject,'Value') || process.finished
                process.it = 1;
                process.server = socketclose(process.server);
                break;
            end;
        end;
        process.server = socketclose(process.server);
        
        data = struct();
        data.labels = process.dataset{1}.classes;
        data.X = process.dataset{1}.X';
        data.y = process.dataset{1}.y';
        data.fsampl = process.dataset{1}.edf{1}.head.SampleRate;

        plan = bsl_exec_plan ({
                @neuro_bining,     {},     [1],    []; 
                @neuro_fourier,    {},     [2 3 4], [];
                @neuro_som_train,  {},     [],     [];
                @neuro_evaluate,   {},     [],     [];
                @neuro_draw,       {},     [],     []
            }, [
                0 1 0 0 0;
                0 0 1 0 0;
                0 0 0 1 0;
                0 0 0 0 1;
                0 0 0 0 0
            ],{
                [256 500 1000 2000 4000];   % f samp reduced
                [256 500 1000 2000 4000];   % time window before transform
                [ 10 20 50 ];               % number of steps inside one window
                [
                    0  20; 
                    20 250
                ]                           % frequency filters (column vetors of 2 components)
            } );
        
        fprintf(2, 'Train..');
        
        %plan = bsl_dag_dfs(data, plan, [], 1000, 1000, 5, [ 0; 20] );
        plan = bsl_dag_dfs(data, plan, [], 1000, 1000, 5, [20;250] );        
        
        process.dataset{1}.data = plan.def{4,4}{1};
        
        assignin('base','dataset',process.dataset);
        set(hObject,'Value', 0);
        set(handles.datagetter, 'UserData', process);

        set(handles.instructions, 'String', '');
        
    end;
    guidata(hObject, handles);
catch e
    process = [];
    set(handles.datagetter, 'UserData', process);
    set(hObject,'Value', 0);
    throw(e);
end

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over start.
function start_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on key press with focus on start and none of its controls.
function start_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to start (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)



function host_Callback(hObject, eventdata, handles)
% hObject    handle to host (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of host as text
%        str2double(get(hObject,'String')) returns contents of host as a double


% --- Executes during object creation, after setting all properties.
function host_CreateFcn(hObject, eventdata, handles)
% hObject    handle to host (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function port_Callback(hObject, eventdata, handles)
% hObject    handle to port (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of port as text
%        str2double(get(hObject,'String')) returns contents of port as a double


% --- Executes during object creation, after setting all properties.
function port_CreateFcn(hObject, eventdata, handles)
% hObject    handle to port (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function periodr_Callback(hObject, eventdata, handles)
% hObject    handle to periodr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of periodr as text
%        str2double(get(hObject,'String')) returns contents of periodr as a double


% --- Executes during object creation, after setting all properties.
function periodr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to periodr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function periodc_Callback(hObject, eventdata, handles)
% hObject    handle to periodc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of periodc as text
%        str2double(get(hObject,'String')) returns contents of periodc as a double


% --- Executes during object creation, after setting all properties.
function periodc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to periodc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function periodl_Callback(hObject, eventdata, handles)
% hObject    handle to periodr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of periodr as text
%        str2double(get(hObject,'String')) returns contents of periodr as a double


% --- Executes during object creation, after setting all properties.
function periodl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to periodr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function blink(obj, event, target, handles)
    a = get(target, 'UserData');
    if isempty(a), a.active = 0; end;
    if a.active == 0,
        set(target, 'BackgroundColor', [ 0 0 0 ]);
        a.active = 1;
    else
        set(target, 'BackgroundColor', [ .702 .702 .702 ]);
        a.active = 0;
    end;
    guidata(target, handles);
    set(target,'UserData', a);

% --- Executes on button press in togglebutton2.
function togglebutton2_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    t = get(hObject,'UserData');
    if isempty(t), t = timer; end;
    if get(hObject, 'Value'),
        t.TimerFcn = {@blink, handles.left, handles};
        t.ExecutionMode = 'fixedRate';
        t.UserData = handles.left;
        t.Period = 1/str2double(get(handles.periodl, 'String'));
        start(t);
    else
        stop(t);
        delete(t);
        t = [];
    end;    
    set(hObject,'UserData',t);

% --- Executes on button press in togglebutton3.
function togglebutton3_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    t = get(hObject,'UserData');
    if isempty(t), t = timer; end;
    if get(hObject, 'Value'),
        t.TimerFcn = {@blink, handles.center, handles};
        t.ExecutionMode = 'fixedRate';
        t.UserData = handles.center;
        t.Period = 1/str2double(get(handles.periodc, 'String'));
        start(t);
    else
        stop(t);
        delete(t);
        t = [];
    end;    
    set(hObject,'UserData',t);

% --- Executes on button press in togglebutton4.
function togglebutton4_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    t = get(hObject,'UserData');
    if isempty(t), t = timer; end;
    if get(hObject, 'Value'),set(hObject,'Value', 0);
        t.TimerFcn = {@blink, handles.right, handles};
        t.ExecutionMode = 'fixedRate';
        t.UserData = handles.right;
        t.Period = 1/str2double(get(handles.periodr, 'String'));
        start(t);
    else
        stop(t);
        delete(t);
        t = [];
    end;    
    set(hObject,'UserData',t);



function equip_Callback(hObject, eventdata, handles)
% hObject    handle to equip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of equip as text
%        str2double(get(hObject,'String')) returns contents of equip as a double


% --- Executes during object creation, after setting all properties.
function equip_CreateFcn(hObject, eventdata, handles)
% hObject    handle to equip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in demo.
function demo_Callback(hObject, eventdata, handles)
% hObject    handle to demo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of demo
try
    if get(hObject,'Value')
        process = get(handles.datagetter, 'UserData');
        if isempty(process) || (isfield(process, 'finished') && process.finished)
            process = struct('dataset', process.dataset );
            process.finished = 0;
            process.server = struct('host', get(handles.host,'String'), 'port', str2double(get(handles.port,'String')));
            set(handles.datagetter, 'UserData', process);
        end;
        

        fprintf(2, 'Demo..');
        % init neuroclient
        set(handles.instructions, 'ForeGroundColor', [1 0 0]);
        process.server =  edfdata( process.server, 1, [], 1, 20, @(data) neuro_classify(data, process.dataset.data, handles.instructions) ); 
        set(handles.instructions, 'String', '');
        
        process.server = socketclose(process.server);
        process.finished = 1;
        
        set(hObject,'Value', 0);
    end;
catch e
    process = struct('dataset', process.dataset );
    set(handles.datagetter, 'UserData', process);
    set(hObject,'Value', 0);
    throw(e);
end