function [] = calc_Segmentation(im_cropped, ...
    work_layer, ...
    saveTomka, ...
    name)
%   im_cropped      - изображение, 
%   work_layer      - обрабатываемый шар, 
%   saveTomka       - корневая дирекория для сохранения, 
%   name            - имя для калькулируемого параметра

im_cropped=im_cropped/255;
cd (saveTomka); pause(1);

   figure('name','SEGMENTATION-Original Image','units','normalized','outerposition',[0 0 1 1],'Color','white')
            imshow(im_cropped); colorbar; grid on;
            title (['Image'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r');
                pause(0.0001);
                frame_h = get(handle(gcf),'JavaFrame');
                set(frame_h,'Maximized',1);
                pause(1);
                img = getframe(gcf); imwrite(img.cdata, [['SEGMENTATION - Image - ' num2str( name )], '.jpeg']); pause(1)

   % Создание сетки координат для иследуемой области
   [x, y] = meshgrid(1:size(im_cropped, 2), size(im_cropped, 1):-1:1);

   figure('name','SEGMENTATION-Information','units','normalized','outerposition',[0 0 1 1],'Color','white')
     subplot 221; imshow(im_cropped); grid on; colorbar
            title (['Image'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r');
     subplot 222; histogram(im_cropped, 'NumBins', 256,'FaceAlpha',0.75,'EdgeColor', 'none'); grid on;
            title (['Image'],'Color','r') 
            xlabel('Values ','Color','r')
            ylabel('N','Color','r');
     subplot 223; contour(x,y,im_cropped); grid on; colorbar
            title (['Image'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r');
            axis equal;
     subplot 224; mesh(im_cropped); grid on;
            title (['Image'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r');
            view(45, 80);
                pause(0.0001);
                frame_h = get(handle(gcf),'JavaFrame');
                set(frame_h,'Maximized',1);
                pause(1);
                img = getframe(gcf); imwrite(img.cdata, [['SEGMENTATION - Information - ' num2str( name )], '.jpeg']); pause(1)

 %  Адаптивное гистограммное выравнивание (Adaptive Histogram Equalization, AHE) — метод обработки изображений, 
 %  который позволяет улучшить контрастность изображения, особенно в областях с низким контрастом. В отличие от 
 %  обычного гистограммного выравнивания, AHE применяет выравнивание гистограммы не ко всему изображению целиком, 
 %  а к небольшим локальным областям.

 I_equalizated = adapthisteq(im_cropped);

   figure('name','SEGMENTATION-Contrasted Image','units','normalized','outerposition',[0 0 1 1],'Color','white')
     subplot 221; imshow(I_equalizated); grid on;
            title (['Image after Adaptive Histogram Equalization, AHE'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r');
      subplot 222; histogram(I_equalizated, 'NumBins', 256,'FaceAlpha',0.75,'EdgeColor', 'none'); grid on;
            title (['Image'],'Color','r') 
            xlabel('Values ','Color','r')
            ylabel('N','Color','r');
     subplot 223; contour(x,y,I_equalizated); grid on; colorbar
            title (['Image after Adaptive Histogram Equalization, AHE'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r');
            axis equal;
     subplot 224; mesh(I_equalizated); grid on;
            title (['Image after Adaptive Histogram Equalization, AHE'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r');
            view(45, 80);
                pause(0.0001);
                frame_h = get(handle(gcf),'JavaFrame');
                set(frame_h,'Maximized',1);
                pause(1);
                img = getframe(gcf); imwrite(img.cdata, [['SEGMENTATION - Adaptive Histogram Equalization - ' num2str( name )], '.jpeg']); pause(1)
 
 % бинаризация изображения на основе graythresh для автоматического вычисления порога и функцию
 % все пиксели, чья интенсивность выше порога, становятся белыми, а остальные — черными
 
% Функция graythresh в MATLAB автоматически рассчитывает пороговое значение для изображения, 
% чтобы преобразовать его в изображение в оттенках серого. Этот порог выбирается таким образом, 
% чтобы оптимально разделить пиксели изображения на передний и задний планы, учитывая их распределение 
% яркости. В итоге, пиксели с яркостью выше порога считаются передним планом, а те, что ниже, - задним планом.


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
                pause(0.0001);
                frame_h = get(handle(gcf),'JavaFrame');
                set(frame_h,'Maximized',1);
                pause(1);
                img = getframe(gcf); imwrite(img.cdata, [['SEGMENTATION - Binarized Image - ' num2str( name )], '.jpeg']); pause(1)


bw2 = imfill(bw,'holes');  
% Вы имеете бинарное изображение bw, где объекты представлены белыми пикселями, а фон — черными.
% Функция imfill принимает два аргумента: изображение и строку, указывающую, какие области заполнить. 
% Строка 'holes' указывает, что нужно заполнить "дыры" в бинарном изображении.
% "Дыры" в бинарном изображении — это области, которые представляют собой черные области, 
% окруженные белыми пикселями. Функция imfill заполняет эти черные области (дыры), делая их белыми.
bw3 = imopen(bw2, ones(5,5));
% Морфологическое открытие над бинарным изображением bw2 с использованием структурного элемента 5x5. 
% Операция открытия включает в себя эрозию (erosion), а затем дилатацию (dilation).
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
            title (['step1 - Використання дірок на зображенні'],'Color','r') 
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
                pause(0.0001);
                frame_h = get(handle(gcf),'JavaFrame');
                set(frame_h,'Maximized',1);
                pause(1);
                img = getframe(gcf); imwrite(img.cdata, [['SEGMENTATION - Steps of Algorithm 01 - ' num2str( name )], '.jpeg']); pause(1)



  % накладання периметру на зображення
  overlay1 = imoverlay(I_equalizated, bw4_perim, [1 0 0]);
  figure('name','SEGMENTATION - overlay 01','units','normalized','outerposition',[0 0 1 1],'Color','white')
  imshow(overlay1); grid on;
            title (['step5'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r'); 
                pause(0.0001);
                frame_h = get(handle(gcf),'JavaFrame');
                set(frame_h,'Maximized',1);
                pause(1);
                img = getframe(gcf); imwrite(img.cdata, [['SEGMENTATION - Overlay 01 - ' num2str( name )], '.jpeg']); pause(1)


 
mask_em1 = imextendedmax(I_equalizated, 0.4);
% Расширение максимальных значений (extended maxima) на изображении I_equalizated с порогом 90. 
% Выделяем яркие максимальные области, возможно, представляющие интересные объекты на изображении.
mask_em2 = imclose(mask_em1, ones(3,3));
% операция морфологического замыкания (imclose) к изображению mask_em1 с использованием структурного 
% элемента размером 3x3. Операция морфологического замыкания объединяет близкие объекты и может быть 
% использована для заполнения небольших промежутков в объектах.
mask_em3 = imfill(mask_em2, 'holes');
% заполнение дырок в маске mask_em2 с помощью функции imfill для того, чтобы заполнить любые внутренние 
% области, которые полностью окружены пикселями переднего плана, в маске mask_em2.
mask_em4 = bwareaopen(mask_em3, 20);
% Удаление объектов (белых областей), размер которых меньше 20 пикселей, на изображении mask_em3. 
% Эта операция может быть полезна для удаления маленьких объектов или шумов, которые могли появиться 
% после предыдущих обработок.

    figure('name','SEGMENTATION test_01 - причесування2','units','normalized','outerposition',[0 0 1 1],'Color','white')
     subplot 221; imshow(mask_em1); grid on;
            title (['step6 - Виділення яскравих областей'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r'); 
     subplot 222; imshow(mask_em2); grid on;
            title (['step7 - Морфологічне замикання'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r');
     subplot 223; imshow(mask_em3); grid on;
            title (['step8 - Заповнення'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r'); 
     subplot 224; imshow(mask_em4); grid on;
            title (['step9 - Видалення дрібних обєктів'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r');
                pause(0.0001);
                frame_h = get(handle(gcf),'JavaFrame');
                set(frame_h,'Maximized',1);
                pause(1);
                img = getframe(gcf); imwrite(img.cdata, [['SEGMENTATION - Steps of Algorithm 02 - ' num2str( name )], '.jpeg']); pause(1)

    % накладання заливки на зображення
    overlay2 = imoverlay(I_equalizated, bw4_perim | mask_em4, [1 0 0]);
    figure('name','SEGMENTATION - OVERLAY 02','units','normalized','outerposition',[0 0 1 1],'Color','white')
             imshow(overlay2); grid on;
            title (['step6'],'Color','r') 
            xlabel('X, mkm ','Color','r')
            ylabel('Y, mkm','Color','r'); 
                pause(0.0001);
                frame_h = get(handle(gcf),'JavaFrame');
                set(frame_h,'Maximized',1);
                pause(1);
                img = getframe(gcf); imwrite(img.cdata, [['SEGMENTATION - Overlay 02 - ' num2str( name )], '.jpeg']); pause(1)
    %---------
    close all;
    pause (2);
end

