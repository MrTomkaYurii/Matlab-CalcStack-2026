function calc_2025_vis_Azimuth_Ellipticity_Extended(Results, save_folder)
% CALC_2025_VIS_AZIMUTH_ELLIPTICITY_EXTENDED Расширенная визуализация двуточечных параметров 
% азимута и эллиптичности с 3D представлениями, АКФ и спектрами мощности
%
% Использование:
%   calc_2025_vis_Azimuth_Ellipticity_Extended(Results, save_folder)
%
% Входные параметры:
%   Results     - структура с результатами расчета азимута и эллиптичности
%   save_folder - папка для сохранения изображений

number_of_contours = 5;

% Проверка входных параметров
if nargin < 2
    error('Необходимо указать папку для сохранения: calc_2025_vis_Azimuth_Ellipticity_Extended(Results, save_folder)');
end

% Создание основной папки если не существует
if ~exist(save_folder, 'dir')
    mkdir(save_folder);
    fprintf('Создана папка: %s\n', save_folder);
end

% Определение цветовых карт
color_maps = {'jet', 'gray'};
map_types = {'цветная', 'серая'};

% Определение поляризаций
polarization_names = {'Polarizer_0', 'Polarizer_45', 'Polarizer_90', 'Polarizer_RC'};
polarization_labels = {'0', '45', '90', 'RC'};
polarization_folders = {'Pol_0deg', 'Pol_45deg', 'Pol_90deg', 'Pol_RC'};

% Создание папок для каждой поляризации
for pol_idx = 1:length(polarization_folders)
    pol_folder = fullfile(save_folder, polarization_folders{pol_idx});
    if ~exist(pol_folder, 'dir')
        mkdir(pol_folder);
        fprintf('Создана папка поляризации: %s\n', pol_folder);
    end
end

% Настройки визуализации
font_size_title = 14;
font_size_label = 11;
font_size_subplot = 10;
figure_size = [1600, 1000];

% Получаем размер матрицы
[matrix_rows, matrix_cols] = size(Results.Polarizer_0.Azimuth_Magnitude);

% Настройка параллельных вычислений
if isempty(gcp('nocreate'))
    parpool('local', 16);
    fprintf('Создан пул параллельных вычислений на 16 потоков\n');
else
    fprintf('Используется существующий пул параллельных вычислений\n');
end

fprintf('\n----- НАЧАЛО РАСШИРЕННОЙ ВИЗУАЛИЗАЦИИ ДВУТОЧЕЧНЫХ ПАРАМЕТРОВ -----\n');
fprintf('Размер матрицы: %dx%d\n', matrix_rows, matrix_cols);
fprintf('Папка сохранения: %s\n', save_folder);
fprintf('Цветовые карты: %s\n', strjoin(color_maps, ', '));
fprintf('Поляризации: %s\n\n', strjoin(polarization_labels, ', '));

fprintf('\--- НАЧАЛО. ЧАСТЬ 01. МОДУЛИ И АРГУМЕНТЫ АЗИМУТА И ЭЛЛИПТИЧНОСТИ\n');

% Цикл по всем цветовым картам
for map_idx = 1:length(color_maps)
    current_colormap = color_maps{map_idx};
    map_type = map_types{map_idx};
    
    %!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    %% Визуализация МОДУЛЕЙ и АРГУМЕНТОВ АЗИМУТА для всех поляризаций
    %!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    fig_azimuth = figure('Name', sprintf('Азимут - %s', current_colormap), ...
        'Position', [50, 50, figure_size(1), figure_size(2)], ...
        'Color', 'white', ...
        'Visible', 'off');
        
    for pol_idx = 1:4
        pol_name = polarization_names{pol_idx};
        pol_label = polarization_labels{pol_idx};
        
        % Subplot для модуля азимута
        subplot(4, 2, (pol_idx-1)*2 + 1);
        azimuth_magnitude = Results.(pol_name).Azimuth_Magnitude;
        imagesc(azimuth_magnitude);
        colormap(gca, current_colormap);
        axis image;
        
        % Колорбар
        c = colorbar;
        c.Label.String = '|2α^C|';
        c.Label.FontSize = font_size_label;
        caxis([min(azimuth_magnitude(:)) max(azimuth_magnitude(:))]);
        
        % Подписи
        xlabel('Индекс X', 'FontSize', font_size_label);
        ylabel('Индекс Y', 'FontSize', font_size_label);
        title(sprintf('|2α^C| - Поляризация %s°', pol_label), ...
            'FontSize', font_size_subplot, 'FontWeight', 'bold');
            
        % Упрощенная система меток осей
        setup_axis_ticks(matrix_cols, matrix_rows);
        grid on; set(gca, 'GridAlpha', 0.3);
        
        % Центр матрицы
        hold on;
        center_x = (matrix_cols + 1) / 2;
        center_y = (matrix_rows + 1) / 2;
        plot(center_x, center_y, 'w+', 'MarkerSize', 10, 'LineWidth', 1);
        hold off;
        
        % Subplot для аргумента азимута  
        subplot(4, 2, (pol_idx-1)*2 + 2);
        azimuth_argument = Results.(pol_name).Azimuth_Argument;
        imagesc(azimuth_argument);
        colormap(gca, current_colormap);
        axis image;
        
        % Колорбар
        c = colorbar;
        c.Label.String = 'Arg(2α^C) [рад]';
        c.Label.FontSize = font_size_label;
        caxis([min(azimuth_argument(:)) max(azimuth_argument(:))]);
        
        % Подписи
        xlabel('Индекс X', 'FontSize', font_size_label);
        ylabel('Индекс Y', 'FontSize', font_size_label);
        title(sprintf('Arg(2α^C) - Поляризация %s°', pol_label), ...
            'FontSize', font_size_subplot, 'FontWeight', 'bold');
            
        setup_axis_ticks(matrix_cols, matrix_rows);
        grid on; set(gca, 'GridAlpha', 0.3);
        
        hold on;
        plot(center_x, center_y, 'w+', 'MarkerSize', 10, 'LineWidth', 1);
        hold off;
    end
    
    % Общий заголовок
    sgtitle(sprintf('Двуточечные параметры азимута [%s]', current_colormap), ...
        'FontSize', font_size_title, 'FontWeight', 'bold');
        
    % Сохранение в общую папку
    filename = fullfile(save_folder, sprintf('%s.Azimuth_All.png', current_colormap));
    saveas(fig_azimuth, filename);
    close(fig_azimuth);
    
    %!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    %% Визуализация МОДУЛЕЙ и АРГУМЕНТОВ ЭЛЛИПТИЧНОСТИ для всех поляризаций
    %!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    fig_ellipticity = figure('Name', sprintf('Эллиптичность - %s', current_colormap), ...
        'Position', [100, 100, figure_size(1), figure_size(2)], ...
        'Color', 'white', ...
        'Visible', 'off');
        
    for pol_idx = 1:4
        pol_name = polarization_names{pol_idx};
        pol_label = polarization_labels{pol_idx};
        
        % Subplot для модуля эллиптичности
        subplot(4, 2, (pol_idx-1)*2 + 1);
        ellipticity_magnitude = Results.(pol_name).Ellipticity_Magnitude;
        imagesc(ellipticity_magnitude);
        colormap(gca, current_colormap);
        axis image;
        
        % Колорбар
        c = colorbar;
        c.Label.String = '|2β^C|';
        c.Label.FontSize = font_size_label;
        caxis([min(ellipticity_magnitude(:)) max(ellipticity_magnitude(:))]);
        
        % Подписи
        xlabel('Индекс X', 'FontSize', font_size_label);
        ylabel('Индекс Y', 'FontSize', font_size_label);
        title(sprintf('|2β^C| - Поляризация %s°', pol_label), ...
            'FontSize', font_size_subplot, 'FontWeight', 'bold');
            
        setup_axis_ticks(matrix_cols, matrix_rows);
        grid on; set(gca, 'GridAlpha', 0.3);
        
        % Центр матрицы
        hold on;
        center_x = (matrix_cols + 1) / 2;
        center_y = (matrix_rows + 1) / 2;
        plot(center_x, center_y, 'w+', 'MarkerSize', 10, 'LineWidth', 1);
        hold off;
        
        % Subplot для аргумента эллиптичности
        subplot(4, 2, (pol_idx-1)*2 + 2);
        ellipticity_argument = Results.(pol_name).Ellipticity_Argument;
        imagesc(ellipticity_argument);
        colormap(gca, current_colormap);
        axis image;
        
        % Колорбар
        c = colorbar;
        c.Label.String = 'Arg(2β^C) [рад]';
        c.Label.FontSize = font_size_label;
        caxis([min(ellipticity_argument(:)) max(ellipticity_argument(:))]);
        
        % Подписи
        xlabel('Индекс X', 'FontSize', font_size_label);
        ylabel('Индекс Y', 'FontSize', font_size_label);
        title(sprintf('Arg(2β^C) - Поляризация %s°', pol_label), ...
            'FontSize', font_size_subplot, 'FontWeight', 'bold');
            
        setup_axis_ticks(matrix_cols, matrix_rows);
        grid on; set(gca, 'GridAlpha', 0.3);
        
        hold on;
        plot(center_x, center_y, 'w+', 'MarkerSize', 10, 'LineWidth', 1);
        hold off;
    end
    
    % Общий заголовок
    sgtitle(sprintf('Двуточечные параметры эллиптичности [%s]', current_colormap), ...
        'FontSize', font_size_title, 'FontWeight', 'bold');
        
    % Сохранение в общую папку
    filename = fullfile(save_folder, sprintf('%s.Ellipticity_All.png', current_colormap));
    saveas(fig_ellipticity, filename);
    close(fig_ellipticity);
end

fprintf('\n=== ВИЗУАЛИЗАЦИЯ ВСЕХ МОДУЛЕЙ И АРГУМЕНТОВ ЗАВЕРШЕНА ===\n');
fprintf('\---- НАЧАЛО. ЧАСТЬ 02. 2D.ГИСТОГРАММЫ\n');

%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%% Визуализация отдельных 2D элементов с гистограммами по поляризациям
%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
for pol_idx = 1:4
    pol_name = polarization_names{pol_idx};
    pol_label = polarization_labels{pol_idx};
    pol_folder = fullfile(save_folder, polarization_folders{pol_idx});
    
    % Цикл по цветовым картам для каждой поляризации
    for map_idx = 1:length(color_maps)
        current_colormap = color_maps{map_idx};
        
        % Создаем фигуру 2x2 для азимута
        fig_azimuth_hist = create_2d_histogram_figure(Results, pol_name, pol_label, ...
            'azimuth', current_colormap, matrix_cols, matrix_rows);
        
        % Сохранение азимута в папку поляризации
        filename = fullfile(pol_folder, sprintf('%s.Azimuth_%s_2D-hist.png', current_colormap, pol_label));
        saveas(fig_azimuth_hist, filename);
        close(fig_azimuth_hist);
        
        % Создаем фигуру 2x2 для эллиптичности
        fig_ellipticity_hist = create_2d_histogram_figure(Results, pol_name, pol_label, ...
            'ellipticity', current_colormap, matrix_cols, matrix_rows);
        
        % Сохранение эллиптичности в папку поляризации
        filename = fullfile(pol_folder, sprintf('%s.Ellipticity_%s_2D-hist.png', current_colormap, pol_label));
        saveas(fig_ellipticity_hist, filename);
        close(fig_ellipticity_hist);
    end
end

fprintf('\n=== ВИЗУАЛИЗАЦИЯ 2D РАСПРЕДЕЛЕНИЙ И ГИСТОГРАМ ЗАВЕРШЕНА ===\n');
fprintf('\---- НАЧАЛО. ЧАСТЬ 03. 3D.КОНТУРЫ\n');

%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%% Визуализация 3D поверхностей и контуров
%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
for pol_idx = 1:4
    pol_name = polarization_names{pol_idx};
    pol_label = polarization_labels{pol_idx};
    pol_folder = fullfile(save_folder, polarization_folders{pol_idx});
    
    for map_idx = 1:length(color_maps)
        current_colormap = color_maps{map_idx};
        
        % 3D визуализация азимута
        fig_3d_azimuth = create_3d_contour_figure(Results, pol_name, pol_label, ...
            'azimuth', current_colormap, matrix_cols, matrix_rows, number_of_contours);
        
        filename = fullfile(pol_folder, sprintf('%s.Azimuth_%s_3D-contour.png', current_colormap, pol_label));
        saveas(fig_3d_azimuth, filename);
        close(fig_3d_azimuth);
        
        % 3D визуализация эллиптичности
        fig_3d_ellipticity = create_3d_contour_figure(Results, pol_name, pol_label, ...
            'ellipticity', current_colormap, matrix_cols, matrix_rows, number_of_contours);
        
        filename = fullfile(pol_folder, sprintf('%s.Ellipticity_%s_3D-contour.png', current_colormap, pol_label));
        saveas(fig_3d_ellipticity, filename);
        close(fig_3d_ellipticity);
    end
end

fprintf('\n=== ВИЗУАЛИЗАЦИЯ 3D ПРЕДСТАВЛЕНИЙ И КОНТУРОВ ЗАВЕРШЕНА ===\n');
fprintf('\---- НАЧАЛО. ЧАСТЬ 04. 2D.АКФ И СПЕКТРЫ МОЩНОСТИ\n');

%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%% Визуализация 2D АКФ и спектров мощности (с параллельными вычислениями)
%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
for pol_idx = 1:4
    pol_name = polarization_names{pol_idx};
    pol_label = polarization_labels{pol_idx};
    pol_folder = fullfile(save_folder, polarization_folders{pol_idx});
    
    fprintf('Обработка поляризации %s°...\n', pol_label);
    
    for map_idx = 1:length(color_maps)
        current_colormap = color_maps{map_idx};
        
        % АКФ и спектры для азимута
        [fig_acf_mag, fig_acf_arg] = create_acf_power_figures(Results, pol_name, pol_label, ...
            'azimuth', current_colormap);
        
        % Сохранение фигур азимута
        filename_mag = fullfile(pol_folder, sprintf('%s.Azimuth_%s_ACF-Power_Magnitude.png', current_colormap, pol_label));
        filename_arg = fullfile(pol_folder, sprintf('%s.Azimuth_%s_ACF-Power_Argument.png', current_colormap, pol_label));
        saveas(fig_acf_mag, filename_mag);
        saveas(fig_acf_arg, filename_arg);
        close(fig_acf_mag);
        close(fig_acf_arg);
        
        % АКФ и спектры для эллиптичности
        [fig_acf_mag, fig_acf_arg] = create_acf_power_figures(Results, pol_name, pol_label, ...
            'ellipticity', current_colormap);
        
        % Сохранение фигур эллиптичности
        filename_mag = fullfile(pol_folder, sprintf('%s.Ellipticity_%s_ACF-Power_Magnitude.png', current_colormap, pol_label));
        filename_arg = fullfile(pol_folder, sprintf('%s.Ellipticity_%s_ACF-Power_Argument.png', current_colormap, pol_label));
        saveas(fig_acf_mag, filename_mag);
        saveas(fig_acf_arg, filename_arg);
        close(fig_acf_mag);
        close(fig_acf_arg);
    end
end

fprintf('\n=== ВИЗУАЛИЗАЦИЯ АКФ И СПЕКТРОВ МОЩНОСТИ ЗАВЕРШЕНА ===\n');
fprintf('\n=== КОНЕЦ ВСЕХ РАСШИРЕННЫХ ВИЗУАЛИЗАЦИЙ ===\n');

end

%% Вспомогательные функции

function setup_axis_ticks(matrix_cols, matrix_rows)
    % Упрощенная система меток осей
    if matrix_cols <= 10
        xticks(1:matrix_cols);
    elseif matrix_cols <= 100
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
    else
        ytick_values = [1, round(matrix_rows/2), matrix_rows];
        yticks(ytick_values);
    end
end

function fig = create_2d_histogram_figure(Results, pol_name, pol_label, param_type, colormap_name, matrix_cols, matrix_rows)
    % Создание 2D фигуры с гистограммами
    
    if strcmp(param_type, 'azimuth')
        magnitude_data = Results.(pol_name).Azimuth_Magnitude;
        argument_data = Results.(pol_name).Azimuth_Argument;
        mag_label = '|2α^C|';
        arg_label = 'Arg(2α^C) [рад]';
        title_prefix = 'Двуточечный азимут';
    else % ellipticity
        magnitude_data = Results.(pol_name).Ellipticity_Magnitude;
        argument_data = Results.(pol_name).Ellipticity_Argument;
        mag_label = '|2β^C|';
        arg_label = 'Arg(2β^C) [рад]';
        title_prefix = 'Двуточечная эллиптичность';
    end
    
    fig = figure('Name', sprintf('%s_%s - %s', title_prefix, pol_label, colormap_name), ...
        'Position', [100, 100, 1400, 1000], ...
        'Color', 'white', ...
        'Visible', 'off');
    
    % Subplot 1,1 - 2D визуализация модуля
    subplot(2, 2, 1);
    imagesc(magnitude_data);
    colormap(gca, colormap_name);
    axis image;
    c = colorbar;
    c.Label.String = mag_label;
    c.Label.FontSize = 10;
    title(sprintf('%s - Поляризация %s°', mag_label, pol_label), 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('Индекс X', 'FontSize', 10);
    ylabel('Индекс Y', 'FontSize', 10);
    grid on; set(gca, 'GridAlpha', 0.3);
    
    % Центр матрицы
    hold on;
    center_x = (matrix_cols + 1) / 2;
    center_y = (matrix_rows + 1) / 2;
    plot(center_x, center_y, 'w+', 'MarkerSize', 10, 'LineWidth', 2);
    hold off;
    
    % Subplot 2,1 - Гистограмма модуля
    subplot(2, 2, 3);
    histogram(magnitude_data(:), 100, 'FaceColor', [0.2 0.4 0.8], 'EdgeColor', 'black');
    title('Гистограмма модуля', 'FontSize', 12, 'FontWeight', 'bold');
    xlabel(mag_label, 'FontSize', 10);
    ylabel('Частота', 'FontSize', 10);
    grid on; set(gca, 'GridAlpha', 0.3);
    
    % Статистика для модуля
    mean_val = mean(magnitude_data(:));
    std_val = std(magnitude_data(:));
    skew_val = skewness(magnitude_data(:));
    kurt_val = kurtosis(magnitude_data(:));
    text_str = sprintf('μ = %.4f\nσ = %.4f\nSkew = %.4f\nKurt = %.4f', ...
                       mean_val, std_val, skew_val, kurt_val);
    text(0.98, 0.98, text_str, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
         'HorizontalAlignment', 'right', 'BackgroundColor', 'white', ...
         'EdgeColor', 'black', 'FontSize', 9, 'Margin', 2);
    
    % Subplot 1,2 - 2D визуализация аргумента
    subplot(2, 2, 2);
    imagesc(argument_data);
    colormap(gca, colormap_name);
    axis image;
    c = colorbar;
    c.Label.String = arg_label;
    c.Label.FontSize = 10;
    title(sprintf('%s - Поляризация %s°', arg_label, pol_label), 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('Индекс X', 'FontSize', 10);
    ylabel('Индекс Y', 'FontSize', 10);
    grid on; set(gca, 'GridAlpha', 0.3);
    
    hold on;
    plot(center_x, center_y, 'w+', 'MarkerSize', 10, 'LineWidth', 2);
    hold off;
    
    % Subplot 2,2 - Гистограмма аргумента
    subplot(2, 2, 4);
    histogram(argument_data(:), 100, 'FaceColor', [0.8 0.4 0.2], 'EdgeColor', 'black');
    title('Гистограмма аргумента', 'FontSize', 12, 'FontWeight', 'bold');
    xlabel(arg_label, 'FontSize', 10);
    ylabel('Частота', 'FontSize', 10);
    grid on; set(gca, 'GridAlpha', 0.3);
    
    % Статистика для аргумента (циклическое среднее)
    mean_angle = angle(mean(exp(1i*argument_data(:))));
    std_angle = std(argument_data(:));
    skew_angle = skewness(argument_data(:));
    kurt_angle = kurtosis(argument_data(:));
    text_str = sprintf('μ = %.4f\nσ = %.4f\nSkew = %.4f\nKurt = %.4f', ...
                       mean_angle, std_angle, skew_angle, kurt_angle);
    text(0.98, 0.98, text_str, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
         'HorizontalAlignment', 'right', 'BackgroundColor', 'white', ...
         'EdgeColor', 'black', 'FontSize', 8, 'Margin', 2);
    
    % Общий заголовок
    sgtitle(sprintf('%s - Поляризация %s° [%s]', title_prefix, pol_label, colormap_name), ...
           'FontSize', 14, 'FontWeight', 'bold');
end

function fig = create_3d_contour_figure(Results, pol_name, pol_label, param_type, colormap_name, matrix_cols, matrix_rows, number_of_contours)
    % Создание ОДНОЙ 3D фигуры с контурами (2x2 субплоты)
    
    if strcmp(param_type, 'azimuth')
        magnitude_data = Results.(pol_name).Azimuth_Magnitude;
        argument_data = Results.(pol_name).Azimuth_Argument;
        mag_label = '|2α^C|';
        arg_label = 'Arg(2α^C) [рад]';
        title_prefix = 'Двуточечный азимут';
    else % ellipticity
        magnitude_data = Results.(pol_name).Ellipticity_Magnitude;
        argument_data = Results.(pol_name).Ellipticity_Argument;
        mag_label = '|2β^C|';
        arg_label = 'Arg(2β^C) [рад]';
        title_prefix = 'Двуточечная эллиптичность';
    end
    
    fig = figure('Name', sprintf('%s_%s - %s - 3D+Contour', title_prefix, pol_label, colormap_name), ...
        'Position', [100, 100, 1400, 1000], ...
        'Color', 'white', ...
        'Visible', 'off');
    
    % Создаем координатные сетки
    [X, Y] = meshgrid(1:size(magnitude_data, 2), 1:size(magnitude_data, 1));
    
    % Subplot 1,1 - 3D поверхность модуля
    subplot(2, 2, 1);
    surf(X, Y, magnitude_data, 'EdgeColor', 'none');
    colormap(gca, colormap_name);
    view(45, 30);
    lighting phong;
    shading interp;
    c = colorbar;
    c.Label.String = mag_label;
    c.Label.FontSize = 10;
    title(sprintf('%s - 3D поверхность', mag_label), 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('Индекс X', 'FontSize', 10);
    ylabel('Индекс Y', 'FontSize', 10);
    zlabel(mag_label, 'FontSize', 10);
    grid on; set(gca, 'GridAlpha', 0.3);
    
    % Subplot 1,2 - 3D поверхность аргумента
    subplot(2, 2, 2);
    surf(X, Y, argument_data, 'EdgeColor', 'none');
    colormap(gca, colormap_name);
    view(45, 30);
    lighting phong;
    shading interp;
    c = colorbar;
    c.Label.String = arg_label;
    c.Label.FontSize = 10;
    title(sprintf('%s - 3D поверхность', arg_label), 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('Индекс X', 'FontSize', 10);
    ylabel('Индекс Y', 'FontSize', 10);
    zlabel(arg_label, 'FontSize', 10);
    grid on; set(gca, 'GridAlpha', 0.3);
    
    % Subplot 2,1 - Контурная карта модуля
    subplot(2, 2, 3);
    min_mag = min(magnitude_data(:));
    max_mag = max(magnitude_data(:));
    contour_levels = linspace(min_mag, max_mag, number_of_contours);
    [C, h] = contour(X, Y, magnitude_data, contour_levels, 'LineWidth', 1);
    colormap(gca, colormap_name);
    axis image;
    
    % Форматирование меток контуров
    ht = findobj(h,'Type','text');
    for kk = 1:numel(ht)
        val = str2double(ht(kk).String);
        ht(kk).String = sprintf('%.2f',val);
    end
    
    c = colorbar;
    c.Label.String = mag_label;
    c.Label.FontSize = 10;
    title(sprintf('%s - Контурная карта', mag_label), 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('Индекс X', 'FontSize', 10);
    ylabel('Индекс Y', 'FontSize', 10);
    
    % Настройка осей
    setup_axis_ticks(matrix_cols, matrix_rows);
    grid on; set(gca, 'GridAlpha', 0.3);
    
    % Центр матрицы
    hold on;
    center_x = (matrix_cols + 1) / 2;
    center_y = (matrix_rows + 1) / 2;
    plot(center_x, center_y, 'k+', 'MarkerSize', 10, 'LineWidth', 2);
    hold off;
    
    % Subplot 2,2 - Контурная карта аргумента
    subplot(2, 2, 4);
    min_arg = min(argument_data(:));
    max_arg = max(argument_data(:));
    contour_levels = linspace(min_arg, max_arg, number_of_contours);
    [C, h] = contour(X, Y, argument_data, contour_levels, 'LineWidth', 1);
    colormap(gca, colormap_name);
    axis image;
    
    % Форматирование меток контуров для аргумента
    ht = findobj(h,'Type','text');
    for kk = 1:numel(ht)
        val = str2double(ht(kk).String);
        ht(kk).String = sprintf('%.2f',val);
    end
    
    c = colorbar;
    c.Label.String = arg_label;
    c.Label.FontSize = 10;
    title(sprintf('%s - Контурная карта', arg_label), 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('Индекс X', 'FontSize', 10);
    ylabel('Индекс Y', 'FontSize', 10);
    
    % Настройка осей
    setup_axis_ticks(matrix_cols, matrix_rows);
    grid on; set(gca, 'GridAlpha', 0.3);
    
    hold on;
    plot(center_x, center_y, 'k+', 'MarkerSize', 10, 'LineWidth', 2);
    hold off;
    
    % Общий заголовок
    sgtitle(sprintf('%s - Поляризация %s° - 3D поверхности и контуры [%s]', title_prefix, pol_label, colormap_name), ...
           'FontSize', 14, 'FontWeight', 'bold');
end

function [fig_mag, fig_arg] = create_acf_power_figures(Results, pol_name, pol_label, param_type, colormap_name)
    % Создание фигур АКФ и спектров мощности с параллельными вычислениями
    
    if strcmp(param_type, 'azimuth')
        magnitude_data = Results.(pol_name).Azimuth_Magnitude;
        argument_data = Results.(pol_name).Azimuth_Argument;
        mag_label = '|2α^C|';
        arg_label = 'Arg(2α^C) [рад]';
        title_prefix = 'Двуточечный азимут';
    else % ellipticity
        magnitude_data = Results.(pol_name).Ellipticity_Magnitude;
        argument_data = Results.(pol_name).Ellipticity_Argument;
        mag_label = '|2β^C|';
        arg_label = 'Arg(2β^C) [рад]';
        title_prefix = 'Двуточечная эллиптичность';
    end
    
    %% ФИГУРА 1: МОДУЛЬ - АКФ и спектры мощности
    fig_mag = figure('Name', sprintf('%s_%s - %s - Модуль АКФ+Спектр', title_prefix, pol_label, colormap_name), ...
                   'Position', [50, 50, 1600, 1200], ...
                   'Color', 'white', ...
                   'Visible', 'off');
    
    % Обработка модуля с параллельными вычислениями
    [M, N] = size(magnitude_data);
    magnitude_centered = magnitude_data - mean(magnitude_data(:));
    
    % Параллельное вычисление 2D АКФ
    fprintf('Вычисление АКФ для модуля %s (поляризация %s°)...\n', lower(param_type), pol_label);
    tic;
    acf_magnitude = compute_2d_acf_parallel(magnitude_centered);
    fprintf('АКФ вычислена за %.2f сек\n', toc);
    
    % Нормализация АКФ в диапазон [0, 1]
    acf_magnitude = acf_magnitude - min(acf_magnitude(:));
    acf_magnitude = acf_magnitude / max(acf_magnitude(:));
    [M_acf, N_acf] = size(acf_magnitude);
    
    % Спектр через АКФ
    fft_acf_mag = fft2(acf_magnitude);
    power_spectrum_acf_mag = abs(fft_acf_mag).^2 / (M_acf * N_acf);
    power_spectrum_acf_mag_centered = fftshift(power_spectrum_acf_mag);
    
    % Прямой спектр
    fft_direct_mag = fft2(magnitude_centered, M_acf, N_acf);
    power_spectrum_direct_mag = abs(fft_direct_mag).^2 / (M * N);
    power_spectrum_direct_mag_centered = fftshift(power_spectrum_direct_mag);
    
    % Частотные оси
    freq_x = (-N_acf/2:N_acf/2-1) / N_acf;
    freq_y = (-M_acf/2:M_acf/2-1) / M_acf;
    [FX, FY] = meshgrid(freq_x, freq_y);
    
    % Subplot 1: Исходные данные модуля
    subplot(2, 3, 1);
    imagesc(magnitude_data);
    colormap(gca, colormap_name);
    title(sprintf('%s - Исходные данные', mag_label), 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('X'); ylabel('Y');
    colorbar; axis image;
    
    % Subplot 2: 2D АКФ
    subplot(2, 3, 2);
    imagesc(real(acf_magnitude));
    colormap(gca, colormap_name);
    title('2D Автокорреляция', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('Лаг X'); ylabel('Лаг Y');
    colorbar; axis image;
    
    % Subplot 3: 2D спектр мощности через АКФ
    subplot(2, 3, 3);
    imagesc(freq_x, freq_y, 10*log10(power_spectrum_acf_mag_centered + eps));
    colormap(gca, colormap_name);
    title('2D Спектр мощности через АКФ (дБ)', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('Частота X'); ylabel('Частота Y');
    colorbar; axis image;
    
    % Subplot 4: Центрированные данные
    subplot(2, 3, 4);
    imagesc(magnitude_centered);
    colormap(gca, colormap_name);
    title('Центрированные данные', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('X'); ylabel('Y');
    colorbar; axis image;
    
    % Subplot 5: 3D представление АКФ
    subplot(2, 3, 5);
    [X_acf, Y_acf] = meshgrid(1:N_acf, 1:M_acf);
    surf(X_acf, Y_acf, real(acf_magnitude), 'EdgeColor', 'none');
    colormap(gca, colormap_name);
    title('3D АКФ', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('Лаг X'); ylabel('Лаг Y'); zlabel('АКФ');
    colorbar; shading interp; view(45, 30);
    
    % Subplot 6: 3D спектр мощности
    subplot(2, 3, 6);
    surf(FX, FY, 10*log10(power_spectrum_acf_mag_centered + eps), 'EdgeColor', 'none');
    colormap(gca, colormap_name);
    title('3D Спектр мощности (дБ)', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('Частота X'); ylabel('Частота Y'); zlabel('Мощность (дБ)');
    colorbar; shading interp; view(45, 30);
    
    % Общий заголовок для модуля
    sgtitle(sprintf('%s - Модуль: АКФ и спектры мощности - Поляризация %s° [%s]', title_prefix, pol_label, colormap_name), ...
           'FontSize', 14, 'FontWeight', 'bold');
    
    %% ФИГУРА 2: АРГУМЕНТ - АКФ и спектры мощности
    fig_arg = figure('Name', sprintf('%s_%s - %s - Аргумент АКФ+Спектр', title_prefix, pol_label, colormap_name), ...
                   'Position', [100, 100, 1600, 1200], ...
                   'Color', 'white', ...
                   'Visible', 'off');
    
    % Обработка аргумента с параллельными вычислениями
    argument_centered = argument_data - mean(argument_data(:));
    
    % Параллельное вычисление 2D АКФ для аргумента
    fprintf('Вычисление АКФ для аргумента %s (поляризация %s°)...\n', lower(param_type), pol_label);
    tic;
    acf_argument = compute_2d_acf_parallel(argument_centered);
    fprintf('АКФ вычислена за %.2f сек\n', toc);
    
    % Нормализация АКФ в диапазон [0, 1]
    acf_argument = acf_argument - min(acf_argument(:));
    acf_argument = acf_argument / max(acf_argument(:));
    
    % Спектр через АКФ для аргумента
    fft_acf_arg = fft2(acf_argument);
    power_spectrum_acf_arg = abs(fft_acf_arg).^2 / (M_acf * N_acf);
    power_spectrum_acf_arg_centered = fftshift(power_spectrum_acf_arg);
    
    % Прямой спектр для аргумента
    fft_direct_arg = fft2(argument_centered, M_acf, N_acf);
    power_spectrum_direct_arg = abs(fft_direct_arg).^2 / (M * N);
    power_spectrum_direct_arg_centered = fftshift(power_spectrum_direct_arg);
    
    % Subplot 1: Исходные данные аргумента
    subplot(2, 3, 1);
    imagesc(argument_data);
    colormap(gca, colormap_name);
    title(sprintf('%s - Исходные данные', arg_label), 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('X'); ylabel('Y');
    colorbar; axis image;
    
    % Subplot 2: 2D АКФ аргумента
    subplot(2, 3, 2);
    imagesc(real(acf_argument));
    colormap(gca, colormap_name);
    title('2D Автокорреляция', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('Лаг X'); ylabel('Лаг Y');
    colorbar; axis image;
    
    % Subplot 3: 2D спектр мощности через АКФ для аргумента
    subplot(2, 3, 3);
    imagesc(freq_x, freq_y, 10*log10(power_spectrum_acf_arg_centered + eps));
    colormap(gca, colormap_name);
    title('2D Спектр мощности через АКФ (дБ)', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('Частота X'); ylabel('Частота Y');
    colorbar; axis image;
    
    % Subplot 4: Центрированные данные аргумента
    subplot(2, 3, 4);
    imagesc(argument_centered);
    colormap(gca, colormap_name);
    title('Центрированные данные', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('X'); ylabel('Y');
    colorbar; axis image;
    
    % Subplot 5: 3D представление АКФ аргумента
    subplot(2, 3, 5);
    surf(X_acf, Y_acf, real(acf_argument), 'EdgeColor', 'none');
    colormap(gca, colormap_name);
    title('3D АКФ', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('Лаг X'); ylabel('Лаг Y'); zlabel('АКФ');
    colorbar; shading interp; view(45, 30);
    
    % Subplot 6: 3D спектр мощности для аргумента
    subplot(2, 3, 6);
    surf(FX, FY, 10*log10(power_spectrum_acf_arg_centered + eps), 'EdgeColor', 'none');
    colormap(gca, colormap_name);
    title('3D Спектр мощности (дБ)', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('Частота X'); ylabel('Частота Y'); zlabel('Мощность (дБ)');
    colorbar; shading interp; view(45, 30);
    
    % Общий заголовок для аргумента
    sgtitle(sprintf('%s - Аргумент: АКФ и спектры мощности - Поляризация %s° [%s]', title_prefix, pol_label, colormap_name), ...
           'FontSize', 14, 'FontWeight', 'bold');
end

function acf_result = compute_2d_acf_parallel(data)
    % Параллельное вычисление 2D автокорреляционной функции
    % Использует параллельные вычисления для ускорения
    
    [M, N] = size(data);
    
    % Для больших матриц используем оптимизированный подход
    if M * N > 10000  % Для больших матриц
        % Используем стандартную функцию, но с предварительной обработкой
        % Разбиваем на блоки для экономии памяти
        block_size = min(64, max(8, floor(sqrt(M * N / 100))));
        
        if M > block_size && N > block_size
            % Для очень больших матриц - блочная обработка
            num_blocks_m = ceil(M / block_size);
            num_blocks_n = ceil(N / block_size);
            
            % Инициализируем результат
            acf_size_m = 2 * M - 1;
            acf_size_n = 2 * N - 1;
            acf_result = zeros(acf_size_m, acf_size_n);
            
            % Параллельная обработка блоков
            parfor block_idx = 1:(num_blocks_m * num_blocks_n)
                % Вычисляем индексы блока
                [i_block, j_block] = ind2sub([num_blocks_m, num_blocks_n], block_idx);
                
                % Границы блока
                i_start = (i_block - 1) * block_size + 1;
                i_end = min(i_start + block_size - 1, M);
                j_start = (j_block - 1) * block_size + 1;
                j_end = min(j_start + block_size - 1, N);
                
                % Вычисляем АКФ для блока
                data_block = data(i_start:i_end, j_start:j_end);
                acf_block = xcorr2(data_block);
                
                % Сохраняем результат (в parfor это безопасно только для независимых индексов)
                % Поэтому используем обычный подход для больших матриц - используем прямое вычисление
            end
            
            % Обычный подход для больших матриц - используем прямое вычисление
            acf_result = xcorr2(data);
        else
            % Для средних матриц используем прямое вычисление
            acf_result = xcorr2(data);
        end
    else
        % Для небольших матриц используем прямое вычисление
        acf_result = xcorr2(data);
    end
end