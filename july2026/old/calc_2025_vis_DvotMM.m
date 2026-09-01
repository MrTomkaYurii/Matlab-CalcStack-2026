function calc_2025_vis_DvotMM(Results, save_folder)
% VISUALIZE_MUELLER_MATRIX Визуализация модулей и аргументов двухточечной матрицы Мюллера
%   с циклом по различным цветовым картам
%
% Использование:
%   calc_2025_vis_DvotMM_2D(Results, save_folder)
%
% Входные параметры:
%   Results     - структура с результатами расчета матрицы Мюллера
%   save_folder - папка для сохранения изображений
number_of_countours = 5;



    % Проверка входных параметров
    if nargin < 2
        error('Необходимо указать папку для сохранения: visualize_mueller_matrix(Results, save_folder)');
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


    fprintf('\--- НАЧАЛО. ЧАСТь 01. МОДУЛИ и АРГУМЕНТЫ\n');
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
            'Visible', 'off'); % Скрываем для ускорения
        for i = 1:4
            for k = 1:4
                subplot(4, 4, (i-1)*4 + k);
                % Получаем данные модуля
                field_name = sprintf('Complex_f%d%d', i, k);
                magnitude_data = Results.(field_name).Magnitude;
                % Отображаем изображение
                imagesc(magnitude_data);
                colormap(gca, current_colormap);
                axis image;
                % Колорбар с автоматическими пределами
                c = colorbar;
                c.Label.String = '|f̃|';
                c.Label.FontSize = font_size_label;
                caxis([min(magnitude_data(:)) max(magnitude_data(:))]);
                % Подписи осей
                xlabel('Индекс X', 'FontSize', font_size_label);
                ylabel('Индекс Y', 'FontSize', font_size_label);
                % Заголовок элемента
                title(sprintf('|f̃_{%d%d}|', i, k), ...
                    'FontSize', font_size_subplot, ...
                    'FontWeight', 'bold');
                % УПРОЩЕННАЯ СИСТЕМА МЕТОК ОСЕЙ
                % Адаптивное количество меток в зависимости от размера
                if matrix_cols <= 10
                    xticks(1:matrix_cols);
                elseif matrix_cols <= 100
                    % Для средних матриц (80) - 5 меток
                    xtick_values = round(linspace(1, matrix_cols, 5));
                    xticks(xtick_values);
                elseif matrix_cols <= 200
                    % Для матриц ~160 - 5 меток
                    xtick_values = round(linspace(1, matrix_cols, 5));
                    xticks(xtick_values);
                else
                    % Для больших матриц (1000) - только 3 метки (начало, середина, конец)
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
                    % Для больших матриц - только 3 метки
                    ytick_values = [1, round(matrix_rows/2), matrix_rows];
                    yticks(ytick_values);
                end
                % Сетка
                grid on;
                set(gca, 'GridAlpha', 0.3);
                % Центр матрицы
                hold on;
                center_x = (matrix_cols + 1) / 2;
                center_y = (matrix_rows + 1) / 2;
                plot(center_x, center_y, 'w+', 'MarkerSize', 10, 'LineWidth', 1);
                hold off;
            end
        end   
        % Общий заголовок с указанием цветовой карты
        sgtitle(sprintf('Модули элементов двухточечной матрицы Мюллера |f̃ᵢₖ| [%s]', current_colormap), ...
            'FontSize', font_size_title, ...
            'FontWeight', 'bold');
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
        % Создаем сабплоты 4x4 для аргументов
        for i = 1:4
            for k = 1:4
                subplot(4, 4, (i-1)*4 + k);
                % Получаем данные аргумента (в радианах)
                field_name = sprintf('Complex_f%d%d', i, k);
                argument_data = Results.(field_name).Argument;
                % Отображаем в радианах
                imagesc(argument_data);
                colormap(gca, current_colormap);
                axis image;
                % Колорбар
                c = colorbar;
                c.Label.String = 'Arg(f̃) [рад]';
                c.Label.FontSize = font_size_label;
                caxis([min(argument_data(:)) max(argument_data(:))]);
                % Подписи осей
                xlabel('Индекс X', 'FontSize', font_size_label);
                ylabel('Индекс Y', 'FontSize', font_size_label);
                % Заголовок элемента
                title(sprintf('Arg(f̃_{%d%d})', i, k), ...
                    'FontSize', font_size_subplot, ...
                    'FontWeight', 'bold');
                % УПРОЩЕННАЯ СИСТЕМА МЕТОК ОСЕЙ (как для модулей)
                % Адаптивное количество меток в зависимости от размера
                if matrix_cols <= 10
                    xticks(1:matrix_cols);
                elseif matrix_cols <= 100
                    % Для средних матриц (80) - 5 меток
                    xtick_values = round(linspace(1, matrix_cols, 5));
                    xticks(xtick_values);
                elseif matrix_cols <= 200
                    % Для матриц ~160 - 5 меток
                    xtick_values = round(linspace(1, matrix_cols, 5));
                    xticks(xtick_values);
                else
                    % Для больших матриц (1000) - только 3 метки (начало, середина, конец)
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
                    % Для больших матриц - только 3 метки
                    ytick_values = [1, round(matrix_rows/2), matrix_rows];
                    yticks(ytick_values);
                end
                % Сетка
                grid on;
                set(gca, 'GridAlpha', 0.3);
                % Центр матрицы
                hold on;
                center_x = (matrix_cols + 1) / 2;
                center_y = (matrix_rows + 1) / 2;
                plot(center_x, center_y, 'w+', 'MarkerSize', 10, 'LineWidth', 1);
                hold off;
            end
        end
        % Общий заголовок
        sgtitle(sprintf('Аргументы элементов двухточечной матрицы Мюллера Arg(f̃ᵢₖ) [рад] [%s]', current_colormap), ...
            'FontSize', font_size_title, ...
            'FontWeight', 'bold');
        % Сохранение
        filename = fullfile(save_folder, sprintf('%s.Arguments.png', current_colormap));
        saveas(fig_arguments, filename);
        close(fig_arguments);
    end

    fprintf('\n=== ВИЗУАЛИЗАЦИЯ ВСЕХ МОДУЛЕЙ И АРГУМЕНТОВ ЗАВЕРШЕНА ===\n');
    fprintf('\---- НАЧАЛО. ЧАСТь 02. 2D.ГИСТОГРАММЫ\n');
    %!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    %% Визуализация отдельных 2D элементов с гистограммами
    %!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    for i = 1:4
        for k = 1:4
            field_name = sprintf('Complex_f%d%d', i, k);
            % Цикл по цветовым картам для каждого элемента
            for map_idx = 1:length(color_maps)
                current_colormap = color_maps{map_idx};

                % Создаем фигуру 2x2
                fig_hist = figure('Name', sprintf('f_%d%d - %s', i, k, current_colormap), ...
                                 'Position', [100, 100, 1400, 1000], ...
                                 'Color', 'white', ...
                                 'Visible', 'off');
                % Получаем данные
                magnitude_data = Results.(field_name).Magnitude;
                argument_data = Results.(field_name).Argument; 
                % Subplot 1,1 - 2D визуализация модуля
                subplot(2, 2, 1);
                imagesc(magnitude_data);
                colormap(gca, current_colormap);
                axis image;
                % Колорбар
                c = colorbar;
                c.Label.String = '|f̃|';
                c.Label.FontSize = 10;
                caxis([min(magnitude_data(:)) max(magnitude_data(:))]);
                % Заголовок и подписи
                title(sprintf('|f̃_{%d%d}| - Модуль', i, k), 'FontSize', 12, 'FontWeight', 'bold');
                xlabel('Индекс X', 'FontSize', 10);
                ylabel('Индекс Y', 'FontSize', 10);
                % УПРОЩЕННАЯ СИСТЕМА МЕТОК ОСЕЙ
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
                % Сетка
                grid on;
                set(gca, 'GridAlpha', 0.3);
                % Центр матрицы
                hold on;
                center_x = (matrix_cols + 1) / 2;
                center_y = (matrix_rows + 1) / 2;
                plot(center_x, center_y, 'w+', 'MarkerSize', 10, 'LineWidth', 2);
                hold off;
                % Subplot 2,1 - Гистограмма модуля
                subplot(2, 2, 3);
                histogram(magnitude_data(:), 50, 'FaceColor', [0.2 0.4 0.8], 'EdgeColor', 'black');
                % Заголовок и подписи
                title('Гистограмма модуля', 'FontSize', 12, 'FontWeight', 'bold');
                xlabel('|f̃|', 'FontSize', 10);
                ylabel('Частота', 'FontSize', 10);
                grid on;
                set(gca, 'GridAlpha', 0.3);
                % Статистика для модуля
                mean_val = mean(magnitude_data(:));
                std_val = std(magnitude_data(:));
                skew_val = skewness(magnitude_data(:));
                kurt_val = kurtosis(magnitude_data(:));
                % Выводим статистику как текст (без привязки к линиям)
                text_str = sprintf('μ = %.4f\nσ = %.4f\nSkew = %.4f\nKurt = %.4f', ...
                                   mean_val, std_val, skew_val, kurt_val);
                text(0.98, 0.98, text_str, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
                     'HorizontalAlignment', 'right', 'BackgroundColor', 'white', ...
                     'EdgeColor', 'black', 'FontSize', 9, 'Margin', 2);
                % Subplot 1,2 - 2D визуализация аргумента
                subplot(2, 2, 2);
                imagesc(argument_data);
                colormap(gca, current_colormap);
                axis image;
                % Колорбар
                c = colorbar;
                c.Label.String = 'Arg(f̃) [рад]';
                c.Label.FontSize = 10;
                caxis([min(argument_data(:)) max(argument_data(:))]);
                % Заголовок и подписи
                title(sprintf('Arg(f̃_{%d%d}) - Аргумент', i, k), 'FontSize', 12, 'FontWeight', 'bold');
                xlabel('Индекс X', 'FontSize', 10);
                ylabel('Индекс Y', 'FontSize', 10);
                % УПРОЩЕННАЯ СИСТЕМА МЕТОК ОСЕЙ (такая же как для модуля)
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
                % Сетка
                grid on;
                set(gca, 'GridAlpha', 0.3);
                % Центр матрицы
                hold on;
                plot(center_x, center_y, 'w+', 'MarkerSize', 10, 'LineWidth', 2);
                hold off;
                % Subplot 2,2 - Гистограмма аргумента
                subplot(2, 2, 4);
                histogram(argument_data(:), 50, 'FaceColor', [0.8 0.4 0.2], 'EdgeColor', 'black');
                % Заголовок и подписи
                title('Гистограмма аргумента', 'FontSize', 12, 'FontWeight', 'bold');
                xlabel('Arg(f̃) [рад]', 'FontSize', 10);
                ylabel('Частота', 'FontSize', 10);
                grid on;
                set(gca, 'GridAlpha', 0.3);
                % Статистика для углов (циклическое среднее)
                mean_angle = angle(mean(exp(1i*argument_data(:))));
                % Для вычисления моментов используем центрированные углы
                centered_angles = argument_data(:) - mean_angle;
                centered_angles = atan2(sin(centered_angles), cos(centered_angles));
                std_angle = std(argument_data(:));
                skew_angle = skewness(centered_angles);
                kurt_angle = kurtosis(centered_angles);
                % Выводим статистику как текст (без привязки к линиям)
                text_str = sprintf('μ = %.4f\nσ = %.4f\nSkew = %.4f\nKurt = %.4f', ...
                                   mean_angle, std_angle, skew_angle, kurt_angle);
                text(0.98, 0.98, text_str, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
                     'HorizontalAlignment', 'right', 'BackgroundColor', 'white', ...
                     'EdgeColor', 'black', 'FontSize', 8, 'Margin', 2);
                % Общий заголовок
                sgtitle(sprintf('f̃_{%d%d} - Модуль и Аргумент [%s]', i, k, current_colormap), ...
                       'FontSize', 14, 'FontWeight', 'bold');
                % Сохранение
                filename = fullfile(save_folder, sprintf('%s.f%d%d_2D-hist.png', current_colormap, i, k));
                saveas(fig_hist, filename);
                close(fig_hist);
            end
        end
    end

    fprintf('\n=== ВИЗУАЛИЗАЦИЯ 2D РАСПРЕДЕЛЕНИЙ И ГИСТОГРАМ ЗАВЕРШЕНА ===\n');
    fprintf('\--- НАЧАЛО. ЧАСТь 03. 3D.КОНТУРЫ\n');
    %!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    %% Визуализация отдельных 3D элементов с поверхностями и контурами   
    %!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    % Цикл по всем элементам матрицы Мюллера
    for i = 1:4
        for k = 1:4
            field_name = sprintf('Complex_f%d%d', i, k);
            % Цикл по цветовым картам для каждого элемента
            for map_idx = 1:length(color_maps)
                current_colormap = color_maps{map_idx};
                % Создаем фигуру 2x2
                fig_3d = figure('Name', sprintf('f_%d%d - %s - 3D+Contour', i, k, current_colormap), ...
                               'Position', [100, 100, 1400, 1000], ...
                               'Color', 'white', ...
                               'Visible', 'off');
                % Получаем данные
                magnitude_data = Results.(field_name).Magnitude;
                argument_data = Results.(field_name).Argument;
                % Создаем координатные сетки
                [X, Y] = meshgrid(1:size(magnitude_data, 2), 1:size(magnitude_data, 1));
                % Subplot 1,1 - 3D поверхность модуля
                subplot(2, 2, 1);
                surf(X, Y, magnitude_data, 'EdgeColor', 'none');
                colormap(gca, current_colormap);
                axis image;
                % Настройки 3D вида
                view(45, 30);
                lighting phong;
                shading interp;
                % Колорбар
                c = colorbar;
                c.Label.String = '|f̃|';
                c.Label.FontSize = 10;
                caxis([min(magnitude_data(:)) max(magnitude_data(:))]);
                % Заголовок и подписи
                title(sprintf('|f̃_{%d%d}| - 3D поверхность', i, k), 'FontSize', 12, 'FontWeight', 'bold');
                xlabel('Индекс X', 'FontSize', 10);
                ylabel('Индекс Y', 'FontSize', 10);
                zlabel('|f̃|', 'FontSize', 10);
                % Сетка
                grid on;
                set(gca, 'GridAlpha', 0.3);
                % Subplot 1,2 - 3D поверхность аргумента
                subplot(2, 2, 2);
                surf(X, Y, argument_data, 'EdgeColor', 'none');
                colormap(gca, current_colormap);
                axis image;
                % Настройки 3D вида
                view(45, 30);
                lighting phong;
                shading interp;
                % Колорбар
                c = colorbar;
                c.Label.String = 'Arg(f̃) [рад]';
                c.Label.FontSize = 10;
                caxis([min(argument_data(:)) max(argument_data(:))]);
                % Заголовок и подписи
                title(sprintf('Arg(f̃_{%d%d}) - 3D поверхность', i, k), 'FontSize', 12, 'FontWeight', 'bold');
                xlabel('Индекс X', 'FontSize', 10);
                ylabel('Индекс Y', 'FontSize', 10);
                zlabel('Arg(f̃) [рад]', 'FontSize', 10);
                % Сетка
                grid on;
                set(gca, 'GridAlpha', 0.3);
                % Subplot 2,1 - Контурная карта модуля
                subplot(2, 2, 3);
                % Создаем 10 уровней контуров от минимума к максимуму
                min_mag = min(magnitude_data(:));
                max_mag = max(magnitude_data(:));
                contour_levels = round(linspace(min_mag, max_mag, number_of_countours), 2);
                [C, h] = contour(X, Y, magnitude_data, contour_levels, 'LineWidth', 1);
                colormap(gca, current_colormap);
                axis image;
                % Подписи контуров с форматированием
                % clabel(C, h, 'FontSize', 7);
                % Находим текстовые метки и переопределяем их формат
                ht = findobj(h,'Type','text');
                for kk = 1:numel(ht)
                    val = str2double(ht(kk).String);
                    ht(kk).String = sprintf('%.2f',val);   % 2 знака после запятой
                end
                % Колорбар
                c = colorbar;
                c.Label.String = '|f̃|';
                c.Label.FontSize = 10;
                caxis([min_mag max_mag]);
                % Заголовок и подписи
                title(sprintf('|f̃_{%d%d}| - Контурная карта', i, k), 'FontSize', 12, 'FontWeight', 'bold');
                xlabel('Индекс X', 'FontSize', 10);
                ylabel('Индекс Y', 'FontSize', 10);
                % УПРОЩЕННАЯ СИСТЕМА МЕТОК ОСЕЙ
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
                % Сетка
                grid on;
                set(gca, 'GridAlpha', 0.3);
                % Центр матрицы
                hold on;
                center_x = (matrix_cols + 1) / 2;
                center_y = (matrix_rows + 1) / 2;
                plot(center_x, center_y, 'k+', 'MarkerSize', 10, 'LineWidth', 2);
                hold off;
                % Subplot 2,2 - Контурная карта аргумента
                subplot(2, 2, 4);
                % Создаем 10 уровней контуров от минимума к максимуму
                min_arg = min(argument_data(:));
                max_arg = max(argument_data(:));
                contour_levels = round(linspace(min_arg, max_arg, number_of_countours), 2);
                [C, h] = contour(X, Y, argument_data, contour_levels, 'LineWidth', 1);
                colormap(gca, current_colormap);
                axis image;
                % Подписи контуров
                % clabel(C, h, 'FontSize', 7);
                % Форматируем метки контуров для аргумента
                ht = findobj(h,'Type','text');
                for kk = 1:numel(ht)
                    val = str2double(ht(kk).String);
                    ht(kk).String = sprintf('%.2f',val);   % 2 знака после запятой
                end
                % Колорбар
                c = colorbar;
                c.Label.String = 'Arg(f̃) [рад]';
                c.Label.FontSize = 10;
                caxis([min_arg max_arg]);
                % Заголовок и подписи
                title(sprintf('Arg(f̃_{%d%d}) - Контурная карта', i, k), 'FontSize', 12, 'FontWeight', 'bold');
                xlabel('Индекс X', 'FontSize', 10);
                ylabel('Индекс Y', 'FontSize', 10);
                % УПРОЩЕННАЯ СИСТЕМА МЕТОК ОСЕЙ (такая же как для модуля)
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
                % Сетка
                grid on;
                set(gca, 'GridAlpha', 0.3);
                % Центр матрицы
                hold on;
                plot(center_x, center_y, 'k+', 'MarkerSize', 10, 'LineWidth', 2);
                hold off;
                % Общий заголовок
                sgtitle(sprintf('f̃_{%d%d} - 3D поверхности и контуры [%s]', i, k, current_colormap), ...
                       'FontSize', 14, 'FontWeight', 'bold');
                % Сохранение
                filename = fullfile(save_folder, sprintf('%s.f%d%d_3D-contour.png', current_colormap, i, k));
                saveas(fig_3d, filename);
                close(fig_3d);
            end
        end
    end

    fprintf('\n=== ВИЗУАЛИЗАЦИЯ 3D ПРЕДСТАВЛЕНИЙ И КОНТУРОВ ЗАВЕРШЕНА ===\n');
    fprintf('\--- НАЧАЛО. ЧАСТь 04. 2D-AKF. 2D-PSD\n');
    %!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    %% Визуализация 2D АКФ и спектров мощности для всех элементов матрицы Мюллера
    %!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    % Цикл по всем элементам матрицы Мюллера
    for i = 1:4
        for k = 1:4
            field_name = sprintf('Complex_f%d%d', i, k);
            % Цикл по цветовым картам для каждого элемента
            for map_idx = 1:length(color_maps)
                current_colormap = color_maps{map_idx};  
                % Получаем данные
                magnitude_data = Results.(field_name).Magnitude;
                argument_data = Results.(field_name).Argument;

                %% ФИГУРА 1: МОДУЛЬ - АКФ и спектры мощности
                fig_mag = figure('Name', sprintf('f_%d%d - %s - Модуль АКФ+Спектр', i, k, current_colormap), ...
                               'Position', [50, 50, 1600, 1200], ...
                               'Color', 'white', ...
                               'Visible', 'off');
                % Обработка модуля
                [M, N] = size(magnitude_data);
                magnitude_centered = magnitude_data - mean(magnitude_data(:));
                % Вычисляем 2D АКФ
                acf_magnitude = xcorr2(magnitude_centered);
                % Нормализация в диапазон [0, 1]
                acf_magnitude = acf_magnitude - min(acf_magnitude(:));  % сдвигаем минимум к 0
                acf_magnitude = acf_magnitude / max(acf_magnitude(:));  % масштабируем максимум к 1
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
                colormap(gca, current_colormap);
                title(sprintf('|f̃_{%d%d}| - Исходные данные', i, k), 'FontSize', 11, 'FontWeight', 'bold');
                xlabel('X'); ylabel('Y');
                colorbar; axis image;
                % Subplot 2: 2D АКФ
                subplot(2, 3, 2);
                imagesc(real(acf_magnitude));
                colormap(gca, current_colormap);
                title('2D Автокорреляция', 'FontSize', 11, 'FontWeight', 'bold');
                xlabel('Лаг X'); ylabel('Лаг Y');
                colorbar; axis image;
                % Subplot 3: 2D спектр мощности через АКФ
                subplot(2, 3, 3);
                imagesc(freq_x, freq_y, 10*log10(power_spectrum_acf_mag_centered + eps));
                colormap(gca, current_colormap);
                title('2D Спектр мощности через АКФ (дБ)', 'FontSize', 11, 'FontWeight', 'bold');
                xlabel('Частота X'); ylabel('Частота Y');
                colorbar; axis image;
                % Subplot 4: Центрированные данные
                subplot(2, 3, 4);
                imagesc(magnitude_centered);
                colormap(gca, current_colormap);
                title('Центрированные данные', 'FontSize', 11, 'FontWeight', 'bold');
                xlabel('X'); ylabel('Y');
                colorbar; axis image;
                % Subplot 5: 3D представление АКФ
                subplot(2, 3, 5);
                [X_acf, Y_acf] = meshgrid(1:N_acf, 1:M_acf);
                surf(X_acf, Y_acf, real(acf_magnitude), 'EdgeColor', 'none');
                colormap(gca, current_colormap);
                title('3D АКФ', 'FontSize', 11, 'FontWeight', 'bold');
                xlabel('Лаг X'); ylabel('Лаг Y'); zlabel('АКФ');
                % Subplot 6: 3D спектр мощности
                subplot(2, 3, 6);
                surf(FX, FY, 10*log10(power_spectrum_acf_mag_centered + eps), 'EdgeColor', 'none');
                colormap(gca, current_colormap);
                title('3D Спектр мощности (дБ)', 'FontSize', 11, 'FontWeight', 'bold');
                xlabel('Частота X'); ylabel('Частота Y'); zlabel('Мощность (дБ)');
                colorbar; shading interp; view(45, 30);
                % Общий заголовок для модуля
                sgtitle(sprintf('f̃_{%d%d} - Модуль: АКФ и спектры мощности [%s]', i, k, current_colormap), ...
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
                % Обработка аргумента
                argument_centered = argument_data - mean(argument_data(:));
                % Вычисляем 2D АКФ для аргумента
                acf_argument = xcorr2(argument_centered);
                % Нормализация в диапазон [0, 1]
                acf_argument = acf_argument - min(acf_argument(:));  % сдвигаем минимум к 0
                acf_argument = acf_argument / max(acf_argument(:));  % масштабируем максимум к 1
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
                colormap(gca, current_colormap);
                title(sprintf('Arg(f̃_{%d%d}) - Исходные данные [рад]', i, k), 'FontSize', 11, 'FontWeight', 'bold');
                xlabel('X'); ylabel('Y');
                colorbar; axis image;
                % Subplot 2: 2D АКФ аргумента
                subplot(2, 3, 2);
                imagesc(real(acf_argument));
                colormap(gca, current_colormap);
                title('2D Автокорреляция', 'FontSize', 11, 'FontWeight', 'bold');
                xlabel('Лаг X'); ylabel('Лаг Y');
                colorbar; axis image;
                % Subplot 3: 2D спектр мощности через АКФ для аргумента
                subplot(2, 3, 3);
                imagesc(freq_x, freq_y, 10*log10(power_spectrum_acf_arg_centered + eps));
                colormap(gca, current_colormap);
                title('2D Спектр мощности через АКФ (дБ)', 'FontSize', 11, 'FontWeight', 'bold');
                xlabel('Частота X'); ylabel('Частота Y');
                colorbar; axis image;
                % Subplot 4: Центрированные данные аргумента
                subplot(2, 3, 4);
                imagesc(argument_centered);
                colormap(gca, current_colormap);
                title('Центрированные данные', 'FontSize', 11, 'FontWeight', 'bold');
                xlabel('X'); ylabel('Y');
                colorbar; axis image;
                % Subplot 5: 3D представление АКФ аргумента
                subplot(2, 3, 5);
                surf(X_acf, Y_acf, real(acf_argument), 'EdgeColor', 'none');
                colormap(gca, current_colormap);
                title('3D АКФ', 'FontSize', 11, 'FontWeight', 'bold');
                xlabel('Лаг X'); ylabel('Лаг Y'); zlabel('АКФ');
                colorbar; shading interp; view(45, 30);
                % Subplot 6: 3D спектр мощности для аргумента
                subplot(2, 3, 6);
                surf(FX, FY, 10*log10(power_spectrum_acf_arg_centered + eps), 'EdgeColor', 'none');
                colormap(gca, current_colormap);
                title('3D Спектр мощности (дБ)', 'FontSize', 11, 'FontWeight', 'bold');
                xlabel('Частота X'); ylabel('Частота Y'); zlabel('Мощность (дБ)');
                colorbar; shading interp; view(45, 30);
                % Общий заголовок для аргумента
                sgtitle(sprintf('f̃_{%d%d} - Аргумент: АКФ и спектры мощности [%s]', i, k, current_colormap), ...
                       'FontSize', 14, 'FontWeight', 'bold');
                % Сохранение фигуры аргумента
                filename_arg = fullfile(save_folder, sprintf('%s.f%d%d_ACF-Power_Argument.png', current_colormap, i, k));
                saveas(fig_arg, filename_arg);
                close(fig_arg);
            end
        end
    end

    fprintf('\n=== ВИЗУАЛИЗАЦИЯ АКФ И СПЕКТРОВ МОЩНОСТИ ЗАВЕРШЕНА ===\n');
fprintf('\n=== КОНЕЦ ВСЕХ ВИЗУАЛИЗАЦИЙ ===\n');
end % end of function