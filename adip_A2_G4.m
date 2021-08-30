% The below code counts the number of white blood cells, red blood cells
% and overlapping cells in the image
%White blood cells are much larger and scattered in a microscopic image of
%a blood smear. This code seperates out large WBC's and smaller RBC's. RBC count 
%is generally very high and the chances of overlapping cells in RBC is
%higher. 

clc;
clear all;

inputImage = imread('blood_smear_ASH.jfif'); %read the original image

figure(1);
imshow(inputImage); 
title('Orignal Image');

%image preprocessing
grayImage = rgb2gray(inputImage); %convert to grayscale image
IM_ad = imadjust(grayImage); %adjust the contrast between foreground and background

IB=imbinarize(grayImage); %convert to a binary image
IB_filled = imfill(~IB, 'holes'); %fill the holes in the binary image

figure(2);
imshow(IB_filled);
title('All holes filled')

%seperate overlapping cells
se = strel('disk',6);
IM3 = imopen(IB_filled,se); %perform opening with a structuring element as a disk
figure(3);
imshow(IM3); %clean and clearly segmented image with foreground as white pixels
title("Clearly segmented Image")
%%finding and counting WBCs

cc = bwconncomp(IM3); %find connected components in the binary image
stats = regionprops(cc,'Area','Perimeter'); %find area and perimeter of these components

idx = find([stats.Area] > 800 & [stats.Perimeter] > 175); 
BW2 = ismember(labelmatrix(cc),idx); %area and perimeter is used as the criteria to seperate out WBC and RBC
%The resulting binary image is cleaned to remove RBC's overlapping on WBC
%and those on border cells to get only the regions for WBC's
se = strel('disk',15);
IM_WBC = imopen(BW2,se);
IM_WBC= imclearborder(IM_WBC);
figure(4);
imshow(IM_WBC);
title("WBC regions")
%WBC regions are then removed from the original binary image
IM_RBC=IM3-IM_WBC;
figure(5);
imshow(IM_RBC);
title("RBC regions")

%count number of WBCs
connectedComponent = bwconncomp(IM_WBC, 4);
circularCellCount = connectedComponent.NumObjects;
fprintf('%s %d\n','Total number of white blood cells = ',circularCellCount);


%For RBC- we find the number of overlapping RBCs and the total count of
%RBC's in the image

%find the edge map of the RBC image and then filter elliptical regions to
%get the regions of overlapping cells
[Gmag,Gdir] = imgradient(IM_RBC);
[extractOverlappedCells,properties]=filterRegionsElliptical(Gmag);
figure(6);
imshow(extractOverlappedCells);
title("overlapping RBCs regions")
% Total number of Overlapped cells

connectedComponent = bwconncomp(extractOverlappedCells, 4);
overlappedCellsCount = connectedComponent.NumObjects;
fprintf('%s %d\n','Total number of overlapped cells = ',overlappedCellsCount);

%Total number of RBC's

connectedComponent = bwconncomp(IM_RBC, 4); 
circularCellCount = connectedComponent.NumObjects;
fprintf('%s %d\n','Total number of red blood cells = ',circularCellCount);

%function to find elliptical regions

function [BW_out,properties] = filterRegionsElliptical(BW_in)
%clean the image and then specify the dimensions of an elliptical region to
%filter out overlapping cell regions
BW_out = imbinarize(BW_in);
BW_out = imclearborder(BW_out);
BW_out = imfill(BW_out, 'holes'); 
BW_out = bwpropfilt(BW_out, 'MajorAxisLength', [30, 50]); 
BW_out = bwpropfilt(BW_out, 'MinorAxisLength', [0, 30]);
BW_out = bwpropfilt(BW_out, 'Eccentricity', [0.795, 0.907]);
BW_out = bwpropfilt(BW_out, 'Area', [300, 2700]);
properties = regionprops(BW_out, {'Eccentricity','MajorAxisLength', 'MinorAxisLength','Perimeter'});
end
