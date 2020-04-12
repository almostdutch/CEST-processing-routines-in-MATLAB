function varargout = showSpectra(varargin)
% showSpectra
%
% Simple GUI for quick assessment of quality of the data. 
% Load data: 
%    (1) 4D CEST-MRI data: dimensions [dim1 x dim2 x Nslices x Noffsets]
%    (2) 1D Frequency offsets: units [ppm]   
%
% Adjusting the sliders for slice and/or frequency offset will show the
% corresponding image in the left GUI part, whereas moving cursor over the
% image will show the corresponding CEST-MRI spectra in the right GUI part.
%

% (c) Vitaliy Khlebnikov, PhD
% vital.khlebnikov@gmail.com

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @showSpectra_OpeningFcn, ...
    'gui_OutputFcn',  @showSpectra_OutputFcn, ...
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

% --- Executes just before showSpectra is made visible.
function showSpectra_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to showSpectra (see VARARGIN)

% Choose default command line output for showSpectra
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes showSpectra wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = showSpectra_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in loadDate.
function loadDate_Callback(hObject, eventdata, handles)
% hObject    handle to loadDate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global cestData offsets Nslices Noffsets
[varout,varoutnames] = uigetvariables({'4D CEST dataset [dim1 x dim2 x Nslices x Noffsets]','Frequency offsets [ppm]'},...
    'InputDimensions',[4 1],'InputTypes',{'numeric','numeric'});
cestData=varout{1};
offsets=varout{2};
[~,~,Nslices,Noffsets]=size(cestData);
axes(handles.axes1);
imshow(squeeze(cestData(:,:,1,1)),[]);
drawnow;
axes(handles.axes2);
plot(offsets,squeeze(cestData(1,1,1,:)),'.-','MarkerSize',20)
drawnow;
set(handles.axes1,'WindowButtonMotionFcn', @figure1_WindowButtonMotionFcn)

% --- Executes on slider movement.
function sliderSlice_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSlice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global cestData offsets Nslices Noffsets sliceNoSlider offsetNoSlider
if Nslices==1
    sliceNoSlider=1;
else
    sliceNoSlider = round(get(handles.sliderSlice, 'Value'));
end
set(handles.sliderSlice, 'Value', sliceNoSlider);
set(handles.sliceNo, 'String', num2str(sliceNoSlider));
axes(handles.axes1);
imshow(squeeze(cestData(:,:,sliceNoSlider,offsetNoSlider)),[]);
drawnow;
axes(handles.axes2);
plot(offsets,squeeze(cestData(1,1,sliceNoSlider,:)),'.-','MarkerSize',20)
drawnow;
set(handles.axes1,'WindowButtonMotionFcn', @figure1_WindowButtonMotionFcn)

% --- Executes during object creation, after setting all properties.
function sliderSlice_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSlice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
global cestData offsets Nslices Noffsets sliceNoSlider offsetNoSlider
set(hObject, 'min', 1,'max', Nslices, 'Value', 1, 'SliderStep', [1/(Nslices) 1/(Nslices)]);

% --- Executes on slider movement.
function sliderOffset_Callback(hObject, eventdata, handles)
% hObject    handle to sliderOffset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global cestData offsets Nslices Noffsets sliceNoSlider offsetNoSlider
offsetNoSlider = round(get(handles.sliderOffset, 'Value'));
set(handles.sliderOffset, 'Value', offsetNoSlider);
set(handles.offsetNo, 'String', sprintf('%0.2f',offsets(offsetNoSlider)));
axes(handles.axes1);
imshow(squeeze(cestData(:,:,sliceNoSlider,offsetNoSlider)),[]);
drawnow;

% --- Executes during object creation, after setting all properties.
function sliderOffset_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderOffset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
global cestData offsets Nslices Noffsets sliceNoSlider offsetNoSlider
set(hObject, 'min', 1,'max', Noffsets, 'Value', 1, 'SliderStep', [1/(Noffsets-1) 1/(Noffsets-1)]);

% --- Executes on mouse motion over figure - except title and menu.
function figure1_WindowButtonMotionFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global cestData offsets Nslices Noffsets sliceNoSlider offsetNoSlider

C = get(handles.axes1, 'CurrentPoint');
X=round(C(1,1));
Y=round(C(1,2));
if X<=0 || X>=size(cestData,2)
    X=1;
end
if Y<=0 || Y>=size(cestData,1)
    Y=1;
end

if X>=2 && Y>=2
    title(handles.axes1, ['(X,Y) = (', num2str(X), ', ',num2str(Y), ')']);
    axes(handles.axes2);
    xlimMin=str2double(get(handles.axisMin, 'String'));
    xlimMax=str2double(get(handles.axisMax, 'String'));
    plot(offsets,squeeze(cestData(round(Y),round(X),sliceNoSlider,:)),'.-','MarkerSize',20)
    xlim([xlimMin xlimMax])
    set(gca, 'Xdir', 'reverse')
    drawnow;
    grid on
end
axes(handles.axes1);

function axisMin_Callback(hObject, eventdata, handles)
% hObject    handle to axisMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of axisMin as text
%        str2double(get(hObject,'String')) returns contents of axisMin as a double


% --- Executes during object creation, after setting all properties.
function axisMin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axisMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function axisMax_Callback(hObject, eventdata, handles)
% hObject    handle to axisMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of axisMin as text
%        str2double(get(hObject,'String')) returns contents of axisMin as a double


% --- Executes during object creation, after setting all properties.
function axisMax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axisMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
