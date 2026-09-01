
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Аналіз поляризаційних зображень
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = calc__INFO_About_Sample(savePath, readPath, pathForCode)

    filesInFolder = dir(fullfile(readPath, '*.bmp'));                      % получаем список всех файлов в папке
    for i = 1:numel(filesInFolder)
        [~, fileName, ~] = fileparts(filesInFolder(i).name);
        fileNames{i} = fileName;
    end

    cd (savePath);
    mkdir ('Інформація про поляризац. зображення') %(fileName);
    savePathLocal = [savePath, 'Інформація про поляризац. зображення', '\'];
    cd (savePathLocal); 
    disp(savePath);

    for i = 1 : numel(fileNames)     
          fileName = fileNames{i};

                    % путь для сохранения частей изоображения (подпапки 0-0, 0-90 и т.д.)
                    % mkdir (fileName);
                    % savePathLocal = [savePath, fileName, '\'];
                    % cd (savePathLocal); 
                    % pause(0.5);        
        %----------------------------------------------------------------------
        en ='.bmp';  
        [IM,mapIM] = imread([readPath, fileName, en]);
        IM =rgb2gray(IM);
        IM = double(IM);
        work_layer = '-';
        name = fileName;
        CORR_MATRIX_2D = xcorr2(IM);
        CORR_MATRIX_2D = CORR_MATRIX_2D + abs( min(min(CORR_MATRIX_2D)) );
        CORR_MATRIX_2D = CORR_MATRIX_2D./(max(max(CORR_MATRIX_2D)));
 
            IM_reshape = reshape (IM, 1, []);
            IM_SER = mean(IM_reshape);
            IM_SKV = std(IM_reshape);
            IM_A   = skewness(IM_reshape);
            IM_E   = kurtosis(IM_reshape);
        
            STAT_str = {['Mean = ' num2str( IM_SER )], 
                        ['Standart Deviation = ' num2str( IM_SKV )], 
                        ['Asymmetry = ' num2str( IM_A )], 
                        ['Kurtosis = ' num2str( IM_E )], 
            };
        
            location_dim = [.82 .82 .1 .1];

            % %----------------------------------------------------------------------
            % colormaps = {'jet', 'gray'};
            % for cm = 1:length(colormaps)
            %     colormap_value = colormaps{cm}; 
            %     %figure('name',[' 2D;  Layer = ' num2str( work_layer ) ],'units','normalized','outerposition',[0 0 1 1],'Color','white')
            %     figure('name',[' 2D;  Image - ' num2str( fileName ) ],'units','normalized','outerposition',[0 0 1 1],'Color','white','Visible', 'off');
            %     set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
            %     subplot 221; imshow (IM, 'DisplayRange', [min(min(IM)) max(max(IM))]); colormap (colormap_value); colorbar; 
            %             title ('2D','Color','r')
            %             xlabel('X, pixels','Color','r');
            %             ylabel('Y, pixels','Color','r');
            %     subplot 222; mesh (IM);
            %             xlabel('X, pixels','Color','r');
            %             ylabel('Y, pixels','Color','r');
            %             annotation('textbox',location_dim,'String', STAT_str,'FitBoxToText','on','BackgroundColor','white','FaceAlpha',.9)
            %     subplot 223; imshow (CORR_MATRIX_2D, 'DisplayRange', [min(min(CORR_MATRIX_2D)) max(max(CORR_MATRIX_2D))]); colormap (colormap_value); colorbar; 
            %             title ('AKF','Color','r')
            %             xlabel('X, pixels','Color','r')
            %             ylabel('Y, pixels','Color','r'); 
            %             grid on;
            %     subplot 224; histogram(IM_reshape, 200); xlim([min(min(IM)) max(max(IM))]); 
            %             title ('HISTOGRAM','Color','r')
            %             ylabel('N','Color','r')
            %             xlabel('200 equally spaced bins','Color','r');
            %             grid on;
            %     filename = fullfile(savePathLocal, sprintf('%s.Info about sample-%s.png', colormap_value, num2str(fileName)));
            %     % Збереження фігури у файл PNG
            %     saveas(gcf, filename);
            %     close(gcf);
            % end            

                    %--показываем область только 500 на 500 пикселей (удалить потом)
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %--показываем область только 500 на 500 пикселей
                    colormaps = {'jet', 'gray'};
                    % Извлекаем область 500x500 из верхнего левого угла
                    % Проверяем размеры изображения и берем минимум между 500 и реальным размером
                    crop_size = 500;
                    max_row = min(size(IM, 1), crop_size);
                    max_col = min(size(IM, 2), crop_size);
                    % Обрезаем изображение до области 500x500 (или меньше, если изображение меньше)
                    IM_cropped = IM(1:max_row, 1:max_col);
                    % Пересчитываем корреляционную матрицу для обрезанной области
                    CORR_MATRIX_2D_cropped = xcorr2(IM_cropped - mean(IM_cropped(:)));
                    % Reshape для гистограммы обрезанной области
                    IM_cropped_reshape = reshape(IM_cropped, [], 1);
                    % Пересчитываем статистику для обрезанной области (если нужно)
                    % Предполагаем, что STAT_str нужно пересчитать для новой области
                    % Если статистика должна остаться от полного изображения, закомментируйте этот блок
                    mean_val = mean(IM_cropped(:));
                    std_val = std(IM_cropped(:));
                    min_val = min(IM_cropped(:));
                    max_val = max(IM_cropped(:));
                    STAT_str = sprintf('Область 500x500\nMean: %.2f\nStd: %.2f\nMin: %.2f\nMax: %.2f', ...
                                       mean_val, std_val, min_val, max_val);
                    for cm = 1:length(colormaps)
                        colormap_value = colormaps{cm};
                        figure('name',[' 2D; Image - ' num2str(fileName) ' (500x500 region)'],'units','normalized','outerposition',[0 0 1 1],'Color','white','Visible', 'off');
                        set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
                        % Subplot 1: 2D изображение с крестиком в центре
                        subplot(2,2,1); 
                        imshow(IM_cropped, 'DisplayRange', [min(IM_cropped(:)) max(IM_cropped(:))]); 
                        colormap(colormap_value); 
                        colorbar;
                        title('2D (500x500 region)','Color','r')
                        xlabel('X, pixels','Color','r');
                        ylabel('Y, pixels','Color','r');
                        % Добавляем крестик в центр изображения
                        hold on;
                        center_x = max_col / 2;
                        center_y = max_row / 2;
                        % Белый крестик с черной обводкой для лучшей видимости
                        plot(center_x, center_y, 'k+', 'MarkerSize', 15, 'LineWidth', 3); % Черная обводка
                        plot(center_x, center_y, 'w+', 'MarkerSize', 12, 'LineWidth', 2); % Белый крестик
                        hold off;
                        % Subplot 2: 3D mesh
                        subplot(2,2,2); 
                        mesh(IM_cropped);
                        xlabel('X, pixels','Color','r');
                        ylabel('Y, pixels','Color','r');
                        zlabel('Intensity','Color','r');
                        title('3D Mesh (500x500 region)','Color','r');
                        % Аннотация со статистикой
                        annotation('textbox',location_dim,'String', STAT_str,'FitBoxToText','on','BackgroundColor','white','FaceAlpha',.9)
                        % Subplot 3: Автокорреляционная функция
                        subplot(2,2,3); 
                        imshow(CORR_MATRIX_2D_cropped, 'DisplayRange', [min(CORR_MATRIX_2D_cropped(:)) max(CORR_MATRIX_2D_cropped(:))]); 
                        colormap(colormap_value); 
                        colorbar;
                        title('AKF (500x500 region)','Color','r')
                        xlabel('X, pixels','Color','r')
                        ylabel('Y, pixels','Color','r');
                        grid on;
                        % Добавляем крестик в центр АКФ
                        hold on;
                        akf_center_x = size(CORR_MATRIX_2D_cropped, 2) / 2;
                        akf_center_y = size(CORR_MATRIX_2D_cropped, 1) / 2;
                        plot(akf_center_x, akf_center_y, 'k+', 'MarkerSize', 15, 'LineWidth', 3);
                        plot(akf_center_x, akf_center_y, 'w+', 'MarkerSize', 12, 'LineWidth', 2);
                        hold off;
                        % Subplot 4: Гистограмма
                        subplot(2,2,4); 
                        histogram(IM_cropped_reshape, 200); 
                        xlim([min(IM_cropped(:)) max(IM_cropped(:))]);
                        title('HISTOGRAM (500x500 region)','Color','r')
                        ylabel('N','Color','r')
                        xlabel('200 equally spaced bins','Color','r');
                        grid on;
                        % Сохранение фигуры
                        filename = fullfile(savePathLocal, sprintf('%s.Info about sample-%s_1,1-500,500.png', colormap_value, num2str(fileName)));
                        saveas(gcf, filename);
                        close(gcf);
                    end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



            % ----------------------------------------------------------------------------------
            % ----------------------------------------------------------------------------------
            % набиваем информацией конкретное (0-0 или 90-0) поляризационное изображение

            %  close all; pause(2); 
            %  calc_Full_Information(IM, '',savePath, fileName, 400);    
            % 
            % после наполнения стурктуры информацией про сегменты (стоим гистограммы)
              % close all; pause(2); cd(pathForCode);
              % calc_Histograms(data_sets,  savePath);
            % ----------------------------------------------------------------------------------
            % ----------------------------------------------------------------------------------
    end 
    close all
    pause(0.5);

end