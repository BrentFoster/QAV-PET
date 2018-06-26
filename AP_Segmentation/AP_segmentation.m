function [binary, idx] = AP_segmentation(img, bins, KDthreshold, n, m, smoothing, lambda, maxits)
% AP_segmentation takes four inputs for segmenting PET images based on a
% similarity function that calculates the affinity (similarity) between the
% data points on the histogram. 
%
% PARAMETERS     Value
%   img          A 2D or 3D PET image. The histogram will be estimated from
%                this image
%
%   bins         The number of bins for the histogram estimation
%
%   KDthreshold  The threshold for removing noise based on the kernel
%                desity estimation via diffusion. Using the maximum density
%                of the data points on the image, any points that are less
%                than the threshold times this value is most likely an
%                outlier and is removed for more robust histogram estimation.
%
%   n,m          The parameters for calculating the affinity function of the . 
%                data points n,m must be greater than or equal to zero (and 
%                at least one must be nonzero). 
%
%                Default values are n = 3, m = 1.
%   smoothing    The window size of the exponential smoothing. Default = 20
%
%   lambda       The damping factor for the AP clustering. Must be greater 
%                than or equal to 0.5. Default = 0.8
%
%   maxits       The maximum iterations for AP clustering. Default is 500, but
%                generally converges in less than 100 iterations.
%
%   Outputs:
%   binary       The segmented binary of the image. 
%
%   idx          The index of the intensities to their respective exemplar.
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright NIH (c)2013. This software may be freely used and distributed 
%                  for non-commercial purposes.
% 
% 
% Foster, B.; Bagci, U.; Luna, B.; Dey, B.; Bishai, W.; Jain, S.; Ziyue Xu; 
% Mollura, D.J., "Segmentation of PET Images for Computer-Aided Functional 
% Quantification of Tuberculosis in Small Animal Models," IEEE Transactions 
% on Biomedical Engineering. (In Press)
% 
% Foster, B.; Bagci, U.; Luna, B.; Dey, B.; Bishai, W.; Jain, S.; Ziyue Xu; Mollura, D.J., 
% "Robust segmentation and accurate target definition for positron emission tomography images 
% using Affinity Propagation," 2013 IEEE 10th International Symposium on Biomedical Imaging (ISBI),  
% pp.1461 - 1464, 7-11 April 2013.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%Estimate the histogram of the 2D or 3D image
    H_total = zeros(1,bins)';    

    for i = 1:size(img,3)        
        %Change image type to uint8 to round to nearest intensity for 
        %histogram calculation and 
        %two_D_histogram(:,:,i) = imhist(uint8(img(:,:,i)), bins);  

        temp_img = img(:,:,i);
        two_D_histogram(:,:,i) = hist(temp_img(:), bins)';  
        
        %%%% Use 3D Histogram if more than one slice is given%%%%%
        H_total = H_total + two_D_histogram(:,:,i);          
    end
    
    %%%%% Histogram Smoothing Step %%%%%
    [H] = histogram_smoothing(H_total, KDthreshold, smoothing);
     
    %%%%% Affinity Calculation Step %%%%%
    [intensity_range_for_exemplar, idx] = affinity_calculation(H, n, m, lambda, maxits); 
    
    %Convert the range in the bins to the range of intensities!
    for i = 1:length(intensity_range_for_exemplar)
       intensity_range_for_exemplar{i} = intensity_range_for_exemplar{i}./(bins+1)*max(img(:));
    end
        
    for z = 1:size(img,3)
        %%%%% Segment images using threshold to create binary %%%%%
        temp_img = img(:,:,z);
        for i = 1:size(intensity_range_for_exemplar,2) 
            temp_img(img(:,:,z) > intensity_range_for_exemplar{i}(1)) = i;
        end
        binary(:,:,z) = temp_img;   
    end
    
    temp = unique(binary);
    if temp ~= 0
        %Rescale so the smallest group is 1 for better visualization
        binary(binary>0) = binary(binary>0) - temp(2) + 1;  
    end
end



