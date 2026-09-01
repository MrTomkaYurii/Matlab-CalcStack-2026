function [M, pathM] = calc_2025_DvotMM_1D_OX(savePath, readPath, pathForCode, crop_size, stepik)
global Results;

%% Расчет двуточечных параметров МАТРИЦЫ МЮЛЛЕРА по оси X с фиксированным шагом
% Параметры расчета
readTomka = readPath;
shift_x = stepik; % Фиксированный сдвиг по оси X

% Координаты области для вырезания (полный размер для загрузки изображений)
y1 = 1; 
x1 = 1;
y2 = crop_size; 
x2 = crop_size; % Уменьшаем область на величину сдвига

partFolder = fullfile(savePath, sprintf('part_%d-%d_%d-%d', y1, x1, y2, x2));
if ~exist(partFolder, 'dir')
    mkdir(partFolder);
end
stepFolder = fullfile(partFolder, sprintf('step = %d пікселів по осі X', stepik));
if ~exist(stepFolder, 'dir')
    mkdir(stepFolder);
end
cd(stepFolder);

fprintf('=== ПАРАМЕТРЫ РАСЧЕТА ПО ОСИ X ===\n');
fprintf('Размер обрезки: %dx%d пикселей\n', crop_size, crop_size);
fprintf('Сдвиг по оси X: %d пикселей\n', shift_x);
fprintf('Размер результирующих матриц: %dx%d\n', crop_size, crop_size - shift_x);
fprintf('Общее количество пар точек: %d\n', crop_size * (crop_size - shift_x));

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
    img_crop = img(y1:y2, x1:x2);
    
    % Создаем корректное имя поля
    fieldName = strrep(all_names{k}, '-', '_');
    fieldName = ['img_', fieldName];
    Images.(fieldName) = img_crop;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Инициализация структуры результатов
fprintf('Инициализация структуры результатов...\n');
polarizer_names = {'Polarizer_0', 'Polarizer_45', 'Polarizer_90', 'Polarizer_RC'};
result_height = crop_size;
result_width = crop_size - shift_x;

% Предварительное выделение памяти для всех результатов
for group = 1:4
    group_name = polarizer_names{group};
    
    % Основные параметры Ex, Ey, delta
    Results.(group_name).Ex1 = zeros(result_height, result_width);
    Results.(group_name).Ex2 = zeros(result_height, result_width);
    Results.(group_name).Ey1 = zeros(result_height, result_width);
    Results.(group_name).Ey2 = zeros(result_height, result_width);
    Results.(group_name).delta1 = zeros(result_height, result_width);
    Results.(group_name).delta2 = zeros(result_height, result_width);
    
    % Параметры a1-a4, b1-b4
    for param_idx = 1:4
        Results.(group_name).(sprintf('a%d', param_idx)) = zeros(result_height, result_width);
        Results.(group_name).(sprintf('b%d', param_idx)) = zeros(result_height, result_width);
    end
end

% Комплексные параметры f1k-f4k
for f_idx = 1:4
    for k = 1:4
        field_name = sprintf('Complex_f%d%d', f_idx, k);
        Results.(field_name).A = zeros(result_height, result_width);
        Results.(field_name).B = zeros(result_height, result_width);
        Results.(field_name).Magnitude = zeros(result_height, result_width);
        Results.(field_name).Argument = zeros(result_height, result_width);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Основной расчет по оси X
fprintf('Начало расчета двуточечных параметров по оси X...\n');
tic;

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
    
    % Попиксельный расчет для всех пар точек
    for i = 1:result_height
        for j = 1:result_width
            % Координаты первой точки
            i1 = i;
            j1 = j;
            
            % Координаты второй точки (сдвиг по X на stepik пикселей)
            i2 = i;
            j2 = j + shift_x;
            
            % Расчет Ex параметров (формула: |Ex| = √(I0°))
            u0_1 = img_0(i1, j1);
            u0_2 = img_0(i2, j2);
            Results.(group_name).Ex1(i, j) = sqrt(u0_1);
            Results.(group_name).Ex2(i, j) = sqrt(u0_2);
            
            % Расчет Ey параметров (формула: |Ey| = √(I90°))
            u90_1 = img_90(i1, j1);
            u90_2 = img_90(i2, j2);
            Results.(group_name).Ey1(i, j) = sqrt(u90_1);
            Results.(group_name).Ey2(i, j) = sqrt(u90_2);
            
            % Расчет delta параметров
            % delta1 для первой точки: S2=I45°-I135°, S3=Iправ-Iлев, delta=atan2(S3,S2)
            I45_1 = img_45(i1, j1);
            I135_1 = img_135(i1, j1);
            Iprav_1 = img_prav(i1, j1);
            Iliv_1 = img_liv(i1, j1);
            
            S2_1 = I45_1 - I135_1;
            S3_1 = Iprav_1 - Iliv_1;
            Results.(group_name).delta1(i, j) = atan2(S3_1, S2_1);
            
            % delta2 для второй точки
            I45_2 = img_45(i2, j2);
            I135_2 = img_135(i2, j2);
            Iprav_2 = img_prav(i2, j2);
            Iliv_2 = img_liv(i2, j2);
            
            S2_2 = I45_2 - I135_2;
            S3_2 = Iprav_2 - Iliv_2;
            Results.(group_name).delta2(i, j) = atan2(S3_2, S2_2);
            
            % Расчет параметров a1-a4, b1-b4 по формулам (6)-(13)
            Ex1 = Results.(group_name).Ex1(i, j);
            Ex2 = Results.(group_name).Ex2(i, j);
            Ey1 = Results.(group_name).Ey1(i, j);
            Ey2 = Results.(group_name).Ey2(i, j);
            delta1 = Results.(group_name).delta1(i, j);
            delta2 = Results.(group_name).delta2(i, j);
            
            % Формулы (6)-(13)
            Results.(group_name).a1(i, j) = Ex1 * Ex2 + Ey1 * Ey2 * cos(delta2 - delta1);
            Results.(group_name).b1(i, j) = Ey1 * Ey2 * sin(delta2 - delta1);
            Results.(group_name).a2(i, j) = Ex1 * Ex2 - Ey1 * Ey2 * cos(delta2 - delta1);
            Results.(group_name).b2(i, j) = -Ey1 * Ey2 * sin(delta2 - delta1);
            Results.(group_name).a3(i, j) = Ex1 * Ey2 * cos(delta2) + Ex2 * Ey1 * cos(delta1);
            Results.(group_name).b3(i, j) = Ex1 * Ey2 * sin(delta2) - Ex2 * Ey1 * sin(delta1);
            Results.(group_name).a4(i, j) = Ex1 * Ey2 * sin(delta2) + Ex2 * Ey1 * sin(delta1);
            Results.(group_name).b4(i, j) = Ex1 * Ey2 * cos(delta2) - Ex2 * Ey1 * cos(delta1);
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
Results.Parameters.crop_size = crop_size;
Results.Parameters.shift_x = shift_x;
Results.Parameters.result_height = result_height;
Results.Parameters.result_width = result_width;
Results.Parameters.calculation_type = 'X-axis_shift';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Финальный отчет
fprintf('\n=== РАСЧЕТ ДВУТОЧЕЧНЫХ ПАРАМЕТРОВ ПО ОСИ X ЗАВЕРШЕН ===\n');
fprintf('Время выполнения: %.2f секунд\n', elapsed_time);
fprintf('Размер результирующих матриц: %dx%d\n', result_height, result_width);
fprintf('Сдвиг по оси X: %d пикселей\n', shift_x);
fprintf('Обработано изображений: %d\n', length(all_names));
fprintf('Рассчитано параметров для каждой поляризации:\n');
fprintf('  - Основные: Ex1, Ex2, Ey1, Ey2, delta1, delta2\n');
fprintf('  - Промежуточные: a1-a4, b1-b4\n');
fprintf('  - Комплексные: f11-f44 (A, B, Magnitude, Argument)\n');
fprintf('Результаты сохранены в структуре Results.\n');

% Сохранение структуры Results
% saveFile = fullfile(stepFolder, 'Results_2D_MM_X_axis.mat');
% save(saveFile, 'Results');

% -----------------------------------------------------------------
% ВЫЗОВ ФУНКЦИИ ДЛЯ ВИЗУАЛИЗАЦИИ
calc_2025_vis_DvotMM_2D(Results, stepFolder);

end