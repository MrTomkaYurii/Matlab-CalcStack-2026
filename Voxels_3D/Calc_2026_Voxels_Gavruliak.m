clear; close all; clc;

%==========================================================================
% Параметры чтения, обработки и сохранения
%==========================================================================
% Основные параметры
crop_size = 300;                                                           % Размер области (k x k пикселей)
base_path = 'C:\\Users\\Yurii\\Desktop\\Results_10_30_tomka\\';            % Базовый путь к папкам
pathForSave = 'C:\\[TOMKA] - Modelling 2026\\01. Voxels - 3D. Зразок від Гавриляка\\';                         % Путь для сохранения
num_steps = 25;                                                            % Количество шагов

% Список имен файлов для обработки
file_names = {
    'alpha_0_argument'
    'alpha_0_module'
    'alpha_45_argument'
    'alpha_45_module'
    'beta_0_argument'
    'beta_0_module'
    'beta_45_argument'
    'beta_45_module'
    'r_12_amplitude'
    'r_12_phase'
    'r_14_amplitude'
    'r_14_phase'
    'r_23_amplitude'
    'r_23_phase'
    'r_24_amplitude'
    'r_24_phase'
};

file_names_for_use = {
    'alpha_0. Argument '
    'alpha_0. Module '
    'alpha_{45}. Argument '
    'alpha_{45}. Module '
    'beta_0. Argument '
    'beta_0. Module '
    'beta_{45}. Argument '
    'beta_{45}. Module '
    'r_{12}. Amplitude '
    'r_{12}. Phase '
    'r_{14}. Amplitude '
    'r_{14}. Phase '
    'r_{23}. Amplitude '
    'r_{23}. Phase '
    'r_{24}. Amplitude '
    'r_{24}. Phase '
};

% Визуализация (цветовые параметры)
cmap = jet;             % Color map for data visualization
face_alpha = 0.75;          % Transparency for 3D visualizations
face_alpha2 = 0.5;
fontSize = 15;

%==========================================================================
%==========================================================================
% 1. Загрузка данных в структуру (отдельный шар - это шаг)
%==========================================================================
%==========================================================================

disp('== Загрузка данных ==');
data_structure = struct(); % Инициализация структуры

for file_id = 1:length(file_names)
    file_to_load = file_names{file_id};
    fprintf('Processing file: %s\n', file_to_load);

    % Инициализация пустого массива для данных
    temp_data = [];
    for step = 0:num_steps
        % Формирование пути к файлу
        folder_name = sprintf('phase_range_0_2pi_minus_%dsteps', step);
        file_path = fullfile(base_path, folder_name, [file_to_load, '.mat']);
        if exist(file_path, 'file')
            loaded_data = load(file_path);
            field_names = fieldnames(loaded_data);
            current_layer = loaded_data.(field_names{1});

            if isempty(temp_data)
                [rows, cols] = size(current_layer);
                temp_data = zeros(rows, cols, num_steps + 1);
            end
            temp_data(:, :, step + 1) = current_layer;
        else
            warning('File not found: %s', file_path);
        end
    end
    %clear temp_data;
    % Сохранение данных в структуру
    data_structure.(file_to_load) = temp_data;
end
save('final_combined_structure.mat', 'data_structure');
disp('All data saved into final_combined_structure.mat.');

%==========================================================================
% 2. Визуализация в класическом приближении
%==========================================================================

disp('== Visualizing and Saving Data ==');
structure_fields = fieldnames(data_structure);

for field_idx = 1:length(structure_fields)
    current_field = structure_fields{field_idx};
    current_field_name = file_names_for_use{field_idx};
    current_data = data_structure.(current_field);

    % Создание папки для текущего типа данных (например, alpha_0_argument)
    save_folder = fullfile(pathForSave, current_field);
    if ~exist(save_folder, 'dir')
        mkdir(save_folder);
    end

    % Перебор всех слоев данных
    for layer_idx = 1:size(current_data, 3)
        current_layer_data = current_data(:, :, layer_idx);
        % Создание новой фигуры для текущего слоя
        figure_handle = figure('Visible', 'off', 'Position', [100, 100, 1200, 800]); 
        % [1] 2D Visualization (Color Map)
        subplot(1, 2, 1);
        imagesc(current_layer_data);
        colormap(cmap); colorbar;
        axis image; title(sprintf('2D Color Map: %s. Layer(step) %d', current_field_name, layer_idx));
        xlabel('X, pixels'); ylabel('Y, pixels'); zlabel('Intensity');
        % [2] 3D Visualization (Color Surface)
        [X, Y] = meshgrid(1:size(current_layer_data, 2), 1:size(current_layer_data, 1));
        subplot(1, 2, 2);
        surf(X, Y, current_layer_data, 'EdgeColor', 'none', 'FaceAlpha', face_alpha);
        colormap(cmap); colorbar;
        title(sprintf('3D Surface Plot: %s Layer %d', current_field_name, layer_idx));
        xlabel('X, pixels'); ylabel('Y, pixels'); zlabel('Intensity');
        view([-45, 70]); % Установить азимут -45° и высоту 70°
        % Генерация файла для сохранения
        output_filename = sprintf('%s_Layer_%02d.png', current_field, layer_idx);
        saveas(figure_handle, fullfile(save_folder, output_filename));
        close(figure_handle); % Закрываем фигуру
    end
end

%==========================================================================
%==========================================================================
% 3. Визуализация 2D шаров последовательно вдоль оси ОХ
%==========================================================================
%==========================================================================

disp('== Визуализация шаров в 2D с надписями и греческими обозначениями ==');
structure_fields = fieldnames(data_structure);

selected_layers = [1, 5, 10, 15, 20, 25];  % Слои для визуализации (по оси OX)
space_between_blinchiki = 5;               % Расстояние между "блинчиками" (в пикселях)

for field_idx = 1:length(structure_fields)
    current_field = structure_fields{field_idx};
    current_field_name = file_names_for_use{field_idx};
    current_data = data_structure.(current_field);
    % Создание папки для сохранения
    save_folder = fullfile(pathForSave, current_field);
    if ~exist(save_folder, 'dir')
        mkdir(save_folder);
    end

    % Вычисление итоговой ширины изображения: шары плюс промежутки
    blinchiki_width = size(current_data, 2); % Ширина одного слоя
    total_width = blinchiki_width * length(selected_layers) + space_between_blinchiki * (length(selected_layers) - 1);
    total_height = size(current_data, 1) + 70; % Высота слоя плюс место для надписей
    % Итоговая матрица изображения
    combined_image = zeros(total_height, total_width);
    % Начало рисования блинчиков
    figure('Visible', 'off', 'Position', [100, 100, 1600, 800]); 
    hold on;

    x_start = 1; % Начальная координата по оси X
    for i = 1:length(selected_layers)
        layer_idx = selected_layers(i); % Индекс слоя
        if layer_idx > size(current_data, 3)
            warning('Layer %d отсутствует для %s. Пропускаем...', layer_idx, current_field);
            continue;
        end
        % Загрузка данных текущего слоя
        layer_data = current_data(:, :, layer_idx);
        % Размещение слоя (блинчика) в изображении
        x_end = x_start + blinchiki_width - 1;
        imagesc([x_start, x_end], [1, size(layer_data, 1)], layer_data);
        colormap(cmap);
        % Генерация текста для текущего слоя (греческий символ и индекс)
        text_x = x_start + round(blinchiki_width / 2);
        text_y = size(layer_data, 1) + 30; 
        % Подпись над блинчиком
        layer_name = current_field_name;
        %greek_symbol = '\alpha'; % Используем греческий символ, это пример
        % if contains(layer_name, 'module')
        %     greek_symbol = '\mu'; % Подмена символа для модуля на греческую букву
        % end
        layer_label = sprintf('layer(step)=%d', layer_idx);
        text(text_x, text_y, layer_label, 'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
        % Обновление смещения координат
        x_start = x_end + space_between_blinchiki; % Смещение для следующего блинчика
    end

    % Финальные настройки визуализации
    axis image;
    colorbar;
    xlabel(sprintf('Візуалізація шарів для %s площини ZOY взводж осі OX', current_field_name));
    xticks([]);
    ylabel('Y, pixels')

    grid on;

    % Сохранение результата
    output_filename = fullfile(save_folder, sprintf('%s_2D_Layers_in_Row_01.png', current_field));
    saveas(gcf, output_filename);
    close(gcf); % Закрытие фигуры
    fprintf('Результат сохранен: %s\n', output_filename);
end

%==========================================================================
%==========================================================================
% 4. Визуализация слоев: Размер плоскости 300×300 пикселей, X = [1, 5, 10, 15, 20, 25]
%==========================================================================
%==========================================================================

disp('== Визуализация слоев с расстоянием между слоями по оси OX (300×300 пикселей) под углом ==');
structure_fields = fieldnames(data_structure);

selected_layers = [1, 5, 10, 15, 20, 25];  % Слои для визуализации по оси X
distance_between_planes = 100;             % Расстояние между слоями по оси OX

for field_idx = 1:length(structure_fields)
    current_field = structure_fields{field_idx};
    current_field_name = file_names_for_use{field_idx};
    current_data = data_structure.(current_field);

    % Создание папки для сохранения
    save_folder = fullfile(pathForSave, current_field);
    if ~exist(save_folder, 'dir')
        mkdir(save_folder);
    end

    % Создание фигуры для визуализации
    figure('Visible', 'on', 'Position', [100, 100, 1600, 900]);
    hold on;

    % Визуализация каждого слоя
    for i = 1:length(selected_layers)
        layer_idx = selected_layers(i); % Индекс слоя
        if layer_idx > size(current_data, 3)
            warning('Слой %d отсутствует для %s. Пропускаем...', layer_idx, current_field);
            continue;
        end

        % Загрузка данных текущего слоя
        layer_data = current_data(1:300, 1:300, layer_idx); % Обрезание до 300×300 пикселей

        % Проверка на наличие NaN и замена их на минимальное значение в текущем слое
        if any(isnan(layer_data(:))) % Проверяем наличие NaN в слое
            min_value = min(layer_data(~isnan(layer_data)), [], 'all'); % Ищем минимальное значение среди не-NaN
            layer_data(isnan(layer_data)) = min_value; % Заменяем NaN на минимальное значение
        end

        % Сетка для отображения слоя
        [Y_grid, Z_grid] = meshgrid(1:size(layer_data, 1), 1:size(layer_data, 2));
        X_grid = (distance_between_planes * (i - 1)) * ones(size(layer_data)); % Смещение по оси X

        % Построение слоя
        surf(X_grid, Y_grid, Z_grid, layer_data, 'EdgeColor', 'none', 'FaceAlpha', 0.9);

        % Рамка слоя (по границам визуализируемой матрицы)
        x_min = min(X_grid(:));
        x_max = max(X_grid(:));
        y_min = 1;
        y_max = size(layer_data, 1);
        z_min = 1;
        z_max = size(layer_data, 2);

        % Координаты углов рамки для построения прямоугольника
        rect_X = [x_min, x_min, x_max, x_max, x_min];
        rect_Y = [y_min, y_max, y_max, y_min, y_min];
        rect_Z = [1, 1, size(layer_data, 2), size(layer_data, 2), 1];

        % Рисуем белую рамку вокруг слоя
        plot3(rect_X, rect_Y, rect_Z, 'w-', 'LineWidth', 4); % Белая обводка с толщиной 4

        % Добавляем подпись для текущего слоя напротив оси X
        text(mean([x_min, x_max]), y_min - 20, z_min - 10, sprintf('layer/step = %d', layer_idx), ...
            'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', 'k', 'FontWeight', 'bold');
    end

    % Настройки графика
    colormap(cmap);
    colorbar;
    axis equal;
    axis([0, (distance_between_planes * (length(selected_layers) - 1)) + distance_between_planes, 0, 300, 0, 300]); % Ограничение осей

    % Установка цвета заголовка и подписей осей в черный
    title(sprintf('Візуалізація шарів для %s площини ZOY вздовж осі OX', current_field_name), 'Color', 'k');
    ylabel('Y, pixels', 'Color', 'k');
    zlabel('Z, pixels', 'Color', 'k');

    grid on;
    view([35, 35]); % Угол визуализации
    xticks([]);

    % Сохранение
    output_filename = fullfile(save_folder, sprintf('%s_Spaced_X.png', current_field));
    saveas(gcf, output_filename);
    close(gcf); % Закрытие фигуры
    fprintf('Результат сохранён: %s\n', output_filename);
end

%===========================================================================
%===========================================================================
%= 6. Обработка данных на уровне плиток (crop) с возможностью вставки кода =
%===========================================================================
%===========================================================================
disp('== Обработка данных с разбиением и созданием подпапок ==');
structure_fields = fieldnames(data_structure);
for field_idx = 1:length(structure_fields)
    current_field = structure_fields{field_idx};
    current_data = data_structure.(current_field);
    % Размер данных
    [num_rows, num_cols, ~] = size(current_data);
    % Генерация подпапок
    for row_start = 1:crop_size:num_rows
        for col_start = 1:crop_size:num_cols
            % Координаты текущего блока
            row_end = min(row_start + crop_size - 1, num_rows);
            col_end = min(col_start + crop_size - 1, num_cols);
            % Создание подпапки
            crop_folder_name = sprintf('Rows_{%d-%d}Cols_{%d-%d}', row_start, row_end, col_start, col_end);
            save_folder = fullfile(pathForSave, current_field, crop_folder_name);
            if ~exist(save_folder, 'dir')
                mkdir(save_folder);
                fprintf('Папка %s создана.\n', save_folder);
            else
                fprintf('Папка %s уже существует. Пропущено.\n', save_folder);
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % --- Ваш код для обработки данных ---
            % Тут вставьте ваш код для обработки и визуализации, например:

            %1. Извлечение данных из текущей плитки
            crop_data = current_data(row_start:row_end, col_start:col_end, :);

            %--------------------------------------------------------------
            %--------------------------------------------------------------
            % 01. Min Max Mean
            % === ВИЗУАЛИЗАЦИЯ 5% МИНИМАЛЬНЫХ И МАКСИМАЛЬНЫХ ЗНАЧЕНИЙ С СОХРАНЕНИЕМ В ПОДПАПКИ ===
            fprintf('\n=== Визуализация 5%% минимальных, 5%% максимальных и ±2.5%% от среднего значений ===\n');
            M = crop_data; % Используем текущую плитку данных
            
            % --- Пороги для 5% минимальных и максимальных значений ---
            min_threshold = prctile(M(:), 5); % Порог для 5% минимальных значений
            max_threshold = prctile(M(:), 95); % Порог для 5% максимальных значений
            fprintf('Минимальный порог (5%%): %.4f\n', min_threshold);
            fprintf('Максимальный порог (95%%): %.4f\n', max_threshold);
            
            % --- Расчёт границ для диапазона ±2.5% от среднего значения ---
            mean_lower_threshold = prctile(M(:), 47.5); % Порог для -2.5%
            mean_upper_threshold = prctile(M(:), 52.5); % Порог для +2.5%
            fprintf('Порог для среднего значения -2.5%%: %.4f\n', mean_lower_threshold);
            fprintf('Порог для среднего значения +2.5%%: %.4f\n', mean_upper_threshold);
            
            % Генерация масок ---
            L_mask_min = M <= min_threshold; % Маска для минимальных значений
            L_mask_max = M >= max_threshold; % Маска для максимальных значений
            L_mask_mean = (M >= mean_lower_threshold) & (M <= mean_upper_threshold); % Маска для средних значений
            
            % --- Визуализация минимальных значений ---
            min_figure = figure('Visible', 'off', 'Position', [100, 100, 1400, 1000]); % Фигура для минимальных значений
            title('5% Minimal Values in 3D Volume', 'FontSize', fontSize, 'FontWeight', 'bold');
            xlabel('X - Columns', 'FontSize', fontSize); 
            ylabel('Y - Rows', 'FontSize', fontSize); 
            zlabel('Z - Layers', 'FontSize', fontSize);
            hold on;
            
            % Построение данных для минимальных значений
            [F_min, V_min, C_min] = im2patch(M, L_mask_min, 'vb');
            gpatch(F_min, V_min, C_min, 'none', face_alpha); % Воксели с прозрачностью
            
            % Настройка визуализации
            colormap(cmap); % Палитра цветов
            colorbar; % Шкала значений
            caxis([min(M(:)) max(M(:))]); % Диапазон цветов
            lighting gouraud; % Гладкое освещение
            light('Position', [0, 0, 10], 'Style', 'infinite'); % Источник света
            material shiny; % Глянцевое освещение
            axisGeom(gca, fontSize); % Настройка осей
            view([-40, 60]); % Угол визуализации
            axis equal; axis tight; % Пропорции графика
            
            % Сохранение изображения для минимальных значений
            output_min_file = fullfile(save_folder, sprintf('%s_MinValues_5Percent.png', crop_folder_name));
            saveas(min_figure, output_min_file); % Сохранить изображение
            close(min_figure); % Закрыть фигуру
            fprintf('Изображение для 5%% минимальных значений сохранено: %s\n', output_min_file);
            
            % --- Визуализация максимальных значений ---
            max_figure = figure('Visible', 'off', 'Position', [100, 100, 1400, 1000]); % Фигура для максимальных значений
            title('5% Maximal Values in 3D Volume', 'FontSize', fontSize, 'FontWeight', 'bold');
            xlabel('X - Columns', 'FontSize', fontSize); 
            ylabel('Y - Rows', 'FontSize', fontSize); 
            zlabel('Z - Layers', 'FontSize', fontSize);
            hold on;
            
            % Построение данных для максимальных значений
            [F_max, V_max, C_max] = im2patch(M, L_mask_max, 'vb');
            gpatch(F_max, V_max, C_max, 'none', face_alpha); % Воксели с прозрачностью
            
            % Настройка визуализации
            colormap(cmap); % Палитра цветов
            colorbar; % Шкала значений
            caxis([min(M(:)) max(M(:))]); % Диапазон цветов
            lighting gouraud; % Гладкое освещение
            camlight headlight; % Источник света
            material shiny; % Глянцевое освещение
            axisGeom(gca, fontSize); % Настройка осей
            view([-40, 60]); % Угол визуализации
            axis equal; axis tight; % Пропорции графика
            
            % Сохранение изображения для максимальных значений
            output_max_file = fullfile(save_folder, sprintf('%s_MaxValues_5Percent.png', crop_folder_name));
            saveas(max_figure, output_max_file); % Сохранить изображение
            close(max_figure); % Закрыть фигуру
            fprintf('Изображение для 5%% максимальных значений сохранено: %s\n', output_max_file);
            
            % --- Визуализация значений в диапазоне ±2.5% от среднего значения ---
            mean_figure = figure('Visible', 'off', 'Position', [100, 100, 1400, 1000]); % Фигура для средних значений
            title('±2.5% Mean Values in 3D Volume', 'FontSize', fontSize, 'FontWeight', 'bold');
            xlabel('X - Columns', 'FontSize', fontSize); 
            ylabel('Y - Rows', 'FontSize', fontSize); 
            zlabel('Z - Layers', 'FontSize', fontSize);
            hold on;
            
            % Построение данных для значений в диапазоне ±2.5%
            [F_mean, V_mean, C_mean] = im2patch(M, L_mask_mean, 'vb');
            gpatch(F_mean, V_mean, C_mean, 'none', face_alpha); % Воксели с прозрачностью
            
            % Настройка визуализации
            colormap(cmap); % Палитра цветов
            colorbar; % Шкала значений
            caxis([min(M(:)) max(M(:))]); % Диапазон цветов
            lighting gouraud; % Гладкое освещение
            light('Position', [0, 0, 10], 'Style', 'infinite'); % Источник света
            material shiny; % Глянцевое освещение
            axisGeom(gca, fontSize); % Настройка осей
            view([-40, 60]); % Угол визуализации
            axis equal; axis tight; % Пропорции графика
            
            % Сохранение изображения для диапазона средних значений
            output_mean_file = fullfile(save_folder, sprintf('%s_MeanValues_2.5Percent.png', crop_folder_name));
            saveas(mean_figure, output_mean_file); % Сохранить изображение
            close(mean_figure); % Закрыть фигуру
            fprintf('Изображение для ±2.5%% от среднего значения сохранено: %s\n', output_mean_file);
            
            fprintf('Визуализация завершена для всех диапазонов значений.\n');


                                    
            %--------------------------------------------------------------
            %--------------------------------------------------------------
            % 02. GIF Animation
            M = crop_data; % Используем текущую плитку данных
            fprintf('\n=== 3D VISUALIZATION WITH MOVING CAMERA ===\n');
            fprintf('Size of %s data: %d x %d x %d\n', current_field, size(M, 1), size(M, 2), size(M, 3));

            cFigure;
            % Title and axis labels
            title(sprintf('3D Voxel Visualization with Moving Camera: %s', crop_folder_name));
            xlabel('X - Columns'); 
            ylabel('Y - Rows'); 
            zlabel('Z - Layers');
            hold on;
            % Setting layer spacing
            slice_spacing = 1.0;
            % Calculating gradient
            fprintf('Calculating gradient...\n');
            [Gx, Gy, Gz] = gradient(M);
            Gmag = sqrt(Gx.^2 + Gy.^2 + Gz.^2); % Magnitude of the gradient

            % Gradient threshold for visualization (top 15%)
            threshold_grad = prctile(Gmag(:), 85); % Top 15% of gradient magnitude
            L_mask_grad = Gmag >= threshold_grad;
            fprintf('Gradient threshold: %.4f\n', threshold_grad);
            fprintf('Number of boundary voxels: %d\n', sum(L_mask_grad(:))); % Count selected voxels
            % Extract voxel indices
            [I_ind, J_ind, K_ind] = ind2sub(size(M), find(L_mask_grad)); 
            % Data visualization with layer spacing
            for k = 1:size(M, 3)
                slice_mask = (K_ind == k); % Select the current slice (layer)
                if sum(slice_mask) > 0
                    L_current_slice = false(size(M));
                    linear_ind = sub2ind(size(M), I_ind(slice_mask), J_ind(slice_mask), K_ind(slice_mask));
                    L_current_slice(linear_ind) = true; % Apply mask for the current slice
                    [F, V, C] = im2patch(M, L_current_slice, 'vb');
                    % Adding Z-coordinate spacing between layers
                    V(:, 3) = V(:, 3) + (k - 1) * slice_spacing;
                    % Layer transparency (increases with depth)
                    faceAlpha = 0.4 + 0.6 * (k / size(M, 3)); % Transparency based on layer depth
                    hp = gpatch(F, V, C, 'none', faceAlpha);
                    set(hp, 'EdgeColor', 'none');
                end
            end
            % Color map settings
            colormap(cmap);
            colorbar;
            caxis([min(M(:)) max(M(:))]);
            axis equal; % Preserve proportions
            xlim([1, size(M, 2)]); % Limit X to the data dimensions
            ylim([1, size(M, 1)]); % Limit Y to the data dimensions
            zlim([1, size(M, 3)] * slice_spacing); % Limit Z with layer spacing accounted
            axis tight; % Adjust axis limits
            % Camera animation generation
            fprintf('Creating animation and saving images in associated subfolder...\n');
            % Camera key points
            key_azimuth =   [0,  0, -45, -45, -45, -45, -60, -90, -90]; % Azimuth
            key_elevation = [90, 60, 50, 70,  90,   70, 50, 60, 90];    % Elevation
            n_frames_per_segment = 30; % Number of frames per segment in the trajectory
            % Initialize interpolated camera trajectory
            full_azimuth = [];
            full_elevation = [];
            time_param = linspace(0, 1, n_frames_per_segment); % Time parameter (0 to 1)
            for idx = 1:(length(key_azimuth)-1)
                % Add interpolation for current segment
                segment_az = key_azimuth(idx) * (1 - time_param) + key_azimuth(idx+1) * time_param;
                segment_el = key_elevation(idx) * (1 - time_param) + key_elevation(idx+1) * time_param;
                full_azimuth = [full_azimuth, segment_az];
                full_elevation = [full_elevation, segment_el];
            end

            % GIF Filename
            gif_name = fullfile(save_folder, sprintf('%s_camera_trajectory_visualization.gif', crop_folder_name));
            % Generate the GIF and save key view images
            for frame_idx = 1:length(full_azimuth)
                % Update camera angles
                az = full_azimuth(frame_idx);
                el = full_elevation(frame_idx);
                view([az, el]);
                % Capture current frame
                frame = getframe(gcf);
                im = frame2im(frame);
                [imind, cm] = rgb2ind(im, 256);
                % Save frame to GIF
                if frame_idx == 1
                    imwrite(imind, cm, gif_name, 'gif', 'Loopcount', inf, 'DelayTime', 0.05);
                else
                    imwrite(imind, cm, gif_name, 'gif', 'WriteMode', 'append', 'DelayTime', 0.05);
                end
                % Save images for specified azimuth and elevation key points
                for key_idx = 1:length(key_azimuth)
                    if abs(az - key_azimuth(key_idx)) < 1e-5 && abs(el - key_elevation(key_idx)) < 1e-5
                        img_filename = fullfile(save_folder, ...
                            sprintf('%s_View_Azim_%d_Elev_%d.png', crop_folder_name, key_azimuth(key_idx), key_elevation(key_idx)));
                        % Save image
                        imwrite(imind, cm, img_filename);
                        fprintf('Image saved: %s\n', img_filename);
                        break;
                    end
                end
            end
            % Close the figure
            close(gcf);
            fprintf('GIF and images successfully created for subfolder: %s\n', save_folder);
           

            %--------------------------------------------------------------
            %--------------------------------------------------------------
            % Updated Visualization Logic - Unified with the first Example
            % 03. GIF Animation (полная заливка с выводом всех данных)
            M = crop_data; % Используем текущую плитку данных

            fprintf('\n=== 3D VISUALIZATION WITH MOVING CAMERA (WITH ALL DATA) ===\n');
            fprintf('Size of %s data: %d x %d x %d\n', current_field, size(M, 1), size(M, 2), size(M, 3));

            % Calculate full data range
            threshold_low = min(M(:));
            threshold_high = max(M(:));
            L_mask = M >= threshold_low & M <= threshold_high;

            fprintf('Установка порога для визуализации: %.4f до %.4f\n', threshold_low, threshold_high);

            cFigure;
            % Title and axis labels
            title(sprintf('3D Voxel Visualization with Moving Camera: %s', crop_folder_name));
            xlabel('X - Columns'); 
            ylabel('Y - Rows'); 
            zlabel('Z - Layers');
            hold on;

            % Extract all values for voxel visualization
            [F, V, C] = im2patch(M, L_mask, 'vb');
            gpatch(F, V, C, 'none', 1.0);

            % Color map settings
            colormap(cmap);
            colorbar;
            caxis([min(M(:)) max(M(:))]);
            axis equal; % Keep proportions
            xlim([1, size(M, 2)]);
            ylim([1, size(M, 1)]);
            zlim([1, size(M, 3)]);
            axis tight;
            axisGeom(gca, fontSize);
            camlight headlight;

            fprintf('Количество вокселей для отображения: %d\n', sum(L_mask(:))); % Every voxel for visualization
            fprintf('Starting Animation Generation...\n');

            % Camera animation generation
            key_azimuth = [0,  0, -45, -45, -45, -45, -60, -90, -90]; % Azimuth
            key_elevation = [90, 60, 50, 70,  90,   70, 50, 60, 90];  % Elevation
            n_frames_per_segment = 30; % Number of frames per segment in the trajectory
            full_azimuth = [];
            full_elevation = [];
            time_param = linspace(0, 1, n_frames_per_segment);

            % Create the full camera trajectory
            for idx = 1:(length(key_azimuth)-1)
                % Add interpolation for current segment
                segment_az = key_azimuth(idx) * (1 - time_param) + key_azimuth(idx+1) * time_param;
                segment_el = key_elevation(idx) * (1 - time_param) + key_elevation(idx+1) * time_param;
                full_azimuth = [full_azimuth, segment_az];
                full_elevation = [full_elevation, segment_el];
            end

            % GIF Filename
            gif_name = fullfile(save_folder, sprintf('v2_%s_camera_trajectory_visualization.gif', crop_folder_name));

            % Generate the GIF and save images for the key views
            for frame_idx = 1:length(full_azimuth)
                % Update camera angles
                az = full_azimuth(frame_idx);
                el = full_elevation(frame_idx);
                view([az, el]);
                % Capture current frame
                frame = getframe(gcf);
                im = frame2im(frame);
                [imind, cm] = rgb2ind(im, 256);
                % Save frame to GIF
                if frame_idx == 1
                    imwrite(imind, cm, gif_name, 'gif', 'Loopcount', inf, 'DelayTime', 0.05);
                else
                    imwrite(imind, cm, gif_name, 'gif', 'WriteMode', 'append', 'DelayTime', 0.05);
                end
                % Save images for specified azimuth and elevation key points
                for key_idx = 1:length(key_azimuth)
                    if abs(az - key_azimuth(key_idx)) < 1e-5 && abs(el - key_elevation(key_idx)) < 1e-5
                        img_filename = fullfile(save_folder, ...
                            sprintf('v2_%s_View_Azim_%d_Elev_%d.png', crop_folder_name, key_azimuth(key_idx), key_elevation(key_idx)));
                        % Save image
                        imwrite(imind, cm, img_filename);
                        fprintf('Image saved: %s\n', img_filename);
                        break;
                    end
                end
            end

            % Close the figure
            close(gcf);
            fprintf('GIF and images successfully created for subfolder: %s\n', save_folder);
            %--------------------------------------------------------------
            %--------------------------------------------------------------
                  

        end
    end
end
disp('Обработка с разбиением на плитки завершена.');

