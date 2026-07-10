function [M, pathM] = calc_2025_DvotMM_Azimuth_Ellipticity(savePath, readPath, pathForCode, crop_size, stepik)
global Results;

%% Расчет двуточечных параметров азимута и эллиптичности по оси X с фиксированным шагом
% Параметры расчета
readTomka = readPath;
shift_x = stepik; % Фиксированный сдвиг по оси X

% Координаты области для вырезания
y1 = 1; 
x1 = 1;
y2 = crop_size; 
x2 = crop_size;

partFolder = fullfile(savePath, sprintf('part_%d-%d_%d-%d', y1, x1, y2, x2));
if ~exist(partFolder, 'dir')
    mkdir(partFolder);
end
stepFolder = fullfile(partFolder, sprintf('step = %d пікселів по осі X', stepik));
if ~exist(stepFolder, 'dir')
    mkdir(stepFolder);
end
cd(stepFolder);

fprintf('=== ПАРАМЕТРЫ РАСЧЕТА ДВУТОЧЕЧНЫХ ПАРАМЕТРОВ АЗИМУТА И ЭЛЛИПТИЧНОСТИ ===\n');
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
    
    % Промежуточные параметры a-f (формулы 6-11)
    Results.(group_name).a = zeros(result_height, result_width);
    Results.(group_name).b = zeros(result_height, result_width);
    Results.(group_name).c = zeros(result_height, result_width);
    Results.(group_name).d = zeros(result_height, result_width);
    Results.(group_name).e = zeros(result_height, result_width);
    Results.(group_name).f = zeros(result_height, result_width);
    
    % Промежуточные параметры A, B, C, D для расчета модулей и аргументов
    Results.(group_name).A = zeros(result_height, result_width);
    Results.(group_name).B = zeros(result_height, result_width);
    Results.(group_name).C = zeros(result_height, result_width);
    Results.(group_name).D = zeros(result_height, result_width);
    
    % Финальные параметры азимута и эллиптичности
    Results.(group_name).Azimuth_Magnitude = zeros(result_height, result_width);     % |2α^C|
    Results.(group_name).Azimuth_Argument = zeros(result_height, result_width);      % Arg(tan 2α^C)
    Results.(group_name).Ellipticity_Magnitude = zeros(result_height, result_width); % |2β^C|
    Results.(group_name).Ellipticity_Argument = zeros(result_height, result_width);  % Arg(sin 2β^C)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Основной расчет по оси X
fprintf('Начало расчета двуточечных параметров азимута и эллиптичности...\n');
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
            
            % Расчет |Ex| параметров (формула: |Ex| = √(I0°))
            Ix1_0 = img_0(i1, j1);
            Ix2_0 = img_0(i2, j2);
            Results.(group_name).Ex1(i, j) = sqrt(Ix1_0);
            Results.(group_name).Ex2(i, j) = sqrt(Ix2_0);
            
            % Расчет |Ey| параметров (формула: |Ey| = √(I90°))
            Iy1_90 = img_90(i1, j1);
            Iy2_90 = img_90(i2, j2);
            Results.(group_name).Ey1(i, j) = sqrt(Iy1_90);
            Results.(group_name).Ey2(i, j) = sqrt(Iy2_90);
            
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
            
            % Получаем рассчитанные параметры
            Ex1 = Results.(group_name).Ex1(i, j);
            Ex2 = Results.(group_name).Ex2(i, j);
            Ey1 = Results.(group_name).Ey1(i, j);
            Ey2 = Results.(group_name).Ey2(i, j);
            delta1 = Results.(group_name).delta1(i, j);
            delta2 = Results.(group_name).delta2(i, j);
            
            % Расчет промежуточных параметров a-f по формулам (6)-(11)
            a = Ex1 * Ex2 + Ey1 * Ey2 * cos(delta2 - delta1);
            b = Ey1 * Ey2 * sin(delta2 - delta1);
            c = Ex1 * Ey2 * cos(delta2) + Ex2 * Ey1 * cos(delta1);
            d = Ex1 * Ey2 * sin(delta2) + Ex2 * Ey1 * sin(delta1);
            e = Ex1 * Ey2 * sin(delta2) - Ex2 * Ey1 * sin(delta1); % исправлено: минус
            f = Ex1 * Ey2 * cos(delta2) - Ex2 * Ey1 * cos(delta1); % исправлено: минус
            
            Results.(group_name).a(i, j) = a;
            Results.(group_name).b(i, j) = b;
            Results.(group_name).c(i, j) = c;
            Results.(group_name).d(i, j) = d;
            Results.(group_name).e(i, j) = e;
            Results.(group_name).f(i, j) = f;
            
            % Расчет промежуточных параметров A, B, C, D
            % Для tan 2α^C = SC3/SC2 = (c+id)/(a-ib) = A + iB
            denominator_azimuth = a^2 + b^2;
            if denominator_azimuth > eps % избегаем деления на ноль
                A = (a*c + b*d) / denominator_azimuth;
                B = (a*d - b*c) / denominator_azimuth;
            else
                A = 0;
                B = 0;
            end
            
            % Для sin 2β^C = SC4/SC1 = (e+if)/(a+ib) = C + iD
            denominator_ellipticity = a^2 + b^2;
            if denominator_ellipticity > eps % избегаем деления на ноль
                C = (a*e - b*f) / denominator_ellipticity;
                D = (a*f + b*e) / denominator_ellipticity;
            else
                C = 0;
                D = 0;
            end
            
            Results.(group_name).A(i, j) = A;
            Results.(group_name).B(i, j) = B;
            Results.(group_name).C(i, j) = C;
            Results.(group_name).D(i, j) = D;
            
            % Расчет финальных параметров
            % Модуль азимута: |2α^C| = 0.5 * arctan(√(A² + B²)) - формула (13)
            Results.(group_name).Azimuth_Magnitude(i, j) = 0.5 * atan(sqrt(A^2 + B^2));
            
            % Аргумент азимута: Arg(tan 2α^C) = atan2(B,A) - формула (14) ИСПРАВЛЕНО
            Results.(group_name).Azimuth_Argument(i, j) = atan2(B, A);
            
            % Модуль эллиптичности: |2β^C| = 0.5 * arctan(√(C² + D²)) - формула (16) ИСПРАВЛЕНО
            Results.(group_name).Ellipticity_Magnitude(i, j) = 0.5 * atan(sqrt(C^2 + D^2));
            
            % Аргумент эллиптичности: Arg(sin 2β^C) = atan2(D,C) - формула (17) ИСПРАВЛЕНО  
            Results.(group_name).Ellipticity_Argument(i, j) = atan2(D, C);
        end
    end
end

elapsed_time = toc;
fprintf('Обработка завершена за %.2f секунд\n', elapsed_time);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Сохранение параметров расчета
Results.Parameters.crop_size = crop_size;
Results.Parameters.shift_x = shift_x;
Results.Parameters.result_height = result_height;
Results.Parameters.result_width = result_width;
Results.Parameters.calculation_type = 'X-axis_shift_Azimuth_Ellipticity';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Финальный отчет
fprintf('\n=== РАСЧЕТ ДВУТОЧЕЧНЫХ ПАРАМЕТРОВ АЗИМУТА И ЭЛЛИПТИЧНОСТИ ЗАВЕРШЕН ===\n');
fprintf('Время выполнения: %.2f секунд\n', elapsed_time);
fprintf('Размер результирующих матриц: %dx%d\n', result_height, result_width);
fprintf('Сдвиг по оси X: %d пикселей\n', shift_x);
fprintf('Обработано изображений: %d\n', length(all_names));
fprintf('Рассчитано параметров для каждой входной поляризации:\n');
fprintf('  - Основные: Ex1, Ex2, Ey1, Ey2, delta1, delta2\n');
fprintf('  - Промежуточные: a, b, c, d, e, f, A, B, C, D\n');
fprintf('  - Финальные: Azimuth_Magnitude, Azimuth_Argument, Ellipticity_Magnitude, Ellipticity_Argument\n');
fprintf('Результаты сохранены в структуре Results.\n');

% Сохранение структуры Results
 saveFile = fullfile(stepFolder, 'Results_2D_Azimuth_Ellipticity.mat');
 save(saveFile, 'Results');

% Вызов функции для визуализации (если есть)
 calc_2025_vis_Azimuth_Ellipticity(Results, stepFolder);

end