clear;clc;
% Создаем большие структуры для хранения всех данных
delta_all = struct();
rho_all = struct();
A_magnitude = struct();
Phi_A = struct();
B_magnitude = struct();
Phi_B = struct();


colormap_value = 'parula';                % 🔧 карта кольорів
steps = [20, 10, 5, 1];                 % 🔧 кроки сканування
base_path = 'C:\[TOMKA] - Modelling\ЕТАП №02 - порівняння чутливості\2.3';

%% РАСЧЕТ АЛЬФА и БЕТТА
% Вызываем функцию для каждого случая и сохраняем в большие структуры
[delta_all.case1, rho_all.case1] = harmonic_modulation(colormap_value, 400, [1, 5, 20], 'C:/[TOMKA] - Modelling/2.3', 1);
[delta_all.case2, rho_all.case2] = harmonic_modulation(colormap_value, 400, [1, 5, 20], 'C:/[TOMKA] - Modelling/2.3', 2);
[delta_all.case3, rho_all.case3] = harmonic_modulation(colormap_value, 400, [1, 5, 20], 'C:/[TOMKA] - Modelling/2.3', 3);
[delta_all.case4, rho_all.case4] = harmonic_modulation(colormap_value, 400, [1, 5, 20], 'C:/[TOMKA] - Modelling/2.3', 4);

% Получаем все случаи (case1, case2, case3, case4)
cases = fieldnames(delta_all);

% Определяем шаги для псевдокорреляций
steps = [20, 10, 5, 1];

% Размеры карт (400x400 пикселей)
map_size = 400;
n = map_size;  % размер по x
m = map_size;  % размер по y

% Проходим по всем случаям
for case_idx = 1:length(cases)
    current_case = cases{case_idx};
    
    % Инициализируем структуры для текущего случая
    A_magnitude.(current_case) = struct();
    Phi_A.(current_case) = struct();
    B_magnitude.(current_case) = struct();
    Phi_B.(current_case) = struct();
    
    % Получаем все ключи модуляции (m_1, m_5, m_20)
    modulation_keys = fieldnames(delta_all.(current_case));
    
    % Проходим по всем ключам модуляции
    for mod_idx = 1:length(modulation_keys)
        key = modulation_keys{mod_idx};
        
        % Получаем delta и rho для текущего случая и модуляции
        delta_map = delta_all.(current_case).(key);
        rho_map = rho_all.(current_case).(key);
        
        % Инициализируем структуры для разных шагов корреляции
        A_magnitude.(current_case).(key) = struct();
        Phi_A.(current_case).(key) = struct();
        B_magnitude.(current_case).(key) = struct();
        Phi_B.(current_case).(key) = struct();
        
        % Проходим по всем шагам корреляции
        for step_idx = 1:length(steps)
            step = steps(step_idx);
            step_name = sprintf('step_%d', step);
            
            fprintf('Обрабатываем %s, %s, шаг %d\n', current_case, key, step);
            
            % === 1. Диапазоны допустимых сдвигов ===
            dx_range = -(n-1):step:(n-1);
            dy_range = -(m-1):step:(m-1);
            
            % === 2. Размер псевдокорреляционного ядра ===
            KsizeX = length(dx_range);
            KsizeY = length(dy_range);
            
            % === 3. Центральный сдвиг (нулевой) ===
            centerX = ceil(KsizeX / 2);
            centerY = ceil(KsizeY / 2);
            
            % === 4. Предварительное выделение памяти ===
            results_A_magnitude = zeros(KsizeY, KsizeX);
            results_Phi_A = zeros(KsizeY, KsizeX);
            results_B_magnitude = zeros(KsizeY, KsizeX);
            results_Phi_B = zeros(KsizeY, KsizeX);
            
            % === 5. Основной цикл по сдвигам с параллельными вычислениями ===
            parfor ii = 1:length(dx_range)
                dx = dx_range(ii);
                
                % Временные массивы для накопления результатов
                temp_A_magnitude = zeros(length(dy_range), 1);
                temp_Phi_A = zeros(length(dy_range), 1);
                temp_B_magnitude = zeros(length(dy_range), 1);
                temp_Phi_B = zeros(length(dy_range), 1);
                
                for jj = 1:length(dy_range)
                    dy = dy_range(jj);
                    
                    % === 6. Определение областей перекрытия ===
                    x1 = max(1, 1 - dx) : min(n, n - dx);
                    y1 = max(1, 1 - dy) : min(m, m - dy);
                    x2 = x1 + dx;
                    y2 = y1 + dy;
                    
                    % === 7. Извлечение сдвинутых областей ===
                    % Исходные области (delta1, rho1)
                    delta1 = delta_map(y1, x1);
                    rho1 = rho_map(y1, x1);
                    
                    % Сдвинутые области (delta2, rho2)
                    delta2 = delta_map(y2, x2);
                    rho2 = rho_map(y2, x2);
                    
                    % === 8. ВЫЧИСЛЕНИЕ КОЭФФИЦИЕНТОВ a1-a4, b1-b4 ===
                    a1 = sin(delta1) .* sin(delta2) .* cos(rho1 - rho2) + cos(delta1) .* cos(delta2);
                    b1 = sin(delta1) .* cos(delta2) .* cos(rho1) - cos(delta1) .* sin(delta2) .* cos(rho2);
                    
                    a2 = sin(delta1) .* sin(delta2) .* cos(rho1 + rho2) + cos(delta1) .* cos(delta2);
                    b2 = sin(delta1) .* cos(delta2) .* cos(rho1) - cos(delta1) .* sin(delta2) .* cos(rho2);
                    
                    a3 = sin(delta1) .* sin(delta2) .* sin(rho1 + rho2);
                    b3 = sin(delta1) .* cos(delta2) .* sin(rho1) - cos(delta1) .* sin(delta2) .* sin(rho2);
                    
                    a4 = -sin(delta1) .* cos(delta2) .* sin(rho1) - cos(delta1) .* sin(delta2) .* sin(rho2);
                    b4 = sin(delta1) .* sin(delta2) .* sin(rho1 - rho2);
                    
                    % === 9. ВЫЧИСЛЕНИЕ ДВУТОЧЕЧНЫХ ПОЛЯРИЗАЦИОННЫХ ПАРАМЕТРОВ ===
                    
                    % Обработка особенностей деления на ноль
                    epsilon = 1e-10;
                    
                    % |A| = 0.5 * arctan(sqrt(a3² + b3²) / sqrt(a2² + b2²))
                    denominator_A = sqrt(a2.^2 + b2.^2);
                    sing_mask_A = abs(denominator_A) < epsilon;
                    denominator_A(sing_mask_A) = epsilon;
                    
                    A_mag_local = 0.5 * atan(sqrt(a3.^2 + b3.^2) ./ denominator_A);
                    
                    % Φ(A) = 0.5 * atan2(a2*a3 - b2*b3, a2*b3 - a3*b2)
                    numerator_PhiA = a2.*a3 - b2.*b3;
                    denominator_PhiA = a2.*b3 - a3.*b2;
                    sing_mask_PhiA = abs(denominator_PhiA) < epsilon;
                    denominator_PhiA(sing_mask_PhiA) = sign(denominator_PhiA(sing_mask_PhiA)) * epsilon;
                    
                    Phi_A_local = 0.5 * atan2(numerator_PhiA, denominator_PhiA);
                    
                    % |B| = 0.5 * arcsin(sqrt(a4² + b4²) / sqrt(a2² + b2²))
                    argument_B = sqrt(a4.^2 + b4.^2) ./ denominator_A;
                    % Ограничиваем аргумент arcsin в пределах [-1, 1]
                    argument_B = max(-1, min(1, argument_B));
                    B_mag_local = 0.5 * asin(argument_B);
                    
                    % Φ(B) = atan2(a1*b4 - a4*b1, a2*b3 - a3*b2)
                    numerator_PhiB = a1.*b4 - a4.*b1;
                    denominator_PhiB = a2.*b3 - a3.*b2;
                    sing_mask_PhiB = abs(denominator_PhiB) < epsilon;
                    denominator_PhiB(sing_mask_PhiB) = sign(denominator_PhiB(sing_mask_PhiB)) * epsilon;
                    
                    Phi_B_local = atan2(numerator_PhiB, denominator_PhiB);
                    
                    % === 10. УСРЕДНЕНИЕ ПО ОБЛАСТИ ПЕРЕКРЫТИЯ ===
                    temp_A_magnitude(jj) = mean(A_mag_local(:), 'omitnan');
                    temp_Phi_A(jj) = mean(Phi_A_local(:), 'omitnan');
                    temp_B_magnitude(jj) = mean(B_mag_local(:), 'omitnan');
                    temp_Phi_B(jj) = mean(Phi_B_local(:), 'omitnan');
                end
                
                % === 11. СОХРАНЕНИЕ РЕЗУЛЬТАТОВ ТЕКУЩЕГО dx ===
                results_A_magnitude(:, ii) = temp_A_magnitude;
                results_Phi_A(:, ii) = temp_Phi_A;
                results_B_magnitude(:, ii) = temp_B_magnitude;
                results_Phi_B(:, ii) = temp_Phi_B;
            end
            
            % === 12. СОХРАНЕНИЕ РЕЗУЛЬТАТОВ В СТРУКТУРЫ ===
            A_magnitude.(current_case).(key).(step_name) = results_A_magnitude;
            Phi_A.(current_case).(key).(step_name) = results_Phi_A;
            B_magnitude.(current_case).(key).(step_name) = results_B_magnitude;
            Phi_B.(current_case).(key).(step_name) = results_Phi_B;
            
            fprintf('Завершено для %s, %s, шаг %d\n', current_case, key, step);
        end
    end
end

% === 13. СОЗДАНИЕ ИТОГОВОЙ СТРУКТУРЫ С ОПИСАНИЯМИ ===
polarization_pseudocorr = struct();

% A_magnitude - модуль двуточечного азимута
polarization_pseudocorr.A_magnitude = struct();
polarization_pseudocorr.A_magnitude.description = 'Модуль двуточечного азимута |A|';
polarization_pseudocorr.A_magnitude.data = A_magnitude;

% Phi_A - аргумент двуточечного азимута
polarization_pseudocorr.Phi_A = struct();
polarization_pseudocorr.Phi_A.description = 'Аргумент двуточечного азимута Φ(A)';
polarization_pseudocorr.Phi_A.data = Phi_A;

% B_magnitude - модуль двуточечной эллиптичности
polarization_pseudocorr.B_magnitude = struct();
polarization_pseudocorr.B_magnitude.description = 'Модуль двуточечной эллиптичности |B|';
polarization_pseudocorr.B_magnitude.data = B_magnitude;

% Phi_B - аргумент двуточечной эллиптичности
polarization_pseudocorr.Phi_B = struct();
polarization_pseudocorr.Phi_B.description = 'Аргумент двуточечной эллиптичности Φ(B)';
polarization_pseudocorr.Phi_B.data = Phi_B;

fprintf('Расчет псевдокорреляций двуточечных поляризационных параметров завершен!\n');

% === 14. СОХРАНЕНИЕ РЕЗУЛЬТАТОВ В MAT-ФАЙЛЫ ===
save_folder = 'C:\[TOMKA] - Modelling\2.3';

% Создаем папку, если она не существует
if ~exist(save_folder, 'dir')
    mkdir(save_folder);
    fprintf('Создана папка: %s\n', save_folder);
end
% Сохраняем исходные данные
save(fullfile(save_folder, 'delta_all.mat'), 'delta_all');
save(fullfile(save_folder, 'rho_all.mat'), 'rho_all');
fprintf('Сохранены исходные данные: delta_all.mat, rho_all.mat\n');
% Сохраняем результаты псевдокорреляций
save(fullfile(save_folder, 'A_magnitude.mat'), 'A_magnitude');
save(fullfile(save_folder, 'Phi_A.mat'), 'Phi_A');
save(fullfile(save_folder, 'B_magnitude.mat'), 'B_magnitude');
save(fullfile(save_folder, 'Phi_B.mat'), 'Phi_B');
fprintf('Сохранены результаты псевдокорреляций: A_magnitude.mat, Phi_A.mat, B_magnitude.mat, Phi_B.mat\n');
% Сохраняем итоговую структуру с описаниями
save(fullfile(save_folder, 'polarization_pseudocorr.mat'), 'polarization_pseudocorr');
fprintf('Сохранена итоговая структура: polarization_pseudocorr.mat\n');
% Сохраняем дополнительную информацию о расчете
calculation_info = struct();
calculation_info.steps = steps;
calculation_info.map_size = map_size;
calculation_info.epsilon = 1e-10;
calculation_info.calculation_date = datestr(now);
calculation_info.cases = cases;
calculation_info.description = 'Псевдокорреляции двуточечных поляризационных параметров';

save(fullfile(save_folder, 'calculation_info.mat'), 'calculation_info');
fprintf('Сохранена информация о расчете: calculation_info.mat\n');
fprintf('Все файлы сохранены в папку: %s\n', save_folder);

            % % Спочатку обчислюємо коефіцієнти a1-a4, b1-b4
            % a1 = sin(delta1) .* sin(delta2) .* cos(rho1 - rho2) + cos(delta1) .* cos(delta2);
            % b1 = sin(delta1) .* cos(delta2) .* cos(rho1) - cos(delta1) .* sin(delta2) .* cos(rho2);
            % a2 = sin(delta1) .* sin(delta2) .* cos(rho1 + rho2) + cos(delta1) .* cos(delta2);
            % b2 = sin(delta1) .* cos(delta2) .* cos(rho1) - cos(delta1) .* sin(delta2) .* cos(rho2);
            % a3 = sin(delta1) .* sin(delta2) .* sin(rho1 + rho2);
            % b3 = sin(delta1) .* cos(delta2) .* sin(rho1) - cos(delta1) .* sin(delta2) .* sin(rho2);
            % a4 = -sin(delta1) .* cos(delta2) .* sin(rho1) - cos(delta1) .* sin(delta2) .* sin(rho2);
            % b4 = sin(delta1) .* sin(delta2) .* sin(rho1 - rho2);
            % 
            % % ДВОТОЧКОВІ ПОЛЯРИЗАЦІЙНІ ПАРАМЕТРИ АЗИМУТА
            % % |A| = 0.5 * arctan(sqrt(a3² + b3²) / sqrt(a2² + b2²))
            % A_magnitude.(current_case).(key) = 0.5 * atan(sqrt(a3.^2 + b3.^2) ./ sqrt(a2.^2 + b2.^2));
            % % Φ(A) = 0.5 * (a2*a3 - b2*b3) / (a2*b3 - a3*b2)
            % Phi_A.(current_case).(key) = 0.5 * (a2.*a3 - b2.*b3) ./ (a2.*b3 - a3.*b2);
            % 
            % % ДВОТОЧКОВІ ПОЛЯРИЗАЦІЙНІ ПАРАМЕТРИ ЕЛІПТИЧНОСТІ
            % % |B| = 0.5 * arcsin(sqrt(a4² + b4²) / sqrt(a2² + b2²))
            % B_magnitude.(current_case).(key) = 0.5 * asin(sqrt(a4.^2 + b4.^2) ./ sqrt(a2.^2 + b2.^2));
            % % Φ(B) = (a1*b4 - a4*b1) / (a2*b3 - a3*b2)
            % Phi_B.(current_case).(key) = (a1.*b4 - a4.*b1) ./ (a2.*b3 - a3.*b2);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  СТАТИЧНІ МОМЕНТИ %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% РОЗРАХУНОК СТАТИЧНИХ МОМЕНТІВ ДЛЯ A_magnitude, Phi_A, B_magnitude та Phi_B
% Создаем структуры для хранения статистических данных
stat_data_A_magnitude = struct(); % Для A_magnitude
stat_data_Phi_A = struct(); % Для Phi_A
stat_data_B_magnitude = struct(); % Для B_magnitude
stat_data_Phi_B = struct(); % Для Phi_B

% Получаем все случаи (case1, case2, case3, case4)
cases = fieldnames(A_magnitude);

% Внешний цикл по случаям
for case_idx = 1:length(cases)
    current_case = cases{case_idx};
    fprintf('Обработка случая: %s\n', current_case);
    % Получаем все ключи модуляции (m_1, m_5, m_20)
    modulation_keys = fieldnames(A_magnitude.(current_case));
    % Средний цикл по модуляциям
    for mod_idx = 1:length(modulation_keys)
        current_modulation = modulation_keys{mod_idx};
        fprintf('  Обработка модуляции: %s\n', current_modulation);
        % Получаем все шаги (step1, step2, ...)
        step_keys = fieldnames(A_magnitude.(current_case).(current_modulation));
        
        % Внутренний цикл по шагам
        for step_idx = 1:length(step_keys)
            current_step = step_keys{step_idx};
            fprintf('    Обработка шага: %s\n', current_step);
            
            % Создаем структуры в порядке: step → modulation → case
            if ~isfield(stat_data_A_magnitude, current_step)
                stat_data_A_magnitude.(current_step) = struct();
                stat_data_Phi_A.(current_step) = struct();
                stat_data_B_magnitude.(current_step) = struct();
                stat_data_Phi_B.(current_step) = struct();
            end
            
            if ~isfield(stat_data_A_magnitude.(current_step), current_modulation)
                stat_data_A_magnitude.(current_step).(current_modulation) = struct();
                stat_data_Phi_A.(current_step).(current_modulation) = struct();
                stat_data_B_magnitude.(current_step).(current_modulation) = struct();
                stat_data_Phi_B.(current_step).(current_modulation) = struct();
            end
            
            % Получаем матрицы данных для текущего шага
            A_magnitude_matrix = A_magnitude.(current_case).(current_modulation).(current_step);
            Phi_A_matrix = Phi_A.(current_case).(current_modulation).(current_step);
            B_magnitude_matrix = B_magnitude.(current_case).(current_modulation).(current_step);
            Phi_B_matrix = Phi_B.(current_case).(current_modulation).(current_step);  
            % Преобразуем в векторы
            A_magnitude_values = A_magnitude_matrix(:);
            Phi_A_values = Phi_A_matrix(:);
            B_magnitude_values = B_magnitude_matrix(:);
            Phi_B_values = Phi_B_matrix(:);
            % Расчет статистических моментов для A_magnitude
            stat_data_A_magnitude.(current_step).(current_modulation).(current_case).Mean = mean(A_magnitude_values);
            stat_data_A_magnitude.(current_step).(current_modulation).(current_case).Dispersion = var(A_magnitude_values);
            stat_data_A_magnitude.(current_step).(current_modulation).(current_case).Asymmetry = skewness(A_magnitude_values);
            stat_data_A_magnitude.(current_step).(current_modulation).(current_case).Excess = kurtosis(A_magnitude_values);
            % Расчет статистических моментов для Phi_A
            stat_data_Phi_A.(current_step).(current_modulation).(current_case).Mean = mean(Phi_A_values);
            stat_data_Phi_A.(current_step).(current_modulation).(current_case).Dispersion = var(Phi_A_values);
            stat_data_Phi_A.(current_step).(current_modulation).(current_case).Asymmetry = skewness(Phi_A_values);
            stat_data_Phi_A.(current_step).(current_modulation).(current_case).Excess = kurtosis(Phi_A_values);
            % Расчет статистических моментов для B_magnitude
            stat_data_B_magnitude.(current_step).(current_modulation).(current_case).Mean = mean(B_magnitude_values);
            stat_data_B_magnitude.(current_step).(current_modulation).(current_case).Dispersion = var(B_magnitude_values);
            stat_data_B_magnitude.(current_step).(current_modulation).(current_case).Asymmetry = skewness(B_magnitude_values);
            stat_data_B_magnitude.(current_step).(current_modulation).(current_case).Excess = kurtosis(B_magnitude_values);
            % Расчет статистических моментов для Phi_B
            stat_data_Phi_B.(current_step).(current_modulation).(current_case).Mean = mean(Phi_B_values);
            stat_data_Phi_B.(current_step).(current_modulation).(current_case).Dispersion = var(Phi_B_values);
            stat_data_Phi_B.(current_step).(current_modulation).(current_case).Asymmetry = skewness(Phi_B_values);
            stat_data_Phi_B.(current_step).(current_modulation).(current_case).Excess = kurtosis(Phi_B_values);
        end  
        fprintf('  Завершена обработка модуляции %s\n', current_modulation);
    end 
    fprintf('Завершена обработка случая %s\n', current_case);
end
fprintf('Расчет статических моментов завершен!\n');

% Примеры доступа к данным (новый формат):
% stat_data_A_magnitude.step1.m_1.case1.Mean
% stat_data_A_magnitude.step3.m_5.case2.Dispersion
% stat_data_Phi_A.step2.m_20.case1.Asymmetry
% stat_data_Phi_A.step1.m_1.case4.Excess
% stat_data_B_magnitude.step2.m_5.case3.Mean
% stat_data_B_magnitude.step4.m_20.case1.Dispersion
% stat_data_Phi_B.step3.m_1.case2.Asymmetry
% stat_data_Phi_B.step1.m_5.case4.Excess

%% СТВОРЕННЯ ТА ЗБЕРЕЖЕННЯ ФАЙЛІВ ІЗ СТАТИСТИЧНИМИ МОМЕНТАМИ ДЛЯ КОЖНОГО КРОКУ ТА МОДУЛЯЦІЇ
% Створення основної папки якщо вона не існує
outputDir = 'C:\[TOMKA] - Modelling\ЕТАП №02 - порівняння чутливості\2.3';
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% Групування структур для створення двох файлів
group1_structures = {'stat_data_A_magnitude', 'stat_data_Phi_A'};
group1_titles = {'|А|', 'Ф(A)'};
group2_structures = {'stat_data_B_magnitude', 'stat_data_Phi_B'};
group2_titles = {'|B|', 'Ф(B)'};

groups = {group1_structures, group2_structures};
group_titles = {group1_titles, group2_titles};
group_names = {'Двоточковий азимут', 'Двоточкова еліптичність'};

% Цикл по кожній групі структур
for group_idx = 1:length(groups)
    current_group_structures = groups{group_idx};
    current_group_titles = group_titles{group_idx};
    current_group_name = group_names{group_idx};
    % Створення папки для поточної групи
    group_folder = fullfile(outputDir, current_group_name);
    if ~exist(group_folder, 'dir')
        mkdir(group_folder);
    end
    % Отримання всіх ключів кроків (з першої структури групи)
    first_struct = eval(current_group_structures{1});
    step_keys = fieldnames(first_struct);
    
    % Цикл по кожному кроку
    for step_idx = 1:length(step_keys)
        current_step = step_keys{step_idx};
        % Створення папки для поточного кроку
        step_folder = fullfile(group_folder, current_step);
        if ~exist(step_folder, 'dir')
            mkdir(step_folder);
        end
        % Отримання всіх ключів модуляції
        modulation_keys = fieldnames(first_struct.(current_step));
        % Цикл по кожній модуляції
        for mod_idx = 1:length(modulation_keys)
            current_modulation = modulation_keys{mod_idx};
            % Створення підпапки для поточної модуляції
            modulation_folder = fullfile(step_folder, current_modulation);
            if ~exist(modulation_folder, 'dir')
                mkdir(modulation_folder);
            end
            % Формування імені файлу
            filename = fullfile(modulation_folder, sprintf('таблиця_моментів_%s_%s_%s.txt', current_group_name, current_step, current_modulation));
            % Відкриття файлу для запису
            fid = fopen(filename, 'w', 'n', 'UTF-8');
            if fid == -1
                error('Не вдалося створити файл: %s', filename);
            end
            % Заголовок таблиці
            fprintf(fid, 'Таблиця статистичних моментів для %s -> %s -> %s\n', current_group_name, current_step, current_modulation);
            fprintf(fid, 'Створено: %s\n\n', datestr(datetime('now'), 'yyyy-mm-dd HH:MM:SS'));
            % Цикл по структурах у групі
            for struct_idx = 1:length(current_group_structures)
                current_struct_name = current_group_structures{struct_idx};
                current_title = current_group_titles{struct_idx};
                
                % Отримання поточної структури
                current_struct = eval(current_struct_name);  
                % Заголовок для поточної структури
                %fprintf(fid, '=== %s ===\n', current_title);
                % Верхня межа таблиці
                fprintf(fid, '│%17s│%17s│%17s│%17s│%17s│\n', ...
                    '================', '================', '================', '================', '================');
                % Заголовок стовпців
                fprintf(fid, '│%17s│%17s│%17s│%17s│%17s│\n', ...
                    '', 'Case1', 'Case2', 'Case3', 'Case4');
                % Верхня межа таблиці
                fprintf(fid, '│%17s│%17s│%17s│%17s│%17s│\n', ...
                    '================', '================', '================', '================', '================');
                % Заголовок стовпців з параметрами
                fprintf(fid, '│%17s│%17s│%17s│%17s│%17s│\n', ...
                    'Моменти', sprintf('%s(m×n,δ,ρ)', current_title), sprintf('%s(m×n,δ,ρ~)', current_title), sprintf('%s(m×n,δ,ρ*)', current_title), sprintf('%s(m×n,δ,ρ**)', current_title));
                % Роздільник заголовка
                fprintf(fid, '│%17s│%17s│%17s│%17s│%17s│\n', ...
                    '================', '================', '================', '================', '================');
                % Рядок "Середнє"
                fprintf(fid, '│%17s│%17f│%17f│%17f│%17f│\n', ...
                    'Середнє', ...
                    current_struct.(current_step).(current_modulation).case1.Mean, ...
                    current_struct.(current_step).(current_modulation).case2.Mean, ...
                    current_struct.(current_step).(current_modulation).case3.Mean, ...
                    current_struct.(current_step).(current_modulation).case4.Mean);
                % Рядок "Дисперсія"
                fprintf(fid, '│%17s│%17f│%17f│%17f│%17f│\n', ...
                    'Дисперсія', ...
                    current_struct.(current_step).(current_modulation).case1.Dispersion, ...
                    current_struct.(current_step).(current_modulation).case2.Dispersion, ...
                    current_struct.(current_step).(current_modulation).case3.Dispersion, ...
                    current_struct.(current_step).(current_modulation).case4.Dispersion);
                % Рядок "Асиметрія"
                fprintf(fid, '│%17s│%17f│%17f│%17f│%17f│\n', ...
                    'Асиметрія', ...
                    current_struct.(current_step).(current_modulation).case1.Asymmetry, ...
                    current_struct.(current_step).(current_modulation).case2.Asymmetry, ...
                    current_struct.(current_step).(current_modulation).case3.Asymmetry, ...
                    current_struct.(current_step).(current_modulation).case4.Asymmetry); 
                % Рядок "Ексцес"
                fprintf(fid, '│%17s│%17f│%17f│%17f│%17f│\n', ...
                    'Ексцес', ...
                    current_struct.(current_step).(current_modulation).case1.Excess, ...
                    current_struct.(current_step).(current_modulation).case2.Excess, ...
                    current_struct.(current_step).(current_modulation).case3.Excess, ...
                    current_struct.(current_step).(current_modulation).case4.Excess); 
                % Нижня межа таблиці
                fprintf(fid, '│%17s│%17s│%17s│%17s│%17s│\n', ...
                    '================', '================', '================', '================', '================');
                % Додаткові відступи між таблицями
                if struct_idx < length(current_group_structures)
                    fprintf(fid, '\n\n');
                end
            end    
            % Закриття файлу
            fclose(fid);   
            % Вивід інформації про створений файл
            fprintf('Таблиця для %s -> %s -> %s успішно створена!\n', current_group_name, current_step, current_modulation);
            fprintf('Файл збережено: %s\n', filename);
        end
    end
end
fprintf('\nВсі таблиці успішно створені!\n');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  ЗБЕРЕЖЕННЯ ФІГУР %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% БЛОК СТВОРЕННЯ 2D ВІЗУАЛІЗАЦІЇ ДЛЯ A і B
% Основна папка для збереження (та ж що і для статистичних моментів)
outputDir = 'C:\[TOMKA] - Modelling\ЕТАП №02 - порівняння чутливості\2.3';

group_names = {'Двоточковий азимут', 'Двоточкова еліптичність'};
elevation_angle = 25;     % Кут нахилу камери
azimuth_angle = 45;       % Кут поворота камери
lighting_style = 'gouraud'; % Стиль освітлення
alpha_value = 0.8;        % Прозорість поверхні


% Групи назв для збереження
group_names = {'Двоточковий азимут', 'Двоточкова еліптичність'};
% Получаем все случаи (case1, case2, case3, case4)
cases = fieldnames(A_magnitude);

% Внешний цикл по случаям
for case_idx = 1:length(cases)
    current_case = cases{case_idx};
    fprintf('Обработка случая: %s\n', current_case);
    
    % Получаем все ключи модуляции (m_1, m_5, m_20)
    modulation_keys = fieldnames(A_magnitude.(current_case));
    % Средний цикл по модуляциям
    for mod_idx = 1:length(modulation_keys)
        current_modulation = modulation_keys{mod_idx};
        fprintf(' Обработка модуляции: %s\n', current_modulation);
        
        % Получаем все шаги (step1, step2, ...)
        step_keys = fieldnames(A_magnitude.(current_case).(current_modulation));
        % Внутренний цикл по шагам
        for step_idx = 1:length(step_keys)
            current_step = step_keys{step_idx};
            fprintf('  Обработка шага: %s\n', current_step);
            
            % Получаем матрицы данных для текущего шага
            A_magnitude_matrix = A_magnitude.(current_case).(current_modulation).(current_step);
            Phi_A_matrix = Phi_A.(current_case).(current_modulation).(current_step);
            B_magnitude_matrix = B_magnitude.(current_case).(current_modulation).(current_step);
            Phi_B_matrix = Phi_B.(current_case).(current_modulation).(current_step);
            
            % ----------------------------------------------------------
            % === ФІГУРА 1: Двоточковий азимут (A_magnitude і Phi_A) ===
            % ----------------------------------------------------------
            figure('Name', sprintf('2D-представлення %s для %s -> %s -> %s', group_names{1}, current_step, current_modulation, current_case));
            set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
            subplot(1, 2, 1);
            imagesc(A_magnitude_matrix);
            axis image;
            colormap(colormap_value);
            colorbar;
            xlabel('\Delta x');
            ylabel('\Delta y');
            title('|А|', 'Interpreter', 'none');
            grid on; 
            set(gca, 'GridAlpha', 0.2);
            subplot(1, 2, 2);
            imagesc(Phi_A_matrix);
            axis image;
            colormap(colormap_value);
            colorbar;
            xlabel('\Delta x');
            ylabel('\Delta y');
            title('Ф(A)', 'Interpreter', 'none');
            grid on; 
            set(gca, 'GridAlpha', 0.2);
                group_folder = fullfile(outputDir, group_names{1});
                step_folder = fullfile(group_folder, current_step);
                modulation_folder = fullfile(step_folder, current_modulation);
                filename1 = fullfile(modulation_folder, sprintf('%s_2D_візуалізація_%s_%s_%s_%s.png', ...
                    colormap_value, strrep(group_names{1}, ' ', '_'), current_step, current_modulation, current_case));
                
                saveas(gcf, filename1);
                close(gcf);
            % ----------------------------------------------------------
            % === ФІГУРА 2: Двоточкова еліптичність (B_magnitude і Phi_B) ===
            % ----------------------------------------------------------
            figure('Name', sprintf('2D-представлення %s для %s -> %s -> %s', group_names{2}, current_step, current_modulation, current_case));
            set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
            subplot(1, 2, 1);
            imagesc(B_magnitude_matrix);
            axis image;
            colormap(colormap_value);
            colorbar;
            xlabel('\Delta x');
            ylabel('\Delta y');
            title('|B|', 'Interpreter', 'none');
            grid on; 
            set(gca, 'GridAlpha', 0.2);
            subplot(1, 2, 2);
            imagesc(Phi_B_matrix);
            axis image;
            colormap(colormap_value);
            colorbar;
            xlabel('\Delta x');
            ylabel('\Delta y');
            title('Ф(B)', 'Interpreter', 'none');
            grid on; 
            set(gca, 'GridAlpha', 0.2);
                group_folder = fullfile(outputDir, group_names{2});
                step_folder = fullfile(group_folder, current_step);
                modulation_folder = fullfile(step_folder, current_modulation);
                filename2 = fullfile(modulation_folder, sprintf('%s_2D_візуалізація_%s_%s_%s_%s.png', ...
                    colormap_value, strrep(group_names{2}, ' ', '_'), current_step, current_modulation, current_case));
                saveas(gcf, filename2);
                close(gcf);               
                fprintf('   2D візуалізації для %s -> %s -> %s успішно збережені!\n', ...
                    current_step, current_modulation, current_case);

            % ----------------------------------------------------------
            % === ФІГУРА 3: 3D. Двоточковий азимут (A_magnitude і Phi_A) ===
            % ----------------------------------------------------------
            % Создаем координатные сетки
            [X, Y] = meshgrid(1:size(A_magnitude_matrix, 2), 1:size(A_magnitude_matrix, 1));
            
            figure('Name', sprintf('3D-представлення %s для %s -> %s -> %s', group_names{1}, current_step, current_modulation, current_case));
            set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
            set(gcf, 'Color', 'white');
            subplot(1, 2, 1);
            surf(X, Y, A_magnitude_matrix, 'FaceAlpha', alpha_value, 'EdgeColor', 'none');
            % Настройка освещения и внешнего вида
            colormap(colormap_value);
            colorbar('Location', 'eastoutside');
            shading interp;
            lighting(lighting_style);
            % Добавляем источники света
            light('Position', [1 1 1], 'Style', 'infinite');
            light('Position', [-1 -1 1], 'Style', 'infinite', 'Color', [0.3 0.3 0.3]);
            % Настройка осей и меток
            xlabel('\Delta x', 'FontSize', 12, 'FontWeight', 'bold');
            ylabel('\Delta y', 'FontSize', 12, 'FontWeight', 'bold');
            zlabel('|A|', 'FontSize', 12, 'FontWeight', 'bold');
            title('3D поверхня |А|', 'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'none');
            % Установка ракурса
            view(azimuth_angle, elevation_angle);
            % Улучшение сетки
            grid on;
            set(gca, 'GridAlpha', 0.3, 'GridColor', [0.5 0.5 0.5]);
            axis tight;
            subplot(1, 2, 2);
            surf(X, Y, Phi_A_matrix, 'FaceAlpha', alpha_value, 'EdgeColor', 'none');
            % Настройка освещения и внешнего вида
            colormap(colormap_value);
            colorbar('Location', 'eastoutside');
            shading interp;
            lighting(lighting_style);
            % Добавляем источники света
            light('Position', [1 1 1], 'Style', 'infinite');
            light('Position', [-1 -1 1], 'Style', 'infinite', 'Color', [0.3 0.3 0.3]);
            % Настройка осей и меток
            xlabel('\Delta x', 'FontSize', 12, 'FontWeight', 'bold');
            ylabel('\Delta y', 'FontSize', 12, 'FontWeight', 'bold');
            zlabel('Ф(A)', 'FontSize', 12, 'FontWeight', 'bold');
            title('3D поверхня Ф(A)', 'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'none');
            % Установка ракурса
            view(azimuth_angle, elevation_angle);
            % Улучшение сетки
            grid on;
            set(gca, 'GridAlpha', 0.3, 'GridColor', [0.5 0.5 0.5]);
            axis tight;
                % Збереження фігури 1
                group_folder = fullfile(outputDir, group_names{1});
                step_folder = fullfile(group_folder, current_step);
                modulation_folder = fullfile(step_folder, current_modulation);
                % Создаем папки если их нет
                if ~exist(modulation_folder, 'dir')
                    mkdir(modulation_folder);
                end
                filename1 = fullfile(modulation_folder, sprintf('%s_3D_візуалізація_%s_%s_%s_%s.png', ...
                    colormap_value, strrep(group_names{1}, ' ', '_'), current_step, current_modulation, current_case));
                saveas(gcf, filename1);
                close(gcf);
            
            % ----------------------------------------------------------
            % === ФІГУРА 4: 3D. Двоточкова еліптичність (B_magnitude і Phi_B) ===
            % ----------------------------------------------------------
            figure('Name', sprintf('3D-представлення %s для %s -> %s -> %s', group_names{2}, current_step, current_modulation, current_case));
            set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
            set(gcf, 'Color', 'white');
            subplot(1, 2, 1);
            surf(X, Y, B_magnitude_matrix, 'FaceAlpha', alpha_value, 'EdgeColor', 'none');
            % Настройка освещения и внешнего вида
            colormap(colormap_value);
            colorbar('Location', 'eastoutside');
            shading interp;
            lighting(lighting_style);
            % Добавляем источники света
            light('Position', [1 1 1], 'Style', 'infinite');
            light('Position', [-1 -1 1], 'Style', 'infinite', 'Color', [0.3 0.3 0.3]);
            % Настройка осей и меток
            xlabel('\Delta x', 'FontSize', 12, 'FontWeight', 'bold');
            ylabel('\Delta y', 'FontSize', 12, 'FontWeight', 'bold');
            zlabel('|B|', 'FontSize', 12, 'FontWeight', 'bold');
            title('3D поверхня |B|', 'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'none');
            % Установка ракурса
            view(azimuth_angle, elevation_angle);
            % Улучшение сетки
            grid on;
            set(gca, 'GridAlpha', 0.3, 'GridColor', [0.5 0.5 0.5]);
            axis tight;
            % Субплот 2: 3D Phi_B
            subplot(1, 2, 2);
            surf(X, Y, Phi_B_matrix, 'FaceAlpha', alpha_value, 'EdgeColor', 'none');
            % Настройка освещения и внешнего вида
            colormap(colormap_value);
            colorbar('Location', 'eastoutside');
            shading interp;
            lighting(lighting_style);
            % Добавляем источники света
            light('Position', [1 1 1], 'Style', 'infinite');
            light('Position', [-1 -1 1], 'Style', 'infinite', 'Color', [0.3 0.3 0.3]);
            % Настройка осей и меток
            xlabel('\Delta x', 'FontSize', 12, 'FontWeight', 'bold');
            ylabel('\Delta y', 'FontSize', 12, 'FontWeight', 'bold');
            zlabel('Ф(B)', 'FontSize', 12, 'FontWeight', 'bold');
            title('3D поверхня Ф(B)', 'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'none');
            % Установка ракурса
            view(azimuth_angle, elevation_angle);
            % Улучшение сетки
            grid on;
            set(gca, 'GridAlpha', 0.3, 'GridColor', [0.5 0.5 0.5]);
            axis tight;
                % Збереження фігури 4
                group_folder = fullfile(outputDir, group_names{2});
                step_folder = fullfile(group_folder, current_step);
                modulation_folder = fullfile(step_folder, current_modulation);
                % Создаем папки если их нет
                if ~exist(modulation_folder, 'dir')
                    mkdir(modulation_folder);
                end
                
                filename2 = fullfile(modulation_folder, sprintf('%s_3D_візуалізація_%s_%s_%s_%s.png', ...
                    colormap_value, strrep(group_names{2}, ' ', '_'), current_step, current_modulation, current_case));
                
                saveas(gcf, filename2);
                close(gcf);
                
                fprintf('   3D візуалізації для %s -> %s -> %s успішно збережені!\n', ...
                    current_step, current_modulation, current_case);
        end
    end
end