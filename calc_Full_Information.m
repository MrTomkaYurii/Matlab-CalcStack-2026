%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Разарезает масив на 12 частей в виде квадрата 320 пикселей на 320
% пикселей (по умолчанию) либо по парамтру заданому пользователем и 
% для такой отдельно взятой части считает:
% - двумерную AKF 
% - перевод двумерной AKF в полярную систему координат
% - AKF(angle) - PSD(angle) - STAT - 
% - WAVELET
% - Сегментация
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [] = calc_Full_Information(image_3d, work_layer, savePath, name, segmentSize)
%  calc_Full_Information(image_3d, work_layer, savePath, name, segmentSize)
%  image_3d     - трехмерный массив с изоражениями по шарам, 
%  work_layer   - обрабатываемый шар, 
%  savePath     - корневая дирекория для сохранения, 
%  name         - имя параметра () для которого происходит расчет
%  segmentSize  - размер сегмента 

    % если вызов без рамерности сегмента, то устанавливаем по умолчанию 320
    % на 320 пикселей
    if nargin < 5 || isempty(segmentSize)
       segmentSize = 400; % Устанавливаем значение по умолчанию
    end

        %=>> для многошарового
        % IM(:,:) = image_3d (:,:,work_layer);
        %=>> для одношарового
          IM(:,:) = image_3d (:,:);
        
        assignin('base','IM',IM)
        programspath = evalin('base',  'pathForCode');

                %----------------------------------------------------------
                %%% РАЗБИТИЕ ИЗОБРАЖЕНИЯ НА ЧАСТИ И РАСЧЕТ
                %----------------------------------------------------------
                [row, col] = size(image_3d); 
                patchSize = segmentSize;

                global data_sets;
                global patch;                                               

                for i = 1:patchSize:1200%старт на 1
                    for j = 1:patchSize:800%старт на 1
                        % Извлекаем патч размером 400x400
                        patch = image_3d(i:min(i+patchSize-1, row), j:min(j+patchSize-1, col));
                        % Создаем уникальное имя папки на основе i и j
                        folder = sprintf('Part_%d_%d', i, j);
                        cd (savePath); mkdir (folder); savePath_PATCH = [savePath, folder, '\']; pause (1);
                        cd (savePath_PATCH); 

                       % для ЧАСТЕЙ производим полный расчет
                          % cd(programspath); pause(1);
                          %     CORR_MATRIX_2D = calc_Corr_Func_2D_2024(patch, '', savePath_PATCH, folder);
                          % close all; cd(programspath); pause(1);
                          %     calc_To_Polar_Coordinates(CORR_MATRIX_2D, '', savePath_PATCH, folder);
                          % close all; cd(programspath); pause(1);
                          %      POLAR_OUT = evalin('base',  'POLAR_OUT');
                          %      calc_Akf_Psd_Stat_Directions(CORR_MATRIX_2D, POLAR_OUT, 5, '-', savePath_PATCH, folder);
                          % close all; cd(programspath); pause(1);
                          %      calc_Segmentation(patch, '', savePath_PATCH, folder)
                          % close all; cd(programspath); pause(1);
                          %     calc_Wavelet(patch, savePath_PATCH, folder)                              
                    end
                end
                %----------------------------------------------------------
                %----------------------------------------------------------
end