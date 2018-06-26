function varargout = AP_Segmentation_Parameters(varargin)
% AP_SEGMENTATION_PARAMETERS M-file for AP_Segmentation_Parameters.fig
%      AP_SEGMENTATION_PARAMETERS, by itself, creates a new AP_SEGMENTATION_PARAMETERS or raises the existing
%      singleton*.
%
%      H = AP_SEGMENTATION_PARAMETERS returns the handle to a new AP_SEGMENTATION_PARAMETERS or the handle to
%      the existing singleton*.
%
%      AP_SEGMENTATION_PARAMETERS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in AP_SEGMENTATION_PARAMETERS.M with the given input arguments.
%
%      AP_SEGMENTATION_PARAMETERS('Property','Value',...) creates a new AP_SEGMENTATION_PARAMETERS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before AP_Segmentation_Parameters_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to AP_Segmentation_Parameters_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help AP_Segmentation_Parameters

% Last Modified by GUIDE v2.5 16-Jan-2014 10:27:32

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AP_Segmentation_Parameters_OpeningFcn, ...
                   'gui_OutputFcn',  @AP_Segmentation_Parameters_OutputFcn, ...
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


% --- Executes just before AP_Segmentation_Parameters is made visible.
function AP_Segmentation_Parameters_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to AP_Segmentation_Parameters (see VARARGIN)

% Choose default command line output for AP_Segmentation_Parameters
% handles.output = hObject;
% handles.output = [];


%Update the numbers based on what was entered previously!! Or the default
%values!

input = varargin{1};
handles.bins        = input{1};
handles.KD          = input{2};
handles.n           = input{3};
handles.m           = input{4};
handles.window_size = input{5}; 
handles.damping     = input{6};
handles.iterations  = input{7};
handles.groups      = input{8};


% Update handles structure
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = AP_Segmentation_Parameters_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.bins_edit,'String', num2str(handles.bins));
set(handles.KD_edit,'String', num2str(handles.KD));
set(handles.n_edit,'String', num2str(handles.n));
set(handles.m_edit,'String', num2str(handles.m));
set(handles.window_size_edit,'String', num2str(handles.window_size));
set(handles.damping_edit,'String', num2str(handles.damping));
set(handles.iterations_edit,'String', num2str(handles.iterations));
set(handles.groups_to_keep_edit,'String', num2str(handles.groups));


uiwait(gcf);

handles.output = [];
handles.output{1} = str2num(get(handles.bins_edit, 'String'));
handles.output{2} = str2num(get(handles.KD_edit, 'String'));
handles.output{3} = str2num(get(handles.n_edit, 'String'));
handles.output{4} = str2num(get(handles.m_edit, 'String'));
handles.output{5} = str2num(get(handles.window_size_edit, 'String'));
handles.output{6} = str2num(get(handles.damping_edit, 'String'));
handles.output{7} = str2num(get(handles.iterations_edit, 'String'));
handles.output{8} = str2num(get(handles.groups_to_keep_edit, 'String'));


%Check to make sure damping is between 0.5 and 1! Constraint from AP
if handles.output{6} > 1
    handles.output{6} = .99;
elseif handles.output{6} < 0.5
    handles.output{6} = 0.5;
end
    

% Get default command line output from handles structure
varargout{1} = handles.output;




function n_edit_Callback(hObject, eventdata, handles)
% hObject    handle to n_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of n_edit as text
%        str2double(get(hObject,'String')) returns contents of n_edit as a double


% --- Executes during object creation, after setting all properties.
function n_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to n_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function m_edit_Callback(hObject, eventdata, handles)
% hObject    handle to m_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of m_edit as text
%        str2double(get(hObject,'String')) returns contents of m_edit as a double


% --- Executes during object creation, after setting all properties.
function m_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to m_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function KD_edit_Callback(hObject, eventdata, handles)
% hObject    handle to KD_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of KD_edit as text
%        str2double(get(hObject,'String')) returns contents of KD_edit as a double


% --- Executes during object creation, after setting all properties.
function KD_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to KD_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function window_size_edit_Callback(hObject, eventdata, handles)
% hObject    handle to window_size_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of window_size_edit as text
%        str2double(get(hObject,'String')) returns contents of window_size_edit as a double


% --- Executes during object creation, after setting all properties.
function window_size_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to window_size_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function iterations_edit_Callback(hObject, eventdata, handles)
% hObject    handle to iterations_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of iterations_edit as text
%        str2double(get(hObject,'String')) returns contents of iterations_edit as a double


% --- Executes during object creation, after setting all properties.
function iterations_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to iterations_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function damping_edit_Callback(hObject, eventdata, handles)
% hObject    handle to damping_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of damping_edit as text
%        str2double(get(hObject,'String')) returns contents of damping_edit as a double


% --- Executes during object creation, after setting all properties.
function damping_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to damping_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function bins_edit_Callback(hObject, eventdata, handles)
% hObject    handle to bins_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bins_edit as text
%        str2double(get(hObject,'String')) returns contents of bins_edit as a double


% --- Executes during object creation, after setting all properties.
function bins_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bins_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function groups_to_keep_edit_Callback(hObject, eventdata, handles)
% hObject    handle to groups_to_keep_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of groups_to_keep_edit as text
%        str2double(get(hObject,'String')) returns contents of groups_to_keep_edit as a double

% --- Executes during object creation, after setting all properties.
function groups_to_keep_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to groups_to_keep_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


uiresume(gcbf)

guidata(hObject, handles);


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



uiresume(gcbf)

guidata(hObject, handles);
