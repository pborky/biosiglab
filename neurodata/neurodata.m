function varargout = neurodata(varargin)
%% NEURODATA MATLAB code for neurodata.fig
%      NEURODATA, by itself, creates a new NEURODATA or raises the existing
%      singleton*.
%
%      H = NEURODATA returns the handle to a new NEURODATA or the handle to
%      the existing singleton*.
%
%      NEURODATA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in NEURODATA.M with the given input arguments.
%
%      NEURODATA('Property','Value',...) creates a new NEURODATA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before neurodata_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to neurodata_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help neurodata

% Last Modified by GUIDE v2.5 17-Apr-2011 14:41:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @neurodata_OpeningFcn, ...
                   'gui_OutputFcn',  @neurodata_OutputFcn, ...
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

function neurodata_OpeningFcn(hObject, eventdata, handles, varargin)
%% neurodata_OpeningFcn --- Executes just before neurodata is made visible.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to neurodata (see VARARGIN)

    % Parse arguments
    required = {'actions', 'server'};
    data = struct; i = 1; 
    while (i <= length(varargin)),
        name = lower(varargin{i});
        required(strcmp( name , required)) = [];
        switch name,
            case 'actions' 
                i = i + 1;
                data.actions = varargin{i};
            case 'server'
                i = i + 1;
                if iscell(varargin{i}),
                    data.server = struct(varargin{i}{:});
                else
                    data.server = varargin{i};
                end;                
            otherwise
                fprintf(2, 'Ignoring unrecognized argument (%s)', name);
        end;
        i = i + 1;
    end;
    if ~isempty(required),
        required = [char(required), repmat(',',length(required),1)]';
        required = required(:); required(required==32) = []; required(end) = [];
        throw(MException('NeuroData:InitFail', ...
            sprintf('Expecting required argument(s) [%s].\n', required)));
    end;
    
    % Set userdata
    data.dataset = [];
    data.messages = cell(0);
    data.figures = [];
    
    set(hObject, 'UserData', data);
    
    % Set controls
    set(handles.action, 'String', data.actions);
    set(handles.host, 'String', [data.server.host, ':', int2str( data.server.port)]);
    %set equipments combo
    probe_Callback(hObject, eventdata, handles);
    
    % Choose default command line output for neurodata
    handles.output = hObject;

    % Update handles structure
    guidata(hObject, handles);

function varargout = neurodata_OutputFcn(hObject, eventdata, handles)
%% neurodata_OutputFcn --- Outputs from this function are returned to the command line.
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    % Get default command line output from handles structure
    varargout{1} = handles.output;

function main_CreateFcn(hObject, eventdata, handles)
%% main_CreateFcn --- Executes during object creation, after setting all properties.
% hObject    handle to main (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    [];

function action_Callback(hObject, eventdata, handles)
%% action_Callback --- Executes on selection change in action.
% hObject    handle to action (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [];

function action_CreateFcn(hObject, eventdata, handles)
%% action_CreateFcn --- Executes during object creation, after setting all properties.
% hObject    handle to action (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    [];

function train_Callback(hObject, eventdata, handles)
%% train_Callback  --- Executes on button press in train.
% hObject    handle to train (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    data = get(handles.main, 'UserData');
    
    delay = get(handles.delay, 'String');
    delay = str2double(delay(get(handles.delay, 'Value')));
    
    equip = get(handles.equip, 'String');
    equip = str2double(equip(get(handles.equip, 'Value')));
    
    action = get(handles.action, 'Value');
    
    data = message(data, handles, 'Receiving data from neuroserver..');
    
    [ data.server, d ] = edfdata( data.server, delay, equip );
    [ data.server ] = socketclose( data.server );
    
    if ~isempty(data.dataset),
        dataset = data.dataset;
    else
        dataset.classes = data.actions;
        dataset.edf = cell(0);
        dataset.class = zeros(0);
        dataset.X = zeros(0);
        dataset.y = zeros(0);
    end;
    dataset.edf{end+1} = d{1};
    dataset.class(end+1) = action;
    d = d{1}.data;
    [siz,dim] = size(d);
    dataset.X(end+1:end+siz,1:dim) = d;
    dataset.y(end+1:end+siz,1) = action; 
    data.dataset = dataset;
    
    data = message(data, handles, '=> done.');
    
    set(handles.main, 'UserData', data);
    
    data = message(data, handles, 'Training..');
    
    d = struct();
    d.labels = data.dataset.classes;
    d.X = data.dataset.X';
    d.y = data.dataset.y';
    d.fsampl = data.dataset.edf{1}.head.SampleRate;
    
    if isempty(data.figures),
        data.figures = [...
                figure('Name', 'Umatrix and BMUs labeling'),  ...
                figure('Name', 'PCA projection of topological structure and features')];
    end;

    execplan = neuro_mk_exec_plan ({
            @neuro_bining,     {},     [1],    []; 
            @neuro_fourier,    {},     [2 3 4], [];
            @neuro_som_train,  {},     [],     [];
            @neuro_evaluate,   {},     [],     [];
            @neuro_draw,       {data.figures},     [],     []
        }, [
            0 1 0 0 0;
            0 0 1 0 0;
            0 0 0 1 0;
            0 0 0 0 1;
            0 0 0 0 0
        ],{
            [256 500 1000 2000 4000];   % f samp reduced
            [256 500 1000 2000 4000];   % time window before transform
            [ 5 10 20 50 ];               % number of steps inside one window
            [
                0  20; 
                20 250
            ]                           % frequency filters (column vetors of 2 components)
        } );
    
    profile = {execplan, [], 3, 3, 1, 2};
    
    execplan = neuro_exec(d, profile{:});
    
    data.dataset.trainset = execplan.def{4,4}{1};
    
    data = message(data, handles, '=> done.');
    
    set(handles.main, 'UserData', data);
catch e,
    message(data, handles, '!!! Got exception!');
    rethrow(e);
end;
    
function demo_Callback(hObject, eventdata, handles)
%% demo_Callback  --- Executes on button press in demo.
% hObject    handle to demo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    data = get(handles.main, 'UserData');
    
    delay = get(handles.delay, 'String');
    delay = str2double(delay(get(handles.delay, 'Value')));
    
    equip = get(handles.equip, 'String');
    equip = str2double(equip(get(handles.equip, 'Value')));
    
    action = get(handles.action, 'Value');
    
    data = message(data, handles, 'Demo..');
    
    set(handles.action, 'ForegroundColor', [1 0 0]);
    val = get(handles.action, 'Value');

    data.server =  edfdata( data.server, delay, equip, 1, 10, @(d) neuro_classify(d, data.dataset.trainset, handles.action) ); 
    [ data.server ] = socketclose( data.server );

    set(handles.action, 'ForegroundColor', [0 0 0]);
    set(handles.action, 'Value', val);
    
    data = message(data, handles, '=> done.');
    
    set(handles.main, 'UserData', data);    
catch e,
    message(data, handles, '!!! Got exception!');
    rethrow(e);
end

function equip_Callback(hObject, eventdata, handles)
%% equip_Callback --- Executes on selection change in equip.
% hObject    handle to equip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [];

function equip_CreateFcn(hObject, eventdata, handles)
%% equip_CreateFcn --- Executes during object creation, after setting all properties.
% hObject    handle to equip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    [];
    
function probe_Callback(hObject, eventdata, handles)
%% probe_Callback --- Executes on button press in probe.
% hObject    handle to probe (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    data = get(handles.main, 'UserData');
    data = message(data, handles, 'Reading neuroserver status..');
    data.server = edfstatus(data.server);
    equips = num2str(data.server.eeg(:));
    if isempty(equips), 
        data = message(data, handles, sprintf('=> no equipments found.'));
        set(handles.equip, 'Visible', 'off'); 
        set(handles.delay, 'Visible', 'off'); 
        set(handles.train, 'Visible', 'off'); 
        set(handles.demo, 'Visible', 'off'); 
        set(handles.action, 'Visible', 'off'); 
    else
        data = message(data, handles, sprintf('=> %i equipment(s) found.',...
            length(data.server.eeg)));
        set(handles.equip, 'Visible', 'on'); 
        set(handles.delay, 'Visible', 'on'); 
        set(handles.train, 'Visible', 'on'); 
        set(handles.demo, 'Visible', 'on'); 
        set(handles.action, 'Visible', 'on'); 
        set(handles.equip, 'String', equips);
    end;
    set(handles.main, 'UserData', data); 

function host_Callback(hObject, eventdata, handles)
%% host_Callback --- 
% hObject    handle to host (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [];

function host_CreateFcn(hObject, eventdata, handles)
%% host_CreateFcn --- Executes during object creation, after setting all properties.
% hObject    handle to host (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    [];

function data = message(data, handles, message)
%% message --- Shows message in messagebox and stores it in data.messages.
% data
% handles
% message
    if isempty(data),
        data = get(handles.main, 'UserData');
    end;
    data.messages{end+1} = message;
    if length(data.messages) < 9,
        set(handles.message, 'String', char(data.messages));
    else
        set(handles.message, 'String', char(data.messages(end-8:end)));
    end;
    set(handles.main, 'UserData', data);

function delay_Callback(hObject, eventdata, handles)
%% delay_Callback  --- Executes on selection change in delay.
% hObject    handle to delay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [];

function delay_CreateFcn(hObject, eventdata, handles)
%% delay_CreateFcn --- Executes during object creation, after setting all properties.
% hObject    handle to delay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    [];

function main_ResizeFcn(hObject, eventdata, handles)
%% main_ResizeFcn --- Executes when main is resized.
% hObject    handle to main (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [];

function purge_Callback(hObject, eventdata, handles)
%% purge_Callback --- Executes on button press in purge.
% hObject    handle to purge (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    data = get(handles.main, 'UserData');
    
    d.actions = data.actions;
    d.server = socketclose(data.server);
    d.figures = data.figures;
    
    d.dataset = [];
    d.messages = cell(0);
    
    data = message(d, handles, 'Purged userdata.');
    
    set(handles.main, 'UserData', data);
    
    probe_Callback(hObject, eventdata, handles)
