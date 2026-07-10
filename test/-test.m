% I_original = imread('https://blogs.mathworks.com/images/steve/60/nuclei.png');
% I_cropped = I_original(400:900, 465:965);

en='.bmp';  
[Z00,mapZ00]=imread(['C:\Users\Yurii\Documents\MATLAB\', '0-0', en]);
Z00=rgb2gray(Z00);
I_original = Z00;
I_cropped = I_original(150:350, 250:450);


   figure('name','SEGMENTATION-Original Image','units','normalized','outerposition',[0 0 1 1],'Color','white')
            imshow(I_original); grid on;
            title (['Image'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r');

   % Создание сетки координат для иследуемой области
   [x, y] = meshgrid(1:size(I_cropped, 2), size(I_cropped, 1):-1:1);

   figure('name','SEGMENTATION-Croped Image-Information','units','normalized','outerposition',[0 0 1 1],'Color','white')
     subplot 221; imshow(I_cropped); grid on; colorbar
            title (['Image'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r');
     subplot 222; histogram(I_cropped, 'NumBins', 256,'FaceAlpha',0.75,'EdgeColor', 'none'); grid on;
            title (['Image'],'Color','r') 
            xlabel('Values ','Color','r')
            ylabel('N','Color','r');
     subplot 223; contour(x,y,I_cropped); grid on; colorbar
            title (['Image'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r');
            axis equal;
     subplot 224; mesh(I_cropped); grid on;
            title (['Image'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r');
            view(45, 80);

 %  Адаптивное гистограммное выравнивание (Adaptive Histogram Equalization, AHE) — метод обработки изображений, 
 %  который позволяет улучшить контрастность изображения, особенно в областях с низким контрастом. В отличие от 
 %  обычного гистограммного выравнивания, AHE применяет выравнивание гистограммы не ко всему изображению целиком, 
 %  а к небольшим локальным областям.
 I_equalizated = adapthisteq(I_cropped);


   figure('name','SEGMENTATION-Contrasted Image','units','normalized','outerposition',[0 0 1 1],'Color','white')
     subplot 221; imshow(I_equalizated); grid on;
            title (['Image'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r');
      subplot 222; histogram(I_equalizated, 'NumBins', 256,'FaceAlpha',0.75,'EdgeColor', 'none'); grid on;
            title (['Image'],'Color','r') 
            xlabel('Values ','Color','r')
            ylabel('N','Color','r');
     subplot 223; contour(x,y,I_equalizated); grid on; colorbar
            title (['Image'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r');
            axis equal;
     subplot 224; mesh(I_equalizated); grid on;
            title (['Image'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r');
            view(45, 80);
 
 % бинаризация изображения на основе graythresh для автоматического вычисления порога и функцию
 % все пиксели, чья интенсивность выше порога, становятся белыми, а остальные — черными
 bw = im2bw(I_equalizated, graythresh(I_equalizated));

    figure('name','SEGMENTATION-бінаризоване зображення','units','normalized','outerposition',[0 0 1 1],'Color','white')
     subplot 121; imshow(I_equalizated); grid on;
            title (['Contrasted Image'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r'); 
     subplot 122; imshow(bw); grid on;
            title (['Binarized Image'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r');

bw2 = imfill(bw,'holes');  
% Вы имеете бинарное изображение bw, где объекты представлены белыми пикселями, а фон — черными.
% Функция imfill принимает два аргумента: изображение и строку, указывающую, какие области заполнить. 
% Строка 'holes' указывает, что нужно заполнить "дыры" в бинарном изображении.
% "Дыры" в бинарном изображении — это области, которые представляют собой черные области, 
% окруженные белыми пикселями. Функция imfill заполняет эти черные области (дыры), делая их белыми.
bw3 = imopen(bw2, ones(3,3));
% Морфологическое открытие над бинарным изображением bw2 с использованием структурного элемента 5x5. Операция открытия включает в себя эрозию (erosion), а затем дилатацию (dilation).
% Эрозия уменьшает объекты на изображении, удаляя пиксели по краям объектов.
% Дилатация увеличивает объекты, добавляя пиксели по краям объектов.
% В результате, мелкие детали, шумы и тонкие соединения в объектах могут быть удалены, и объекты становятся более компактными.
bw4 = bwareaopen(bw3, 5);
% Удаления объектов, размер которых менее 5 пикселей, что может помочь устранить мелкие
% шумы или небольшие объекты на изображении
bw4_perim = bwperim(bw4);
% выделение периметра объектов на бинарном изображении bw4, что позволяет визуализировать границы объектов 
% и может быть использовано для дальнейшего анализа.
    
    [labeledImage, numCells] = bwlabel(bw4);
    figure('name','SEGMENTATION-Transforms','units','normalized','outerposition',[0 0 1 1],'Color','white')
     subplot 221; imshow(bw2); grid on;
            title (['step1 - Використання holes'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r'); 
     subplot 222; imshow(bw3); grid on;
            title (['step2 - Морфологічне відкриття'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r');
     subplot 223; imshow(bw4); grid on;
            title (['step3 - Очистка від дрібних обєктів'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r'); 
     subplot 224; imshow(bw4_perim); grid on;
            title (['step4 - Виділення периметру'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r');


  overlay1 = imoverlay(I_equalizated, bw4_perim, [1 0 0]);
  figure('name','SEGMENTATION test_01 - overlay','units','normalized','outerposition',[0 0 1 1],'Color','white')
  imshow(overlay1); grid on;
            title (['step5'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r'); 



 
mask_em1 = imextendedmax(I_equalizated, 90);
% Расширение максимальных значений (extended maxima) на изображении I_equalizated с порогом 90. 
% Выделяем яркие максимальные области, возможно, представляющие интересные объекты на изображении.
mask_em2 = imclose(mask_em1, ones(3,3));
% операция морфологического замыкания (imclose) к изображению mask_em1 с использованием структурного 
% элемента размером 3x3. Операция морфологического замыкания объединяет близкие объекты и может быть 
% использована для заполнения небольших промежутков в объектах.
mask_em3 = imfill(mask_em2, 'holes');
mask_em4 = bwareaopen(mask_em3, 40);
% Удаление объектов (белых областей), размер которых меньше 40 пикселей, на изображении mask_em3. 
% Эта операция может быть полезна для удаления маленьких объектов или шумов, которые могли появиться 
% после предыдущих обработок.

    figure('name','SEGMENTATION test_01 - причесування2','units','normalized','outerposition',[0 0 1 1],'Color','white')
     subplot 221; imshow(mask_em1); grid on;
            title (['step6'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r'); 
     subplot 222; imshow(mask_em2); grid on;
            title (['step7'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r');
     subplot 223; imshow(mask_em3); grid on;
            title (['step8'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r'); 
     subplot 224; imshow(mask_em4); grid on;
            title (['step9'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r');

    overlay2 = imoverlay(I_equalizated, bw4_perim | mask_em4, [1 0 0]);
    figure('name','SEGMENTATION test_01 - OVERLAY','units','normalized','outerposition',[0 0 1 1],'Color','white')
             imshow(overlay2); grid on;
            title (['step6'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r'); 