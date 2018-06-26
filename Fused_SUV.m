function varargout = Fused_SUV(varargin)
% FUSED_SUV M-file for Fused_SUV.fig
%      FUSED_SUV, by itself, creates a new FUSED_SUV or raises the existing
%      singleton*.
%
%      H = FUSED_SUV returns the handle to a new FUSED_SUV or the handle to
%      the existing singleton*.
%
%      FUSED_SUV('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FUSED_SUV.M with the given input arguments.
%
%      FUSED_SUV('Property','Value',...) creates a new FUSED_SUV or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Fused_SUV_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Fused_SUV_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Fused_SUV

% Last Modified by GUIDE v2.5 26-Jun-2018 09:23:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Fused_SUV_OpeningFcn, ...
                   'gui_OutputFcn',  @Fused_SUV_OutputFcn, ...
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


% --- Executes just before Fused_SUV is made visible.
function Fused_SUV_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Fused_SUV (see VARARGIN)

% Choose default command line output for Fused_SUV
handles.output = hObject;
clc

% We are adding analyze read/write files in the following folder.
addpath('LoadNiiFiles')

%Add the AP Segmentation Files for ROI Refinement
addpath('AP_Segmentation')

%Add the PDF Write Files 
addpath('PDF_write')

%Add the current folder to the path so that if the user changes folders the
%GUI will still function!
addpath(pwd)

%Initizalize Some Varables
handles.Settings = {'space','control', 'q'};
handles.Flips = [];
handles.subtract_ROI = false;
handles.add_ROI_motion = false;
handles.add_ROI = false;
handles.zoom = false;
handles.pan_mouse  = false;
handles.pan = false;
handles.datacursor = false;
handles.orientation = 'Axial';
handles.button_down = false;
handles.zoom_down   = false;
handles.C_Bar = false;
%Initialize the opacity variable
handles.Tmap_opacity = 0.3;
handles.thresholded_Tmap = 0.85;

%Show the Fused image as the default
handles.Image_Selected = 'Show Fused';

%Initizalize the Parameters for the AP Segmentation Refinement
handles.AP_Parameters{1} = 255;
handles.AP_Parameters{2} = 20;
handles.AP_Parameters{3} = 3;
handles.AP_Parameters{4} = 1;
handles.AP_Parameters{5} = 20;
handles.AP_Parameters{6} = 0.8;
handles.AP_Parameters{7} = 500;
handles.AP_Parameters{8} = 2;


%Assume that we are going to use 8 different colors for different ROIs
handles.ROINumOfColor = 8; % number of color used for ROI coloring
handles.ROIColorStrings = ['c', 'k','m','r','w','g','b','y','c', 'r']; % color codes for ROI colors
%first ROI color is red..
handles.CurrentROIColor = 1;

%Initizalize the currently selected label!
handles.curr_selection = 1;

%Remove the 'ticks' from the axes
set(handles.axes1,'xtick',[],'ytick',[]);
set(handles.axes2,'xtick',[],'ytick',[]);
set(handles.axes3,'xtick',[],'ytick',[]);


%LOAD THE IMAGES

%Load the Functional image (PET)!
[FileName,PathName] = uigetfile({'*.hdr'; '*.mat'; '*.img'} ,'Load the Functional Image! Analyze or Matlab format');

try    
    %Try to load the image, and catch if the image is the wrong format. 
    if strcmp(FileName(end-2:end), 'hdr')
        %Load image if in Analyze Format
        a = load_nii([PathName FileName]);    
        handles.PET_img = double(a.img);
        handles.PET_pixdim = a.hdr.dime.pixdim(2:4);    
        handles.hdr = a;
        %Rotate image!
        for z = 1:size(handles.PET_img,3)
            handles.PET_img(:,:,z) = imrotate(handles.PET_img(:,:,z), 90);    
        end      
        %Get the pixel physical size dimensions for the volume calculation.
        handles.pixdim_PET = a.hdr.dime.pixdim(2:4);      
    elseif strcmp(FileName(end-2:end), 'mat')    
        %Load image if in Matlab Format
        a = load([PathName FileName]);
        try
            handles.PET_img = double(a.img);
        catch
            error('When loading matlab images, image variable must include a structure format  "xxx.img".')
        end
        %If using Matlab format, pixdim is assumed to be 1mm x 1mm x 1mm for
        %the volume calculations. 
        handles.pixdim_PET = [1 1 1];        
    end
end



%Load the Anatomical image (CT or MRI)!
[FileName,PathName] = uigetfile({'*.hdr'; '*.mat'; '*.img'} ,'Load the Anatomical Image! Analyze or Matlab format');
try    
    %Try to load the image, and catch if the image is the wrong format. 
    if strcmp(FileName(end-2:end), 'hdr')
        %Load image if in Analyze Format
        a = load_nii([PathName FileName]);
        handles.CT_img = double(a.img);
        handles.CT_pixdim = a.hdr.dime.pixdim(2:4);
         for z = 1:size(handles.CT_img,3)
            handles.CT_img(:,:,z) = imrotate(handles.CT_img(:,:,z), 90);
         end
        %Get the pixel physical size dimensions for the volume calculation.
        handles.pixdim_CT = a.hdr.dime.pixdim(2:4);      
    elseif strcmp(FileName(end-2:end), 'mat')    
        %Load image if in Matlab Format
        a = load([PathName FileName]);
        try
            handles.CT_img = double(a.img);
        catch
            error('When loading matlab images, image variable must be name "img".')
        end
        %If using Matlab format, pixdim is assumed to be 1mm x 1mm x 1mm for
        %the volume calculations. 
        handles.pixdim_CT = [1 1 1];
       
    end
end

%Set the filename boxes in the GUI to the image filenames 
set(handles.PET_Filename_Edit, 'String', FileName);
set(handles.CT_Filename_Edit, 'String', FileName);

%Initialize the contrast adjustment variables to the maximum and minimum of
%the image when the user loads it.
handles.PET_contrast_min = 0;
handles.PET_contrast_max = max(handles.PET_img(:))*.2;

%Initialize the contrast adjustment variables to the maximum and minimum of
%the image when the user loads it.
handles.CT_contrast_min = -max(handles.CT_img(:))*.1;
handles.CT_contrast_max = max(handles.CT_img(:))*.2;

%Initialize the ROI
handles.currentROIindex (1:size(handles.PET_img,3))= 0;
handles.ROI = zeros(size(handles.PET_img));

%Set slider values based on the number of slices of the loaded image
slider_max = size(handles.PET_img, 3);

%Set the current slice to be the middle slice of the loaded image!
handles.curr_slice = round(slider_max/2);
set(handles.Slice_Slider, 'Min', 0);
set(handles.Slice_Slider, 'Max', slider_max);
set(handles.Slice_Slider, 'Value', handles.curr_slice);
set(handles.Slice_Slider, 'SliderStep', [1 5]/(slider_max));

handles.colormap = 'Jet';
handles.XL = xlim;
handles.YL = ylim;

%Update the axes with the now loaded images!
update_images(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Fused_SUV wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Executes on button press in open_functional_image.
function open_functional_image_Callback(hObject, eventdata, handles)
% hObject    handle to open_functional_image (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
                   
%Load the Functional image (PET)!
[FileName,PathName] = uigetfile({'*.hdr'; '*.mat'; '*.img'} ,'Select the Analyze Image file or MATLAB image file');

 
%Try to load the image, and catch if the image is the wrong format. 
if strcmp(FileName(end-2:end), 'hdr')
    %Load image if in Analyze Format
    a = load_nii([PathName FileName]);    
    handles.PET_img = double(a.img);
    handles.PET_pixdim = a.hdr.dime.pixdim(2:4);
    handles.hdr = a;
    %Rotate image!
    for z = 1:size(handles.PET_img,3)
        handles.PET_img(:,:,z) = imrotate(handles.PET_img(:,:,z), -90);   
        handles.PET_img(:,:,z) = fliplr(handles.PET_img(:,:,z));        
    end      
    %Get the pixel physical size dimensions for the volume calculation.
    handles.pixdim_PET = a.hdr.dime.pixdim(2:4);      
elseif strcmp(FileName(end-2:end), 'mat')    
    %Load image if in Matlab Format
    a = load([PathName FileName]);
    try
        handles.PET_img = double(a.img);
    catch
        error('When loading matlab images, image variable must include a structure format  "xxx.img".')
    end
    %If using Matlab format, pixdim is assumed to be 1mm x 1mm x 1mm for
    %the volume calculations. 
    handles.pixdim_PET = [1 1 1];
end

set(handles.PET_Filename_Edit, 'String', FileName)

%Set slider values based on the number of slices of the loaded image
slider_max = size(handles.PET_img, 3);

%Set the current slice to be the middle slice of the loaded image!
handles.curr_slice = round(slider_max/2);

set(handles.Slice_Slider, 'Min', 0);
set(handles.Slice_Slider, 'Max', slider_max);
set(handles.Slice_Slider, 'Value', handles.curr_slice);
set(handles.Slice_Slider, 'SliderStep', [1 5]/(slider_max));


%Initialize the contrast adjustment variables to the maximum and minimum of
%the image when the user loads it.
handles.PET_contrast_min = 0;
handles.PET_contrast_max = max(handles.PET_img(:))*.2;

freezeColors
%Show the current slice of the PET image
handles.colormap = 'Jet';
set(gcf, 'CurrentAxes',handles.axes1);
cla 
imagesc(handles.PET_img(:,:,handles.curr_slice), [handles.PET_contrast_min handles.PET_contrast_max])
colormap(handles.colormap)
axis off;

%Initialize the ROI
handles.currentROIindex (1:size(handles.PET_img,3))= 0;
handles.ROI = zeros(size(handles.PET_img));

child_handles = allchild(handles.axes1);
set(child_handles,'buttondownfcn',{@axes1_ButtonDownFcn,handles});

handles.PET_min = min(handles.PET_img(:));
handles.PET_max = max(handles.PET_img(:));

% Update handles structure
guidata(hObject, handles);




% --- Executes on button press in open_anatomical_image.
function open_anatomical_image_Callback(hObject, eventdata, handles)
% hObject    handle to open_anatomical_image (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Load the Anatomical image (CT or MRI)!
[FileName,PathName] = uigetfile({'*.hdr'; '*.mat'; '*.img'} ,'Select the Analyze Image file or MATLAB image file');

%Try to load the image, and catch if the image is the wrong format. 
try
    if strcmp(FileName(end-2:end), 'hdr')
        %Load image if in Analyze Format
        a = load_nii([PathName FileName]);

        handles.CT_img = double(a.img);
        handles.CT_pixdim = a.hdr.dime.pixdim(2:4);

         for z = 1:size(handles.CT_img,3)
            handles.CT_img(:,:,z) = imrotate(handles.CT_img(:,:,z), -90); 
            handles.CT_img(:,:,z) = fliplr(handles.CT_img(:,:,z));
         end


        %Get the pixel physical size dimensions for the volume calculation.
        handles.pixdim_CT = a.hdr.dime.pixdim(2:4);      
    elseif strcmp(FileName(end-2:end), 'mat')    
        %Load image if in Matlab Format
        a = load([PathName FileName]);
        try
            handles.CT_img = double(a.img);
        catch
            error('When loading matlab images, image variable must be name "img".')
        end
        %If using Matlab format, pixdim is assumed to be 1mm x 1mm x 1mm for
        %the volume calculations. 
        handles.pixdim_CT = [1 1 1];
    end


    set(handles.CT_Filename_Edit, 'String', FileName)

    %Set slider values based on the number of slices of the loaded image
    slider_max = size(handles.CT_img, 3);

    %Set the current slice to be the middle slice of the loaded image!
    handles.curr_slice = round(slider_max/2);
    % handles.curr_slice = round(slider_max/2);


    set(handles.Slice_Slider, 'Min', 0);
    set(handles.Slice_Slider, 'Max', slider_max);
    set(handles.Slice_Slider, 'Value', handles.curr_slice);
    set(handles.Slice_Slider, 'SliderStep', [1 5]/(slider_max));


    %Initialize the contrast adjustment variables to the maximum and minimum of
    %the image when the user loads it.
    handles.CT_contrast_min = -max(handles.CT_img(:))*.1;
    handles.CT_contrast_max = max(handles.CT_img(:))*.2;

    freezeColors
    
    %Show the current slice of the PET image
    handles.colormap = 'gray';
    set(gcf, 'CurrentAxes',handles.axes2);
    cla reset
    imagesc(handles.CT_img(:,:,handles.curr_slice), [handles.CT_contrast_min handles.CT_contrast_max])
    colormap(handles.colormap)
    axis off;
catch
    'Error loading Anatomical image!'
end

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in load_ROI_button.
function load_ROI_button_Callback(hObject, eventdata, handles)
% hObject    handle to load_ROI_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 
%Try to load the image, and catch if the image is the wrong format. 
try               
    %Load an ROI!
    [FileName,PathName] = uigetfile({'*.hdr'; '*.img'; '*.mat'} ,'Select the Analyze Image file or MATLAB image file');

    if strcmp(FileName(end-2:end), 'hdr')
        %Load image if in Analyze Format
        a = load_nii([PathName FileName]);    
        temp_ROI = double(a.img);
    elseif strcmp(FileName(end-2:end), 'img')
        %Load image if in Analyze Format
        a = load_nii([PathName FileName]);    
        temp_ROI  = double(a.img);
    elseif strcmp(FileName(end-2:end), 'mat')
        load([PathName FileName])    
        temp_ROI  = bin;
        temp_ROI(temp_ROI~=0) = 1;
    end
catch         
    'Problem loading ROI!'        
end

%ADD LABEL THEN ADD THE NEW ROI TO THAT LABEL
Label_List = cellstr(get(handles.listbox1,'String'));

if handles.curr_selection < 1 
    handles.curr_selection = 1;
    set(handles.listbox1,'Value',handles.curr_selection);
end

if get(handles.listbox1,'Value') < 1
    set(handles.listbox1,'Value', 1)
end

%Find the lowest number that isn't on the list already!
temp = [];
for i = 1:size(Label_List,1)    
    temp = [temp Label_List{i}(end-4)];
end

num = [];
for i = 1:size(Label_List,1) 
    if ~any(temp == num2str(i))
        num = i;
        break
    end
end

if isempty(num)
    num = size(Label_List,1) + 1;    
end

if isempty(Label_List)
    new_name = {'Label 1'};
else
    new_name = [Label_List;{['Label ' num2str(num)]}];
end

new_name{end} = [new_name{end} '   ' handles.ROIColorStrings(rem(length(new_name),9)+1)];
set(handles.listbox1,'String',new_name)
handles.ROI(temp_ROI == 1) = num;

%Update images with the new ROI
update_images(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);




% --- Executes on slider movement.
function Slice_Slider_Callback(hObject, eventdata, handles)
% hObject    handle to Slice_Slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

%Get the current slice from the slider!
handles.curr_slice = round(get(hObject, 'Value'));

if handles.datacursor == true    
    %%%UPDATE THE IMAGE IN THE SUV DATA CURSOR CALLBACK%%%    
    %Get the weight and dosage for converting the PET image to SUV 
    weight    = str2num(get(handles.weight, 'String'));
    dose      = str2num(get(handles.dosage, 'String'));
    time      = str2num(get(handles.scan_time, 'String'));
    half_life = str2num(get(handles.half_life, 'String'));
    %Calculate the decay foctor correction!
    decay_factor  = 2^(-time*60/half_life);    
    dcm_obj = datacursormode(gcf);
    set(dcm_obj,'UpdateFcn',{@myupdatefcn, handles.PET_img(:,:,handles.curr_slice),weight,decay_factor,dose})    
end   
    
update_images(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);




function update_images(hObject, eventdata, handles)

%Get the weight and dosage for the SUV calculation
weight    = str2num(get(handles.weight, 'String'));
dose      = str2num(get(handles.dosage, 'String'));
time      = str2num(get(handles.scan_time, 'String'));
half_life = str2num(get(handles.half_life, 'String'));

%Calculate the decay foctor correction!
decay_factor  = 2^(-time*60/half_life);

%Find the current zoom level
handles.XL = xlim;
handles.YL = ylim;

%Show the current slice of the PET image
set(gcf, 'CurrentAxes',handles.axes1);
cla
imagesc(handles.PET_img(:,:,handles.curr_slice), [handles.PET_contrast_min handles.PET_contrast_max]);
colormap Jet
axis off;
freezeColors

child_handles = allchild(handles.axes1);
set(child_handles,'buttondownfcn',{@axes1_ButtonDownFcn,handles});

%Show the current slice of the CT image
set(gcf, 'CurrentAxes',handles.axes2);
cla
imagesc(handles.CT_img(:,:,handles.curr_slice), [handles.CT_contrast_min handles.CT_contrast_max]);
colormap Gray
axis off;
freezeColors

child_handles = allchild(handles.axes2);
set(child_handles,'buttondownfcn',{@axes2_ButtonDownFcn,handles});

%Does the user want to show the fused image or the functional or anatomical?
set(gcf, 'CurrentAxes',handles.axes3);
cla
if strcmp(handles.Image_Selected, 'Show Functional')         
    imagesc(handles.PET_img(:,:,handles.curr_slice)*weight/(decay_factor*dose), [handles.PET_contrast_min*weight/(decay_factor*dose) handles.PET_contrast_max*weight/(decay_factor*dose)])
    handles.colormap  = 'Jet';        
elseif strcmp(handles.Image_Selected, 'Show Anatomical')       
    imagesc(handles.CT_img(:,:,handles.curr_slice), [handles.CT_contrast_min handles.CT_contrast_max])
    handles.colormap  = 'gray';
elseif strcmp(handles.Image_Selected, 'Show Fused') 
%     handles.thresholded_Tmap = .2;
    compound_RGB  = fusemripet(handles.CT_img(:,:,handles.curr_slice),handles.PET_img(:,:,handles.curr_slice),  handles.Tmap_opacity, handles.thresholded_Tmap);
    imagesc(compound_RGB);     
end

colormap(handles.colormap)

try
    if any(find(handles.ROI(:,:,handles.curr_slice)~=0))
        hold on
            ROI = handles.ROI(:,:,handles.curr_slice);
            Labels = unique(ROI(:));
            for i = 2:length(Labels)
                temp_roi = ROI;
                temp_roi(temp_roi~=Labels(i)) = 0;
                B = bwboundaries(temp_roi);        

                %Get the color of the current label!
                Label_List = cellstr(get(handles.listbox1,'String'));   
                curr_color = Label_List{Labels(i)}(end);          
                for k = 1:length(B)   
                    plot(B{k}(:,2),B{k}(:,1), curr_color, 'LineWidth', 4)
                end
            end
        %Calculate the SUV metrics given the ROI
        SUV_calculations(hObject, eventdata, handles)
    else
        set(handles.SUV_max_edit, 'String', 0)
        set(handles.SUV_mean_edit, 'String', 0)
        set(handles.CT_mean_edit, 'String', 0)    
    end  
catch
    
end
%Update the slice number!!
set(handles.edit_Slice_Number, 'String', num2str(handles.curr_slice));
axis tight

%Remove the 'ticks' from the axes
set(handles.axes3,'xtick',[],'ytick',[])

%Fix the zoom level when first loading the images!!
if handles.XL == [0 1]
    handles.XL = xlim;
    handles.YL = ylim;     
end

%Keep the zoom level 
xlim(handles.XL)
ylim(handles.YL)


% --- Executes on slider movement.
function Opacity_Slider_Callback(hObject, eventdata, handles)
% hObject    handle to Opacity_Slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.Tmap_opacity = get(hObject,'Value');
update_images(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function Opacity_Slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Opacity_Slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end




% --- Executes during object creation, after setting all properties.
function Slice_Slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Slice_Slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in add_ROI_button.
function add_ROI_button_Callback(hObject, eventdata, handles)
% hObject    handle to add_ROI_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Set add_ROI to true so the mouse motion is tracked when moved!
handles.add_ROI = true;

%Reset the BIN for the mouse tracking step to store the points
handles.BIN = [];

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in subtract_ROI_button.
function subtract_ROI_button_Callback(hObject, eventdata, handles)
% hObject    handle to subtract_ROI_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Set subtract_ROI to true so the mouse motion is tracked when moved!
handles.subtract_ROI = true;

%Reset the BIN for the mouse tracking step to store the points
handles.BIN = [];

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in delete_ROI_button.
function delete_ROI_button_Callback(hObject, eventdata, handles)
% hObject    handle to delete_ROI_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%Reset the ROI for the current label!!
handles.ROI(handles.ROI == handles.curr_selection) = 0;
update_images(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);


function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function weight_Callback(hObject, eventdata, handles)
% hObject    handle to weight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of weight as text
%        str2double(get(hObject,'String')) returns contents of weight as a double


% --- Executes during object creation, after setting all properties.
function weight_CreateFcn(hObject, eventdata, handles)
% hObject    handle to weight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dosage_Callback(hObject, eventdata, handles)
% hObject    handle to dosage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dosage as text
%        str2double(get(hObject,'String')) returns contents of dosage as a double


% --- Executes during object creation, after setting all properties.
function dosage_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dosage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function scan_time_Callback(hObject, eventdata, handles)
% hObject    handle to scan_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of scan_time as text
%        str2double(get(hObject,'String')) returns contents of scan_time as a double


% --- Executes during object creation, after setting all properties.
function scan_time_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scan_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function half_life_Callback(hObject, eventdata, handles)
% hObject    handle to half_life (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of half_life as text
%        str2double(get(hObject,'String')) returns contents of half_life as a double


% --- Executes during object creation, after setting all properties.
function half_life_CreateFcn(hObject, eventdata, handles)
% hObject    handle to half_life (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popup_Image_select.
function popup_Image_select_Callback(hObject, eventdata, handles)
% hObject    handle to popup_Image_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popup_Image_select contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popup_Image_select

%Change between Show Functional, Anatomical, or Fused!
contents = cellstr(get(hObject,'String'));
handles.Image_Selected = contents{get(hObject,'Value')};

update_images(hObject, eventdata, handles);
  
% Update handles structure
guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function popup_Image_select_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_Image_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SUV_max_edit_Callback(hObject, eventdata, handles)
% hObject    handle to SUV_max_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SUV_max_edit as text
%        str2double(get(hObject,'String')) returns contents of SUV_max_edit as a double


% --- Executes during object creation, after setting all properties.
function SUV_max_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SUV_max_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SUV_mean_edit_Callback(hObject, eventdata, handles)
% hObject    handle to SUV_mean_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SUV_mean_edit as text
%        str2double(get(hObject,'String')) returns contents of SUV_mean_edit as a double


% --- Executes during object creation, after setting all properties.
function SUV_mean_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SUV_mean_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SUV_calculations(hObject, eventdata, handles)

%Calculate the SUVmax and SUVmean of the current slice/ROI

%Get the weight and dosage for the SUV calculation
weight    = str2num(get(handles.weight, 'String'));
dose      = str2num(get(handles.dosage, 'String'));
time      = str2num(get(handles.scan_time, 'String'));
half_life = str2num(get(handles.half_life, 'String'));


temp_img = handles.PET_img(:,:,handles.curr_slice);
BW = handles.ROI(:,:,handles.curr_slice);
BW(BW~=handles.curr_selection) = 0;
BW(BW~=0) = 1;

temp_img = temp_img.*BW;

%Calculate the decay foctor correction!
decay_factor  = 2^(-time*60/half_life);

SUV_max = max(temp_img(:)*weight)/(decay_factor*dose);
SUV_mean = mean(temp_img(temp_img~=0)*weight)/(decay_factor*dose);
            
if isnan(SUV_mean)
    SUV_mean = 0;
end

set(handles.SUV_max_edit, 'String', SUV_max)
set(handles.SUV_mean_edit, 'String', SUV_mean)

temp_img2 = handles.CT_img(:,:,handles.curr_slice).*BW;
CT_mean = mean(temp_img2(:));
set(handles.CT_mean_edit, 'String', CT_mean)

function edit_Slice_Number_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Slice_Number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_Slice_Number as text
%        str2double(get(hObject,'String')) returns contents of edit_Slice_Number as a double


% --- Executes during object creation, after setting all properties.
function edit_Slice_Number_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Slice_Number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function CT_mean_edit_Callback(hObject, eventdata, handles)
% hObject    handle to CT_mean_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of CT_mean_edit as text
%        str2double(get(hObject,'String')) returns contents of CT_mean_edit as a double


% --- Executes during object creation, after setting all properties.
function CT_mean_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to CT_mean_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in contrast_button.
function contrast_button_Callback(hObject, eventdata, handles)
% hObject    handle to contrast_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Reset the contrast to the initial values!
handles.PET_contrast_min = 0;
handles.PET_contrast_max = max(handles.PET_img(:))*.8;

handles.CT_contrast_min = min(handles.CT_img(:));
handles.CT_contrast_max = max(handles.CT_img(:))*.5;

handles.thresholded_Tmap = 0.85;

update_images(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in zoom_button.
function zoom_button_Callback(hObject, eventdata, handles)
% hObject    handle to zoom_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Turn zoom on
if handles.zoom == false  
    zoom on
    pan off
    handles.zoom = true;
else
    zoom off
    pan off
    handles.zoom = false;
end

datacursormode off

linkaxes([handles.axes1 handles.axes2 handles.axes3], 'xy')

guidata(hObject, handles);


% --- Executes on button press in pan_button.
function pan_button_Callback(hObject, eventdata, handles)
% hObject    handle to pan_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Turn pan on
if handles.pan == false  
    zoom off
    pan on
    handles.pan = true;
else
    zoom off
    pan off
    handles.pan = false;
end

datacursormode off

guidata(hObject, handles);


% --- Executes on scroll wheel click while the figure is in focus.
function figure1_WindowScrollWheelFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	VerticalScrollCount: signed integer indicating direction and number of clicks
%	VerticalScrollAmount: number of lines scrolled for each click
% handles    structure with handles and user data (see GUIDATA)

handles.curr_slice = handles.curr_slice - eventdata.VerticalScrollCount;

%Update the slider to the current slice value!
set(handles.Slice_Slider, 'Value', handles.curr_slice);

update_images(hObject, eventdata, handles)

guidata(hObject, handles);



function PET_threshold_edit_Callback(hObject, eventdata, handles)
% hObject    handle to PET_threshold_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PET_threshold_edit as text
%        str2double(get(hObject,'String')) returns contents of PET_threshold_edit as a double


% --- Executes during object creation, after setting all properties.
function PET_threshold_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PET_threshold_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function CT_threshold_edit_Callback(hObject, eventdata, handles)
% hObject    handle to CT_threshold_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of CT_threshold_edit as text
%        str2double(get(hObject,'String')) returns contents of CT_threshold_edit as a double


% --- Executes during object creation, after setting all properties.
function CT_threshold_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to CT_threshold_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function PET_volume_edit_Callback(hObject, eventdata, handles)
% hObject    handle to PET_volume_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PET_volume_edit as text
%        str2double(get(hObject,'String')) returns contents of PET_volume_edit as a double


% --- Executes during object creation, after setting all properties.
function PET_volume_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PET_volume_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function CT_volume_edit_Callback(hObject, eventdata, handles)
% hObject    handle to CT_volume_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of CT_volume_edit as text
%        str2double(get(hObject,'String')) returns contents of CT_volume_edit as a double


% --- Executes during object creation, after setting all properties.
function CT_volume_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to CT_volume_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function figure1_WindowKeyPressFcn(hObject, eventdata, handles)


guidata(hObject, handles);


% --- Executes on button press in data_button.
function data_button_Callback(hObject, eventdata, handles)
% hObject    handle to data_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Turn data cursor on
if handles.datacursor == false      
    datacursormode on    
    %Get the weight and dosage for converting the PET image to SUV 
    weight    = str2num(get(handles.weight, 'String'));
    dose      = str2num(get(handles.dosage, 'String'));
    time      = str2num(get(handles.scan_time, 'String'));
    half_life = str2num(get(handles.half_life, 'String'));


    %Calculate the decay foctor correction!
    decay_factor  = 2^(-time*60/half_life);
    dcm_obj = datacursormode(gcf);
    
    set(dcm_obj,'UpdateFcn',{@myupdatefcn, handles.PET_img(:,:,handles.curr_slice),weight,decay_factor,dose})
    
    handles.datacursor = true;
else
   datacursormode off
    handles.datacursor = false;
end

zoom off
pan off

guidata(hObject, handles);




function output_txt = myupdatefcn(~, event_obj, PET_img,weight,decay_factor,dose)
% ~            Currently not used (empty)
% event_obj    Object containing event data structure
% output_txt   Data cursor text (string or cell array of strings)

figHandles = findall(0,'Type','figure');

alldatacursors = findall(figHandles(1),'type','hggroup');
set(alldatacursors,'FontSize',16);

temp = round(event_obj.Position);
SUV_at_cursor = PET_img(temp(2), temp(1))*weight/(decay_factor*dose);

%Round to 2 decimal places!
SUV_at_cursor = round(SUV_at_cursor*100)/100;

output_txt = ['SUV: ' num2str(SUV_at_cursor)];

% --- Executes on mouse press over axes background.
function axes3_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



guidata(hObject, handles);


% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure1_WindowButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% 
% handles = guidata( ancestor(hObject, 'figure') );

% Settings Here

if any(handles.add_ROI == true | handles.subtract_ROI == true)  
    handles.add_ROI_motion = true;
else    
    which_button = get(gcf,'SelectionType');
    switch which_button
        case 'alt' % click right mouse button
             handles.pan_mouse = true;         
        case 'normal' % left mouse button
            handles.button_down = true;        
        case 'extended' % Shift+click left mouse button    

        case 'extend' % Shift+click left mouse button             
            handles.zoom_down = true;
            axis tight
        case 'open' % Double click any mouse button            
            %Reset the current zoom level!
            handles.YL = [0 size(handles.PET_img, 1)];
            handles.XL = [0 size(handles.PET_img, 2)];
            
            %Keep the zoom level 
            xlim(handles.XL)
            ylim(handles.YL)            
            update_images(hObject, eventdata, handles)             
    end    
end
handles.mouse_point = get(handles.axes3,'currentpoint'); 

% Update handles structure
guidata(hObject, handles);


% --- Executes on mouse press over axes background.
function axes1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.Image_Selected = 'Show Functional';
set(handles.popup_Image_select,'Value',2);

%Keep the zoom level 
xlim(handles.XL)
ylim(handles.YL)

update_images(hObject, eventdata, handles)
hObject = gcf;

% Update handles structure
guidata(hObject, handles);


% --- Executes on mouse press over axes background.
function axes2_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB


handles.Image_Selected = 'Show Anatomical';
set(handles.popup_Image_select,'Value',3);

%Keep the zoom level 
xlim(handles.XL)
ylim(handles.YL)

update_images(hObject, eventdata, handles)
hObject = gcf;

% Update handles structure
guidata(hObject, handles);


% --- Executes on mouse motion over figure - except title and menu.
function figure1_WindowButtonMotionFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Get the weight and dosage for the SUV calculation
weight    = str2num(get(handles.weight, 'String'));
dose      = str2num(get(handles.dosage, 'String'));
time      = str2num(get(handles.scan_time, 'String'));
half_life = str2num(get(handles.half_life, 'String'));

%Calculate the decay foctor correction!
decay_factor  = 2^(-time*60/half_life);

% handles = guidata( ancestor(hObject, 'figure') );
if handles.button_down == true
    
    coords = get(handles.axes3,'currentpoint');   
    change = coords - handles.mouse_point;
    
    if strcmp(handles.Image_Selected, 'Show Functional') 
        %Contrast adjustment    
        handles.PET_contrast_min = handles.PET_contrast_min - change(1,1);
        handles.PET_contrast_max = handles.PET_contrast_max + change(1,1);

        %Brightness adjustment!! 
        handles.PET_contrast_min = handles.PET_contrast_min + change(1,2);
        handles.PET_contrast_max = handles.PET_contrast_max + change(1,2);
        
        %Check and make sure the max is larger than the min!
        if handles.PET_contrast_max <= handles.PET_contrast_min
            handles.PET_contrast_max = handles.PET_contrast_min + 1; 
        end
        
        %Show the current slice of the PET image
        set(gcf, 'CurrentAxes',handles.axes3); 
        imagesc(handles.PET_img(:,:,handles.curr_slice), [handles.PET_contrast_min handles.PET_contrast_max])
        handles.colormap = 'Jet';
        colormap(handles.colormap)

    elseif strcmp(handles.Image_Selected, 'Show Anatomical') 
        handles.Show_Image = handles.CT_img(:,:,handles.curr_slice);
        handles.colormap  = 'gray';         

        %Contrast adjustment    
        handles.CT_contrast_min = handles.CT_contrast_min - change(1,1);
        handles.CT_contrast_max = handles.CT_contrast_max + change(1,1);

        %Brightness adjustment!! 
        handles.CT_contrast_min  = handles.CT_contrast_min + change(1,2);
        handles.CT_contrast_max = handles.CT_contrast_max + change(1,2);

        %Check and make sure the max is larger than the min!
        if handles.CT_contrast_max <= handles.CT_contrast_min
           handles.CT_contrast_max = handles.CT_contrast_min + 1; 
        end
                
        set(gcf, 'CurrentAxes',handles.axes3);    
        imagesc(handles.CT_img(:,:,handles.curr_slice), [handles.CT_contrast_min handles.CT_contrast_max])
        colormap(handles.colormap)       
        
    elseif strcmp(handles.Image_Selected, 'Show Fused') 

        handles.Tmap_opacity = handles.Tmap_opacity + 0.001*change(1,2);
        
        if handles.Tmap_opacity < 0 
            handles.Tmap_opacity = 0;
        elseif handles.Tmap_opacity > 1
            handles.Tmap_opacity =1;
        end
        
        handles.thresholded_Tmap = handles.thresholded_Tmap + 0.001*change(1,1);
        if handles.thresholded_Tmap < 0 
            handles.thresholded_Tmap = 0;
        elseif handles.thresholded_Tmap > 1
            handles.thresholded_Tmap =1;
        end
        
       %Move the slider!
        set(handles.Opacity_Slider, 'Value', handles.Tmap_opacity);
        compound_RGB  = fusemripet(handles.CT_img(:,:,handles.curr_slice),handles.PET_img(:,:,handles.curr_slice),  handles.Tmap_opacity, handles.thresholded_Tmap);
        imagesc(compound_RGB);        
    end
    
    %Keep the zoom level 
    xlim(handles.XL)
    ylim(handles.YL)
     
elseif handles.zoom_down == true      
    coords = get(handles.axes3,'currentpoint');
    change = coords - handles.mouse_point;    
    set(gcf, 'CurrentAxes',handles.axes3); 
    zoom(abs(change(1,2)*.01) + abs(change(1,1)*.01))
    
elseif handles.pan_mouse == true    
            
    coords = get(handles.axes3,'currentpoint');
    change = coords - handles.mouse_point;      


    set(gcf, 'CurrentAxes',handles.axes3);      
    handles.XL = xlim + change(1,1)*.01;
    handles.YL = ylim + change(1,2)*.01;    

    xlim(handles.XL)
    ylim(handles.YL)   
   
elseif handles.add_ROI_motion == true   
    
    coords = get(handles.axes3,'currentpoint');   
    handles.BIN = [handles.BIN; coords(1,1:2)];
    
    set(gcf, 'CurrentAxes',handles.axes3);   
    hold on 
    plot(handles.BIN(:,1), handles.BIN(:,2), '-mo',...
                'LineWidth',2,...
                'MarkerEdgeColor','k',...
                'MarkerFaceColor',[.49 1 .63],...
                'MarkerSize',7)   
end

axis off;

% Update handles structure
guidata(hObject, handles);



% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure1_WindowButtonUpFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Find the current zoom level
handles.XL = xlim;
handles.YL = ylim;

handles.button_down = false;
handles.zoom_down = false;
handles.pan_mouse = false;

%Keep the zoom level 
xlim(handles.XL)
ylim(handles.YL)

if handles.add_ROI == true
    handles.add_ROI_motion = false;
    handles.add_ROI = false;    
    x = handles.BIN(:,1);
    y = handles.BIN(:,2);
    [r c z] = size(handles.PET_img);
    %Create a mask from the convexhull!!
    mask = poly2mask(x, y, r, c);

    %Save the ROI Before Changing to potentially undo this!
    handles.Undo = handles.ROI;   
    
    temp_ROI = handles.ROI(:,:,handles.curr_slice);
    
    %Use the CURRENT LABEL for the ROI Addition
    temp_ROI(mask == 1) = handles.curr_selection;
    handles.ROI(:,:,handles.curr_slice) = temp_ROI;

    handles.currentROIindex(handles.curr_slice) = 1; 
   
elseif handles.subtract_ROI == true    
    handles.add_ROI_motion = false;
    handles.subtract_ROI = false;    
    x = handles.BIN(:,1);
    y = handles.BIN(:,2);
  
    [r c z] = size(handles.PET_img);
    %Create a mask from the convexhull!!
    mask = poly2mask(x, y, r, c);
    
    %Save the ROI Before Changing to potentially undo this!
    handles.Undo = handles.ROI;   
    
    temp_ROI = handles.ROI(:,:,handles.curr_slice);    
    temp_Label = temp_ROI;    
    
    %Use the CURRENT LABEL for the ROI Addition
    temp_Label(temp_ROI ~= handles.curr_selection) = 0;
    temp_Label(temp_Label~=0) = 1;

    temp = mask.*temp_Label.*handles.curr_selection;       
    handles.ROI(:,:,handles.curr_slice) = handles.ROI(:,:,handles.curr_slice) - temp; 
    handles.currentROIindex(handles.curr_slice) = 1;    
    
end

handles.subtract_ROI = false;
handles.add_ROI = false; 
handles.add_ROI_motion = false;

update_images(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in Sagittal_Button.
function Sagittal_Button_Callback(hObject, eventdata, handles)
% hObject    handle to Sagittal_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%Skip if the images are in Sagittal already
if ~strcmp(handles.orientation,'Sagittal')
    if strcmp(handles.orientation,'Axial')
                
        [handles.PET_img handles.CT_img handles.ROI handles.Flips] = undo_Flips(handles.PET_img, handles.CT_img, handles.ROI, handles.Flips);     

        %Rotate the 3D images since they are in Axial view already!
        handles.PET_img = permute(handles.PET_img, [1 3 2]);
        handles.CT_img  = permute(handles.CT_img,  [1 3 2]);
        handles.ROI     = permute(handles.ROI,  [1 3 2]);
                
    elseif strcmp(handles.orientation,'Coronal')       
        
       [handles.PET_img handles.CT_img handles.ROI handles.Flips] = undo_Flips(handles.PET_img, handles.CT_img, handles.ROI, handles.Flips);     
        
       %Rotate the 3D images  back to Axial view then flip to Saggital!
        handles.PET_img = ipermute(handles.PET_img, [3 2 1]);
        handles.CT_img  = ipermute(handles.CT_img,  [3 2 1]);
        handles.ROI     = ipermute(handles.ROI,  [3 2 1]);

        %Now the images are in axial and rotate to Saggital!
        handles.PET_img = permute(handles.PET_img, [1 3 2]);
        handles.CT_img  = permute(handles.CT_img,  [1 3 2]);
        handles.ROI     = permute(handles.ROI,  [1 3 2]);
    end
    
    %Reset the Slider values!

    %Set slider values based on the number of slices of the loaded image
    slider_max = size(handles.PET_img, 3);

    %Set the current slice to be the middle slice of the loaded image!
    handles.curr_slice = round(slider_max/2);

    set(handles.Slice_Slider, 'Min', 0);
    set(handles.Slice_Slider, 'Max', slider_max);
    set(handles.Slice_Slider, 'Value', handles.curr_slice);
    set(handles.Slice_Slider, 'SliderStep', [1 5]/(slider_max));

    %Reset the current zoom level
    handles.YL = [0 size(handles.PET_img, 1)];
    handles.XL = [0 size(handles.PET_img, 2)];
    
    %Keep the zoom level 
    xlim(handles.XL)
    ylim(handles.YL)
    
    update_images(hObject, eventdata, handles)
else    
    [handles.PET_img handles.CT_img handles.ROI handles.Flips] = undo_Flips(handles.PET_img, handles.CT_img, handles.ROI, handles.Flips);
    update_images(hObject, eventdata, handles)
end

handles.orientation = 'Sagittal';

'Sagittal'

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in Axial_Button.
function Axial_Button_Callback(hObject, eventdata, handles)
% hObject    handle to Axial_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Skip if the images are in Sagittal already
if ~strcmp(handles.orientation,'Axial')
    if strcmp(handles.orientation,'Sagittal')
       [handles.PET_img handles.CT_img handles.ROI handles.Flips] = undo_Flips(handles.PET_img, handles.CT_img, handles.ROI, handles.Flips);
                   
        %Rotate the 3D images back to Axial view!
        handles.PET_img = ipermute(handles.PET_img, [1 3 2]);
        handles.CT_img  = ipermute(handles.CT_img,  [1 3 2]);
        handles.ROI     = ipermute(handles.ROI,  [1 3 2]);
    
    elseif strcmp(handles.orientation,'Coronal')
        
       [handles.PET_img handles.CT_img handles.ROI handles.Flips] = undo_Flips(handles.PET_img, handles.CT_img, handles.ROI, handles.Flips);
     
       %Rotate the 3D images  back to Axial view!
        handles.PET_img = ipermute(handles.PET_img, [3 2 1]);
        handles.CT_img  = ipermute(handles.CT_img,  [3 2 1]);
        handles.ROI     = ipermute(handles.ROI,  [3 2 1]);
    end

    %Reset the Slider values!

    %Set slider values based on the number of slices of the loaded image
    slider_max = size(handles.PET_img, 3);

    %Set the current slice to be the middle slice of the loaded image!
    handles.curr_slice = round(slider_max/2);

    set(handles.Slice_Slider, 'Min', 0);
    set(handles.Slice_Slider, 'Max', slider_max);
    set(handles.Slice_Slider, 'Value', handles.curr_slice);
    set(handles.Slice_Slider, 'SliderStep', [1 5]/(slider_max));


    %Reset the current zoom level
    handles.XL = [0 size(handles.PET_img, 1)];
    handles.YL = [0 size(handles.PET_img, 2)];
        
    %Keep the zoom level 
    xlim(handles.XL)
    ylim(handles.YL)
    
    update_images(hObject, eventdata, handles)
    
else
    
    [handles.PET_img handles.CT_img handles.ROI handles.Flips] = undo_Flips(handles.PET_img, handles.CT_img, handles.ROI, handles.Flips);
    update_images(hObject, eventdata, handles)
end

handles.orientation = 'Axial';

        
'Axial'
% Update handles structure
guidata(hObject, handles);





% --- Executes on button press in Coronal_button.
function Coronal_button_Callback(hObject, eventdata, handles)
% hObject    handle to Coronal_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Skip if the images are in Sagittal already
if ~strcmp(handles.orientation,'Coronal')
    if strcmp(handles.orientation,'Axial')

        [handles.PET_img handles.CT_img handles.ROI handles.Flips] = undo_Flips(handles.PET_img, handles.CT_img, handles.ROI, handles.Flips);
            
        %Rotate the 3D images since they are in Axial view already!
        handles.PET_img = permute(handles.PET_img, [3 2 1]);
        handles.CT_img  = permute(handles.CT_img,  [3 2 1]);
        handles.ROI     = permute(handles.ROI,  [3 2 1]);
        
    elseif strcmp(handles.orientation,'Sagittal')
        
        [handles.PET_img handles.CT_img handles.ROI handles.Flips] = undo_Flips(handles.PET_img, handles.CT_img, handles.ROI, handles.Flips);
     
       %Rotate the 3D images  back to Axial view then flip to Coronal!
        handles.PET_img = ipermute(handles.PET_img, [1 3 2]);
        handles.CT_img  = ipermute(handles.CT_img,  [1 3 2]);
        handles.ROI     = ipermute(handles.ROI,  [1 3 2]);

        %Now the images are in axial and rotate to Coronal!
        handles.PET_img = permute(handles.PET_img, [3 2 1]);
        handles.CT_img  = permute(handles.CT_img,  [3 2 1]);
        handles.ROI     = permute(handles.ROI,  [3 2 1]);

    end

    %Reset the Slider values!

    %Set slider values based on the number of slices of the loaded image
    slider_max = size(handles.PET_img, 3);

    %Set the current slice to be the middle slice of the loaded image!
    handles.curr_slice = round(slider_max/2);

    set(handles.Slice_Slider, 'Min', 0);
    set(handles.Slice_Slider, 'Max', slider_max);
    set(handles.Slice_Slider, 'Value', handles.curr_slice);
    set(handles.Slice_Slider, 'SliderStep', [1 5]/(slider_max));

    %Reset the current zoom level
    handles.XL = [0 size(handles.PET_img, 2)];
    handles.YL = [0 size(handles.PET_img, 1)];

    %Keep the zoom level 
    xlim(handles.XL)
    ylim(handles.YL)
    
    update_images(hObject, eventdata, handles)
    
else    
    [handles.PET_img handles.CT_img handles.ROI handles.Flips] = undo_Flips(handles.PET_img, handles.CT_img, handles.ROI, handles.Flips);
    update_images(hObject, eventdata, handles)
end

handles.orientation = 'Coronal';
'Coronal'

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in Flip_X_button.
function Flip_X_button_Callback(hObject, eventdata, handles)
% hObject    handle to Flip_X_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.PET_img = flipdim(handles.PET_img,2);
handles.CT_img  = flipdim(handles.CT_img,2);
handles.ROI     = flipdim(handles.ROI,2);

handles.Flips = [{'X'} handles.Flips];

update_images(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in Flip_Y_Button.
function Flip_Y_button_Callback(hObject, eventdata, handles)
% hObject    handle to Flip_Y_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.PET_img = flipdim(handles.PET_img,1);
handles.CT_img  = flipdim(handles.CT_img,1);
handles.ROI     = flipdim(handles.ROI,1);

handles.Flips = [{'Y'} handles.Flips];

update_images(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in Swap_X_Y_Button.
function Swap_X_Y_Button_Callback(hObject, eventdata, handles)
% hObject    handle to Swap_X_Y_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.PET_img = imrotate(handles.PET_img, 90);
handles.CT_img  = imrotate(handles.CT_img,  90);
handles.ROI     = imrotate(handles.ROI, 90);

%Track the flips!! 
if ~isempty(handles.Flips) && isnumeric(handles.Flips{1})    
    %If there was just a flip keep track of the degrees rotated for faster
    %unflipping!!
    if handles.Flips{1} == 90
        handles.Flips{1} = 180;
    elseif handles.Flips{1} == 180
        handles.Flips{1} = -90;
    elseif handles.Flips{1} == -90
        handles.Flips{1} = 0;
    end   
else
    handles.Flips = [{90} handles.Flips];
end
        
%Reset the current zoom level
handles.YL = [0 size(handles.PET_img, 1)];
handles.XL = [0 size(handles.PET_img, 2)];

%Keep the zoom level 
xlim(handles.XL)
ylim(handles.YL)

update_images(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);


function [PET_img CT_img ROI Flips] = undo_Flips(PET_img, CT_img, ROI, Flips)

%Undo the flips (if any)!
for i = length(Flips):-1:1    
    if Flips{i} == 'X'            
        ROI     = flipdim(ROI,2);
        PET_img = flipdim(PET_img,2);
        CT_img  = flipdim(CT_img,2);        
    elseif Flips{i} == 'Y'
        ROI     = flipdim(ROI,1);
        PET_img = flipdim(PET_img,1);
        CT_img  = flipdim(CT_img,1);
    elseif isnumeric(Flips{i})          
        %Flip the X and Y axis back!
        ROI     = imrotate(ROI, -1*Flips{i});
        PET_img = imrotate(PET_img, -1*Flips{i});
        CT_img  = imrotate(CT_img,  -1*Flips{i});
    end
end
%Clear the Flips variable since all flipping has been undone!
Flips = [];

 
% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

% Settings Here

which_button = eventdata.Key;

switch which_button
    case handles.Settings{1}
        %Set add_ROI to true so the mouse motion is tracked when moved!
        handles.add_ROI = true;
        %Reset the BIN for the mouse tracking step to store the points
        handles.BIN = [];
    case handles.Settings{2}
        %Set subtract_ROI to true so the mouse motion is tracked when moved!
        handles.subtract_ROI = true;
        %Reset the BIN for the mouse tracking step to store the points
        handles.BIN = [];    
    case handles.Settings{3}
        if strcmp(handles.Image_Selected, 'Show Functional')   
            handles.Image_Selected = 'Show Anatomical';      
            set(handles.popup_Image_select,'Value',3);
        elseif strcmp(handles.Image_Selected, 'Show Anatomical')       
            handles.Image_Selected = 'Show Fused';   
            set(handles.popup_Image_select,'Value',1);
        elseif strcmp(handles.Image_Selected, 'Show Fused') 
            handles.Image_Selected = 'Show Functional';
            set(handles.popup_Image_select,'Value',2);
        end

    update_images(hObject, eventdata, handles)        
end
    
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in Report_Button.
function Report_Button_Callback(hObject, eventdata, handles)
% hObject    handle to Report_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Undo the Flips because this code assumes the images are in Axial view
[handles.PET_img handles.CT_img handles.ROI handles.Flips] = undo_Flips(handles.PET_img, handles.CT_img, handles.ROI, handles.Flips);
     
% handles.ROIColorStrings = ['r','m','g','k','g','b','y','c', 'r'];

weight    = str2num(get(handles.weight, 'String'));
dose      = str2num(get(handles.dosage, 'String'));
time      = str2num(get(handles.scan_time, 'String'));
half_life = str2num(get(handles.half_life, 'String'));

%Calculate the decay foctor correction!
decay_factor  = 2^(-time*60/half_life);

dpi = 300;
 
output_FileName{1} = [];
SUV_Marker_Size = 4;
ButtonName = questdlg('Report Labels Seperately?', ...
                         'Report Generation', ...
                         'Yes', 'No', 'Yes');                  
                                        
switch ButtonName
    case 'Yes'
        %Consider the different labels as a single label for the report purposes!!
        show_all_Objects = false;
    case 'No'
        show_all_Objects = true;       
    otherwise         
        show_all_Objects = false;
end                       


NumObjects = unique(handles.ROI);
NumObjects = NumObjects(2:end);

for i = 1:length(NumObjects)
    
    num_Obj = NumObjects(i);    
    
    pdfFileName{num_Obj}   = ['Uptake_Number_' num2str(num_Obj) '.pdf'];    
    output_FileName{end+1} = ['Uptake_Number_' num2str(num_Obj) '.pdf'];
    
    %Create a binary of the first Uptakes (Found from the connected
    %components function bwconncomp)
    Temp_ROI = zeros(size(handles.PET_img));  
    Temp_ROI(handles.ROI == num_Obj) = 1;
    
    if show_all_Objects == true
        Temp_ROI(handles.ROI>0) = 1;
    end
    
    temp_img = Temp_ROI.*handles.PET_img;    
        
    [r c Z] = size(handles.PET_img);      
    
    for i = 1:Z
       SUV_max(i) =  max(max(temp_img(:,:,i)));      
    end
    
    Max_Axial_Slice = find(SUV_max == max(SUV_max));
    Max_Axial_Slice = Max_Axial_Slice(1);
    SUV_max = SUV_max(Max_Axial_Slice);

    [SUV_max_X SUV_max_Y] = find(temp_img(:,:,Max_Axial_Slice) == SUV_max, 1);
    
    %Convert the Highest Intensity found to SUV using the weight, decay factor 
    SUV_max = SUV_max*weight/(decay_factor*dose);
    %Round to 2 decimal places to show better on the Results PDF
    SUV_max = round(SUV_max*100)/100;

    SUV_mean = mean(temp_img(temp_img~=0))*weight/(decay_factor*dose);
    SUV_mean = round(SUV_mean*100)/100;
    
    
    fig = figure('InvertHardcopy', 'off', 'Color', [0 0 0]);
    set(gca,'position',[0 0 1 1],'units','normalized')

     
    
    
    
    volume = length(find(Temp_ROI>0))*prod(handles.PET_pixdim)/1000;    
    
    %Round to 2 decimal places!
    volume = round(volume*100)/100;
    
    %%%%Show the Axial Slice of the SUVmax%%%%
    subplot(3,3,1)
    imagesc(handles.PET_img(:,:,Max_Axial_Slice), [handles.PET_contrast_min handles.PET_contrast_max]);
    colormap Jet
    axis off;
    freezeColors
    hold on

    title('Axial Slice Highest SUV', 'FontWeight','bold', 'FontSize', 10, 'Color', 'w')

    %Use the color in the label list for the boundary color!
    Label_List = cellstr(get(handles.listbox1,'String'));            

    B = bwboundaries(Temp_ROI(:,:,Max_Axial_Slice));        
    for k = 1:length(B)
        plot(B{k}(:,2),B{k}(:,1), Label_List{num_Obj}(end), 'LineWidth', 1)
        colormap('Jet')
    end
    
    plot(SUV_max_Y,SUV_max_X, 'bp','MarkerFaceColor','w','MarkerSize', SUV_Marker_Size)

    %Plot CT Image
    subplot(3,3,2)
    imagesc(handles.CT_img(:,:,Max_Axial_Slice), [handles.CT_contrast_min handles.CT_contrast_max]);
    colormap('gray')
    axis off
 
    subplot(3,3,3)
    compound_RGB  = fusemripet(handles.CT_img(:,:,Max_Axial_Slice),handles.PET_img(:,:,Max_Axial_Slice),  handles.Tmap_opacity, handles.thresholded_Tmap);
    imagesc(compound_RGB);   
    axis off
  
    %%%%Show Sagittal View as well!!!!%%%% 

    temp_Sagittal_PET = handles.PET_img(:,SUV_max_Y,:);
    temp_Sagittal_PET = imrotate(permute(temp_Sagittal_PET, [1 3 2]),90);
    temp_Sagittal_CT = handles.CT_img(:,SUV_max_Y,:);
    temp_Sagittal_CT = imrotate(permute(temp_Sagittal_CT, [1 3 2]),90);
    temp_ROI = Temp_ROI(:,SUV_max_Y,:);
    temp_ROI = imrotate(permute(temp_ROI, [1 3 2]),90);

    a = subplot(3,3,4);
    imagesc(temp_Sagittal_PET, [handles.PET_contrast_min handles.PET_contrast_max])
    colormap Jet
    axis off;
    freezeColors
    
    hold on  
    
    B = bwboundaries(temp_ROI);        
    for k = 1:length(B)
        plot(B{k}(:,2),B{k}(:,1), Label_List{num_Obj}(end), 'LineWidth', 1)
        colormap('Jet')
    end

    
    plot(SUV_max_X,Z - Max_Axial_Slice, 'bp','MarkerFaceColor','w','MarkerSize',SUV_Marker_Size)
  
    title(a, 'Sagittal Slice with Highest SUV', 'FontWeight','bold', 'FontSize', 10, 'Color', 'w');

    subplot(3,3,5)
    imagesc(temp_Sagittal_CT, [handles.CT_contrast_min handles.CT_contrast_max])
    colormap('gray')
    axis off
    freezeColors

    subplot(3,3,6)
    compound_RGB  = fusemripet(temp_Sagittal_CT,temp_Sagittal_PET,  handles.Tmap_opacity, handles.thresholded_Tmap);
    imagesc(compound_RGB);   
    axis off

    %%%%Show Coronal View as well!!%%%%

    temp_Coronal_PET = handles.PET_img(SUV_max_X,:,:);
    temp_Coronal_PET = fliplr(flipud(permute(temp_Coronal_PET, [3 2 1])));
    temp_Coronal_CT = handles.CT_img(SUV_max_X,:,:);
    temp_Coronal_CT = fliplr(flipud(permute(temp_Coronal_CT, [3 2 1])));
    temp_ROI = Temp_ROI(SUV_max_X,:,:);
    temp_ROI = fliplr(flipud(permute(temp_ROI, [3 2 1])));

    b = subplot(3,3,7);
    imagesc(temp_Coronal_PET, [handles.PET_contrast_min handles.PET_contrast_max])
    colormap Jet
    axis off;
    freezeColors

    hold on
    B = bwboundaries(temp_ROI);        
    for k = 1:length(B)
        plot(B{k}(:,2),B{k}(:,1), Label_List{num_Obj}(end), 'LineWidth', 1)
        colormap('Jet')
    end

    plot(r-SUV_max_Y,Z - Max_Axial_Slice, 'bp','MarkerFaceColor','w','MarkerSize',SUV_Marker_Size)

    title(b, 'Coronal Slice with Highest SUV', 'FontWeight','bold', 'FontSize', 10, 'Color', 'w');

    subplot(3,3,8)
    imagesc(temp_Coronal_CT, [handles.CT_contrast_min handles.CT_contrast_max])
    colormap('gray')
    axis off
    freezeColors

    subplot(3,3,9)
    compound_RGB  = fusemripet(temp_Coronal_CT,temp_Coronal_PET,  handles.Tmap_opacity, handles.thresholded_Tmap);
    imagesc(compound_RGB);   
    axis off

    ax=axes('Units','Normal','Position',[0.075 0.075 .87 .87],'Visible','off');
    set(get(ax,'Title'),'Visible','on')
    title(['Uptake Number ' num2str(num_Obj) '  Volume =  ' num2str(volume)  '  mL  SUVmax = ' num2str(SUV_max) ' SUVmean = ' num2str(SUV_mean)], 'FontWeight','bold', 'FontSize', 12, 'Color', 'r');

  

    %%%Save as a pdf!%%
    figHandles = get(0,'Children');
    print(figHandles(1), '-dpdf', '-painters', pdfFileName{num_Obj})

    %Close the figure since it is saved as a pdf now!
    close(figHandles(1)) 

   %%
    figure
    
    %%%%CONVERT LABELS FROM PIXEL UNITS TO PHYSICAL UNITS%%%%
    
    %Get the current X Labels then convert to milimeters using the pixel
    %dimensions obtained from the image header.
    x = str2num(get(gca,'XTickLabel'));    
    x = x*prod(handles.PET_pixdim);        
    %Set the bottom index to be 0 for relative distance in mm's
    x = max(x(:)) - x;    
    %Round to 2 decimal places!!!
    x = round(x*100)/100;    
    set(gca,'fontWeight', 'bold', 'XTickLabel',num2str(x));
    
    %Do the same procedure for the Y axis label!
    y = str2num(get(gca,'YTickLabel'));    
    y = y*prod(handles.PET_pixdim);      
    %Set the bottom index to be 0 for relative distance in mm's
    y = max(y(:)) - y;    
    %Round to 2 decimal places!!!
    y = round(y*100)/100;    
    set(gca,'YTickLabel',num2str(y));
     
    %Do the same procedure for the Z axis label!
    z = str2num(get(gca,'ZTickLabel'));    
    z = z*prod(handles.PET_pixdim);      
    
    if ~isempty(z)
        %Set the bottom index to be 0 for relative distance in mm's
        z = z - min(z(:));    
        %Round to 2 decimal places!!!
        z = round(z*100)/100;    
        set(gca,'ZTickLabel',num2str(z));
    end
    
    

    %COLOR BASED ON THE INTENSITIES FROM THE PET IMAGE

    %Erode slightly to get better visualization!
    se = strel('disk',3);        
    Temp_ROI = imerode(Temp_ROI,se);
    
    [faces, vertices] = isosurface(Temp_ROI, .8, 'verbose');
    p1 = patch('Faces', faces,'Vertices', vertices,'FaceColor', Label_List{num_Obj}(end), 'FaceLighting', 'flat',...
    'EdgeColor', 'none', 'SpecularStrength', 0, 'AmbientStrength', 0.4, 'DiffuseStrength', 0.6);

    colormap jet

    view(150,30); 
    %Use the physical voxel size for the rendering!
    daspect(1./handles.PET_pixdim);
    camlight; 
    lighting phong;
    % rotate3d on;
    grid on
    material shiny; 
    
    
    
    %COLOR BASED ON THE INTENSITIES FROM THE PET IMAGE
    temp_PET = handles.PET_img;
    temp_PET = temp_PET*weight/(decay_factor*dose);
    [x y z] = meshgrid(1:size(Temp_ROI,2), 1:1:size(Temp_ROI,1), 1:1:size(Temp_ROI,3));
    isocolors(x,y,z,temp_PET,p1)
    shading flat
   
    colorbar
    
    
    
    %Get the current X Labels then convert to milimeters using the pixel
    %dimensions obtained from the image header.
    x = str2num(get(gca,'XTickLabel'));    
    x = x*prod(handles.PET_pixdim);        
    %Set the bottom index to be 0 for relative distance in mm's
    x = max(x(:)) - x;    
    %Round to 2 decimal places!!!
    x = round(x*100)/100;    
    set(gca,'fontWeight', 'bold', 'XTickLabel',num2str(x));
    
    %Do the same procedure for the Y axis label!
    y = str2num(get(gca,'YTickLabel'));    
    y = y*prod(handles.PET_pixdim);      
    %Set the bottom index to be 0 for relative distance in mm's
    y = max(y(:)) - y;    
    %Round to 2 decimal places!!!
    y = round(y*100)/100;    
    set(gca,'YTickLabel',num2str(y));
     
    %Do the same procedure for the Z axis label!
    z = str2num(get(gca,'ZTickLabel'));    
    z = z*prod(handles.PET_pixdim);     
    
    if ~isempty(z)
        %Set the bottom index to be 0 for relative distance in mm's
        z = z - min(z(:));    
        %Round to 2 decimal places!!!
        z = round(z*100)/100;    
        set(gca,'ZTickLabel',num2str(z));
    end    
    
    figHandles = get(0,'Children');
    print(figHandles(1), '-dpdf','-opengl', [pdfFileName{num_Obj}(1:end-4) '_Rendered.pdf'])

        
    output_FileName{end+1} = [pdfFileName{num_Obj}(1:end-4) '_Rendered.pdf'];
    
    %Close the figure since it is saved as a pdf now!
    close(figHandles(1)) 

    if show_all_Objects == true
        break
    end
end
%%%%%Add rendering of all the objects together%%%%

if show_all_Objects == false
    %Find the total volume of all objects!! 
    Volume_all = length(find(handles.ROI>0))*prod(handles.PET_pixdim)/1000;

    %Render the Current Uptake!!! Save as a new PDF
    figure
    title(['Rendering of All High Uptakes ' '  Volume =  ' num2str(Volume_all)  ' mL'], 'FontWeight','bold', 'FontSize', 10, 'Color', 'w')

    for i = 1:length(NumObjects)
        num_Obj = NumObjects(i);
        
        Temp_ROI = zeros(size(handles.PET_img)); 
        Temp_ROI(handles.ROI == num_Obj) = 1;
        
        %Erode slightly for better visualization!
        se = strel('disk',3);        
        Temp_ROI = imerode(Temp_ROI,se);
        
        %USE THE SAME COLORING AS BEFORE FOR THE VARIOUS OBJECTS 
        % isosurface matlab function is used for rendering
        % isosurface is a function of Volume Visualization in Matlab 
        [faces, vertices] = isosurface(Temp_ROI, .8, 'verbose');
        p1 = patch('Faces', faces,'Vertices', vertices,'FaceColor', Label_List{num_Obj}(end), 'FaceLighting', 'flat',...
        'EdgeColor', 'none', 'SpecularStrength', 0, 'AmbientStrength', 0.4, 'DiffuseStrength', 0.6);
        hold on
        
      %COLOR BASED ON THE INTENSITIES FROM THE PET IMAGE
        temp_PET = handles.PET_img;
        temp_PET = temp_PET*weight/(decay_factor*dose);
        [x y z] = meshgrid(1:size(Temp_ROI,2), 1:1:size(Temp_ROI,1), 1:1:size(Temp_ROI,3));
        isocolors(x,y,z,temp_PET,p1)
        shading flat
        colorbar
    end
    
    colormap jet

    view(150,30); 
    %Use the physical voxel size for the rendering!
    daspect(1./handles.PET_pixdim);
    camlight; 
    lighting phong;
    % rotate3d on;
    grid on
    material shiny; 
    
    %Get the current X Labels then convert to milimeters using the pixel
    %dimensions obtained from the image header.
    x = str2num(get(gca,'XTickLabel'));    
    x = x*prod(handles.PET_pixdim);        
    %Set the bottom index to be 0 for relative distance in mm's
    x = max(x(:)) - x;    
    %Round to 2 decimal places!!!
    x = round(x*100)/100;    
    set(gca,'fontWeight', 'bold', 'XTickLabel',num2str(x));
    
    %Do the same procedure for the Y axis label!
    y = str2num(get(gca,'YTickLabel'));    
    y = y*prod(handles.PET_pixdim);      
    %Set the bottom index to be 0 for relative distance in mm's
    y = max(y(:)) - y;    
    %Round to 2 decimal places!!!
    y = round(y*100)/100;    
    set(gca,'YTickLabel',num2str(y));
     
    %Do the same procedure for the Z axis label!
    z = str2num(get(gca,'ZTickLabel'));    
    z = z*prod(handles.PET_pixdim);     
    
    if ~isempty(z)
        %Set the bottom index to be 0 for relative distance in mm's
        z = z - min(z(:));    
        %Round to 2 decimal places!!!
        z = round(z*100)/100;    
        set(gca,'ZTickLabel',num2str(z));
    end
       
    figHandles = get(0,'Children');
    print(figHandles(1), '-dpdf','-painters', 'All_Uptakes_Rendered.pdf')
    output_FileName{end+1} = 'All_Uptakes_Rendered.pdf';

    %Close the figure since it is saved as a pdf now!
    close(figHandles(1)) 
end


%Remove any empty cells from the cell array of filenames of saved pdfs!
output_FileName =  output_FileName(~cellfun('isempty',output_FileName)); 


%Combine the pdfs!
append_pdfs('Combined_Uptakes.pdf', output_FileName{:})

% Update handles structure
guidata(hObject, handles);



% --- Executes on mouse press over figure background.
function figure1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in Bounding_Box_Button.
function Bounding_Box_Button_Callback(hObject, eventdata, handles)
% hObject    handle to Bounding_Box_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Save the ROI Before Changing to potentially undo this!
handles.Undo = handles.ROI;
%Keep the current number for the label when doing the bounding box!
Label_List = cellstr(get(handles.listbox1,'String'));
for K = 1:size(Label_List,1)
    temp_ROI = handles.ROI;
    temp_ROI(temp_ROI~=K) = 0;    
    %Find the connected components!
    CC = bwconncomp(temp_ROI);
    %Find the bounding box of each connected component
    stats = regionprops(CC);
    for Z = 1:CC.NumObjects
        temp_BB = round(stats(Z).BoundingBox);
        for i = 1:temp_BB(5)        
            handles.ROI(temp_BB(2) + i-1, temp_BB(1):temp_BB(1) + temp_BB(4),temp_BB(3):temp_BB(3)+temp_BB(6)-1) = K;    
        end
    end
end

%Update images with the new Bounding Box!
update_images(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in AP_Segmentation_Button.
function AP_Segmentation_Button_Callback(hObject, eventdata, handles)
% hObject    handle to AP_Segmentation_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%Save the ROI incase of Redo!
handles.Undo = handles.ROI;

%Run the AP Segmentation only on the current label selection!
temp_ROI = handles.ROI;
temp_ROI(temp_ROI ~= handles.curr_selection) = 0;
temp_ROI(temp_ROI~=0) = 1;
for j = 1:size(temp_ROI,3)       
    if any(find(temp_ROI(:,:,j)~=0))
        temp_slice(j) = 1;
    end
end    

%Use only the slices with a non-zero ROI to speed up the refinement
slices = find(temp_slice);


temp_PET = handles.PET_img(:,:,slices).*temp_ROI(:,:,slices);
[AP_binary, idx] = AP_segmentation(temp_PET, handles.AP_Parameters{1:end-1});      
temp_Binary(:,:,slices) = AP_binary;   

groups_Keep = handles.AP_Parameters{end};
AP_binary(AP_binary<max(AP_binary(:))-groups_Keep+1) = 0;
AP_binary(AP_binary~=0) = handles.curr_selection;


temp_ROI(:,:,slices) = handles.ROI(:,:,slices);
temp_ROI(temp_ROI==handles.curr_selection) = 0;

handles.ROI(:,:,slices) = AP_binary + temp_ROI(:,:,slices);

update_images(hObject, eventdata, handles)


% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in pushbutton24.
function pushbutton24_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton24 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Get the parameters for the AP Segmentation (The refine function)!

handles.AP_Parameters = AP_Segmentation_Parameters(handles.AP_Parameters);

% Close the AP Parameters Gui
delete(gcf);

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



% --- Executes on button press in Undo_Button.
function Undo_Button_Callback(hObject, eventdata, handles)
% hObject    handle to Undo_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Don't change the Redo if it's the same as the current ROI (Pressing Redo
%twice by mistake)
if ~isequal(handles.Undo, handles.ROI);
    %Save the ROI in case of Redo!
    handles.Redo = handles.ROI;    
end

%Revert the ROI back!
handles.ROI = handles.Undo;

update_images(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in Redo_Button.
function Redo_Button_Callback(hObject, eventdata, handles)
% hObject    handle to Redo_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Don't change the Undo if it's the same as the current ROI (Pressing Undo
%twice by mistake)
if ~isequal(handles.Redo, handles.ROI)
   %Revert the ROI back!
    handles.ROI = handles.Redo;  
end

%Revert the ROI back!
handles.ROI = handles.Redo;

update_images(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in Interpolate_Button.
function Interpolate_Button_Callback(hObject, eventdata, handles)
% hObject    handle to Interpolate_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Save the ROI in case of Redo!
handles.Undo = handles.ROI;  
    
ROI = handles.ROI;

ROI(ROI~=handles.curr_selection) = 0;
ROI(ROI~=0) = 1;

% Find the non-zero slices!!
for z = 1:size(ROI,3)    
    non_zero_slice(z) = any(any(ROI(:,:,z)));      
end

non_zero_slice = find(non_zero_slice==1);

%Convex hull in axial view!
for z = non_zero_slice
    temp = ROI(:,:,z);
    boundaries = bwboundaries(temp);
    if ~isempty(boundaries)
     try
        x = [];
        y = [];        
        for j = 1:size(boundaries,1)
            temp_boundaries = boundaries{j};
            x = [x; temp_boundaries(:,2)];
            y = [y; temp_boundaries(:,1)];            
        end      
        k = convhull(x,y);
        [r c Z] = size(temp);   
        mask = poly2mask(x(k), y(k),r,c);  
        %Catch if there is an error some place and just make it zero
        %for the slice
        catch
    %             ['Error in Convex Hull on Slice ' num2str(z)]
            mask = zeros(size(temp));                 
        end      
    else
        mask = zeros(size(temp));    
    end    
    ROI(:,:,z) = mask;   
end

%Flip image to Saggital view!!
ROI = permute(ROI, [3 2 1]);

% Find the non-zero slices!!

for z = 1:size(ROI,3)    
    non_zero_slice(z) = any(any(ROI(:,:,z)));      
end
non_zero_slice = find(non_zero_slice==1);

% Get the Convex Hull of the saggital view!
for z = non_zero_slice
    temp = ROI(:,:,z);
    boundaries = bwboundaries(temp);
    if ~isempty(boundaries)
     try
        x = [];
        y = [];        
        for j = 1:size(boundaries,1)
            temp_boundaries = boundaries{j};
            x = [x; temp_boundaries(:,2)];
            y = [y; temp_boundaries(:,1)];            
        end      
        k = convhull(x,y);
        [r c Z] = size(temp);   
        mask = poly2mask(x(k), y(k),r,c);  
        %Catch if there is an error some place and just make it zero
        %for the slice
        catch
            mask = temp;
        end      
    else
        mask = zeros(size(temp));    
    end    
    ROI(:,:,z) = mask;
end

%Flip Image Back to Axial !!!
ROI = ipermute(ROI, [3 2 1]);

%Flip image to Coronal view!!
ROI = permute(ROI, [1 3 2]);

% Find the non-zero slices!!
for z = 1:size(ROI,3)    
    non_zero_slice(z) = any(any(ROI(:,:,z)));      
end
non_zero_slice = find(non_zero_slice==1);

for z = non_zero_slice
    temp = ROI(:,:,z);
    boundaries = bwboundaries(temp);
    if ~isempty(boundaries)
     try
        x = [];
        y = [];        
        for j = 1:size(boundaries,1)
            temp_boundaries = boundaries{j};
            x = [x; temp_boundaries(:,2)];
            y = [y; temp_boundaries(:,1)];            
        end      
        k = convhull(x,y);
        [r c Z] = size(temp);   
        mask = poly2mask(x(k), y(k),r,c);  
        %Catch if there is an error some place and just make it zero
        %for the slice
        catch

            mask = temp;               
        end      
    else
        mask = temp; 
    end    
    ROI(:,:,z) = mask;   
end

%Flip back to axial view!
ROI = ipermute(ROI, [1 3 2]);

% Find the non-zero slices!!
for z = 1:size(ROI,3)    
    non_zero_slice(z) = any(any(ROI(:,:,z)));      
end

non_zero_slice = find(non_zero_slice==1);

%Convex hull in axial view!
for z = non_zero_slice
    temp = ROI(:,:,z);
    boundaries = bwboundaries(temp);
    if ~isempty(boundaries)
     try
        x = [];
        y = [];        
        for j = 1:size(boundaries,1)
            temp_boundaries = boundaries{j};
            x = [x; temp_boundaries(:,2)];
            y = [y; temp_boundaries(:,1)];            
        end      
        k = convhull(x,y);
        [r c Z] = size(temp);   
        mask = poly2mask(x(k), y(k),r,c);  
        %Catch if there is an error some place and just make it zero
        %for the slice
        catch
            mask = temp;
        end      
    else
        mask = temp;  
    end    
    ROI(:,:,z) = mask;   
end


ROI(ROI == 1) = handles.curr_selection;
handles.ROI(handles.ROI == handles.curr_selection) = 0;
handles.ROI =  handles.ROI + ROI;

'Done Interpolating!'

update_images(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in Render_Button.
function Render_Button_Callback(hObject, eventdata, handles)
% hObject    handle to Render_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

Label_List = cellstr(get(handles.listbox1,'String'));

%VOLUME RENDERING
%Get the rendering settings from the user
% here we call another GUI for rendering parameters called Popup.
rendering_settings = Popup(Label_List);

BIN = handles.ROI;
groups_to_render = rendering_settings{4};

%Fix the number of the labels from the listbox in the GUI!
groups_to_render = size(Label_List,1) -  groups_to_render + 1;
all_labels = 1:length(Label_List);

%FIND THE GROUPS THAT WEREN'T SELECTED AND MAKE THE LABELS ZERO IN THE
%BINARY (BIN)
temp = [];
for j= 1:length(all_labels)
    temp = [temp any(find(j == groups_to_render))];
end
[x non_selected_groups] = find(temp==0);
for i = 1:length(non_selected_groups)
    BIN(BIN == non_selected_groups(i)) = 0;    
end

%Errode the BINARY if the user selected this!
if rendering_settings{1} ~=0     
    if rendering_settings{1} < .5
        se = strel('disk',3);        
        BIN = imerode(BIN,se);
    elseif rendering_settings{1} >= .5
        se = strel('disk',5);        
        BIN = imerode(BIN,se);
    end        
end


% Smooth if the user selected it
if rendering_settings{2} ~=0
    BIN = smooth3(BIN, 'gaussian', 3, rendering_settings{2});
end

figure
if rendering_settings{3} == 0 
    %DONT RENDER WITH PET OVERLAID. Use the label colors!
    for i = groups_to_render
        temp_BIN = BIN;
        temp_BIN(temp_BIN~=i) = 0;
        [faces, vertices] = isosurface(temp_BIN, .8, 'verbose');
        p1 = patch('Faces', faces,'Vertices', vertices,'FaceColor', Label_List{i}(end), 'FaceLighting', 'flat',...
        'EdgeColor', 'none', 'SpecularStrength', 0, 'AmbientStrength', 0.4, 'DiffuseStrength', 0.6);
        freezeColors
        hold on 
    end
else  
    %RENDER WITH PET INFORMATION OVERLAID
    BIN(BIN~=0) = 1;
    [faces, vertices] = isosurface(BIN, .8, 'verbose');
    p1 = patch('Faces', faces,'Vertices', vertices,'FaceColor', 'r', 'FaceLighting', 'flat',...
    'EdgeColor', 'none', 'SpecularStrength', 0, 'AmbientStrength', 0.4, 'DiffuseStrength', 0.6);
    freezeColors
    hold on 

    %COLOR BASED ON THE INTENSITIES FROM THE PET IMAGE
    temp_PET = handles.PET_img;
    [x y z] = meshgrid(1:size(BIN,2), 1:1:size(BIN,1), 1:1:size(BIN,3));
    isocolors(x,y,z,temp_PET,p1);
    shading flat    
end

colormap jet
view(150,30); 
%Use the physical voxel size for the rendering!
daspect(1./handles.PET_pixdim);
camlight; 
lighting phong;
rotate3d on;
grid on
material shiny; 
    
    
    
% Update handles structure
guidata(hObject, handles);

% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1

%Use the Current Label Selection for the ROI Generation and for the Report
handles.curr_selection = get(handles.listbox1,'Value');

% contents = cellstr(get(hObject,'String'))

%Calculate the SUV metrics given the ROI
SUV_calculations(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Add_Label_Button.
function Add_Label_Button_Callback(hObject, eventdata, handles)
% hObject    handle to Add_Label_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

Label_List = cellstr(get(handles.listbox1,'String'));

if handles.curr_selection < 1 
    handles.curr_selection = 1;
    set(handles.listbox1,'Value',handles.curr_selection);
end

if get(handles.listbox1,'Value') < 1
    set(handles.listbox1,'Value', 1)
end

%Find the lowest number that isn't on the list already!
temp = [];
for i = 1:size(Label_List,1)    
    temp = [temp Label_List{i}(end-4)];
end

num = [];
for i = 1:size(Label_List,1) 
    if ~any(temp == num2str(i))
        num = i;
        break
    end
end

if isempty(num)
    num = size(Label_List,1) + 1;    
end

if isempty(Label_List)
    new_name = {'Label 1'};
else
    new_name = [Label_List;{['Label ' num2str(num)]}];
end

new_name{end} = [new_name{end} '   ' handles.ROIColorStrings(rem(length(new_name),9)+1)];

set(handles.listbox1,'String',new_name)

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in Delete_Label_Button.
function Delete_Label_Button_Callback(hObject, eventdata, handles)
% hObject    handle to Delete_Label_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.curr_selection = get(handles.listbox1,'Value');

Label_List = cellstr(get(handles.listbox1,'String'));

try
    new_name = Label_List;
    new_name{handles.curr_selection} = [];

    %Remove the empty rows!!
    new_name = new_name(~cellfun('isempty',new_name(:)));

    set(handles.listbox1,'String',new_name)

    %Reset the ROI for the current label!!
    handles.ROI(handles.ROI == handles.curr_selection) = 0;

    for i = handles.curr_selection+1:length(Label_List)+1
        %Subtract one from the rest of the labels! So the binary reflects the
        %order of the labels in the list.
        handles.ROI(handles.ROI == i) = i-1;
    end

    %Fix the current value of the listbox if removing the bottom label
    if handles.curr_selection >= length(Label_List)
        set(handles.listbox1,'Value', handles.curr_selection - 1)
    end

    update_images(hObject, eventdata, handles)
catch
      
end
    
 
% Update handles structure
guidata(hObject, handles);



% --- Executes on button press in Rename_Label_Button.
function Rename_Label_Button_Callback(hObject, eventdata, handles)
% hObject    handle to Rename_Label_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.curr_selection = get(handles.listbox1,'Value');

Label_List = cellstr(get(handles.listbox1,'String'));
prompt = {'Rename Current Label:'};

dlg_title = 'Rename Label';
num_lines = 1;
def = {Label_List{handles.curr_selection}};
New_Name = inputdlg(prompt,dlg_title,num_lines,def);
Label_List{handles.curr_selection} = New_Name{1};
set(handles.listbox1,'String',Label_List)

update_images(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);




% --- Executes on button press in Material_Statistics_Button.
function Material_Statistics_Button_Callback(hObject, eventdata, handles)
% hObject    handle to Material_Statistics_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Get the weight and dosage for the SUV calculation
weight    = str2num(get(handles.weight, 'String'));
dose      = str2num(get(handles.dosage, 'String'));
time      = str2num(get(handles.scan_time, 'String'));
half_life = str2num(get(handles.half_life, 'String'));

handles.curr_selection = get(handles.listbox1,'Value');
volume = length(find(handles.ROI == handles.curr_selection))*prod(handles.pixdim_PET)/1000;

%Round to three decimal places!
volume = round(volume*1000)/1000;

Label_List = cellstr(get(handles.listbox1,'String'));  

slices = [];
for i = 1:size(handles.ROI,3)    
    temp_ROI = handles.ROI(:,:,i);
    if any(temp_ROI(:)== handles.curr_selection)
       slices = [slices i]; 
    end
end

choice = questdlg(['Volume of ' Label_List{handles.curr_selection}(1:end-1) 'is ' num2str(volume) '   mL over ' num2str(length(slices)) ' slices!'], ...
	'Material Statistics', ...
	'Display as Table','Save as CSV file', 'Done', 'Done');
%CALCULATE THE MATERIAL STATISTICS
temp_img = handles.PET_img(:,:,slices);
BW = handles.ROI(:,:,slices);
BW(BW~=handles.curr_selection) = 0;
BW(BW~=0) = 1;
temp_PET_img = temp_img.*BW;

%Calculate the decay foctor correction!
decay_factor  = 2^(-time*60/half_life);           
for z = 1:length(slices)       
    temp_Volume = length(find(handles.ROI(:,:,slices(z))))*prod(handles.pixdim_PET)/1000;            
    %Round to three decimal places!
    temp_Volume = round(temp_Volume*1000)/1000;            
    temp_img_SUV = temp_PET_img(:,:,z);
    temp_SUV_max = max(temp_img_SUV(:))*weight/(decay_factor*dose);         
    temp_SUV_mean = mean(temp_img_SUV(temp_img_SUV~=0))*weight/(decay_factor*dose);

    %Round to three decimal places!
    SUV_Max_slice = round(temp_SUV_max*1000)/1000;       
    SUV_Mean_slice = round(temp_SUV_mean*1000)/1000;           

    Output{z,1} = temp_Volume;
    Output{z,2} = SUV_Max_slice;          
    Output{z,3} = SUV_Mean_slice;
end 

switch choice
    case 'Display as Table'         
       
        f = figure;         
        colnames = {'Volume', 'SUVmax', 'SUVmean'};
        t = uitable(f, 'Data', Output, 'ColumnName', colnames, 'RowName',slices, 'units','Normalized', ...
            'RowStriping','on');
        set(f,'DockControls','off');
    case 'Save as CSV file'
        
        [filename, path] = uiputfile('*.csv','Save Material Statistics As');
        
        %ADD THE SLICES TO THE FIRST COLUMN BEFORE SAVING!
        for k = 1:size(Output,1)
            temp{k,1} = slices(k);
        end
        
        Output = [temp Output];  
        csvwrite([path filename], Output);
                
    case 'Done'  
        
end


% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in Long_Axis_Button.
function Long_Axis_Button_Callback(hObject, eventdata, handles)
% hObject    handle to Long_Axis_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


BW = handles.ROI;
BW(BW ~= handles.curr_selection) = 0;
BW(BW ~= 0) = 1;

BW = BW(:,:,handles.curr_slice);
BW_stats = regionprops(BW,'all');

temp_Boundary = bwboundaries(BW);
Boundary = temp_Boundary{1};

temp = transpose(Boundary)*Boundary;
[V D] = eig(temp);

theta = 60 + atand([V(2,1)/V(1,1)]);

ctr = BW_stats.Centroid;

plot(ctr(1), ctr(2), 'r*')

Minor_Length = BW_stats.MajorAxisLength;
Major_Length = BW_stats.MinorAxisLength;

set(gcf, 'CurrentAxes',handles.axes3);
xMajor = ctr(1)  +  [ -1 +1 ] * Major_Length*cosd(theta)/2;
yMajor = ctr(2)  +  [ -1 +1 ] * Major_Length*sind(theta)/2;

for i = 0:.1:250   
    x = ctr(1) + i;
    y = tand(theta)*i + ctr(2);    
    x = round(x);
    y = round(y);               
    idx = find(BW_stats.PixelList(:,1) == x);    
    idx2 = find(BW_stats.PixelList(idx,2) == y);    
    if isempty(idx2)       
        break
    end
    temp_endpoint = [x y];    
end

Major_endpoint = temp_endpoint;

for i = 0:-.1:-250  
    x = ctr(1) + i;
    y = tand(theta)*i + ctr(2);
    x = round(x);
    y = round(y);               
    idx = find(BW_stats.PixelList(:,1) == x);    
    idx2 = find(BW_stats.PixelList(idx,2) == y);    
    if isempty(idx2)       
        break
    end
    temp_endpoint = [x y];
end

Major_endpoint = [Major_endpoint; temp_endpoint];

line(Major_endpoint(:,1),Major_endpoint(:,2),'Color','b','LineWidth',4);

theta = 90 + theta;

for i = 0:.1:250   
    x = ctr(1) + i;
    y = tand(theta)*i + ctr(2);    
    x = round(x);
    y = round(y);               
    idx = find(BW_stats.PixelList(:,1) == x);    
    idx2 = find(BW_stats.PixelList(idx,2) == y);    
    if isempty(idx2)       
        break
    end
    temp_endpoint = [x y];    
end


Minor_endpoint = temp_endpoint;

for i = 0:-.1:-250  
    x = ctr(1) + i;
    y = tand(theta)*i + ctr(2);
    x = round(x);
    y = round(y);               
    idx = find(BW_stats.PixelList(:,1) == x);    
    idx2 = find(BW_stats.PixelList(idx,2) == y);    
    if isempty(idx2)       
        break
    end
    temp_endpoint = [x y];
end

Minor_endpoint = [Minor_endpoint; temp_endpoint];

line(Minor_endpoint(:,1),Minor_endpoint(:,2),'Color','b','LineWidth',4);

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in Settings_Button.
function Settings_Button_Callback(hObject, eventdata, handles)
% hObject    handle to Settings_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
prompt={'Button for adding ROI:',...
        'Button for subtracting ROI:', ...
        'Button for switching Modalities:'};
name='Input for Peaks function';
numlines=1;
handles.Settings = {'space','control', 'q'};
defaultanswer = handles.Settings;
answer = inputdlg(prompt,name,numlines,defaultanswer);

%Only change the settings if the user pressed OK!
if ~isempty(answer)
    handles.Settings = answer;
end
% Update handles structure
guidata(hObject, handles);



function PET_Filename_Edit_Callback(hObject, eventdata, handles)
% hObject    handle to PET_Filename_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PET_Filename_Edit as text
%        str2double(get(hObject,'String')) returns contents of PET_Filename_Edit as a double


% --- Executes during object creation, after setting all properties.
function PET_Filename_Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PET_Filename_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function CT_Filename_Edit_Callback(hObject, eventdata, handles)
% hObject    handle to CT_Filename_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of CT_Filename_Edit as text
%        str2double(get(hObject,'String')) returns contents of CT_Filename_Edit as a double


% --- Executes during object creation, after setting all properties.
function CT_Filename_Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to CT_Filename_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton39.
function pushbutton39_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton39 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%SAVE THE BINARY!!

%Load the Functional image (PET)!
[FileName,PathName] = uiputfile({'*.hdr'; '*.mat'; '*.img'} ,'Load the Functional Image! Analyze or Matlab format');

try    
    %Try to load the image, and catch if the image is the wrong format. 
    if strcmp(FileName(end-2:end), 'hdr')
        
        %Replace the image in the header file! 
        handles.hdr.img = handles.ROI;
        %Load image if in Analyze Format
        save_nii(handles.hdr, [PathName FileName]);    
      
    elseif strcmp(FileName(end-2:end), 'mat')
       
        bin = handles.ROI;        
        save([PathName FileName], 'bin')           
    end   
    
catch
    'Error saving binary!'    
end


% --- Executes on button press in Colorbar_Button.
function Colorbar_Button_Callback(hObject, eventdata, handles)
% hObject    handle to Colorbar_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(gcf, 'CurrentAxes',handles.axes3);
if handles.C_Bar == true
    colorbar off
    handles.C_Bar = false;
else     
    colorbar 
    handles.C_Bar = true;    
end

% Update handles structure
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = Fused_SUV_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

