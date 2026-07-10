%Segmentation using the watershed transform works better if you can identify, or "mark," foreground objects and background locations. 
%Marker-controlled watershed segmentation follows this basic procedure:
%-Compute a segmentation function. This is an image whose dark regions are the objects you are trying to segment.
%-Compute foreground markers. These are connected blobs of pixels within each of the objects.
%-Compute background markers. These are pixels that are not part of any object.
%-Modify the segmentation function so that it only has minima at the foreground and background marker locations.
%-Compute the watershed transform of the modified segmentation function.

%1: Read in the Color Image and Convert it to Grayscale
rgb = imread("pears.png");
I = im2gray(rgb);


en='.bmp';  
[Z00,mapZ00]=imread(['C:\Users\Yurii\Documents\MATLAB\', '0-0', en]);
Z00=rgb2gray(Z00);


imshow(I)

text(732,501,"Image courtesy of Corel(R)",...
     "FontSize",7,"HorizontalAlignment","right")

%2: Use the Gradient Magnitude as the Segmentation Function
gmag = imgradient(I);
imshow(gmag,[])
title("Gradient Magnitude")

%Can you segment the image by using the watershed transform directly on the gradient magnitude?
L = watershed(gmag);
Lrgb = label2rgb(L);
imshow(Lrgb)
title("Watershed Transform of Gradient Magnitude")

%3: Mark the Foreground Objects
se = strel("disk",20);
Io = imopen(I,se);
imshow(Io)
title("Opening")

%Next compute the opening-by-reconstruction using imerode and imreconstruct.
Ie = imerode(I,se);
Iobr = imreconstruct(Ie,I);
imshow(Iobr)
title("Opening-by-Reconstruction")

%Following the opening with a closing can remove the dark spots and stem marks. Compare a regular morphological closing with a closing-by-reconstruction. First try imclose:
Ioc = imclose(Io,se);
imshow(Ioc)
title("Opening-Closing")

%Now use imdilate followed by imreconstruct. Notice you must complement the image inputs and output of imreconstruct.
Iobrd = imdilate(Iobr,se);
Iobrcbr = imreconstruct(imcomplement(Iobrd),imcomplement(Iobr));
Iobrcbr = imcomplement(Iobrcbr);
imshow(Iobrcbr)
title("Opening-Closing by Reconstruction")

%As you can see by comparing Iobrcbr with Ioc, reconstruction-based opening and closing are more effective than standard opening and closing at removing small blemishes without affecting the overall shapes of the objects. Calculate the regional maxima of Iobrcbr to obtain good foreground markers.
fgm = imregionalmax(Iobrcbr);
imshow(fgm)
title("Regional Maxima of Opening-Closing by Reconstruction")

%To help interpret the result, superimpose the foreground marker image on the original image.
I2 = labeloverlay(I,fgm);
imshow(I2)
title("Regional Maxima Superimposed on Original Image")

%Notice that some of the mostly-occluded and shadowed objects are not marked, which means that these objects will not be segmented properly in the end result. 
%This procedure tends to leave some stray isolated pixels that must be removed. You can do this using bwareaopen, which removes all blobs that have fewer than a certain number of pixels.
se2 = strel(ones(5,5));
fgm2 = imclose(fgm,se2);
fgm3 = imerode(fgm2,se2);

fgm4 = bwareaopen(fgm3,20);
I3 = labeloverlay(I,fgm4);
imshow(I3)
title("Modified Regional Maxima Superimposed on Original Image")

%4: Compute Background Markers
bw = imbinarize(Iobrcbr);
imshow(bw)
title("Thresholded Opening-Closing by Reconstruction")

%The background pixels are in black, but ideally we don't want the background markers to be too close to the edges of the objects we are trying to segment. We'll "thin" the background by computing the "skeleton by influence zones", or SKIZ, of the foreground of bw.
D = bwdist(bw);
DL = watershed(D);
bgm = DL == 0;
imshow(bgm)
title("Watershed Ridge Lines")

%5: Compute the Watershed Transform of the Segmentation Function
gmag2 = imimposemin(gmag, bgm | fgm4);
L = watershed(gmag2);

%6: Visualize the Result
labels = imdilate(L==0,ones(3,3)) + 2*bgm + 3*fgm4;
I4 = labeloverlay(I,labels);
imshow(I4)
title("Markers and Object Boundaries Superimposed on Original Image")


Lrgb = label2rgb(L,"jet","w","shuffle");
imshow(Lrgb)
title("Colored Watershed Label Matrix")


figure
imshow(I)
hold on
himage = imshow(Lrgb);
himage.AlphaData = 0.3;
title("Colored Labels Superimposed Transparently on Original Image")