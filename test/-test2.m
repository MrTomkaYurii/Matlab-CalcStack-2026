% im=imread('https://i.stack.imgur.com/aBHUL.jpg');
% im=im(58:500,86:585,:);
% imOrig=im;

en='.bmp';  
[Z00,mapZ00]=imread(['C:\Users\Yurii\Documents\MATLAB\', '0-0', en]);
Z00=rgb2gray(Z00);
Z00=double(Z00);
imOrig = Z00;
im = imOrig(50:200,50:200);
%% Виділення елементівна тестовому зображенні

% %виділення зеленого каналу для опрацювання
im=double(im);
% r=im(:,:,1);
% g=im(:,:,2);
% b=im(:,:,3);
% tmp=((g-r)./(r-b));
 tmp = im;

figure ('Name','Test Image')
subplot 121;imagesc(tmp),axis image;colorbar
    title ('Image','Color','r')
    xlabel('X, pixels','Color','r');
    ylabel('Y, pixels','Color','r');
% subplot 122;imagesc(tmp>0),axis image;colorbar
subplot 122;imagesc(tmp>200),axis image;colorbar
    title ('Binary Image','Color','r')
    xlabel('X, pixels','Color','r');
    ylabel('Y, pixels','Color','r');

%% Transforms

% Distance transform 
% im_dist=bwdist(tmp<0);   
 im_dist=bwdist(tmp<200);                                                      % https://www.mathworks.com/help/images/ref/bwdist.html

% Blur
sigma=10;
kernel = fspecial('gaussian',4*sigma+1,sigma);                              % Создается гауссовский фильтр с помощью функции fspecial. Гауссовский фильтр является фильтром размытия, 
im_blured=imfilter(im_dist,kernel,'symmetric');                             % применяется созданный гауссовский фильтр kernel к изображению im_dist с помощью функции imfilter

figure ('Name','DistanceTransform-BluredDistanceTransform')
subplot(121);imagesc(im_dist),axis image;colorbar
    title ('Distance transform','Color','r')
    xlabel('X, pixels','Color','r');
    ylabel('Y, pixels','Color','r');
subplot(122);imagesc(im_blured),axis image;colorbar
    title ('Blured Distance Transform','Color','r')
    xlabel('X, pixels','Color','r');
    ylabel('Y, pixels','Color','r');

% Watershed
L = watershed(max(im_blured(:))-im_blured);                                 % Применение алгоритма водораздела к размытому изображению
[x,y]=find(L==0);                                                           % Нахождение координат пикселей, принадлежащих линии водораздела

figure ('Name','Watershed')
imagesc(tmp), axis image
hold on, plot(y,x,'r.','MarkerSize',3)

%% Local thresholding 

trees=zeros(size(im_dist));
centers= [];
for i=1:max(L(:))    
    ind=find(L==i & im_blured>1);
    mask=L==i;

    [thr,metric] =multithresh(g(ind),1);
    trees(ind)=g(ind)>thr*1;

    trees_individual=trees*0;
    trees_individual(ind)=g(ind)>thr*1;

    s=regionprops(trees_individual,'Centroid');
    centers=[centers; cat(1,[],s.Centroid)];
end

figure ('Name','Local thresholding ')
imagesc(trees),axis image
hold on, plot(y,x,'r.','MarkerSize',3)
hold on, plot(centers(:,1),centers(:,2),'k^','MarkerFaceColor','r','MarkerSize',4)

figure ('Name','Watershed-Local thresholding')
subplot 121
imagesc(imOrig), axis image
hold on, plot(y,x,'r.','MarkerSize',1)
hold on, plot(centers(:,1),centers(:,2),'k^','MarkerFaceColor','r','MarkerSize',4)
title('Watershed')
subplot 122
imagesc(trees),axis image
hold on, plot(y,x,'r.','MarkerSize',3)
hold on, plot(centers(:,1),centers(:,2),'k^','MarkerFaceColor','r','MarkerSize',4)
title('Local thresholding')