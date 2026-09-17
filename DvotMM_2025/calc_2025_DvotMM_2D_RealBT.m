% функция для моделирования двут. параметров матрицы Мюллера на основе ро и
% дельта по формулам от ДУБОЛАЗОВА на основе псевдоАКФ

function [M, pathM ] = calc_2025_DvotMM_2Dv2(savePath, readPath, pathForCode, crop_size, stepik )
global Results;

%% Расчет двуточечных параметров МАТРИЦЫ МЮЛЛЕРА на основе алгоритма псевдо-АКФ
% Параметры псевдо-АКФ
readTomka = readPath;
max_shift = crop_size - 1; % Полный диапазон сдвигов (399 пикселей)

    % Координаты области для вырезания
    y1 = 1; 
    x1 = 1;
    y2 = crop_size; 
    x2 = crop_size;

    partFolder = fullfile(savePath, sprintf('part_%d-%d_%d-%d', y1, x1, y2, x2));
    if ~exist(partFolder, 'dir')
        mkdir(partFolder);
    end
    stepFolder = fullfile(partFolder,sprintf('step = %d пікселів', stepik));
    if ~exist(stepFolder, 'dir')
        mkdir(stepFolder);
    end
    cd(stepFolder);
    
    % Вычисляем диапазон сдвигов и размер результирующих матриц
    shift_range = -max_shift:stepik:max_shift;
    matrix_size = length(shift_range);
    
    fprintf('=== ПАРАМЕТРЫ ПСЕВДО-АКФ ===\n');
    fprintf('Размер обрезки: %dx%d пикселей\n', crop_size, crop_size);
    fprintf('Диапазон сдвигов: от %d до %d с шагом %d\n', -max_shift, max_shift, stepik);
    fprintf('Размер результирующих матриц: %dx%d\n', matrix_size, matrix_size);
    fprintf('Общее количество комбинаций сдвигов: %d\n', matrix_size^2);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Имена файлов по группам (поляризации: 0°, 45°, 90°, правая циркулярная)
    names_groups = {
        {'0-0','0-45','0-90','0-135','0-liv','0-prav'};       % Входная поляризация 0°
        {'45-0','45-45','45-90','45-135','45-liv','45-prav'}; % Входная поляризация 45°
        {'90-0','90-45','90-90','90-135','90-liv','90-prav'}; % Входная поляризация 90°
        {'prav-0','prav-45','prav-90','prav-135','prav-liv','prav-prav'} % Правая циркулярная
    };
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Загрузка всех изображений с обрезкой
    fprintf('Загрузка и обрезка изображений...\n');
    Images = struct();
    all_names = [names_groups{:}]; % Объединяем все имена
    
    for k = 1:numel(all_names)
        img = imread([readTomka, all_names{k}, '.bmp']);
        if size(img,3) == 3
            img = rgb2gray(img);
        end
        img = double(img) / 255; % Нормализация [0,1]
        
        % Обрезка до crop_size x crop_size пикселей из левого верхнего угла
        img_crop = img(y1:y2, x1:x2, :);
        
        % Создаем корректное имя поля
        fieldName = strrep(all_names{k}, '-', '_');
        fieldName = ['img_', fieldName];
        Images.(fieldName) = img;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Инициализация структуры результатов для псевдо-АКФ
    fprintf('Инициализация структуры результатов...\n');
    polarizer_names = {'Polarizer_0', 'Polarizer_45', 'Polarizer_90', 'Polarizer_RC'};
    
    % Предварительное выделение памяти для всех результатов
    for group = 1:4
        group_name = polarizer_names{group};
        
        % Параметры a1-a4, b1-b4
        for param_idx = 1:4
            Results.(group_name).(sprintf('a%d', param_idx)) = zeros(matrix_size, matrix_size);
            Results.(group_name).(sprintf('b%d', param_idx)) = zeros(matrix_size, matrix_size);
        end
    end
    
    % Комплексные параметры f1k-f4k
    for f_idx = 1:4
        for k = 1:4
            field_name = sprintf('Complex_f%d%d', f_idx, k);
            Results.(field_name).A = zeros(matrix_size, matrix_size);
            Results.(field_name).B = zeros(matrix_size, matrix_size);
            Results.(field_name).Magnitude = zeros(matrix_size, matrix_size);
            Results.(field_name).Argument = zeros(matrix_size, matrix_size);
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Подготовка для параллельной обработки
    total_shifts = matrix_size^2;
    shift_combinations = zeros(total_shifts, 2);
    linear_indices = zeros(total_shifts, 2);
    
    % Создание массива всех комбинаций сдвигов
    idx = 1;
    for i = 1:matrix_size
        for j = 1:matrix_size
            shift_combinations(idx, 1) = shift_range(i); % shift_x
            shift_combinations(idx, 2) = shift_range(j); % shift_y
            linear_indices(idx, 1) = i; % индекс в результирующей матрице
            linear_indices(idx, 2) = j; % индекс в результирующей матрице
            idx = idx + 1;
        end
    end
    
    % Инициализация массива для сбора результатов из parfor
    all_group_results = cell(total_shifts, 1);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Основной параллельный цикл по всем комбинациям сдвигов
    fprintf('Начало параллельного расчета псевдо-АКФ...\n');
    tic;
    
    parfor shift_idx = 1:total_shifts
        shift_x = shift_combinations(shift_idx, 1);
        shift_y = shift_combinations(shift_idx, 2);
        matrix_i = linear_indices(shift_idx, 1);
        matrix_j = linear_indices(shift_idx, 2);
        
        % Структура для накопления результатов этого сдвига
        shift_results = struct();
        
        % Обработка каждой группы поляризаций
        for group = 1:4
            current_names = names_groups{group};
            
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
            
            % Определяем область перекрытия для данного сдвига (логика АКФ)
    % Для положительных сдвигов точка 1 начинается с (1,1)
    % Для отрицательных сдвигов точка 2 начинается с (1,1)
    
    if shift_x >= 0
        i1_start = 1;
        i1_end = crop_size - shift_x;
        i2_start = 1 + shift_x;
        i2_end = crop_size;
    else
        i1_start = 1 - shift_x;
        i1_end = crop_size;
        i2_start = 1;
        i2_end = crop_size + shift_x;
    end
    
    if shift_y >= 0
        j1_start = 1;
        j1_end = crop_size - shift_y;
        j2_start = 1 + shift_y;
        j2_end = crop_size;
    else
        j1_start = 1 - shift_y;
        j1_end = crop_size;
        j2_start = 1;
        j2_end = crop_size + shift_y;
    end
    
    % Проверка валидности области
    if i1_end < i1_start || j1_end < j1_start || i2_end < i2_start || j2_end < j2_start
        % Нет перекрытия - записываем нули
        for param_idx = 1:4
            shift_results.(sprintf('group_%d', group)).(sprintf('a%d', param_idx)) = 0;
            shift_results.(sprintf('group_%d', group)).(sprintf('b%d', param_idx)) = 0;
        end
        continue;
    end
    
    valid_points = (i1_end - i1_start + 1) * (j1_end - j1_start + 1);
    
    % Накопители только для корреляций a1-a4, b1-b4
    sum_a1 = 0; sum_a2 = 0; sum_a3 = 0; sum_a4 = 0;
    sum_b1 = 0; sum_b2 = 0; sum_b3 = 0; sum_b4 = 0;
    
    % Основной цикл по области перекрытия
    for i_idx = 1:(i1_end - i1_start + 1)
        for j_idx = 1:(j1_end - j1_start + 1)
            % Координаты в изображениях
            i1 = i1_start + i_idx - 1;
            j1 = j1_start + j_idx - 1;
            i2 = i2_start + i_idx - 1;
            j2 = j2_start + j_idx - 1;
            
            % Проверка границ (на всякий случай)
            if i1 < 1 || i1 > crop_size || j1 < 1 || j1 > crop_size || ...
               i2 < 1 || i2 > crop_size || j2 < 1 || j2 > crop_size
                continue;
            end
            
            % Расчет параметров для каждой пары точек
            % Ex параметры
            u0_1 = img_0(i1, j1);
            u0_2 = img_0(i2, j2);
            Ex1 = sqrt(u0_1);
            Ex2 = sqrt(u0_2);
            
            % Ey параметры
            u90_1 = img_90(i1, j1);
            u90_2 = img_90(i2, j2);
            Ey1 = sqrt(u90_1);
            Ey2 = sqrt(u90_2);
            
            % delta параметры
            I0_45_1 = img_45(i1, j1);
            I0_135_1 = img_135(i1, j1);
            I0_prav_1 = img_prav(i1, j1);
            I0_liv_1 = img_liv(i1, j1);
            S2_1 = I0_45_1 - I0_135_1;
            S3_1 = I0_prav_1 - I0_liv_1;
            delta1 = atan2(S3_1, S2_1);
            
            I0_45_2 = img_45(i2, j2);
            I0_135_2 = img_135(i2, j2);
            I0_prav_2 = img_prav(i2, j2);
            I0_liv_2 = img_liv(i2, j2);
            S2_2 = I0_45_2 - I0_135_2;
            S3_2 = I0_prav_2 - I0_liv_2;
            delta2 = atan2(S3_2, S2_2);
            
            % ИСПРАВЛЕНИЕ: Вычисляем корреляции для каждой пары точек 
            % и накапливаем их (правильная АКФ)
            % Формулы (6)-(13)
            a1_pair = Ex1 * Ex2 + Ey1 * Ey2 * cos(delta2 - delta1);
            b1_pair = Ey1 * Ey2 * sin(delta2 - delta1);
            a2_pair = Ex1 * Ex2 - Ey1 * Ey2 * cos(delta2 - delta1);
            b2_pair = -Ey1 * Ey2 * sin(delta2 - delta1);
            a3_pair = Ex1 * Ey2 * cos(delta2) + Ex2 * Ey1 * cos(delta1);
            b3_pair = Ex1 * Ey2 * sin(delta2) - Ex2 * Ey1 * sin(delta1);
            a4_pair = Ex1 * Ey2 * sin(delta2) + Ex2 * Ey1 * sin(delta1);
            b4_pair = Ex1 * Ey2 * cos(delta2) - Ex2 * Ey1 * cos(delta1);
            
            % Накапливаем корреляции
            sum_a1 = sum_a1 + a1_pair;
            sum_b1 = sum_b1 + b1_pair;
            sum_a2 = sum_a2 + a2_pair;
            sum_b2 = sum_b2 + b2_pair;
            sum_a3 = sum_a3 + a3_pair;
            sum_b3 = sum_b3 + b3_pair;
            sum_a4 = sum_a4 + a4_pair;
            sum_b4 = sum_b4 + b4_pair;
        end
    end      
            % Усреднение корреляций
            if valid_points > 0
                % ИСПРАВЛЕНИЕ: Усреднение только корреляций (правильная АКФ)
                shift_results.(sprintf('group_%d', group)).a1 = sum_a1 / valid_points;
                shift_results.(sprintf('group_%d', group)).b1 = sum_b1 / valid_points;
                shift_results.(sprintf('group_%d', group)).a2 = sum_a2 / valid_points;
                shift_results.(sprintf('group_%d', group)).b2 = sum_b2 / valid_points;
                shift_results.(sprintf('group_%d', group)).a3 = sum_a3 / valid_points;
                shift_results.(sprintf('group_%d', group)).b3 = sum_b3 / valid_points;
                shift_results.(sprintf('group_%d', group)).a4 = sum_a4 / valid_points;
                shift_results.(sprintf('group_%d', group)).b4 = sum_b4 / valid_points;
            else
                shift_results.(sprintf('group_%d', group)).a1 = 0;
                shift_results.(sprintf('group_%d', group)).b1 = 0;
                shift_results.(sprintf('group_%d', group)).a2 = 0;
                shift_results.(sprintf('group_%d', group)).b2 = 0;
                shift_results.(sprintf('group_%d', group)).a3 = 0;
                shift_results.(sprintf('group_%d', group)).b3 = 0;
                shift_results.(sprintf('group_%d', group)).a4 = 0;
                shift_results.(sprintf('group_%d', group)).b4 = 0;
            end
        end
        
        % Сохранение результатов для этого сдвига
        all_group_results{shift_idx} = struct();
        all_group_results{shift_idx}.matrix_i = matrix_i;
        all_group_results{shift_idx}.matrix_j = matrix_j;
        all_group_results{shift_idx}.data = shift_results;
    end
    
    elapsed_time = toc;
    fprintf('Параллельная обработка завершена за %.2f секунд\n', elapsed_time);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Сборка результатов в основную структуру
    fprintf('Сборка результатов в основную структуру...\n');
    
    for shift_idx = 1:total_shifts
        if isempty(all_group_results{shift_idx}) || ~isfield(all_group_results{shift_idx}, 'data')
            continue;
        end
        
        matrix_i = all_group_results{shift_idx}.matrix_i;
        matrix_j = all_group_results{shift_idx}.matrix_j;
        data = all_group_results{shift_idx}.data;
        
        % Сохранение результатов для каждой группы поляризаций
        for group = 1:4
            if ~isfield(data, sprintf('group_%d', group))
                continue;
            end
            
            group_name = polarizer_names{group};
            group_data = data.(sprintf('group_%d', group));
            
            % Параметры a1-a4, b1-b4
            for param_idx = 1:4
                a_field = sprintf('a%d', param_idx);
                b_field = sprintf('b%d', param_idx);
                if isfield(group_data, a_field) && isfield(group_data, b_field)
                    Results.(group_name).(a_field)(matrix_i, matrix_j) = group_data.(a_field);
                    Results.(group_name).(b_field)(matrix_i, matrix_j) = group_data.(b_field);
                end
            end
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Расчет комплексных параметров f1k-f4k (аналогично оригинальному коду)
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
                % f̃х₁ = 0.5((a⁰ + a⁹⁰) + i(b⁰ + b⁹⁰))
                Results.(field_name).A = 0.5 * (a_0 + a_90);
                Results.(field_name).B = 0.5 * (b_0 + b_90);
            elseif k == 2
                % f̃х₂ = 0.5((a⁰ + a⁹⁰) - i(b⁰ + b⁹⁰))
                Results.(field_name).A = 0.5 * (a_0 + a_90);
                Results.(field_name).B = -0.5 * (b_0 + b_90);
            elseif k == 3
                % f̃₃ = (a⁴⁵ - (a⁰ + a⁹⁰)) + i(b⁴⁵ - (b⁰ + b⁹⁰))
                Results.(field_name).A = a_45 - (a_0 + a_90);
                Results.(field_name).B = b_45 - (b_0 + b_90);
            else % k == 4
                % f̃х₄ = (aᴿᶜ - (a⁰ + a⁹⁰)) + i(bᴿᶜ - (b⁰ + b⁹⁰))
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
    Results.Parameters.crop_size = crop_size;
    Results.Parameters.max_shift = max_shift;
    Results.Parameters.step = stepik;
    Results.Parameters.matrix_size = matrix_size;
    Results.Parameters.shift_range = shift_range;
    Results.Parameters.center_coordinates = [find(shift_range == 0), find(shift_range == 0)]; % Центр матрицы (сдвиг 0,0)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Финальный отчет
    fprintf('\n=== РАСЧЕТ ПСЕВДО-АКФ ЗАВЕРШЕН ===\n');
    fprintf('Время выполнения: %.2f секунд\n', elapsed_time);
    fprintf('Размер результирующих матриц: %dx%d\n', matrix_size, matrix_size);
    fprintf('Центр матрицы (сдвиг 0,0): [%d,%d]\n', Results.Parameters.center_coordinates);
    fprintf('Обработано изображений: %d\n', length(all_names));
    fprintf('Рассчитано параметров для каждой поляризации:\n');
    fprintf('  - Основные: Ex1, Ex2, Ey1, Ey2, delta1, delta2\n');
    fprintf('  - Промежуточные: a1-a4, b1-b4\n');
    fprintf('  - Комплексные: f11-f44 (A, B, Magnitude, Argument)\n');
    fprintf('Результаты сохранены в структуре Results.\n');

    % Сохранение структуры Results
    % saveFile = fullfile(stepFolder, 'Results_2D_MM.mat');
    % save(saveFile, 'Results');

    % -----------------------------------------------------------------
    % ВИКЛИК ФУНКЦІЇ ДЛЯ ВІЗУАЛІЗАЦІЇ
    calc_2025_vis_DvotMM_2D(Results, stepFolder);
end