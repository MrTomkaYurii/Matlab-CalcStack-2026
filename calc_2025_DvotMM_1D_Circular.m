function [M, pathM] = calc_2025_DvotMM_Circular(savePath, readPath, pathForCode, max_radius, angular_step_deg)
global Results;

                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %% Расчет двуточечных параметров МАТРИЦЫ МЮЛЛЕРА по окружностям БЕЗ интерполяции
                    % Параметры расчета
                    readTomka = readPath;
                    angular_step = deg2rad(angular_step_deg); % Переводим угловой шаг в радианы
                    
                    % Параметры круглой области
                    center_x = max_radius + 1; % Центр по X (с запасом для обрезки)
                    center_y = max_radius + 1; % Центр по Y (с запасом для обрезки)
                    crop_size = 2 * max_radius + 1; % Размер квадрата для вырезки круга
                    
                    partFolder = fullfile(savePath, sprintf('circular_radius_%d_no_interpolation', max_radius));
                    if ~exist(partFolder, 'dir')
                        mkdir(partFolder);
                    end
                    stepFolder = fullfile(partFolder, sprintf('angular_step = %.1f градусів', angular_step_deg));
                    if ~exist(stepFolder, 'dir')
                        mkdir(stepFolder);
                    end
                    cd(stepFolder);
                    
                    fprintf('=== ПАРАМЕТРЫ РАСЧЕТА ПО ОКРУЖНОСТЯМ БЕЗ ИНТЕРПОЛЯЦИИ ===\n');
                    fprintf('Максимальный радиус: %d пикселей\n', max_radius);
                    fprintf('Угловой шаг: %.1f градусов (%.4f радиан)\n', angular_step_deg, angular_step);
                    fprintf('Центр области: (%d, %d)\n', center_x, center_y);
                    fprintf('Размер обрезки: %dx%d пикселей\n', crop_size, crop_size);
                    
                    % Рассчитываем количество углов для полного оборота
                    num_angles = round(2 * pi / angular_step);
                    actual_angular_step = 2 * pi / num_angles; % Корректируем шаг для точного деления окружности
                    
                    fprintf('Количество углов на окружности: %d\n', num_angles);
                    fprintf('Скорректированный угловой шаг: %.4f радиан (%.2f градусов)\n', ...
                        actual_angular_step, rad2deg(actual_angular_step));
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Имена файлов по группам (поляризации: 0°, 45°, 90°, правая циркулярная)
                    names_groups = {
                        {'0-0','0-45','0-90','0-135','0-liv','0-prav'};       % Входная поляризация 0°
                        {'45-0','45-45','45-90','45-135','45-liv','45-prav'}; % Входная поляризация 45°
                        {'90-0','90-45','90-90','90-135','90-liv','90-prav'}; % Входная поляризация 90°
                        {'prav-0','prav-45','prav-90','prav-135','prav-liv','prav-prav'} % Правая циркулярная
                    };
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Загрузка всех изображений с обрезкой круглой области
                    fprintf('Загрузка и обрезка изображений...\n');
                    Images = struct();
                    all_names = [names_groups{:}]; % Объединяем все имена
                    
                    for k = 1:numel(all_names)
                        img = imread([readTomka, '\', all_names{k}, '.bmp']);
                        if size(img,3) == 3
                            img = rgb2gray(img);
                        end
                        img = double(img) / 255; % Нормализация [0,1]
                        
                        % Определяем область для вырезки (центр исходного изображения)
                        [img_height, img_width] = size(img);
                        img_center_x = round(img_width / 2);
                        img_center_y = round(img_height / 2);
                        
                        % Координаты для вырезки квадрата
                        x1 = img_center_x - max_radius;
                        x2 = img_center_x + max_radius;
                        y1 = img_center_y - max_radius;
                        y2 = img_center_y + max_radius;
                        
                        % Проверяем границы
                        if x1 < 1 || x2 > img_width || y1 < 1 || y2 > img_height
                            error('Изображение слишком маленькое для заданного радиуса %d', max_radius);
                        end
                        
                        % Обрезка квадратной области
                        img_crop = img(y1:y2, x1:x2);
                        
                        % Создание круглой маски
                        [X, Y] = meshgrid(1:crop_size, 1:crop_size);
                        distances = sqrt((X - center_x).^2 + (Y - center_y).^2);
                        circular_mask = distances <= max_radius;
                        
                        % Применение маски (точки вне круга = NaN)
                        img_crop(~circular_mask) = NaN;
                        
                        % Создаем корректное имя поля
                        fieldName = strrep(all_names{k}, '-', '_');
                        fieldName = ['img_', fieldName];
                        Images.(fieldName) = img_crop;
                    end
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Инициализация структуры результатов
                    fprintf('Инициализация структуры результатов...\n');
                    polarizer_names = {'Polarizer_0', 'Polarizer_45', 'Polarizer_90', 'Polarizer_RC'};
                    
                    % Результирующие матрицы такого же размера как crop_size x crop_size
                    result_height = crop_size;
                    result_width = crop_size;
                    
                    % Предварительное выделение памяти для всех результатов
                    for group = 1:4
                        group_name = polarizer_names{group};
                        
                        % Основные параметры Ex, Ey, delta
                        Results.(group_name).Ex1 = NaN(result_height, result_width);
                        Results.(group_name).Ex2 = NaN(result_height, result_width);
                        Results.(group_name).Ey1 = NaN(result_height, result_width);
                        Results.(group_name).Ey2 = NaN(result_height, result_width);
                        Results.(group_name).delta1 = NaN(result_height, result_width);
                        Results.(group_name).delta2 = NaN(result_height, result_width);
                        
                        % Параметры a1-a4, b1-b4
                        for param_idx = 1:4
                            Results.(group_name).(sprintf('a%d', param_idx)) = NaN(result_height, result_width);
                            Results.(group_name).(sprintf('b%d', param_idx)) = NaN(result_height, result_width);
                        end
                    end
                    
                    % Комплексные параметры f1k-f4k
                    for f_idx = 1:4
                        for k = 1:4
                            field_name = sprintf('Complex_f%d%d', f_idx, k);
                            Results.(field_name).A = NaN(result_height, result_width);
                            Results.(field_name).B = NaN(result_height, result_width);
                            Results.(field_name).Magnitude = NaN(result_height, result_width);
                            Results.(field_name).Argument = NaN(result_height, result_width);
                        end
                    end
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Основной расчет ПО КОЛЬЦАМ БЕЗ ИНТЕРПОЛЯЦИИ
                    fprintf('Начало расчета двуточечных параметров по кольцам БЕЗ интерполяции...\n');
                    tic;
                    
                    total_pairs = 0;
                    
                    % Обработка каждой группы поляризаций
                    for group = 1:4
                        group_name = polarizer_names{group};
                        current_names = names_groups{group};
                        
                        fprintf('Обработка группы %d: %s\n', group, group_name);
                        
                        % Получаем все необходимые изображения для данной группы
                        name_0 = strrep(current_names{1}, '-', '_');     % анализатор 0°
                        name_45 = strrep(current_names{2}, '-', '_');    % анализатор 45°
                        name_90 = strrep(current_names{3}, '-', '_');    % анализатор 90°
                        name_135 = strrep(current_names{4}, '-', '_');   % анализатор 135°
                        name_liv = strrep(current_names{5}, '-', '_');   % левый циркулярный
                        name_prav = strrep(current_names{6}, '-', '_');  % правый циркулярный
                        
                        img_0 = Images.(['img_', name_0]);
                        img_45 = Images.(['img_', name_45]);
                        img_90 = Images.(['img_', name_90]);
                        img_135 = Images.(['img_', name_135]);
                        img_liv = Images.(['img_', name_liv]);
                        img_prav = Images.(['img_', name_prav]);
                        
                        % ===== ОБРАБОТКА ПО КОЛЬЦАМ БЕЗ ИНТЕРПОЛЯЦИИ =====
                        for radius = 1:max_radius
                            
                            % ШАГ 1: НАЙТИ ВСЕ ТОЧКИ КОЛЬЦА
                            ring_points = [];
                            ring_angles = [];
                            
                            % Сканируем всю область и ищем точки кольца
                            for y = 1:crop_size
                                for x = 1:crop_size
                                    dist = sqrt((x - center_x)^2 + (y - center_y)^2);
                                    
                                    % Если точка на кольце (±0.6 пикселя)
                                    if abs(dist - radius) <= 0.6
                                        angle = atan2(y - center_y, x - center_x);
                                        if angle < 0, angle = angle + 2*pi; end  % Приводим к [0, 2π]
                                        
                                        ring_points = [ring_points; x, y];
                                        ring_angles = [ring_angles; angle];
                                    end
                                end
                            end
                            
                            % Сортируем по углам
                            if ~isempty(ring_angles)
                                [ring_angles, idx] = sort(ring_angles);
                                ring_points = ring_points(idx, :);
                            end
                            
                            num_ring_points = size(ring_points, 1);
                            
                            if num_ring_points < 2
                                fprintf('    Пропускаю кольцо - мало точек (%d)\n', num_ring_points);
                                continue;
                            end
                            
                            % ШАГ 2: ВЫЧИСЛИТЬ КОРРЕЛЯЦИИ ДЛЯ ПАР С ЗАДАННЫМ ШАГОМ
                            % И СРАЗУ ЗАПИСАТЬ В РЕЗУЛЬТАТЫ (БЕЗ ИНТЕРПОЛЯЦИИ)
                            step_rad = actual_angular_step;
                            local_num_steps = num_angles;
                            
                            % Для малых радиусов уменьшаем количество шагов
                            if radius <= 5
                                local_num_steps = max(8, round(2 * pi * radius / 2));
                                step_rad = 2 * pi / local_num_steps;
                            end
                            
                            for i = 1:local_num_steps
                                angle1 = (i-1) * step_rad;
                                angle2 = angle1 + step_rad;
                                
                                % Находим ближайшие точки
                                [~, idx1] = min(abs(ring_angles - angle1));
                                [~, idx2] = min(abs(ring_angles - angle2));
                                
                                if idx1 ~= idx2
                                    x1 = ring_points(idx1, 1); y1 = ring_points(idx1, 2);
                                    x2 = ring_points(idx2, 1); y2 = ring_points(idx2, 2);
                                    
                                    % Проверяем, что точки не NaN
                                    if ~isnan(img_0(y1, x1)) && ~isnan(img_0(y2, x2))
                                        % Расчет Ex параметров
                                        u0_1 = img_0(y1, x1);
                                        u0_2 = img_0(y2, x2);
                                        Ex1 = sqrt(u0_1);
                                        Ex2 = sqrt(u0_2);
                                        
                                        % Расчет Ey параметров
                                        u90_1 = img_90(y1, x1);
                                        u90_2 = img_90(y2, x2);
                                        Ey1 = sqrt(u90_1);
                                        Ey2 = sqrt(u90_2);
                                        
                                        % Расчет delta параметров
                                        % delta1 для первой точки
                                        I45_1 = img_45(y1, x1);
                                        I135_1 = img_135(y1, x1);
                                        Iprav_1 = img_prav(y1, x1);
                                        Iliv_1 = img_liv(y1, x1);
                                        
                                        S2_1 = I45_1 - I135_1;
                                        S3_1 = Iprav_1 - Iliv_1;
                                        delta1 = atan2(S3_1, S2_1);
                                        
                                        % delta2 для второй точки
                                        I45_2 = img_45(y2, x2);
                                        I135_2 = img_135(y2, x2);
                                        Iprav_2 = img_prav(y2, x2);
                                        Iliv_2 = img_liv(y2, x2);
                                        
                                        S2_2 = I45_2 - I135_2;
                                        S3_2 = Iprav_2 - Iliv_2;
                                        delta2 = atan2(S3_2, S2_2);
                                        
                                        % Расчет параметров a1-a4, b1-b4 по формулам (6)-(13)
                                        a1 = Ex1 * Ex2 + Ey1 * Ey2 * cos(delta2 - delta1);
                                        b1 = Ey1 * Ey2 * sin(delta2 - delta1);
                                        a2 = Ex1 * Ex2 - Ey1 * Ey2 * cos(delta2 - delta1);
                                        b2 = -Ey1 * Ey2 * sin(delta2 - delta1);
                                        a3 = Ex1 * Ey2 * cos(delta2) + Ex2 * Ey1 * cos(delta1);
                                        b3 = Ex1 * Ey2 * sin(delta2) - Ex2 * Ey1 * sin(delta1);
                                        a4 = Ex1 * Ey2 * sin(delta2) + Ex2 * Ey1 * sin(delta1);
                                        b4 = Ex1 * Ey2 * cos(delta2) - Ex2 * Ey1 * cos(delta1);
                                        
                                        % СРАЗУ ЗАПИСЫВАЕМ В РЕЗУЛЬТАТЫ (для обеих точек)
                                        % Точка 1
                                        Results.(group_name).Ex1(y1, x1) = Ex1;
                                        Results.(group_name).Ex2(y1, x1) = Ex2;
                                        Results.(group_name).Ey1(y1, x1) = Ey1;
                                        Results.(group_name).Ey2(y1, x1) = Ey2;
                                        Results.(group_name).delta1(y1, x1) = delta1;
                                        Results.(group_name).delta2(y1, x1) = delta2;
                                        Results.(group_name).a1(y1, x1) = a1;
                                        Results.(group_name).b1(y1, x1) = b1;
                                        Results.(group_name).a2(y1, x1) = a2;
                                        Results.(group_name).b2(y1, x1) = b2;
                                        Results.(group_name).a3(y1, x1) = a3;
                                        Results.(group_name).b3(y1, x1) = b3;
                                        Results.(group_name).a4(y1, x1) = a4;
                                        Results.(group_name).b4(y1, x1) = b4;
                                        
                                        % Точка 2
                                        Results.(group_name).Ex1(y2, x2) = Ex1;
                                        Results.(group_name).Ex2(y2, x2) = Ex2;
                                        Results.(group_name).Ey1(y2, x2) = Ey1;
                                        Results.(group_name).Ey2(y2, x2) = Ey2;
                                        Results.(group_name).delta1(y2, x2) = delta1;
                                        Results.(group_name).delta2(y2, x2) = delta2;
                                        Results.(group_name).a1(y2, x2) = a1;
                                        Results.(group_name).b1(y2, x2) = b1;
                                        Results.(group_name).a2(y2, x2) = a2;
                                        Results.(group_name).b2(y2, x2) = b2;
                                        Results.(group_name).a3(y2, x2) = a3;
                                        Results.(group_name).b3(y2, x2) = b3;
                                        Results.(group_name).a4(y2, x2) = a4;
                                        Results.(group_name).b4(y2, x2) = b4;
                                        
                                        total_pairs = total_pairs + 1;
                                    end
                                end
                            end
                        end
                    end
                    
                    elapsed_time = toc;
                    fprintf('Обработка завершена за %.2f секунд\n', elapsed_time);
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Расчет комплексных параметров f1k-f4k
                    fprintf('Расчет комплексных параметров f1k-f4k...\n');
                    
                    for f_idx = 1:4
                        % Получаем параметры a и b для всех поляризаций
                        a_0 = Results.Polarizer_0.(sprintf('a%d', f_idx));
                        a_45 = Results.Polarizer_45.(sprintf('a%d', f_idx));
                        a_90 = Results.Polarizer_90.(sprintf('a%d', f_idx));
                        a_RC = Results.Polarizer_RC.(sprintf('a%d', f_idx));
                        b_0 = Results.Polarizer_0.(sprintf('b%d', f_idx));
                        b_45 = Results.Polarizer_45.(sprintf('b%d', f_idx));
                        b_90 = Results.Polarizer_90.(sprintf('b%d', f_idx));
                        b_RC = Results.Polarizer_RC.(sprintf('b%d', f_idx));
                        
                        % Расчет комплексных параметров для каждого k
                        for k = 1:4
                            field_name = sprintf('Complex_f%d%d', f_idx, k);
                            
                            if k == 1
                                % f̃₁ = 0.5((a⁰ + a⁹⁰) + i(b⁰ + b⁹⁰))
                                Results.(field_name).A = 0.5 * (a_0 + a_90);
                                Results.(field_name).B = 0.5 * (b_0 + b_90);
                            elseif k == 2
                                % f̃₂ = 0.5((a⁰ + a⁹⁰) - i(b⁰ + b⁹⁰))
                                Results.(field_name).A = 0.5 * (a_0 + a_90);
                                Results.(field_name).B = -0.5 * (b_0 + b_90);
                            elseif k == 3
                                % f̃₃ = (a⁴⁵ - (a⁰ + a⁹⁰)) + i(b⁴⁵ - (b⁰ + b⁹⁰))
                                Results.(field_name).A = a_45 - (a_0 + a_90);
                                Results.(field_name).B = b_45 - (b_0 + b_90);
                            else % k == 4
                                % f̃₄ = (aᴿᶜ - (a⁰ + a⁹⁰)) + i(bᴿᶜ - (b⁰ + b⁹⁰))
                                Results.(field_name).A = a_RC - (a_0 + a_90);
                                Results.(field_name).B = b_RC - (b_0 + b_90);
                            end
                            
                            % Расчет модулей и аргументов
                            Results.(field_name).Magnitude = sqrt(Results.(field_name).A.^2 + Results.(field_name).B.^2);
                            Results.(field_name).Argument = atan2(Results.(field_name).B, Results.(field_name).A);
                        end
                    end
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Сохранение параметров расчета
                    Results.Parameters.max_radius = max_radius;
                    Results.Parameters.angular_step_deg = angular_step_deg;
                    Results.Parameters.angular_step_rad = actual_angular_step;
                    Results.Parameters.num_angles_per_circle = num_angles;
                    Results.Parameters.center_x = center_x;
                    Results.Parameters.center_y = center_y;
                    Results.Parameters.crop_size = crop_size;
                    Results.Parameters.result_height = result_height;
                    Results.Parameters.result_width = result_width;
                    Results.Parameters.total_pairs = total_pairs;
                    Results.Parameters.calculation_type = 'Circular_correlation_without_interpolation';
                    
                    % ---------------------------------------------------------------------
                    fprintf('\n=== РАСЧЕТ ДВУТОЧЕЧНЫХ ПАРАМЕТРОВ ПО КОЛЬЦАМ БЕЗ ИНТЕРПОЛЯЦИИ ЗАВЕРШЕН ===\n');
                    
                    M = Results;
                    pathM = stepFolder;
                    
                    
                        % -----------------------------------------------------------------
                        % ВИКЛИК ФУНКЦІЇ ДЛЯ ВІЗУАЛІЗАЦІЇ
                        calc_2025_vis_DvotMM_Circular(Results, stepFolder);
                
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    


                    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % %% Расчет двуточечных параметров МАТРИЦЫ МЮЛЛЕРА по окружностям с интерполяцией
                    % % Параметры расчета
                    % readTomka = readPath;
                    % angular_step = deg2rad(angular_step_deg); % Переводим угловой шаг в радианы
                    % 
                    % % Параметры круглой области
                    % center_x = max_radius + 1; % Центр по X (с запасом для обрезки)
                    % center_y = max_radius + 1; % Центр по Y (с запасом для обрезки)
                    % crop_size = 2 * max_radius + 1; % Размер квадрата для вырезки круга
                    % 
                    % partFolder = fullfile(savePath, sprintf('circular_radius_%d_interpolated', max_radius));
                    % if ~exist(partFolder, 'dir')
                    %     mkdir(partFolder);
                    % end
                    % stepFolder = fullfile(partFolder, sprintf('angular_step = %.1f градусів', angular_step_deg));
                    % if ~exist(stepFolder, 'dir')
                    %     mkdir(stepFolder);
                    % end
                    % cd(stepFolder);
                    % 
                    % fprintf('=== ПАРАМЕТРЫ РАСЧЕТА ПО ОКРУЖНОСТЯМ С ИНТЕРПОЛЯЦИЕЙ ===\n');
                    % fprintf('Максимальный радиус: %d пикселей\n', max_radius);
                    % fprintf('Угловой шаг: %.1f градусов (%.4f радиан)\n', angular_step_deg, angular_step);
                    % fprintf('Центр области: (%d, %d)\n', center_x, center_y);
                    % fprintf('Размер обрезки: %dx%d пикселей\n', crop_size, crop_size);
                    % 
                    % % Рассчитываем количество углов для полного оборота
                    % num_angles = round(2 * pi / angular_step);
                    % actual_angular_step = 2 * pi / num_angles; % Корректируем шаг для точного деления окружности
                    % 
                    % fprintf('Количество углов на окружности: %d\n', num_angles);
                    % fprintf('Скорректированный угловой шаг: %.4f радиан (%.2f градусов)\n', ...
                    %     actual_angular_step, rad2deg(actual_angular_step));
                    % 
                    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % % Имена файлов по группам (поляризации: 0°, 45°, 90°, правая циркулярная)
                    % names_groups = {
                    %     {'0-0','0-45','0-90','0-135','0-liv','0-prav'};       % Входная поляризация 0°
                    %     {'45-0','45-45','45-90','45-135','45-liv','45-prav'}; % Входная поляризация 45°
                    %     {'90-0','90-45','90-90','90-135','90-liv','90-prav'}; % Входная поляризация 90°
                    %     {'prav-0','prav-45','prav-90','prav-135','prav-liv','prav-prav'} % Правая циркулярная
                    % };
                    % 
                    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % % Загрузка всех изображений с обрезкой круглой области
                    % fprintf('Загрузка и обрезка изображений...\n');
                    % Images = struct();
                    % all_names = [names_groups{:}]; % Объединяем все имена
                    % 
                    % for k = 1:numel(all_names)
                    %     img = imread([readTomka, '\', all_names{k}, '.bmp']);
                    %     if size(img,3) == 3
                    %         img = rgb2gray(img);
                    %     end
                    %     img = double(img) / 255; % Нормализация [0,1]
                    % 
                    %     % Определяем область для вырезки (центр исходного изображения)
                    %     [img_height, img_width] = size(img);
                    %     img_center_x = round(img_width / 2);
                    %     img_center_y = round(img_height / 2);
                    % 
                    %     % Координаты для вырезки квадрата
                    %     x1 = img_center_x - max_radius;
                    %     x2 = img_center_x + max_radius;
                    %     y1 = img_center_y - max_radius;
                    %     y2 = img_center_y + max_radius;
                    % 
                    %     % Проверяем границы
                    %     if x1 < 1 || x2 > img_width || y1 < 1 || y2 > img_height
                    %         error('Изображение слишком маленькое для заданного радиуса %d', max_radius);
                    %     end
                    % 
                    %     % Обрезка квадратной области
                    %     img_crop = img(y1:y2, x1:x2);
                    % 
                    %     % Создание круглой маски
                    %     [X, Y] = meshgrid(1:crop_size, 1:crop_size);
                    %     distances = sqrt((X - center_x).^2 + (Y - center_y).^2);
                    %     circular_mask = distances <= max_radius;
                    % 
                    %     % Применение маски (точки вне круга = NaN)
                    %     img_crop(~circular_mask) = NaN;
                    % 
                    %     % Создаем корректное имя поля
                    %     fieldName = strrep(all_names{k}, '-', '_');
                    %     fieldName = ['img_', fieldName];
                    %     Images.(fieldName) = img_crop;
                    % end
                    % 
                    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % % Инициализация структуры результатов
                    % fprintf('Инициализация структуры результатов...\n');
                    % polarizer_names = {'Polarizer_0', 'Polarizer_45', 'Polarizer_90', 'Polarizer_RC'};
                    % 
                    % % Результирующие матрицы такого же размера как crop_size x crop_size
                    % result_height = crop_size;
                    % result_width = crop_size;
                    % 
                    % % Предварительное выделение памяти для всех результатов
                    % for group = 1:4
                    %     group_name = polarizer_names{group};
                    % 
                    %     % Основные параметры Ex, Ey, delta
                    %     Results.(group_name).Ex1 = NaN(result_height, result_width);
                    %     Results.(group_name).Ex2 = NaN(result_height, result_width);
                    %     Results.(group_name).Ey1 = NaN(result_height, result_width);
                    %     Results.(group_name).Ey2 = NaN(result_height, result_width);
                    %     Results.(group_name).delta1 = NaN(result_height, result_width);
                    %     Results.(group_name).delta2 = NaN(result_height, result_width);
                    % 
                    %     % Параметры a1-a4, b1-b4
                    %     for param_idx = 1:4
                    %         Results.(group_name).(sprintf('a%d', param_idx)) = NaN(result_height, result_width);
                    %         Results.(group_name).(sprintf('b%d', param_idx)) = NaN(result_height, result_width);
                    %     end
                    % end
                    % 
                    % % Комплексные параметры f1k-f4k
                    % for f_idx = 1:4
                    %     for k = 1:4
                    %         field_name = sprintf('Complex_f%d%d', f_idx, k);
                    %         Results.(field_name).A = NaN(result_height, result_width);
                    %         Results.(field_name).B = NaN(result_height, result_width);
                    %         Results.(field_name).Magnitude = NaN(result_height, result_width);
                    %         Results.(field_name).Argument = NaN(result_height, result_width);
                    %     end
                    % end
                    % 
                    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % % Основной расчет ПО КОЛЬЦАМ С ИНТЕРПОЛЯЦИЕЙ
                    % fprintf('Начало расчета двуточечных параметров по кольцам с интерполяцией...\n');
                    % tic;
                    % 
                    % total_pairs = 0;
                    % 
                    % % Обработка каждой группы поляризаций
                    % for group = 1:4
                    %     group_name = polarizer_names{group};
                    %     current_names = names_groups{group};
                    % 
                    %     fprintf('Обработка группы %d: %s\n', group, group_name);
                    % 
                    %     % Получаем все необходимые изображения для данной группы
                    %     name_0 = strrep(current_names{1}, '-', '_');     % анализатор 0°
                    %     name_45 = strrep(current_names{2}, '-', '_');    % анализатор 45°
                    %     name_90 = strrep(current_names{3}, '-', '_');    % анализатор 90°
                    %     name_135 = strrep(current_names{4}, '-', '_');   % анализатор 135°
                    %     name_liv = strrep(current_names{5}, '-', '_');   % левый циркулярный
                    %     name_prav = strrep(current_names{6}, '-', '_');  % правый циркулярный
                    % 
                    %     img_0 = Images.(['img_', name_0]);
                    %     img_45 = Images.(['img_', name_45]);
                    %     img_90 = Images.(['img_', name_90]);
                    %     img_135 = Images.(['img_', name_135]);
                    %     img_liv = Images.(['img_', name_liv]);
                    %     img_prav = Images.(['img_', name_prav]);
                    % 
                    %     % ===== ОБРАБОТКА ПО КОЛЬЦАМ С ИНТЕРПОЛЯЦИЕЙ =====
                    %     for radius = 1:max_radius
                    %         %fprintf('  Обрабатываю кольцо радиус %d из %d\n', radius, max_radius);
                    % 
                    %         % ШАГ 1: НАЙТИ ВСЕ ТОЧКИ КОЛЬЦА
                    %         ring_points = [];
                    %         ring_angles = [];
                    % 
                    %         % Сканируем всю область и ищем точки кольца
                    %         for y = 1:crop_size
                    %             for x = 1:crop_size
                    %                 dist = sqrt((x - center_x)^2 + (y - center_y)^2);
                    % 
                    %                 % Если точка на кольце (±0.6 пикселя)
                    %                 if abs(dist - radius) <= 0.6
                    %                     angle = atan2(y - center_y, x - center_x);
                    %                     if angle < 0, angle = angle + 2*pi; end  % Приводим к [0, 2π]
                    % 
                    %                     ring_points = [ring_points; x, y];
                    %                     ring_angles = [ring_angles; angle];
                    %                 end
                    %             end
                    %         end
                    % 
                    %         % Сортируем по углам
                    %         if ~isempty(ring_angles)
                    %             [ring_angles, idx] = sort(ring_angles);
                    %             ring_points = ring_points(idx, :);
                    %         end
                    % 
                    %         num_ring_points = size(ring_points, 1);
                    % 
                    %         if num_ring_points < 2
                    %             fprintf('    Пропускаю кольцо - мало точек (%d)\n', num_ring_points);
                    %             continue;
                    %         end
                    % 
                    %         % ШАГ 2: ВЫЧИСЛИТЬ КОРРЕЛЯЦИИ ДЛЯ ПАР С ЗАДАННЫМ ШАГОМ
                    %         step_rad = actual_angular_step;
                    %         local_num_steps = num_angles;
                    % 
                    %         % Для малых радиусов уменьшаем количество шагов
                    %         if radius <= 5
                    %             local_num_steps = max(8, round(2 * pi * radius / 2));
                    %             step_rad = 2 * pi / local_num_steps;
                    %         end
                    % 
                    %         % Массивы для хранения корреляций
                    %         corr_angles = [];
                    %         corr_Ex1 = []; corr_Ex2 = []; corr_Ey1 = []; corr_Ey2 = [];
                    %         corr_delta1 = []; corr_delta2 = [];
                    %         corr_a1 = []; corr_b1 = []; corr_a2 = []; corr_b2 = [];
                    %         corr_a3 = []; corr_b3 = []; corr_a4 = []; corr_b4 = [];
                    % 
                    %         for i = 1:local_num_steps
                    %             angle1 = (i-1) * step_rad;
                    %             angle2 = angle1 + step_rad;
                    % 
                    %             % Находим ближайшие точки
                    %             [~, idx1] = min(abs(ring_angles - angle1));
                    %             [~, idx2] = min(abs(ring_angles - angle2));
                    % 
                    %             if idx1 ~= idx2
                    %                 x1 = ring_points(idx1, 1); y1 = ring_points(idx1, 2);
                    %                 x2 = ring_points(idx2, 1); y2 = ring_points(idx2, 2);
                    % 
                    %                 % Проверяем, что точки не NaN
                    %                 if ~isnan(img_0(y1, x1)) && ~isnan(img_0(y2, x2))
                    %                     % Расчет Ex параметров
                    %                     u0_1 = img_0(y1, x1);
                    %                     u0_2 = img_0(y2, x2);
                    %                     Ex1 = sqrt(u0_1);
                    %                     Ex2 = sqrt(u0_2);
                    % 
                    %                     % Расчет Ey параметров
                    %                     u90_1 = img_90(y1, x1);
                    %                     u90_2 = img_90(y2, x2);
                    %                     Ey1 = sqrt(u90_1);
                    %                     Ey2 = sqrt(u90_2);
                    % 
                    %                     % Расчет delta параметров
                    %                     % delta1 для первой точки
                    %                     I45_1 = img_45(y1, x1);
                    %                     I135_1 = img_135(y1, x1);
                    %                     Iprav_1 = img_prav(y1, x1);
                    %                     Iliv_1 = img_liv(y1, x1);
                    % 
                    %                     S2_1 = I45_1 - I135_1;
                    %                     S3_1 = Iprav_1 - Iliv_1;
                    %                     delta1 = atan2(S3_1, S2_1);
                    % 
                    %                     % delta2 для второй точки
                    %                     I45_2 = img_45(y2, x2);
                    %                     I135_2 = img_135(y2, x2);
                    %                     Iprav_2 = img_prav(y2, x2);
                    %                     Iliv_2 = img_liv(y2, x2);
                    % 
                    %                     S2_2 = I45_2 - I135_2;
                    %                     S3_2 = Iprav_2 - Iliv_2;
                    %                     delta2 = atan2(S3_2, S2_2);
                    % 
                    %                     % Расчет параметров a1-a4, b1-b4 по формулам (6)-(13)
                    %                     a1 = Ex1 * Ex2 + Ey1 * Ey2 * cos(delta2 - delta1);
                    %                     b1 = Ey1 * Ey2 * sin(delta2 - delta1);
                    %                     a2 = Ex1 * Ex2 - Ey1 * Ey2 * cos(delta2 - delta1);
                    %                     b2 = -Ey1 * Ey2 * sin(delta2 - delta1);
                    %                     a3 = Ex1 * Ey2 * cos(delta2) + Ex2 * Ey1 * cos(delta1);
                    %                     b3 = Ex1 * Ey2 * sin(delta2) - Ex2 * Ey1 * sin(delta1);
                    %                     a4 = Ex1 * Ey2 * sin(delta2) + Ex2 * Ey1 * sin(delta1);
                    %                     b4 = Ex1 * Ey2 * cos(delta2) - Ex2 * Ey1 * cos(delta1);
                    % 
                    %                     % Сохраняем корреляции
                    %                     mean_angle = (angle1 + angle2) / 2;
                    %                     corr_angles = [corr_angles; mean_angle];
                    %                     corr_Ex1 = [corr_Ex1; Ex1]; corr_Ex2 = [corr_Ex2; Ex2];
                    %                     corr_Ey1 = [corr_Ey1; Ey1]; corr_Ey2 = [corr_Ey2; Ey2];
                    %                     corr_delta1 = [corr_delta1; delta1]; corr_delta2 = [corr_delta2; delta2];
                    %                     corr_a1 = [corr_a1; a1]; corr_b1 = [corr_b1; b1];
                    %                     corr_a2 = [corr_a2; a2]; corr_b2 = [corr_b2; b2];
                    %                     corr_a3 = [corr_a3; a3]; corr_b3 = [corr_b3; b3];
                    %                     corr_a4 = [corr_a4; a4]; corr_b4 = [corr_b4; b4];
                    % 
                    %                     total_pairs = total_pairs + 1;
                    %                 end
                    %             end
                    %         end
                    % 
                    %         % ШАГ 3: ИНТЕРПОЛЯЦИЯ ПО ВСЕМУ КОЛЬЦУ
                    %           num_correlations = length(corr_angles);
                    %         % fprintf('    Найдено %d точек кольца, %d корреляций\n', num_ring_points, num_correlations);
                    % 
                    %         if num_correlations >= 2
                    %             % Периодическая интерполяция
                    %             extended_angles = [corr_angles - 2*pi; corr_angles; corr_angles + 2*pi];
                    % 
                    %             % Список всех параметров
                    %             param_data = {corr_Ex1, corr_Ex2, corr_Ey1, corr_Ey2, corr_delta1, corr_delta2, ...
                    %                          corr_a1, corr_b1, corr_a2, corr_b2, corr_a3, corr_b3, corr_a4, corr_b4};
                    %             param_names = {'Ex1', 'Ex2', 'Ey1', 'Ey2', 'delta1', 'delta2', ...
                    %                           'a1', 'b1', 'a2', 'b2', 'a3', 'b3', 'a4', 'b4'};
                    % 
                    %             % Интерполируем каждый параметр
                    %             for param_idx = 1:length(param_data)
                    %                 if ~isempty(param_data{param_idx})
                    %                     extended_values = [param_data{param_idx}; param_data{param_idx}; param_data{param_idx}];
                    %                     interpolated = interp1(extended_angles, extended_values, ring_angles, 'linear');
                    % 
                    %                     % Записываем во все точки кольца
                    %                     for point_idx = 1:num_ring_points
                    %                         x = ring_points(point_idx, 1);
                    %                         y = ring_points(point_idx, 2);
                    %                         Results.(group_name).(param_names{param_idx})(y, x) = interpolated(point_idx);
                    %                     end
                    %                 end
                    %             end
                    % 
                    %         elseif num_correlations == 1
                    %             % Одна корреляция - заполняем константой
                    %             param_data = {corr_Ex1, corr_Ex2, corr_Ey1, corr_Ey2, corr_delta1, corr_delta2, ...
                    %                          corr_a1, corr_b1, corr_a2, corr_b2, corr_a3, corr_b3, corr_a4, corr_b4};
                    %             param_names = {'Ex1', 'Ex2', 'Ey1', 'Ey2', 'delta1', 'delta2', ...
                    %                           'a1', 'b1', 'a2', 'b2', 'a3', 'b3', 'a4', 'b4'};
                    % 
                    %             for param_idx = 1:length(param_data)
                    %                 if ~isempty(param_data{param_idx})
                    %                     value = param_data{param_idx}(1);
                    %                     for point_idx = 1:num_ring_points
                    %                         x = ring_points(point_idx, 1);
                    %                         y = ring_points(point_idx, 2);
                    %                         Results.(group_name).(param_names{param_idx})(y, x) = value;
                    %                     end
                    %                 end
                    %             end
                    %         end
                    %     end
                    % end
                    % 
                    % elapsed_time = toc;
                    % fprintf('Обработка завершена за %.2f секунд\n', elapsed_time);
                    % 
                    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % % Расчет комплексных параметров f1k-f4k
                    % fprintf('Расчет комплексных параметров f1k-f4k...\n');
                    % 
                    % for f_idx = 1:4
                    %     % Получаем параметры a и b для всех поляризаций
                    %     a_0 = Results.Polarizer_0.(sprintf('a%d', f_idx));
                    %     a_45 = Results.Polarizer_45.(sprintf('a%d', f_idx));
                    %     a_90 = Results.Polarizer_90.(sprintf('a%d', f_idx));
                    %     a_RC = Results.Polarizer_RC.(sprintf('a%d', f_idx));
                    %     b_0 = Results.Polarizer_0.(sprintf('b%d', f_idx));
                    %     b_45 = Results.Polarizer_45.(sprintf('b%d', f_idx));
                    %     b_90 = Results.Polarizer_90.(sprintf('b%d', f_idx));
                    %     b_RC = Results.Polarizer_RC.(sprintf('b%d', f_idx));
                    % 
                    %     % Расчет комплексных параметров для каждого k
                    %     for k = 1:4
                    %         field_name = sprintf('Complex_f%d%d', f_idx, k);
                    % 
                    %         if k == 1
                    %             % f̃₁ = 0.5((a⁰ + a⁹⁰) + i(b⁰ + b⁹⁰))
                    %             Results.(field_name).A = 0.5 * (a_0 + a_90);
                    %             Results.(field_name).B = 0.5 * (b_0 + b_90);
                    %         elseif k == 2
                    %             % f̃₂ = 0.5((a⁰ + a⁹⁰) - i(b⁰ + b⁹⁰))
                    %             Results.(field_name).A = 0.5 * (a_0 + a_90);
                    %             Results.(field_name).B = -0.5 * (b_0 + b_90);
                    %         elseif k == 3
                    %             % f̃₃ = (a⁴⁵ - (a⁰ + a⁹⁰)) + i(b⁴⁵ - (b⁰ + b⁹⁰))
                    %             Results.(field_name).A = a_45 - (a_0 + a_90);
                    %             Results.(field_name).B = b_45 - (b_0 + b_90);
                    %         else % k == 4
                    %             % f̃₄ = (aᴿᶜ - (a⁰ + a⁹⁰)) + i(bᴿᶜ - (b⁰ + b⁹⁰))
                    %             Results.(field_name).A = a_RC - (a_0 + a_90);
                    %             Results.(field_name).B = b_RC - (b_0 + b_90);
                    %         end
                    % 
                    %         % Расчет модулей и аргументов
                    %         Results.(field_name).Magnitude = sqrt(Results.(field_name).A.^2 + Results.(field_name).B.^2);
                    %         Results.(field_name).Argument = atan2(Results.(field_name).B, Results.(field_name).A);
                    %     end
                    % end
                    % 
                    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % % Сохранение параметров расчета
                    % Results.Parameters.max_radius = max_radius;
                    % Results.Parameters.angular_step_deg = angular_step_deg;
                    % Results.Parameters.angular_step_rad = actual_angular_step;
                    % Results.Parameters.num_angles_per_circle = num_angles;
                    % Results.Parameters.center_x = center_x;
                    % Results.Parameters.center_y = center_y;
                    % Results.Parameters.crop_size = crop_size;
                    % Results.Parameters.result_height = result_height;
                    % Results.Parameters.result_width = result_width;
                    % Results.Parameters.total_pairs = total_pairs;
                    % Results.Parameters.calculation_type = 'Circular_correlation_with_interpolation';
                    % 
                    % % ---------------------------------------------------------------------
                    % fprintf('\n=== РАСЧЕТ ДВУТОЧЕЧНЫХ ПАРАМЕТРОВ ПО КОЛЬЦАМ С ИНТЕРПОЛЯЦИЕЙ ЗАВЕРШЕН ===\n');
                    % 
                    % M = Results;
                    % pathM = stepFolder;
                    % 
                    % 
                    %     % -----------------------------------------------------------------
                    %     % ВИКЛИК ФУНКЦІЇ ДЛЯ ВІЗУАЛІЗАЦІЇ
                    %     calc_2025_vis_DvotMM_Circular(Results, stepFolder);
                    % 
                    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end