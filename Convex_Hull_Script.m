


%% Get the Convex Hull of the axial slices on the rib binary!

for z = 1:size(img,3)
    temp = double(fliplr(flipud(img(:,:,z))));
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
            ['Error in Convex Hull on Slice ' num2str(z)]
            mask = zeros(size(temp));                 
        end      
    else
        mask = zeros(size(temp));    
    end
    output_AXIAL(:,:,z) = double(mask);
end

img = output_AXIAL;


%%%%Get the Convex Hull of the Saggital View of the binary just created from the axial!

%Flip image to Saggital view!!
img = permute(img, [3 2 1]);
img(img~=0) = 1;

for z = 1:size(img,3)

    %NEED TO FLIP Y to match the analyze files Awais created already
%     temp = double(fliplr(img(:,:,z)));
    temp = double(img(:,:,z));
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
            ['Error in Convex Hull on Slice ' num2str(z)]
            mask = zeros(size(temp));                 
        end
    else
        mask = zeros(size(temp));    
    end
    output(:,:,z) = double(mask);            
end

%Flip Image Back to Axial for saving!!!
img = ipermute(output, [3 2 1]);

a.img = img;
a.hdr.dime.dim(2:4) = size(img);

