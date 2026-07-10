%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Аналіз поляризаційних зображень з круговою областю
% Улучшенная версия с быстрым расчетом 2D АКФ через xcorr2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = calc__INFO_About_Sample_Circular(savePath, readPath, pathForCode)

    %==========================================================================
    % ПАРАМЕТРЫ - ВСЕ НАСТРОЙКИ ЗДЕСЬ
    %==========================================================================
    square_size = 920;                          % Размер квадрата для вырезания (пикселей)
    circle_radius_main = 460;                   % Радиус основного круга (пикселей) 
    acf_circle_radius = circle_radius_main * 2; % Радиус круга для АКФ = 920 пикселей
    histogram_bins = 200;                       % Количество бинов для гистограммы
    max_threads = 16;                           % Максимальное количество потоков
    colormaps = {'jet', 'gray'};               % Цветовые схемы для визуализации
    %==========================================================================
    
    % Получаем список файлов
    filesInFolder = dir(fullfile(readPath, '*.bmp'));
    for i = 1:numel(filesInFolder)
        [~, fileName, ~] = fileparts(filesInFolder(i).name);
        fileNames{i} = fileName;
    end

    % Создаем папку для результатов
    cd(savePath);
    mkdir('Інформація про поляризац. зображення (круг)');
    savePathLocal = [savePath, '\','Інформація про поляризац. зображення (круг)', '\'];
    cd(savePathLocal); 
    disp(savePath);
    
    % Настройка параллельных вычислений
    if isempty(gcp('nocreate'))
        try
            parpool('local', min(max_threads, feature('numcores')));
        catch
            fprintf('Не удалось создать параллельный пул. Используем последовательные вычисления.\n');
        end
    end

    for i = 1 : numel(fileNames)     
        fileName = fileNames{i};
        fprintf('Обрабатываем изображение %d/%d: %s\n', i, numel(fileNames), fileName);
        
        % Загрузка изображения
        en = '.bmp';  
        [IM, ~] = imread([readPath,'/', fileName, en]);
        IM = rgb2gray(IM);
        IM = double(IM);
        
        % Шаг 1: Вырезаем квадрат размером square_size
        [img_height, img_width] = size(IM);
        center_x = round(img_width / 2);
        center_y = round(img_height / 2);
        
        half_size = round(square_size / 2);
        x1 = max(1, center_x - half_size);
        x2 = min(img_width, center_x + half_size - 1);
        y1 = max(1, center_y - half_size);
        y2 = min(img_height, center_y + half_size - 1);
        
        % Убеждаемся, что получили квадрат нужного размера
        actual_width = x2 - x1 + 1;
        actual_height = y2 - y1 + 1;
        if actual_width ~= square_size || actual_height ~= square_size
            % Дополняем до нужного размера нулями если нужно
            IM_square = zeros(square_size, square_size);
            start_y = round((square_size - actual_height) / 2) + 1;
            start_x = round((square_size - actual_width) / 2) + 1;
            IM_square(start_y:start_y+actual_height-1, start_x:start_x+actual_width-1) = IM(y1:y2, x1:x2);
        else
            IM_square = IM(y1:y2, x1:x2);
        end
        
        % Шаг 2: Быстрый расчет 2D АКФ с помощью xcorr2
        fprintf('  Расчет 2D автокорреляционной функции...\n');
        tic;
        
        % Рассчитываем автокорреляцию с помощью xcorr2
        CORR_MATRIX_2D_full = xcorr2(IM_square);
        
        % Нормируем АКФ
        CORR_MATRIX_2D_full = CORR_MATRIX_2D_full / max(CORR_MATRIX_2D_full(:));
        
        fprintf('  АКФ рассчитана за %.2f сек\n', toc);
        
        % Шаг 3: Работаем с полной АКФ и вырезаем круг радиусом acf_circle_radius
        % Полная АКФ имеет размер примерно (2*920-1) = 1839x1839
        [acf_full_height, acf_full_width] = size(CORR_MATRIX_2D_full);
        acf_center_x = round(acf_full_width / 2);
        acf_center_y = round(acf_full_height / 2);
        
        % Создаем круговую маску для АКФ
        [X_acf, Y_acf] = meshgrid(1:acf_full_width, 1:acf_full_height);
        distances_acf = sqrt((X_acf - acf_center_x).^2 + (Y_acf - acf_center_y).^2);
        acf_circular_mask = distances_acf <= acf_circle_radius;
        
        % Применяем маску к АКФ
        CORR_MATRIX_2D = CORR_MATRIX_2D_full;
        CORR_MATRIX_2D(~acf_circular_mask) = NaN;
        
        % Шаг 4: Создаем круговую маску для основного изображения
        [square_height, square_width] = size(IM_square);
        mask_center_x = round(square_width / 2);
        mask_center_y = round(square_height / 2);
        
        [X, Y] = meshgrid(1:square_width, 1:square_height);
        distances = sqrt((X - mask_center_x).^2 + (Y - mask_center_y).^2);
        circular_mask = distances <= circle_radius_main;
        
        % Применяем круговую маску к основному изображению
        IM_circular = IM_square;
        IM_circular(~circular_mask) = NaN;
        
        % Статистика только для точек внутри круга
        valid_pixels = IM_square(circular_mask);
        
        IM_SER = mean(valid_pixels);
        IM_SKV = std(valid_pixels);
        IM_A   = skewness(valid_pixels);
        IM_E   = kurtosis(valid_pixels);
        
        STAT_str = sprintf('Mean: %.2f\nStd: %.2f\nAsymmetry: %.3f\nKurtosis: %.3f', ...
                            IM_SER, IM_SKV, IM_A, IM_E);
        
        % Визуализация
        location_dim = [.82 .82 .15 .15];
        
        for cm = 1:length(colormaps)
            colormap_value = colormaps{cm};
            figure('name', [' 2D; Image - ' num2str(fileName) ' (Square=' num2str(square_size) ', Circle R=' num2str(circle_radius_main) ')'], ...
                   'units', 'normalized', 'outerposition', [0 0 1 1], 'Color', 'white', 'Visible', 'off');
            set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
            
            % Subplot 1: 2D изображение с круговой маской
            subplot(2,2,1);
            h_img = imagesc(IM_square); 
            
            % Прозрачность для областей вне круга
            alpha_mask = double(circular_mask);
            set(h_img, 'AlphaData', alpha_mask);
            
            colormap(colormap_value); 
            colorbar;
            axis equal;
            axis tight;
            grid on;
            title(['2D (Квадрат ' num2str(square_size) 'x' num2str(square_size) ', Коло R=' num2str(circle_radius_main) ')'], 'Color', 'r')
            xlabel('X, pixels', 'Color', 'r');
            ylabel('Y, pixels', 'Color', 'r');
            
            % Добавляем визуальные элементы
            hold on;
            plot(mask_center_x, mask_center_y, 'k+', 'MarkerSize', 15, 'LineWidth', 3);
            plot(mask_center_x, mask_center_y, 'w+', 'MarkerSize', 12, 'LineWidth', 2);
            
            theta = linspace(0, 2*pi, 100);
            circle_x = mask_center_x + circle_radius_main * cos(theta);
            circle_y = mask_center_y + circle_radius_main * sin(theta);
            plot(circle_x, circle_y, 'r-', 'LineWidth', 1);
            hold off;
            
            % Subplot 2: 3D surface
            subplot(2,2,2);
            [mesh_x, mesh_y] = meshgrid(1:square_width, 1:square_height);
            IM_3d = IM_square;
            IM_3d(~circular_mask) = NaN;
            
            surf(mesh_x, mesh_y, IM_3d, 'EdgeColor', 'none', 'FaceAlpha', 0.8);
            view(3);
            xlabel('X, pixels', 'Color', 'r');
            ylabel('Y, pixels', 'Color', 'r');
            zlabel('Intensity', 'Color', 'r');
            title(['3D Surface (Квадрат ' num2str(square_size) ', Коло R=' num2str(circle_radius_main) ')'], 'Color', 'r');
            
            % Аннотация со статистикой
            annotation('textbox', location_dim, 'String', STAT_str, 'FitBoxToText', 'on', ...
                      'BackgroundColor', 'white', 'FaceAlpha', .9, 'FontSize', 8)
            
            % Subplot 3: 2D АКФ в натуральном размере
            subplot(2,2,3);
            h_acf = imagesc(CORR_MATRIX_2D); 
            
            % Прозрачность для областей вне круга АКФ
            alpha_mask_acf = double(acf_circular_mask);
            set(h_acf, 'AlphaData', alpha_mask_acf);
            
            colormap(colormap_value); 
            colorbar;
            axis equal;
            axis tight;
            grid on;
            set(gca, 'YDir', 'reverse'); % Нумерация по Y снизу вверх
            title(['2D АКФ (розмір ' num2str(acf_full_height) 'x' num2str(acf_full_width) ', R=' num2str(acf_circle_radius) ')'], 'Color', 'r')
            xlabel('X, pixels', 'Color', 'r')
            ylabel('Y, pixels', 'Color', 'r');
            
            % Добавляем окружность в натуральных координатах
            hold on;
            acf_circle_x = acf_center_x + acf_circle_radius * cos(theta);
            acf_circle_y = acf_center_y + acf_circle_radius * sin(theta);
            plot(acf_circle_x, acf_circle_y, 'r-', 'LineWidth', 1);
            hold off;
            
            % Subplot 4: Гистограмма
            subplot(2,2,4);
            histogram(valid_pixels, histogram_bins);
            xlim([min(valid_pixels) max(valid_pixels)]);
            title(['HISTOGRAM (Коло R=' num2str(circle_radius_main) ')'], 'Color', 'r')
            ylabel('N', 'Color', 'r')
            xlabel([num2str(histogram_bins) ' equally spaced bins'], 'Color', 'r');
            grid on;
            
            % Сохранение
            filename = fullfile(savePathLocal, sprintf('%s.Info_about_sample-%s_CircleR%d_ACF-R%d.png', ...
                               colormap_value, num2str(fileName), circle_radius_main, acf_circle_radius));
            saveas(gcf, filename);
            close(gcf);
        end
        
        fprintf('  Сохранено: Circle R=%d, ACF размер %dx%d с кругом R=%d, точек в круге: %d\n', ...
                circle_radius_main, acf_full_height, acf_full_width, acf_circle_radius, length(valid_pixels));
    end 
    
    % Закрываем параллельный пул
    if ~isempty(gcp('nocreate'))
        delete(gcp('nocreate'));
    end
    
    close all
    pause(0.5);
    
    fprintf('\n=== АНАЛИЗ ЗАВЕРШЕН ===\n');
    fprintf('Размер квадрата: %dx%d пикселей\n', square_size, square_size);
    fprintf('Радиус основного круга: %d пикселей\n', circle_radius_main);
    fprintf('АКФ: натуральный размер ~%dx%d, радиус круга: %d пикселей\n', 2*square_size, 2*square_size, acf_circle_radius);
    fprintf('Обработано изображений: %d\n', length(fileNames));
    fprintf('Результаты сохранены в: %s\n', savePathLocal);

end