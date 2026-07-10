%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% CIRCULAR %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function calc_2025_vis_DvotMM_Circular(Results, save_folder)
% VISUALIZE_MUELLER_MATRIX Визуализация модулей и аргументов двухточечной матрицы Мюллера
%   с обработкой только валидных данных внутри круга
%
% Использование:
%   calc_2025_vis_DvotMM_Circular(Results, save_folder)
%
% Входные параметры:
%   Results     - структура с результатами расчета матрицы Мюллера
%   save_folder - папка для сохранения изображений

number_of_countours = 5;

% Проверка входных параметров
if nargin < 2
    error('Необходимо указать папку для сохранения: calc_2025_vis_DvotMM_Circular(Results, save_folder)');
end

% Создание папки если не существует
if ~exist(save_folder, 'dir')
    mkdir(save_folder);
    fprintf('Создана папка: %s\n', save_folder);
end

% Определение цветовых карт
color_maps = {'jet', 'gray'};
map_types = {'цветная', 'серая'};

% Настройки визуализации
font_size_title = 14;
font_size_label = 11;
font_size_subplot = 10;
figure_size = [1600, 1000];

% Получаем размер матрицы
[matrix_rows, matrix_cols] = size(Results.Complex_f11.Magnitude);

fprintf('\n----- НАЧАЛО ВИЗУАЛИЗАЦИИ -----\n');
fprintf('Размер матрицы: %dx%d\n', matrix_rows, matrix_cols);
fprintf('Папка сохранения: %s\n', save_folder);
fprintf('Цветовые карты: %s\n\n', strjoin(color_maps, ', '));

% ===== СОЗДАНИЕ КРУГЛОЙ МАСКИ =====
fprintf('Создание круглой маски для обработки валидных данных...\n');

% Определяем параметры круга
center_x = (matrix_cols + 1) / 2;
center_y = (matrix_rows + 1) / 2;

% Определяем радиус исходя из структуры Results
if isfield(Results, 'Parameters') && isfield(Results.Parameters, 'max_radius')
    % Для кругового алгоритма
    radius = Results.Parameters.max_radius;
    fprintf('Используем радиус из параметров: %d\n', radius);
else
    % Для псевдо-АКФ или других случаев - берем максимально возможный радиус
    radius = min(center_x, center_y) - 1;
    fprintf('Вычисленный радиус: %.1f\n', radius);
end

% Создаем координатную сетку
[X, Y] = meshgrid(1:matrix_cols, 1:matrix_rows);

% Создаем круглую маску
circular_mask = ((X - center_x).^2 + (Y - center_y).^2) <= radius^2;

% Проверяем количество валидных точек
total_points = matrix_rows * matrix_cols;
circle_points = sum(circular_mask(:));
fprintf('Общее количество точек: %d\n', total_points);
fprintf('Точек внутри круга: %d (%.1f%%)\n', circle_points, 100*circle_points/total_points);

% Функция для получения валидных данных
function valid_data = get_valid_data(data)
    valid_mask = circular_mask & ~isnan(data);
    valid_data = data(valid_mask);
end

% Функция для безопасной статистики
function stats = calculate_stats(data)
    valid_data = get_valid_data(data);
    if isempty(valid_data)
        stats.mean = 0;
        stats.std = 0;
        stats.skew = 0;
        stats.kurt = 0;
        stats.min = 0;
        stats.max = 0;
        stats.count = 0;
    else
        stats.mean = mean(valid_data);
        stats.std = std(valid_data);
        % Проверяем наличие Statistics Toolbox для skewness и kurtosis
        if exist('skewness', 'file') == 2
            stats.skew = skewness(valid_data);
        else
            stats.skew = 0;
        end
        if exist('kurtosis', 'file') == 2
            stats.kurt = kurtosis(valid_data);
        else
            stats.kurt = 0;
        end
        stats.min = min(valid_data);
        stats.max = max(valid_data);
        stats.count = length(valid_data);
    end
end

% Функция для отображения с прозрачностью
function plot_with_transparency(data, title_str)
    % Создаем маску для отображения (круг + не NaN)
    display_mask = circular_mask & ~isnan(data);
    
    % Отображаем данные
    h = imagesc(data);
    set(h, 'AlphaData', double(display_mask));
    
    % Серый фон для областей вне круга
    ax = gca;
    ax.Color = [0.8 0.8 0.8];
    
    axis image;
    colorbar;
    title(title_str, 'FontSize', font_size_subplot, 'FontWeight', 'bold');
    xlabel('Индекс X', 'FontSize', font_size_label);
    ylabel('Индекс Y', 'FontSize', font_size_label);
    
    % Адаптивные метки осей
    if matrix_cols <= 10
        xticks(1:matrix_cols);
    elseif matrix_cols <= 100
        xtick_values = round(linspace(1, matrix_cols, 5));
        xticks(xtick_values);
    elseif matrix_cols <= 200
        xtick_values = round(linspace(1, matrix_cols, 5));
        xticks(xtick_values);
    else
        xtick_values = [1, round(matrix_cols/2), matrix_cols];
        xticks(xtick_values);
    end
    
    if matrix_rows <= 10
        yticks(1:matrix_rows);
    elseif matrix_rows <= 100
        ytick_values = round(linspace(1, matrix_rows, 5));
        yticks(ytick_values);
    elseif matrix_rows <= 200
        ytick_values = round(linspace(1, matrix_rows, 5));
        yticks(ytick_values);
    else
        ytick_values = [1, round(matrix_rows/2), matrix_rows];
        yticks(ytick_values);
    end
    
    grid on;
    set(gca, 'GridAlpha', 0.3);
    
    % Центр матрицы
    hold on;
    plot(center_x, center_y, 'w+', 'MarkerSize', 10, 'LineWidth', 1);
    hold off;
end

fprintf('\--- НАЧАЛО. ЧАСТЬ 01. МОДУЛИ и АРГУМЕНТЫ\n');

% Цикл по всем цветовым картам
for map_idx = 1:length(color_maps)
    current_colormap = color_maps{map_idx};
    map_type = map_types{map_idx};
    
    %!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    %% Визуализация МОДУЛЕЙ |f̃ᵢₖ|
    %!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    fig_modules = figure('Name', sprintf('Модули - %s', current_colormap), ...
        'Position', [50, 50, figure_size(1), figure_size(2)], ...
        'Color', 'white', ...
        'Visible', 'off');
    
    for i = 1:4
        for k = 1:4
            subplot(4, 4, (i-1)*4 + k);
            
            % Получаем данные модуля
            field_name = sprintf('Complex_f%d%d', i, k);
            magnitude_data = Results.(field_name).Magnitude;
            
            % Отображаем с прозрачностью
            plot_with_transparency(magnitude_data, sprintf('|f̃_{%d%d}|', i, k));
            colormap(gca, current_colormap);
            
            % Устанавливаем пределы цвета только по валидным данным
            valid_data = get_valid_data(magnitude_data);
            if ~isempty(valid_data)
                caxis([min(valid_data) max(valid_data)]);
            end
        end
    end
    
    % Общий заголовок
    sgtitle(sprintf('Модули элементов двухточечной матрицы Мюллера |f̃ᵢₖ| [%s]', current_colormap), ...
        'FontSize', font_size_title, 'FontWeight', 'bold');
    
    % Сохранение
    filename = fullfile(save_folder, sprintf('%s.Modules.png', current_colormap));
    saveas(fig_modules, filename);
    close(fig_modules);
    
    %!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    %% Визуализация АРГУМЕНТОВ Arg(f̃ᵢₖ) в радианах
    %!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    fig_arguments = figure('Name', sprintf('Аргументы - %s', current_colormap), ...
        'Position', [100, 100, figure_size(1), figure_size(2)], ...
        'Color', 'white', ...
        'Visible', 'off');
    
    for i = 1:4
        for k = 1:4
            subplot(4, 4, (i-1)*4 + k);
            
            % Получаем данные аргумента
            field_name = sprintf('Complex_f%d%d', i, k);
            argument_data = Results.(field_name).Argument;
            
            % Отображаем с прозрачностью
            plot_with_transparency(argument_data, sprintf('Arg(f̃_{%d%d})', i, k));
            colormap(gca, current_colormap);
            
            % Устанавливаем пределы цвета только по валидным данным
            valid_data = get_valid_data(argument_data);
            if ~isempty(valid_data)
                caxis([min(valid_data) max(valid_data)]);
            end
            
            % Изменяем подпись colorbar
            c = colorbar;
            c.Label.String = 'Arg(f̃) [рад]';
            c.Label.FontSize = font_size_label;
        end
    end
    
    % Общий заголовок
    sgtitle(sprintf('Аргументы элементов двухточечной матрицы Мюллера Arg(f̃ᵢₖ) [рад] [%s]', current_colormap), ...
        'FontSize', font_size_title, 'FontWeight', 'bold');
    
    % Сохранение
    filename = fullfile(save_folder, sprintf('%s.Arguments.png', current_colormap));
    saveas(fig_arguments, filename);
    close(fig_arguments);
end

fprintf('\n=== ВИЗУАЛИЗАЦИЯ ВСЕХ МОДУЛЕЙ И АРГУМЕНТОВ ЗАВЕРШЕНА ===\n');
fprintf('\---- НАЧАЛО. ЧАСТЬ 04. 2D-AKF. 2D-PSD (ИСПРАВЛЕННАЯ ВЕРСИЯ)\n');

%% НАСТРОЙКА ПАРАЛЛЕЛЬНЫХ ВЫЧИСЛЕНИЙ
fprintf('Настройка параллельных вычислений...\n');
if license('test', 'Distrib_Computing_Toolbox')
    current_pool = gcp('nocreate');
    if isempty(current_pool)
        try
            parpool('local', 4); % Уменьшено до 4 потоков для стабильности
            fprintf('Создан пул из 4 потоков\n');
        catch
            fprintf('Не удалось создать пул потоков, продолжаем без параллельности\n');
        end
    else
        fprintf('Используем существующий пул из %d потоков\n', current_pool.NumWorkers);
    end
else
    fprintf('Parallel Computing Toolbox не найден. Вычисления будут последовательными.\n');
end

%% ОСНОВНОЙ ЦИКЛ: РАСЧЕТ АКФ И PSD С ИСПРАВЛЕННОЙ ЛОГИКОЙ
for i = 1:4
    for k = 1:4
        field_name = sprintf('Complex_f%d%d', i, k);
        
        fprintf('\n--- Обработка элемента f%d%d ---\n', i, k);
        
        % Проверяем существование поля
        if ~isfield(Results, field_name)
            fprintf('ВНИМАНИЕ: Поле %s не найдено, пропускаем.\n', field_name);
            continue;
        end
        
        if ~isfield(Results.(field_name), 'Magnitude') || ~isfield(Results.(field_name), 'Argument')
            fprintf('ВНИМАНИЕ: Поля Magnitude или Argument не найдены в %s, пропускаем.\n', field_name);
            continue;
        end
        
        % Получаем данные
        magnitude_data = Results.(field_name).Magnitude;
        argument_data = Results.(field_name).Argument;
        
        % Анализируем размеры данных
        [N_rows, N_cols] = size(magnitude_data);
        if N_rows ~= N_cols
            fprintf('    ВНИМАНИЕ: Данные не квадратные (%dx%d), используем минимальный размер.\n', N_rows, N_cols);
            N = min(N_rows, N_cols);
            magnitude_data = magnitude_data(1:N, 1:N);
            argument_data = argument_data(1:N, 1:N);
        else
            N = N_rows;
        end
        
        %% ===== ПОДГОТОВКА ДАННЫХ ДЛЯ МОДУЛЯ (ИСПРАВЛЕННЫЙ ПОДХОД) =====
        fprintf('  Подготовка данных модуля...\n');
        
        % Получаем валидные данные для модуля
        nan_mask_mag = isnan(magnitude_data);
        valid_data_mag = magnitude_data(~nan_mask_mag);
        
        if isempty(valid_data_mag)
            fprintf('    ВНИМАНИЕ: Нет валидных данных в модуле, пропускаем.\n');
            continue;
        end
        
        % Подготавливаем данные для АКФ и PSD - заменяем NaN нулями + применяем окно
        magnitude_clean = magnitude_data;
        magnitude_clean(nan_mask_mag) = 0;
        
        % Применяем гауссово окно для сглаживания границ (подход 2)
        [X_window, Y_window] = meshgrid(1:N, 1:N);
        center_window_x = (N + 1) / 2;
        center_window_y = (N + 1) / 2;
        dist_from_center_mag = sqrt((X_window - center_window_x).^2 + (Y_window - center_window_y).^2);
        
        % Определяем sigma для гауссова окна (примерно радиус/3)
        valid_distances = dist_from_center_mag(~nan_mask_mag);
        if ~isempty(valid_distances)
            estimated_radius_mag = max(valid_distances);
            sigma_mag = 2*estimated_radius_mag / 3;
        else
            sigma_mag = N / 6; % fallback
        end
        
        % Создаем гауссово окно только для валидных данных
        gaussian_window_mag = ones(N, N);
        gaussian_window_mag(~nan_mask_mag) = exp(-(dist_from_center_mag(~nan_mask_mag).^2) / (2 * sigma_mag^2));
        gaussian_window_mag(nan_mask_mag) = 0; % вне круга = 0
        
        % Применяем окно к данным
        magnitude_windowed = magnitude_clean .* gaussian_window_mag;
        
        fprintf('    Magnitude: валидных точек %d (%.1f%%)\n', ...
                length(valid_data_mag), length(valid_data_mag)/(N*N)*100);
        
        %% ===== РАСЧЕТ 2D АВТОКОРРЕЛЯЦИИ ДЛЯ МОДУЛЯ (ИСПРАВЛЕННЫЙ ПОДХОД) =====
        fprintf('  Расчет 2D АКФ для модуля через xcorr2...\n');
        tic;
        
        % ПРОСТОЙ И ПРАВИЛЬНЫЙ расчет через xcorr2
        acf_magnitude = xcorr2(magnitude_windowed);
        
        % Нормализация АКФ на центральное значение (от 0 до 1)
        center_value = acf_magnitude((size(acf_magnitude,1)+1)/2, (size(acf_magnitude,2)+1)/2);
        if center_value ~= 0
            acf_magnitude = acf_magnitude / center_value;
        end
        
        % Создаем круглую маску для АКФ (радиус 2R для двумерной АКФ)
        [N_acf_rows, N_acf_cols] = size(acf_magnitude);
        center_acf_x = (N_acf_cols + 1) / 2;
        center_acf_y = (N_acf_rows + 1) / 2;
        
        [X_acf, Y_acf] = meshgrid(1:N_acf_cols, 1:N_acf_rows);
        R_acf = sqrt((X_acf - center_acf_x).^2 + (Y_acf - center_acf_y).^2);
        
        % Радиус для АКФ = 2*R (двумерная АКФ увеличивает размерность в 2 раза)
        max_radius_acf = min(center_acf_x, center_acf_y) - 1;
        radius_acf = min(2*radius, max_radius_acf); % используем 2R
        circular_mask_acf = R_acf <= radius_acf;
        
        % Применяем маску к АКФ
        acf_magnitude_circle = acf_magnitude;
        acf_magnitude_circle(~circular_mask_acf) = NaN;
        
        acf_time_mag = toc;
        fprintf('    АКФ модуля рассчитана за %.3f секунд (нормализована 0-1, радиус=2R=%.1f)\n', acf_time_mag, radius_acf);
        
        %% ===== РАСЧЕТ СПЕКТРА МОЩНОСТИ ДЛЯ МОДУЛЯ (НОВЫЙ ПОДХОД) =====
        fprintf('  Расчет PSD для модуля...\n');
        tic;
        
        % ПРОСТОЙ расчет PSD напрямую от данных с окном
        fft_magnitude = fft2(magnitude_windowed);
        psd_magnitude = abs(fft_magnitude).^2 / (N * N);
        psd_magnitude_shifted = fftshift(psd_magnitude);
        
        % Логарифмическая шкала для визуализации
        psd_magnitude_log = log10(psd_magnitude_shifted + eps);
        
        psd_time_mag = toc;
        fprintf('    PSD модуля рассчитана за %.3f секунд (с гауссовым окном)\n', psd_time_mag);
        
        %% ===== АНАЛОГИЧНЫЕ РАСЧЕТЫ ДЛЯ АРГУМЕНТА =====
        fprintf('  Подготовка данных аргумента...\n');
        
        % Получаем валидные данные для аргумента
        nan_mask_arg = isnan(argument_data);
        valid_data_arg = argument_data(~nan_mask_arg);
        
        if isempty(valid_data_arg)
            fprintf('    ВНИМАНИЕ: Нет валидных данных в аргументе, пропускаем.\n');
            continue;
        end
        
        % Подготавливаем данные для АКФ и PSD - заменяем NaN нулями + применяем окно
        argument_clean = argument_data;
        argument_clean(nan_mask_arg) = 0;
        
        % Применяем гауссово окно для аргумента
        dist_from_center_arg = sqrt((X_window - center_window_x).^2 + (Y_window - center_window_y).^2);
        
        valid_distances_arg = dist_from_center_arg(~nan_mask_arg);
        if ~isempty(valid_distances_arg)
            estimated_radius_arg = max(valid_distances_arg);
            sigma_arg = 2*estimated_radius_arg / 3;
        else
            sigma_arg = N / 6; % fallback
        end
        
        % Создаем гауссово окно для аргумента
        gaussian_window_arg = ones(N, N);
        gaussian_window_arg(~nan_mask_arg) = exp(-(dist_from_center_arg(~nan_mask_arg).^2) / (2 * sigma_arg^2));
        gaussian_window_arg(nan_mask_arg) = 0;
        
        % Применяем окно к данным аргумента
        argument_windowed = argument_clean .* gaussian_window_arg;
        
        fprintf('    Argument: валидных точек %d (%.1f%%)\n', ...
                length(valid_data_arg), length(valid_data_arg)/(N*N)*100);
        
        %% ===== РАСЧЕТ 2D АКФ ДЛЯ АРГУМЕНТА =====
        fprintf('  Расчет 2D АКФ для аргумента через xcorr2...\n');
        tic;
        
        % ПРОСТОЙ расчет через xcorr2 с окном
        acf_argument = xcorr2(argument_windowed);
        
        % Нормализация АКФ на центральное значение (от 0 до 1)
        center_value_arg = acf_argument((size(acf_argument,1)+1)/2, (size(acf_argument,2)+1)/2);
        if center_value_arg ~= 0
            acf_argument = acf_argument / center_value_arg;
        end
        
        % Применяем ту же круглую маску (радиус 2R)
        acf_argument_circle = acf_argument;
        acf_argument_circle(~circular_mask_acf) = NaN;
        
        acf_time_arg = toc;
        fprintf('    АКФ аргумента рассчитана за %.3f секунд (нормализована 0-1, радиус=2R=%.1f)\n', acf_time_arg, radius_acf);
        
        %% ===== РАСЧЕТ PSD ДЛЯ АРГУМЕНТА =====
        fprintf('  Расчет PSD для аргумента...\n');
        tic;
        
        % ПРОСТОЙ расчет PSD для аргумента с окном
        fft_argument = fft2(argument_windowed);
        psd_argument = abs(fft_argument).^2 / (N * N);
        psd_argument_shifted = fftshift(psd_argument);
        
        % Логарифмическая шкала
        psd_argument_log = log10(psd_argument_shifted + eps);
        
        psd_time_arg = toc;
        fprintf('    PSD аргумента рассчитана за %.3f секунд (с гауссовым окном)\n', psd_time_arg);
        
        % Подготавливаем данные для визуализации
        magnitude_circle = magnitude_data;
        magnitude_circle(nan_mask_mag) = NaN;
        
        argument_circle = argument_data;
        argument_circle(nan_mask_arg) = NaN;
        
        % Частотные оси
        freq_x = (-N/2:N/2-1) / N;
        freq_y = (-N/2:N/2-1) / N;
        [FX, FY] = meshgrid(freq_x, freq_y);
        
        % 3D координаты для АКФ
        [X_acf_3d, Y_acf_3d] = meshgrid(1:N_acf_cols, 1:N_acf_rows);
        
        %% ВИЗУАЛИЗАЦИЯ ДЛЯ РАЗНЫХ ЦВЕТОВЫХ КАРТ
        fprintf('  Генерация визуализаций для разных цветовых карт...\n');
        
        for map_idx = 1:length(color_maps)
            current_colormap = color_maps{map_idx};
            
            fprintf('    Цветовая карта: %s\n', current_colormap);
            
            %% ФИГУРА 1: МОДУЛЬ - АКФ и спектры мощности
            fig_mag = figure('Name', sprintf('f_%d%d, %s', i, k, current_colormap), ...
                           'Position', [50, 50, 1600, 1200], ...
                           'Color', 'white', ...
                           'Visible', 'off');
            
            % Subplot 1: Исходные данные модуля (только круг)
            subplot(2, 3, 1);
            h = imagesc(magnitude_circle);
            set(h, 'AlphaData', ~isnan(magnitude_circle));
            ax = gca; ax.Color = [0.8 0.8 0.8];
            colormap(gca, current_colormap);
            title(sprintf('|f̃_{%d%d}| - Исходные данные (круг)', i, k), 'FontSize', 11, 'FontWeight', 'bold');
            xlabel('X'); ylabel('Y');
            colorbar; axis image; grid on; set(gca, 'GridAlpha', 0.3);
            if ~isempty(valid_data_mag)
                caxis([min(valid_data_mag) max(valid_data_mag)]);
            end
            
            % Subplot 2: 2D АКФ с круглой маской
            subplot(2, 3, 2);
            h = imagesc(acf_magnitude_circle);
            set(h, 'AlphaData', ~isnan(acf_magnitude_circle));
            ax = gca; ax.Color = [0.8 0.8 0.8];
            colormap(gca, current_colormap);
            title('2D Автокорреляция (круг, 0-1)', 'FontSize', 11, 'FontWeight', 'bold');
            xlabel('Лаг X'); ylabel('Лаг Y');
            colorbar; axis image; grid on; set(gca, 'GridAlpha', 0.3);
            caxis([0 1]); % фиксируем от 0 до 1
            
            % Subplot 3: 2D спектр мощности (квадратный)
            subplot(2, 3, 3);
            imagesc(freq_x, freq_y, psd_magnitude_log);
            colormap(gca, current_colormap);
            title('2D Спектр мощности (log10, квадратный)', 'FontSize', 11, 'FontWeight', 'bold');
            xlabel('Частота X'); ylabel('Частота Y');
            colorbar; axis image; grid on; set(gca, 'GridAlpha', 0.3);
            
            % Subplot 4: Подготовленные данные (с окном)
            subplot(2, 3, 4);
            imagesc(magnitude_windowed);
            colormap(gca, current_colormap);
            title('Данные с гауссовым окном', 'FontSize', 11, 'FontWeight', 'bold');
            xlabel('X'); ylabel('Y');
            colorbar; axis image; grid on; set(gca, 'GridAlpha', 0.3);
            
            % Subplot 5: 3D представление АКФ
            subplot(2, 3, 5);
            surf(X_acf_3d, Y_acf_3d, acf_magnitude_circle, 'EdgeColor', 'none');
            colormap(gca, current_colormap);
            title('3D АКФ (с маской, 0-1)', 'FontSize', 11, 'FontWeight', 'bold');
            xlabel('Лаг X'); ylabel('Лаг Y'); zlabel('АКФ');
            shading interp; view(45, 30); grid on;
            caxis([0 1]); % фиксируем от 0 до 1
            
            % Subplot 6: 3D спектр мощности
            subplot(2, 3, 6);
            surf(FX, FY, psd_magnitude_log, 'EdgeColor', 'none');
            colormap(gca, current_colormap);
            title('3D Спектр мощности (log10)', 'FontSize', 11, 'FontWeight', 'bold');
            xlabel('Частота X'); ylabel('Частота Y'); zlabel('log10(PSD)');
            colorbar; shading interp; view(45, 30); grid on;
            
            % Общий заголовок для модуля
            sgtitle(sprintf('f̃_{%d%d} - Модуль: АКФ (круг 2R, 0-1) и PSD (квадрат, окно) [%s]', i, k, current_colormap), ...
                   'FontSize', 14, 'FontWeight', 'bold');
            
            % Сохранение фигуры модуля
            filename_mag = fullfile(save_folder, sprintf('%s.f%d%d_ACF-Power_Magnitude.png', current_colormap, i, k));
            saveas(fig_mag, filename_mag);
            close(fig_mag);
            
            %% ФИГУРА 2: АРГУМЕНТ - АКФ и спектры мощности
            fig_arg = figure('Name', sprintf('f_%d%d - %s - Аргумент АКФ+Спектр', i, k, current_colormap), ...
                           'Position', [100, 100, 1600, 1200], ...
                           'Color', 'white', ...
                           'Visible', 'off');
            
            % Subplot 1: Исходные данные аргумента (только круг)
            subplot(2, 3, 1);
            h = imagesc(argument_circle);
            set(h, 'AlphaData', ~isnan(argument_circle));
            ax = gca; ax.Color = [0.8 0.8 0.8];
            colormap(gca, current_colormap);
            title(sprintf('Arg(f̃_{%d%d}) - Исходные данные [рад] (круг)', i, k), 'FontSize', 11, 'FontWeight', 'bold');
            xlabel('X'); ylabel('Y');
            colorbar; axis image; grid on; set(gca, 'GridAlpha', 0.3);
            if ~isempty(valid_data_arg)
                caxis([min(valid_data_arg) max(valid_data_arg)]);
            end
            
            % Subplot 2: 2D АКФ аргумента с круглой маской
            subplot(2, 3, 2);
            h = imagesc(acf_argument_circle);
            set(h, 'AlphaData', ~isnan(acf_argument_circle));
            ax = gca; ax.Color = [0.8 0.8 0.8];
            colormap(gca, current_colormap);
            title('2D Автокорреляция (круг, 0-1)', 'FontSize', 11, 'FontWeight', 'bold');
            xlabel('Лаг X'); ylabel('Лаг Y');
            colorbar; axis image; grid on; set(gca, 'GridAlpha', 0.3);
            caxis([0 1]); % фиксируем от 0 до 1
            
            % Subplot 3: 2D спектр мощности для аргумента (квадратный)
            subplot(2, 3, 3);
            imagesc(freq_x, freq_y, psd_argument_log);
            colormap(gca, current_colormap);
            title('2D Спектр мощности (log10, квадратный)', 'FontSize', 11, 'FontWeight', 'bold');
            xlabel('Частота X'); ylabel('Частота Y');
            colorbar; axis image; grid on; set(gca, 'GridAlpha', 0.3);
            
            % Subplot 4: Подготовленные данные аргумента (с окном)
            subplot(2, 3, 4);
            imagesc(argument_windowed);
            colormap(gca, current_colormap);
            title('Данные с гауссовым окном', 'FontSize', 11, 'FontWeight', 'bold');
            xlabel('X'); ylabel('Y');
            colorbar; axis image; grid on; set(gca, 'GridAlpha', 0.3);
            
            % Subplot 5: 3D представление АКФ аргумента
            subplot(2, 3, 5);
            surf(X_acf_3d, Y_acf_3d, acf_argument_circle, 'EdgeColor', 'none');
            colormap(gca, current_colormap);
            title('3D АКФ (с маской, 0-1)', 'FontSize', 11, 'FontWeight', 'bold');
            xlabel('Лаг X'); ylabel('Лаг Y'); zlabel('АКФ');
            colorbar; shading interp; view(45, 30); grid on;
            caxis([0 1]); % фиксируем от 0 до 1
            
            % Subplot 6: 3D спектр мощности для аргумента
            subplot(2, 3, 6);
            surf(FX, FY, psd_argument_log, 'EdgeColor', 'none');
            colormap(gca, current_colormap);
            title('3D Спектр мощности (log10)', 'FontSize', 11, 'FontWeight', 'bold');
            xlabel('Частота X'); ylabel('Частота Y'); zlabel('log10(PSD)');
            colorbar; shading interp; view(45, 30); grid on;
            
            % Общий заголовок для аргумента
            sgtitle(sprintf('f̃_{%d%d} - Аргумент: АКФ (круг 2R, 0-1) и PSD (квадрат, окно) [%s]', i, k, current_colormap), ...
                   'FontSize', 14, 'FontWeight', 'bold');
            
            % Сохранение фигуры аргумента
            filename_arg = fullfile(save_folder, sprintf('%s.f%d%d_ACF-Power_Argument.png', current_colormap, i, k));
            saveas(fig_arg, filename_arg);
            close(fig_arg);




                % %%==============================================================================================================
                % %% ПАКЕТ ГІСТОГРАМ (ВИПРАВЛЕНА ВЕРСІЯ З АДАПТИВНИМИ КОЛЬОРАМИ)
                % %%==============================================================================================================
                % 
                % fprintf('  Початок генерації гістограм для f%d%d...\n', i, k);
                % 
                % % ============================================================
                % % ВИЗНАЧЕННЯ КОЛЬОРОВОЇ СХЕМИ ЗАЛЕЖНО ВІД COLORMAP
                % % ============================================================
                % if strcmpi(current_colormap, 'gray')
                %     % Сіра палітра для gray colormap
                %     color_mag_main = [0.4 0.4 0.4];      % темно-сірий для модуля
                %     color_mag_edge = [0.2 0.2 0.2];      % майже чорний для країв
                %     color_mag_kde = [0.3 0.3 0.3];       % темно-сірий для KDE
                %     color_arg_main = [0.6 0.6 0.6];      % світло-сірий для аргумента
                %     color_arg_edge = [0.3 0.3 0.3];      % темно-сірий для країв
                %     color_arg_kde = [0.5 0.5 0.5];       % середньо-сірий для KDE
                %     color_scatter = [0.5 0.5 0.5];       % середньо-сірий для scatter
                %     color_line_mean = [0.2 0.2 0.2];     % темний для circular mean
                % else
                %     % Кольорова палітра для інших colormap
                %     color_mag_main = [0.2 0.5 0.9];      % синій для модуля
                %     color_mag_edge = [0.1 0.3 0.6];      % темно-синій для країв
                %     color_mag_kde = [1 0 0];             % червоний для KDE
                %     color_arg_main = [0.9 0.3 0.3];      % червоний для аргумента
                %     color_arg_edge = [0.6 0.1 0.1];      % темно-червоний для країв
                %     color_arg_kde = [0 0 1];             % синій для KDE
                %     color_scatter = [0.4 0.4 0.8];       % синюватий для scatter
                %     color_line_mean = [1 0 0];           % червоний для circular mean
                % end
                % 
                % % РОЗРАХУНОК СТАТИСТИКИ ДЛЯ МОДУЛЯ (4 моменти)
                % mean_mag = mean(valid_data_mag);
                % median_mag = median(valid_data_mag);
                % std_mag = std(valid_data_mag);
                % var_mag = var(valid_data_mag);
                % min_mag = min(valid_data_mag);
                % max_mag = max(valid_data_mag);
                % range_mag = max_mag - min_mag;
                % 
                % % Skewness (3-й момент)
                % if exist('skewness', 'file') == 2
                %     skew_mag = skewness(valid_data_mag);
                % else
                %     n_mag = length(valid_data_mag);
                %     m3_mag = sum((valid_data_mag - mean_mag).^3) / n_mag;
                %     skew_mag = m3_mag / (std_mag^3);
                % end
                % 
                % % Kurtosis (4-й момент)
                % if exist('kurtosis', 'file') == 2
                %     kurt_mag = kurtosis(valid_data_mag);
                % else
                %     n_mag = length(valid_data_mag);
                %     m4_mag = sum((valid_data_mag - mean_mag).^4) / n_mag;
                %     kurt_mag = (m4_mag / (std_mag^4)) - 3;
                % end
                % 
                % cv_mag = 100 * std_mag / mean_mag;
                % q1_mag = quantile(valid_data_mag, 0.25);
                % q3_mag = quantile(valid_data_mag, 0.75);
                % iqr_mag = q3_mag - q1_mag;
                % 
                % % РОЗРАХУНОК СТАТИСТИКИ ДЛЯ АРГУМЕНТА (4 моменти + circular)
                % mean_arg = mean(valid_data_arg);
                % median_arg = median(valid_data_arg);
                % std_arg = std(valid_data_arg);
                % var_arg = var(valid_data_arg);
                % min_arg = min(valid_data_arg);
                % max_arg = max(valid_data_arg);
                % range_arg = max_arg - min_arg;
                % 
                % if exist('skewness', 'file') == 2
                %     skew_arg = skewness(valid_data_arg);
                % else
                %     n_arg = length(valid_data_arg);
                %     m3_arg = sum((valid_data_arg - mean_arg).^3) / n_arg;
                %     skew_arg = m3_arg / (std_arg^3);
                % end
                % 
                % if exist('kurtosis', 'file') == 2
                %     kurt_arg = kurtosis(valid_data_arg);
                % else
                %     n_arg = length(valid_data_arg);
                %     m4_arg = sum((valid_data_arg - mean_arg).^4) / n_arg;
                %     kurt_arg = (m4_arg / (std_arg^4)) - 3;
                % end
                % 
                % circ_mean_arg = atan2(mean(sin(valid_data_arg)), mean(cos(valid_data_arg)));
                % R_arg = abs(mean(exp(1i * valid_data_arg)));
                % if R_arg > 0
                %     circ_std_arg = sqrt(-2 * log(R_arg));
                % else
                %     circ_std_arg = NaN;
                % end
                % 
                % q1_arg = quantile(valid_data_arg, 0.25);
                % q3_arg = quantile(valid_data_arg, 0.75);
                % iqr_arg = q3_arg - q1_arg;
                % 
                % corr_val = corr(valid_data_mag, valid_data_arg);
                % 
                % % ============================================================
                % % ФІГУРА 1: РОЗПОДІЛИ (2×3)
                % % ============================================================
                % fig1 = figure('Name', sprintf('Fig1: Distributions f%d%d - %s', i, k, current_colormap), ...
                %               'Position', [50, 50, 1400, 800], 'Color', 'white', 'Visible', 'off');
                % 
                % % Верхній рядок: МОДУЛЬ
                % subplot(2, 3, 1);
                % histogram(valid_data_mag, 50, 'FaceColor', color_mag_main, ...
                %           'EdgeColor', color_mag_edge, 'FaceAlpha', 0.75, 'LineWidth', 1.2);
                % title(sprintf('|f̃_{%d%d}| Гістограма (n=%d)', i, k, length(valid_data_mag)), ...
                %       'FontSize', 11, 'FontWeight', 'bold');
                % xlabel('Значення', 'FontSize', 10); 
                % ylabel('Частота', 'FontSize', 10);
                % grid on; set(gca, 'GridAlpha', 0.3);
                % 
                % subplot(2, 3, 2);
                % histogram(valid_data_mag, 50, 'Normalization', 'pdf', ...
                %          'FaceColor', color_mag_main, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
                % hold on;
                % if exist('ksdensity', 'file') == 2
                %     [f_kde, xi_kde] = ksdensity(valid_data_mag);
                %     plot(xi_kde, f_kde, 'Color', color_mag_kde, 'LineWidth', 2.5);
                %     has_kde_mag = true;
                % else
                %     has_kde_mag = false;
                % end
                % x_norm = linspace(min_mag, max_mag, 200);
                % y_norm = normpdf(x_norm, mean_mag, std_mag);
                % plot(x_norm, y_norm, 'k--', 'LineWidth', 1.5);
                % hold off;
                % title('PDF + KDE + Normal', 'FontSize', 11, 'FontWeight', 'bold');
                % xlabel('Значення', 'FontSize', 10); 
                % ylabel('Щільність', 'FontSize', 10);
                % if has_kde_mag
                %     legend({'Histogram', 'KDE', 'Normal'}, 'Location', 'best', 'FontSize', 8);
                % else
                %     legend({'Histogram', 'Normal'}, 'Location', 'best', 'FontSize', 8);
                % end
                % grid on; set(gca, 'GridAlpha', 0.3);
                % 
                % subplot(2, 3, 3);
                % histogram(valid_data_mag, 50, 'Normalization', 'cdf', ...
                %          'FaceColor', color_mag_main, 'EdgeColor', 'k', 'FaceAlpha', 0.7);
                % hold on;
                % [f_ecdf_mag, x_ecdf_mag] = ecdf(valid_data_mag);
                % stairs(x_ecdf_mag, f_ecdf_mag, 'Color', color_mag_kde, 'LineWidth', 2);
                % hold off;
                % title('Кумулятивний розподіл', 'FontSize', 11, 'FontWeight', 'bold');
                % xlabel('Значення', 'FontSize', 10); 
                % ylabel('CDF', 'FontSize', 10);
                % legend({'Hist CDF', 'ECDF'}, 'Location', 'best', 'FontSize', 8);
                % grid on; set(gca, 'GridAlpha', 0.3);
                % 
                % % Нижній рядок: АРГУМЕНТ
                % subplot(2, 3, 4);
                % histogram(valid_data_arg, 50, 'FaceColor', color_arg_main, ...
                %          'EdgeColor', color_arg_edge, 'FaceAlpha', 0.75, 'LineWidth', 1.2);
                % title(sprintf('Arg(f̃_{%d%d}) [рад] (n=%d)', i, k, length(valid_data_arg)), ...
                %       'FontSize', 11, 'FontWeight', 'bold');
                % xlabel('Аргумент [рад]', 'FontSize', 10); 
                % ylabel('Частота', 'FontSize', 10);
                % grid on; set(gca, 'GridAlpha', 0.3);
                % 
                % subplot(2, 3, 5);
                % histogram(valid_data_arg, 50, 'Normalization', 'pdf', ...
                %          'FaceColor', color_arg_main, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
                % hold on;
                % if exist('ksdensity', 'file') == 2
                %     [f_arg_kde, xi_arg_kde] = ksdensity(valid_data_arg);
                %     plot(xi_arg_kde, f_arg_kde, 'Color', color_arg_kde, 'LineWidth', 2.5);
                %     legend({'Histogram', 'KDE'}, 'Location', 'best', 'FontSize', 8);
                % end
                % hold off;
                % title('PDF + KDE', 'FontSize', 11, 'FontWeight', 'bold');
                % xlabel('Аргумент [рад]', 'FontSize', 10); 
                % ylabel('Щільність', 'FontSize', 10);
                % grid on; set(gca, 'GridAlpha', 0.3);
                % 
                % subplot(2, 3, 6);
                % histogram(valid_data_arg, 50, 'Normalization', 'cdf', ...
                %          'FaceColor', color_arg_main, 'EdgeColor', 'k', 'FaceAlpha', 0.7);
                % hold on;
                % [f_ecdf_arg, x_ecdf_arg] = ecdf(valid_data_arg);
                % stairs(x_ecdf_arg, f_ecdf_arg, 'Color', color_arg_kde, 'LineWidth', 2);
                % hold off;
                % title('Кумулятивний розподіл', 'FontSize', 11, 'FontWeight', 'bold');
                % xlabel('Аргумент [рад]', 'FontSize', 10); 
                % ylabel('CDF', 'FontSize', 10);
                % legend({'Hist CDF', 'ECDF'}, 'Location', 'best', 'FontSize', 8);
                % grid on; set(gca, 'GridAlpha', 0.3);
                % 
                % sgtitle(sprintf('f̃_{%d%d} - Розподіли (Модуль і Аргумент) [%s]', i, k, current_colormap), ...
                %        'FontSize', 14, 'FontWeight', 'bold');
                % 
                % filename1 = fullfile(save_folder, sprintf('%s.f%d%d_Histogram1_Distributions.png', ...
                %                     current_colormap, i, k));
                % saveas(fig1, filename1);
                % close(fig1);
                % fprintf('      ✓ Fig1 збережено\n');
                % 
                % % ============================================================
                % % ФІГУРА 2: ПОЛЯРНІ ГРАФІКИ (1×2, тільки аргумент)
                % % ============================================================
                % 
                % % Визначаємо реальний діапазон аргумента
                % arg_min = min(valid_data_arg);
                % arg_max = max(valid_data_arg);
                % arg_range = arg_max - arg_min;
                % 
                % fprintf('    Аргумент: n=%d, діапазон=[%.3f, %.3f] рад = [%.1f°, %.1f°]\n', ...
                %         length(valid_data_arg), arg_min, arg_max, rad2deg(arg_min), rad2deg(arg_max));
                % 
                % fig2 = figure('Name', sprintf('Fig2: Polar f%d%d - %s', i, k, current_colormap), ...
                %               'Position', [100, 100, 1200, 550], ...
                %               'Color', 'white', ...
                %               'Visible', 'off');
                % 
                % % 2.1. Полярна гістограма (filled, 72 bins, реальний діапазон)
                % subplot(1, 2, 1);
                % polarhistogram(valid_data_arg, 72, 'FaceColor', color_arg_main, ...
                %               'EdgeColor', color_arg_edge, 'FaceAlpha', 0.75, 'LineWidth', 1);
                % hold on;
                % % Додаємо circular mean як лінію (ВИПРАВЛЕНО: rlim замість ylim)
                % r_limits = rlim;  % отримуємо поточні радіальні ліміти
                % polarplot([circ_mean_arg, circ_mean_arg], [0, r_limits(2)*0.9], ...
                %          'Color', color_line_mean, 'LineWidth', 3);
                % hold off;
                % title(sprintf('Полярна гістограма (72 bins)\n[%.2f, %.2f] рад = [%.0f°, %.0f°]', ...
                %               arg_min, arg_max, rad2deg(arg_min), rad2deg(arg_max)), ...
                %       'FontSize', 10, 'FontWeight', 'bold');
                % 
                % % 2.2. Rose Plot (stairs/outline, 72 bins, реальний діапазон)
                % subplot(1, 2, 2);
                % polarhistogram(valid_data_arg, 72, 'FaceColor', 'none', ...
                %               'EdgeColor', color_arg_main, 'DisplayStyle', 'stairs', 'LineWidth', 2);
                % hold on;
                % % Додаємо circular mean як лінію (ВИПРАВЛЕНО: rlim замість ylim)
                % r_limits = rlim;  % отримуємо поточні радіальні ліміти
                % polarplot([circ_mean_arg, circ_mean_arg], [0, r_limits(2)*0.9], ...
                %          'Color', color_line_mean, 'LineWidth', 3);
                % hold off;
                % title(sprintf('Rose Plot (72 bins)\n[%.2f, %.2f] рад = [%.0f°, %.0f°]', ...
                %               arg_min, arg_max, rad2deg(arg_min), rad2deg(arg_max)), ...
                %       'FontSize', 10, 'FontWeight', 'bold');
                % 
                % % Загальний заголовок з детальною інформацією
                % sgtitle(sprintf('f̃_{%d%d} - Полярні розподіли аргумента | Діапазон: %.2f-%.2f рад (%.0f°-%.0f°) | Circ.Mean=%.2f рад [%s]', ...
                %                i, k, arg_min, arg_max, rad2deg(arg_min), rad2deg(arg_max), circ_mean_arg, current_colormap), ...
                %        'FontSize', 12, 'FontWeight', 'bold');
                % 
                % filename2 = fullfile(save_folder, sprintf('%s.f%d%d_Histogram2_Polar.png', ...
                %                     current_colormap, i, k));
                % saveas(fig2, filename2);
                % close(fig2);
                % fprintf('      ✓ Fig2 збережено: діапазон %.1f°-%.1f°\n', rad2deg(arg_min), rad2deg(arg_max));
                % 
                % % ============================================================
                % % ФІГУРА 3: 2D ВІЗУАЛІЗАЦІЇ (1×2)
                % % ============================================================
                % fig3 = figure('Name', sprintf('Fig3: 2D f%d%d - %s', i, k, current_colormap), ...
                %               'Position', [150, 150, 1200, 500], 'Color', 'white', 'Visible', 'off');
                % 
                % subplot(1, 2, 1);
                % histogram2(valid_data_mag, valid_data_arg, [40 40], ...
                %           'DisplayStyle', 'tile', 'ShowEmptyBins', 'on', 'EdgeColor', 'none');
                % colormap(gca, current_colormap);
                % title('2D Heatmap |f̃| vs Arg', 'FontSize', 11, 'FontWeight', 'bold');
                % xlabel('|f̃|', 'FontSize', 10); 
                % ylabel('Arg [рад]', 'FontSize', 10);
                % colorbar;
                % axis tight;
                % 
                % subplot(1, 2, 2);
                % scatter(valid_data_mag, valid_data_arg, 10, 'filled', ...
                %        'MarkerFaceAlpha', 0.4, 'MarkerFaceColor', color_scatter);
                % title('Scatter Plot |f̃| vs Arg', 'FontSize', 11, 'FontWeight', 'bold');
                % xlabel('|f̃|', 'FontSize', 10); 
                % ylabel('Arg [рад]', 'FontSize', 10);
                % grid on; set(gca, 'GridAlpha', 0.3);
                % text(0.05, 0.95, sprintf('r = %.3f', corr_val), ...
                %     'Units', 'normalized', 'FontSize', 10, 'FontWeight', 'bold', ...
                %     'BackgroundColor', 'white', 'EdgeColor', 'k');
                % 
                % sgtitle(sprintf('f̃_{%d%d} - 2D Візуалізації: Модуль vs Аргумент [%s]', i, k, current_colormap), ...
                %        'FontSize', 14, 'FontWeight', 'bold');
                % 
                % filename3 = fullfile(save_folder, sprintf('%s.f%d%d_Histogram3_2D.png', ...
                %                     current_colormap, i, k));
                % saveas(fig3, filename3);
                % close(fig3);
                % fprintf('      ✓ Fig3 збережено\n');
                % 
                % % ============================================================
                % % ФІГУРА 4: Q-Q PLOTS та PERCENTILES (2×2)
                % % ============================================================
                % fig4 = figure('Name', sprintf('Fig4: QQ-Percentiles f%d%d - %s', i, k, current_colormap), ...
                %               'Position', [200, 200, 1200, 900], 'Color', 'white', 'Visible', 'off');
                % 
                % subplot(2, 2, 1);
                % qqplot(valid_data_mag);
                % title('Q-Q Plot |f̃| (Нормальність)', 'FontSize', 11, 'FontWeight', 'bold');
                % xlabel('Теоретичні квантилі', 'FontSize', 10);
                % ylabel('Вибіркові квантилі', 'FontSize', 10);
                % grid on; set(gca, 'GridAlpha', 0.3);
                % 
                % subplot(2, 2, 2);
                % percentiles_mag = prctile(valid_data_mag, 0:10:100);
                % bar(0:10:100, percentiles_mag, 'FaceColor', color_mag_main, ...
                %    'EdgeColor', 'k', 'FaceAlpha', 0.7, 'LineWidth', 1);
                % title('Percentiles |f̃| (0-100%)', 'FontSize', 11, 'FontWeight', 'bold');
                % xlabel('Percentile', 'FontSize', 10); 
                % ylabel('Значення', 'FontSize', 10);
                % grid on; set(gca, 'GridAlpha', 0.3);
                % for p_idx = 1:length(percentiles_mag)
                %     text((p_idx-1)*10, percentiles_mag(p_idx), sprintf('%.2f', percentiles_mag(p_idx)), ...
                %         'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
                %         'FontSize', 7, 'FontWeight', 'bold');
                % end
                % 
                % subplot(2, 2, 3);
                % qqplot(valid_data_arg);
                % title('Q-Q Plot Arg [рад] (Нормальність)', 'FontSize', 11, 'FontWeight', 'bold');
                % xlabel('Теоретичні квантилі', 'FontSize', 10);
                % ylabel('Вибіркові квантилі', 'FontSize', 10);
                % grid on; set(gca, 'GridAlpha', 0.3);
                % 
                % subplot(2, 2, 4);
                % percentiles_arg = prctile(valid_data_arg, 0:10:100);
                % bar(0:10:100, percentiles_arg, 'FaceColor', color_arg_main, ...
                %    'EdgeColor', 'k', 'FaceAlpha', 0.7, 'LineWidth', 1);
                % title('Percentiles Arg [рад] (0-100%)', 'FontSize', 11, 'FontWeight', 'bold');
                % xlabel('Percentile', 'FontSize', 10); 
                % ylabel('Аргумент [рад]', 'FontSize', 10);
                % grid on; set(gca, 'GridAlpha', 0.3);
                % for p_idx = 1:length(percentiles_arg)
                %     text((p_idx-1)*10, percentiles_arg(p_idx), sprintf('%.2f', percentiles_arg(p_idx)), ...
                %         'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
                %         'FontSize', 7, 'FontWeight', 'bold');
                % end
                % 
                % sgtitle(sprintf('f̃_{%d%d} - Q-Q Plots та Percentiles [%s]', i, k, current_colormap), ...
                %        'FontSize', 14, 'FontWeight', 'bold');
                % 
                % filename4 = fullfile(save_folder, sprintf('%s.f%d%d_Histogram4_QQ_Percentiles.png', ...
                %                     current_colormap, i, k));
                % saveas(fig4, filename4);
                % close(fig4);
                % fprintf('      ✓ Fig4 збережено\n');
                % 
                % % ============================================================
                % % ФІГУРА 5: BOX PLOTS (1×2)
                % % ============================================================
                % fig5 = figure('Name', sprintf('Fig5: BoxPlots f%d%d - %s', i, k, current_colormap), ...
                %               'Position', [250, 250, 1000, 450], 'Color', 'white', 'Visible', 'off');
                % 
                % subplot(1, 2, 1);
                % boxplot(valid_data_mag, 'Orientation', 'vertical', ...
                %        'Colors', color_mag_main, 'Symbol', 'r+', 'Widths', 0.5);
                % title('Box Plot |f̃|', 'FontSize', 11, 'FontWeight', 'bold');
                % ylabel('Значення', 'FontSize', 10);
                % grid on; set(gca, 'GridAlpha', 0.3);
                % text(0.55, 0.98, sprintf('Q1=%.3f\nMedian=%.3f\nQ3=%.3f\nIQR=%.3f\nMean=%.3f', ...
                %      q1_mag, median_mag, q3_mag, iqr_mag, mean_mag), ...
                %      'Units', 'normalized', 'FontSize', 9, 'VerticalAlignment', 'top', ...
                %      'BackgroundColor', 'white', 'EdgeColor', 'k');
                % 
                % subplot(1, 2, 2);
                % boxplot(valid_data_arg, 'Orientation', 'vertical', ...
                %        'Colors', color_arg_main, 'Symbol', 'r+', 'Widths', 0.5);
                % title('Box Plot Arg [рад]', 'FontSize', 11, 'FontWeight', 'bold');
                % ylabel('Аргумент [рад]', 'FontSize', 10);
                % grid on; set(gca, 'GridAlpha', 0.3);
                % text(0.55, 0.98, sprintf('Q1=%.3f\nMedian=%.3f\nQ3=%.3f\nIQR=%.3f\nMean=%.3f', ...
                %      q1_arg, median_arg, q3_arg, iqr_arg, mean_arg), ...
                %      'Units', 'normalized', 'FontSize', 9, 'VerticalAlignment', 'top', ...
                %      'BackgroundColor', 'white', 'EdgeColor', 'k');
                % 
                % sgtitle(sprintf('f̃_{%d%d} - Box Plots (Модуль і Аргумент) [%s]', i, k, current_colormap), ...
                %        'FontSize', 14, 'FontWeight', 'bold');
                % 
                % filename5 = fullfile(save_folder, sprintf('%s.f%d%d_Histogram5_BoxPlots.png', ...
                %                     current_colormap, i, k));
                % saveas(fig5, filename5);
                % close(fig5);
                % fprintf('      ✓ Fig5 збережено\n');
                % 
                % % ============================================================
                % % ЗБЕРЕЖЕННЯ СТАТИСТИКИ В ТЕКСТОВИЙ ФАЙЛ
                % % ============================================================
                % stat_filename = fullfile(save_folder, sprintf('%s.f%d%d_Statistics.txt', ...
                %                         current_colormap, i, k));
                % fid = fopen(stat_filename, 'w');
                % 
                % fprintf(fid, '═══════════════════════════════════════════════════════════════\n');
                % fprintf(fid, 'СТАТИСТИЧНИЙ АНАЛІЗ f̃_%d%d [%s]\n', i, k, current_colormap);
                % fprintf(fid, '═══════════════════════════════════════════════════════════════\n\n');
                % 
                % fprintf(fid, '────────────────────────────────────────────────────────────────\n');
                % fprintf(fid, 'МОДУЛЬ |f̃_%d%d| (4 моменти)\n', i, k);
                % fprintf(fid, '────────────────────────────────────────────────────────────────\n');
                % fprintf(fid, 'Кількість точок:       %d\n\n', length(valid_data_mag));
                % 
                % fprintf(fid, '1-й момент (Середнє):\n');
                % fprintf(fid, '  Mean:                %.6f\n', mean_mag);
                % fprintf(fid, '  Median:              %.6f\n', median_mag);
                % fprintf(fid, '  Min:                 %.6f\n', min_mag);
                % fprintf(fid, '  Max:                 %.6f\n', max_mag);
                % fprintf(fid, '  Range:               %.6f\n\n', range_mag);
                % 
                % fprintf(fid, '2-й момент (Варіація):\n');
                % fprintf(fid, '  Variance:            %.6e\n', var_mag);
                % fprintf(fid, '  Std:                 %.6f\n', std_mag);
                % fprintf(fid, '  CV (коеф. варіації): %.2f%%\n\n', cv_mag);
                % 
                % fprintf(fid, '3-й момент (Асиметрія):\n');
                % fprintf(fid, '  Skewness:            %.6f\n\n', skew_mag);
                % 
                % fprintf(fid, '4-й момент (Ексцес):\n');
                % fprintf(fid, '  Kurtosis:            %.6f\n\n', kurt_mag);
                % 
                % fprintf(fid, 'Квантилі:\n');
                % fprintf(fid, '  Q1 (25%%):            %.6f\n', q1_mag);
                % fprintf(fid, '  Q3 (75%%):            %.6f\n', q3_mag);
                % fprintf(fid, '  IQR:                 %.6f\n\n', iqr_mag);
                % 
                % fprintf(fid, '────────────────────────────────────────────────────────────────\n');
                % fprintf(fid, 'АРГУМЕНТ Arg(f̃_%d%d) [рад] (4 моменти)\n', i, k);
                % fprintf(fid, '────────────────────────────────────────────────────────────────\n');
                % fprintf(fid, 'Кількість точок:       %d\n\n', length(valid_data_arg));
                % 
                % fprintf(fid, '1-й момент (Середнє):\n');
                % fprintf(fid, '  Mean:                %.6f рад\n', mean_arg);
                % fprintf(fid, '  Median:              %.6f рад\n', median_arg);
                % fprintf(fid, '  Min:                 %.6f рад\n', min_arg);
                % fprintf(fid, '  Max:                 %.6f рад\n', max_arg);
                % fprintf(fid, '  Range:               %.6f рад\n\n', range_arg);
                % 
                % fprintf(fid, '2-й момент (Варіація):\n');
                % fprintf(fid, '  Variance:            %.6e\n', var_arg);
                % fprintf(fid, '  Std:                 %.6f рад\n\n', std_arg);
                % 
                % fprintf(fid, '3-й момент (Асиметрія):\n');
                % fprintf(fid, '  Skewness:            %.6f\n\n', skew_arg);
                % 
                % fprintf(fid, '4-й момент (Ексцес):\n');
                % fprintf(fid, '  Kurtosis:            %.6f\n\n', kurt_arg);
                % 
                % fprintf(fid, 'Квантилі:\n');
                % fprintf(fid, '  Q1 (25%%):            %.6f рад\n', q1_arg);
                % fprintf(fid, '  Q3 (75%%):            %.6f рад\n', q3_arg);
                % fprintf(fid, '  IQR:                 %.6f рад\n\n', iqr_arg);
                % 
                % fprintf(fid, 'CIRCULAR STATISTICS (для кутових даних):\n');
                % fprintf(fid, '  Circular Mean:       %.6f рад\n', circ_mean_arg);
                % fprintf(fid, '  Circular Std:        %.6f рад\n', circ_std_arg);
                % fprintf(fid, '  Directedness R:      %.6f\n\n', R_arg);
                % 
                % fprintf(fid, '────────────────────────────────────────────────────────────────\n');
                % fprintf(fid, 'КОРЕЛЯЦІЯ МІЖ МОДУЛЕМ ТА АРГУМЕНТОМ\n');
                % fprintf(fid, '────────────────────────────────────────────────────────────────\n');
                % fprintf(fid, '  Pearson r:           %.6f\n\n', corr_val);
                % 
                % fprintf(fid, '═══════════════════════════════════════════════════════════════\n');
                % fprintf(fid, 'Згенеровано: %s\n', datetime('now'));
                % fprintf(fid, '═══════════════════════════════════════════════════════════════\n');
                % 
                % fclose(fid);
                % fprintf('      ✓ Статистика збережена\n');
                % 
                % fprintf('  ✓ Всі гістограми для f%d%d завершено\n', i, k);
                % %%==============================================================================================================
                % %%==============================================================================================================

        end

        
        % Выводим статистику времени для элемента
        total_calc_time = acf_time_mag + psd_time_mag + acf_time_arg + psd_time_arg;
        fprintf('  ИТОГО для f%d%d: ACF_mag=%.2fs, PSD_mag=%.2fs, ACF_arg=%.2fs, PSD_arg=%.2fs\n', ...
                i, k, acf_time_mag, psd_time_mag, acf_time_arg, psd_time_arg);
        fprintf('  Общее время расчетов: %.2fs, визуализаций: %d цветовых карт\n', ...
                total_calc_time, length(color_maps));
    end
end

fprintf('\n=== ВИЗУАЛИЗАЦИЯ АКФ И СПЕКТРОВ МОЩНОСТИ ЗАВЕРШЕНА ===\n');
fprintf('\n=== КОНЕЦ ВСЕХ ВИЗУАЛИЗАЦИЙ ===\n');

% Финальная статистика
fprintf('\n=== ИТОГОВАЯ СТАТИСТИКА ===\n');
fprintf('Размер матрицы: %dx%d\n', matrix_rows, matrix_cols);
fprintf('Радиус круга: %.1f\n', radius);
fprintf('Центр круга: (%.1f, %.1f)\n', center_x, center_y);
fprintf('Точек в круге: %d из %d (%.1f%%)\n', circle_points, total_points, 100*circle_points/total_points);
fprintf('Цветовые карты: %s\n', strjoin(color_maps, ', '));
fprintf('Папка сохранения: %s\n', save_folder);

end % end of function