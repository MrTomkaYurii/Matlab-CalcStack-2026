clear;
clc;

    % Создаем большие структуры для хранения всех данных
    delta_all = struct();
    rho_all = struct();
    alpha_all = struct();
    beta_all = struct();
    colormap_value = 'parula';

    %% РАСЧЕТ АЛЬФА и БЕТТА
    % Вызываем функцию для каждого случая и сохраняем в большие структуры
    [delta_all.case1, rho_all.case1] = harmonic_modulation(colormap_value, 400, [1, 5, 20], 'C:/[TOMKA] - Modelling/2.2', 1);
    [delta_all.case2, rho_all.case2] = harmonic_modulation(colormap_value, 400, [1, 5, 20], 'C:/[TOMKA] - Modelling/2.2', 2);
    [delta_all.case3, rho_all.case3] = harmonic_modulation(colormap_value, 400, [1, 5, 20], 'C:/[TOMKA] - Modelling/2.2', 3);
    [delta_all.case4, rho_all.case4] = harmonic_modulation(colormap_value, 400, [1, 5, 20], 'C:/[TOMKA] - Modelling/2.2', 4);
    % Получаем все случаи (case1, case2, case3, case4)
    cases = fieldnames(delta_all);
    % Проходим по всем случаям
    for case_idx = 1:length(cases)
        current_case = cases{case_idx};
        % Инициализируем структуры для текущего случая
        alpha_all.(current_case) = struct();
        beta_all.(current_case) = struct();
        % Получаем все ключи модуляции (m_1, m_5, m_20)
        modulation_keys = fieldnames(delta_all.(current_case));
         % Проходим по всем ключам модуляции
        for mod_idx = 1:length(modulation_keys)
            key = modulation_keys{mod_idx};
            % Получаем delta и rho для текущего случая и модуляции
            delta = delta_all.(current_case).(key);
            rho = rho_all.(current_case).(key);
            % --------------------------------------------------------------------
            % --------------------------------------------------------------------
            % % Расчет alpha и beta (ОДНОТОЧКОВІ - ВАРІАНТ 1)
            % % α = 0.5 * arctan(sin²δ * sin4ρ / (cos²δ + sin²δ * cos4ρ))
            % % β = 0.5 * arcsin(sin2δ * sin2ρ)
            % numerator = sin(delta).^2 .* sin(4*rho);
            % denominator = cos(delta).^2 + sin(delta).^2 .* cos(4*rho);
            % alpha_all.(current_case).(key) = 0.5 * atan(numerator ./ denominator);
            % beta_all.(current_case).(key) = 0.5 * asin(sin(2*delta) .* sin(2*rho));


            % Расчет alpha и beta (ОДНОТОЧКОВІ - ВАРІАНТ 2)
            % α = 0.5 * arctan(δ² * sin4ρ / (1 + δ² * cos4ρ))
            % β = 0.5 * arcsin(2δ * sin2ρ)
            numerator = delta.^2 .* sin(4*rho);
            denominator = 1 + delta.^2 .* cos(4*rho);
            alpha_all.(current_case).(key) = 0.5 * atan(numerator ./ denominator);
            % Обмежуємо аргумент asin до діапазону [-1, 1] (Фізично параметр β повинен бути реальним, тому обмеження до [-1, 1] є правильним підходом - воно запобігає нефізичним комплексним значенням.)
            beta_arg = 2*delta .* sin(2*rho);
            beta_arg = max(-1, min(1, beta_arg)); % Обмежуємо до [-1, 1]
            beta_all.(current_case).(key) = 0.5 * asin(beta_arg);

            % --------------------------------------------------------------------
            % --------------------------------------------------------------------
        end
    end
    % Теперь можно получить доступ к результатам:
    % alpha_all.case1.m_1  - alpha для случая 1, модуляция m=1
    % alpha_all.case2.m_5  - alpha для случая 2, модуляция m=5
    % beta_all.case3.m_20  - beta для случая 3, модуляция m=20
    % beta_all.case4.m_5  - beta для случая 4, модуляция m=5

        %% СТВОРЕННЯ 2D РОЗПОДІЛІВ ДЛЯ КОЖНОЇ МОДУЛЯЦІЇ ТА ПАРАМЕТРА
        % Створення основної папки якщо вона не існує
        outputDir = 'C:/[TOMKA] - Modelling/2.2';
        if ~exist(outputDir, 'dir')
            mkdir(outputDir);
        end
        % Отримання всіх ключів модуляції
        modulation_keys = fieldnames(delta_all.case1);
        % Зовнішній цикл по модуляціям
        for mod_idx = 1:length(modulation_keys)
            current_modulation = modulation_keys{mod_idx};
            % Витягуємо номер модуляції (1, 5, 20)
            modulation_number = current_modulation(3:end);
            % Створення папки для поточної модуляції
            modulation_folder = fullfile(outputDir, sprintf('m = %s', modulation_number));
            if ~exist(modulation_folder, 'dir')
                mkdir(modulation_folder);
            end
            % Отримання всіх випадків (case1, case2, case3, case4)
            cases = fieldnames(delta_all);
            % Цикл по всім випадкам
            for case_idx = 1:length(cases)
                current_case = cases{case_idx};
                % Отримання матриць для поточного випадку та модуляції
                delta_matrix = delta_all.(current_case).(current_modulation);
                rho_matrix = rho_all.(current_case).(current_modulation);
                alpha_matrix = alpha_all.(current_case).(current_modulation);
                beta_matrix = beta_all.(current_case).(current_modulation);
                % Номер випадку для назви файлу
                case_number = current_case(end);
                
                %---------------------------------------------------------------
                % ПОБУДОВА 2D РОЗПОДІЛУ ДЛЯ DELTA
                figure('Visible', 'on'); set(gcf, 'WindowState', 'maximized');
                imagesc(delta_matrix);
                colorbar;
                title(sprintf('2D розподіл Delta для %s, m=%s', current_case, modulation_number));
                xlabel('Індекс по X');
                ylabel('Індекс по Y');
                colormap(colormap_value);
                grid on; axis image;
                filename_delta = fullfile(modulation_folder, sprintf('%s_Delta_Case%s_m%s.png', colormap_value, case_number, modulation_number));
                saveas(gcf, filename_delta);
                close(gcf);
                %---------------------------------------------------------------
                % ПОБУДОВА 2D РОЗПОДІЛУ ДЛЯ RHO
                figure('Visible', 'on'); set(gcf, 'WindowState', 'maximized');
                imagesc(rho_matrix);
                colorbar;
                title(sprintf('2D розподіл Rho для %s, m=%s', current_case, modulation_number));
                xlabel('Індекс по X');
                ylabel('Індекс по Y');
                colormap(colormap_value);
                grid on; axis image;
                filename_rho = fullfile(modulation_folder, sprintf('%s_Rho_Case%s_m%s.png', colormap_value, case_number, modulation_number));
                saveas(gcf, filename_rho);
                close(gcf);
                %---------------------------------------------------------------
                % ПОБУДОВА 2D РОЗПОДІЛУ ДЛЯ ALPHA
                figure('Visible', 'on'); set(gcf, 'WindowState', 'maximized');
                imagesc(alpha_matrix);
                colorbar;
                title(sprintf('2D розподіл Alpha для %s, m=%s', current_case, modulation_number));
                xlabel('Індекс по X');
                ylabel('Індекс по Y');
                colormap(colormap_value);
                grid on; axis image;
                filename_alpha = fullfile(modulation_folder, sprintf('%s_Alpha_Case%s_m%s.png', colormap_value, case_number, modulation_number));
                saveas(gcf, filename_alpha);
                close(gcf);
                %---------------------------------------------------------------
                % ПОБУДОВА 2D РОЗПОДІЛУ ДЛЯ BETA
                figure('Visible', 'on'); set(gcf, 'WindowState', 'maximized');
                imagesc(beta_matrix);
                colorbar;
                title(sprintf('2D розподіл Beta для %s, m=%s', current_case, modulation_number));
                xlabel('Індекс по X');
                ylabel('Індекс по Y');
                colormap(colormap_value);
                grid on; axis image;
                filename_beta = fullfile(modulation_folder, sprintf('%s_Beta_Case%s_m%s.png', colormap_value, case_number, modulation_number));
                saveas(gcf, filename_beta);
                close(gcf);
                fprintf('  Створено зображення для %s\n', current_case);
            end
            fprintf('Завершено обробку модуляції %s\n', current_modulation);
        end
        fprintf('\nВсі 2D розподіли створено успішно!\n');


        %% СТВОРЕННЯ 3D РОЗПОДІЛІВ
        % Створення основної папки якщо вона не існує
        outputDir = 'C:/[TOMKA] - Modelling/2.2';
        if ~exist(outputDir, 'dir')
            mkdir(outputDir);
        end
        % Отримання всіх ключів модуляції
        modulation_keys = fieldnames(delta_all.case1);
        % Зовнішній цикл по модуляціям
        for mod_idx = 1:length(modulation_keys)
            current_modulation = modulation_keys{mod_idx};
            % Витягуємо номер модуляції (1, 5, 20)
            modulation_number = current_modulation(3:end);
            % Створення папки для поточної модуляції
            modulation_folder = fullfile(outputDir, sprintf('m = %s', modulation_number));
            if ~exist(modulation_folder, 'dir')
                mkdir(modulation_folder);
            end
            fprintf('Обробка 3D модуляції %s...\n', current_modulation);
            % Отримання всіх випадків (case1, case2, case3, case4)
            cases = fieldnames(delta_all);
            % Цикл по всім випадкам
            for case_idx = 1:length(cases)
                current_case = cases{case_idx};
                % Отримання матриць для поточного випадку та модуляції
                delta_matrix = delta_all.(current_case).(current_modulation);
                rho_matrix = rho_all.(current_case).(current_modulation);
                alpha_matrix = alpha_all.(current_case).(current_modulation);
                beta_matrix = beta_all.(current_case).(current_modulation);
                % Номер випадку для назви файлу
                case_number = current_case(end);
                % Створення координатних сіток
                [rows, cols] = size(delta_matrix);
                [X, Y] = meshgrid(1:cols, 1:rows);
                %---------------------------------------------------------------
                % ПОБУДОВА 3D РОЗПОДІЛУ ДЛЯ DELTA
                figure('Visible', 'on');
                set(gcf, 'WindowState', 'maximized');
                set(gcf, 'Color', 'white');
                % Основна 3D поверхня
                surf(X, Y, delta_matrix, 'EdgeColor', 'none', 'FaceAlpha', 0.9);
                hold on;
                % Додаткові контурні лінії на поверхні
                % contour3(X, Y, delta_matrix, 15, 'LineWidth', 1.5);
                % Налаштування осей та підписів
                xlabel('X координата', 'FontSize', 12, 'FontWeight', 'bold');
                ylabel('Y координата', 'FontSize', 12, 'FontWeight', 'bold');
                zlabel('Delta значення', 'FontSize', 12, 'FontWeight', 'bold');
                title(sprintf('3D розподіл Delta для %s, m=%s', current_case, modulation_number), ...
                    'FontSize', 12, 'FontWeight', 'bold');
                % Колірна карта та панель
                colormap(colormap_value);
                c = colorbar;
                c.Label.String = 'Delta значення';
                c.Label.FontSize = 12;
                c.Label.FontWeight = 'bold';
                % Налаштування сіток
                grid on;
                set(gca, 'GridColor', [0.3 0.3 0.3], 'GridAlpha', 0.6);
                set(gca, 'MinorGridColor', [0.5 0.5 0.5], 'MinorGridAlpha', 0.3);
                % Освітлення
                % light('Position', [1 1 1], 'Style', 'infinite');
                % light('Position', [-1 -1 -1], 'Style', 'infinite');
                % lighting gouraud;
                % material shiny;
                % Налаштування перспективи
                view(45, 30);
                axis tight;
                % Збереження Delta 3D
                filename_delta_3d = fullfile(modulation_folder, sprintf('%s_Delta_3D_Case%s_m%s.png', colormap_value, case_number, modulation_number));
                print(gcf, filename_delta_3d, '-dpng', '-r300');
                close(gcf);
                %---------------------------------------------------------------
                % ПОБУДОВА 3D РОЗПОДІЛУ ДЛЯ RHO
                figure('Visible', 'on');
                set(gcf, 'WindowState', 'maximized');
                set(gcf, 'Color', 'white');
                surf(X, Y, rho_matrix, 'EdgeColor', 'none', 'FaceAlpha', 0.9);
                hold on;
                %contour3(X, Y, rho_matrix, 15, 'LineWidth', 1.5);
                xlabel('X координата', 'FontSize', 12, 'FontWeight', 'bold');
                ylabel('Y координата', 'FontSize', 12, 'FontWeight', 'bold');
                zlabel('Rho значення', 'FontSize', 12, 'FontWeight', 'bold');
                title(sprintf('3D розподіл Rho для %s, m=%s', current_case, modulation_number), ...
                    'FontSize', 12, 'FontWeight', 'bold');
                colormap(colormap_value);
                c = colorbar;
                c.Label.String = 'Rho значення';
                c.Label.FontSize = 12;
                c.Label.FontWeight = 'bold';
                grid on;
                set(gca, 'GridColor', [0.3 0.3 0.3], 'GridAlpha', 0.6);
                set(gca, 'MinorGridColor', [0.5 0.5 0.5], 'MinorGridAlpha', 0.3);
                % light('Position', [1 1 1], 'Style', 'infinite');
                % light('Position', [-1 -1 -1], 'Style', 'infinite');
                % lighting gouraud;
                % material shiny;
                view(45, 30);
                axis tight;
                filename_rho_3d = fullfile(modulation_folder, sprintf('%s_Rho_3D_Case%s_m%s.png', colormap_value, case_number, modulation_number));
                print(gcf, filename_rho_3d, '-dpng', '-r300');
                close(gcf);
                %---------------------------------------------------------------
                % ПОБУДОВА 3D РОЗПОДІЛУ ДЛЯ ALPHA
                figure('Visible', 'on');
                set(gcf, 'WindowState', 'maximized');
                set(gcf, 'Color', 'white');
                surf(X, Y, alpha_matrix, 'EdgeColor', 'none', 'FaceAlpha', 0.9);
                hold on;
                %contour3(X, Y, alpha_matrix, 15, 'LineWidth', 1.5);
                xlabel('X координата', 'FontSize', 12, 'FontWeight', 'bold');
                ylabel('Y координата', 'FontSize', 12, 'FontWeight', 'bold');
                zlabel('Alpha значення', 'FontSize', 12, 'FontWeight', 'bold');
                title(sprintf('3D розподіл Alpha для %s, m=%s', current_case, modulation_number), ...
                    'FontSize', 12, 'FontWeight', 'bold');
                colormap(colormap_value);
                c = colorbar;
                c.Label.String = 'Alpha значення';
                c.Label.FontSize = 12;
                c.Label.FontWeight = 'bold';
                grid on;
                set(gca, 'GridColor', [0.3 0.3 0.3], 'GridAlpha', 0.6);
                set(gca, 'MinorGridColor', [0.5 0.5 0.5], 'MinorGridAlpha', 0.3);
                % light('Position', [1 1 1], 'Style', 'infinite');
                % light('Position', [-1 -1 -1], 'Style', 'infinite');
                % lighting gouraud;
                % material shiny;
                view(45, 30);
                axis tight;
                filename_alpha_3d = fullfile(modulation_folder, sprintf('%s_Alpha_3D_Case%s_m%s.png', colormap_value, case_number, modulation_number));
                print(gcf, filename_alpha_3d, '-dpng', '-r300');
                close(gcf);
                %---------------------------------------------------------------
                % ПОБУДОВА 3D РОЗПОДІЛУ ДЛЯ BETA
                figure('Visible', 'on');
                set(gcf, 'WindowState', 'maximized');
                set(gcf, 'Color', 'white');
                surf(X, Y, beta_matrix, 'EdgeColor', 'none', 'FaceAlpha', 0.9);
                hold on;
                %contour3(X, Y, beta_matrix, 15, 'LineWidth', 1.5);
                xlabel('X координата', 'FontSize', 12, 'FontWeight', 'bold');
                ylabel('Y координата', 'FontSize', 12, 'FontWeight', 'bold');
                zlabel('Beta значення', 'FontSize', 12, 'FontWeight', 'bold');
                title(sprintf('3D розподіл Beta для %s, m=%s', current_case, modulation_number), ...
                    'FontSize', 12, 'FontWeight', 'bold');
                colormap(colormap_value);
                c = colorbar;
                c.Label.String = 'Beta значення';
                c.Label.FontSize = 12;
                c.Label.FontWeight = 'bold';
                grid on;
                set(gca, 'GridColor', [0.3 0.3 0.3], 'GridAlpha', 0.6);
                set(gca, 'MinorGridColor', [0.5 0.5 0.5], 'MinorGridAlpha', 0.3);
                % light('Position', [1 1 1], 'Style', 'infinite');
                % light('Position', [-1 -1 -1], 'Style', 'infinite');
                % lighting gouraud;
                % material shiny;
                view(45, 30);
                axis tight;
                filename_beta_3d = fullfile(modulation_folder, sprintf('%s_Beta_3D_Case%s_m%s.png', colormap_value, case_number, modulation_number));
                print(gcf, filename_beta_3d, '-dpng', '-r300');
                close(gcf);
                fprintf('  Створено 3D зображення для %s\n', current_case);
            end
            fprintf('Завершено обробку 3D модуляції %s\n', current_modulation);
        end
        fprintf('\nВсі 3D розподіли створено успішно!\n');



    %% РОЗРАХУНОК СТАТИЧНИХ МОМЕНТІВ
    % Создаем структуру для хранения статистических данных
    stat_data = struct(); % Создаем основную структуру для статистических данных
    % Получаем все ключи модуляции (m_1, m_5, m_20)
    % Берем из любого случая, так как модуляции одинаковые для всех
    modulation_keys = fieldnames(alpha_all.case1);
    % Внешний цикл по модуляциям
    for mod_idx = 1:length(modulation_keys)
        current_modulation = modulation_keys{mod_idx};
        fprintf('Обработка модуляции: %s\n', current_modulation);
        % Создаем подструктуру для текущей модуляции
        stat_data.(current_modulation) = struct();
        % Получаем все случаи (case1, case2, case3, case4)
        cases = fieldnames(alpha_all);
        % Внутренний цикл по случаям
        for case_idx = 1:length(cases)
            current_case = cases{case_idx};
            % Создаем имя для подполя случая
            case_field_name = sprintf('delta1_rho%d', case_idx);
            stat_data.(current_modulation).(case_field_name) = struct();
            % Получаем матрицы alpha и beta для текущего случая и модуляции
            alpha_matrix = alpha_all.(current_case).(current_modulation);
            beta_matrix = beta_all.(current_case).(current_modulation);
            % Преобразуем в векторы
            alpha_values = alpha_matrix(:);
            beta_values = beta_matrix(:);
            % Расчет статистических моментов для Alpha
            stat_data.(current_modulation).(case_field_name).AlfaMean = mean(alpha_values);
            stat_data.(current_modulation).(case_field_name).AlfaDispersion = var(alpha_values);
            stat_data.(current_modulation).(case_field_name).AlfaAsymmetry = skewness(alpha_values);
            stat_data.(current_modulation).(case_field_name).AlfaExcess = kurtosis(alpha_values);
            % Расчет статистических моментов для Beta
            stat_data.(current_modulation).(case_field_name).BettaMean = mean(beta_values);
            stat_data.(current_modulation).(case_field_name).BettaDispersion = var(beta_values);
            stat_data.(current_modulation).(case_field_name).BettaAsymmetry = skewness(beta_values);
            stat_data.(current_modulation).(case_field_name).BettaExcess = kurtosis(beta_values);
        end
        fprintf('Завершена обработка модуляции %s\n', current_modulation);   
    end
            % Пример доступа к данным:
            % stat_data.m_1.delta1_rho1.AlfaMean
            % stat_data.m_5.delta1_rho2.BettaDispersion
            % stat_data.m_20.delta1_rho3.AlfaAsymmetry


    
    %% СТВОРЕННЯ ФАЙЛІВ ІЗ СТАТИСТИЧНИМИ МОМЕНТАМИ ДЛЯ КОЖНОЇ МОДУЛЯЦІЇ
    % Створення основної папки якщо вона не існує
    outputDir = 'C:/[TOMKA] - Modelling/2.2';
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end
    % Отримання всіх ключів модуляції
    modulation_keys = fieldnames(stat_data);
    % Цикл по кожній модуляції
    for mod_idx = 1:length(modulation_keys)
        current_modulation = modulation_keys{mod_idx};
        % Створення папки для поточної модуляції
        modulation_folder = fullfile(outputDir, sprintf('m = %s', current_modulation(3:end)));
        if ~exist(modulation_folder, 'dir')
            mkdir(modulation_folder);
        end
        % Формування імені файлу з датою та часом
        currentTime = datetime('now');
        timestamp = datestr(currentTime, 'yyyy-mm-dd_HH-MM-SS');
        filename = fullfile(modulation_folder, ['таблиця_моментів_', current_modulation, '.txt']);
        % Відкриття файлу для запису
        fid = fopen(filename, 'w', 'n', 'UTF-8');
        if fid == -1
            error('Не вдалося створити файл: %s', filename);
        end
        % Заголовок таблиці
        fprintf(fid, 'Таблиця статистичних моментів для модуляції (m) -> %s\n', current_modulation);
        % Верхня межа таблиці 0
        fprintf(fid, '│%17s│%17s│%17s│%17s│%17s│\n', ...
            '================', '================', '================', '================', '================');
        % Заголовок стовпців
        fprintf(fid, '│%17s│%17s│%17s│%17s│%17s│\n', ...
            '', 'Case1', 'Case2', 'Case3', 'Case4');
        % Верхня межа таблиці
        fprintf(fid, '│%17s│%17s│%17s│%17s│%17s│\n', ...
            '================', '================', '================', '================', '================');
        % Заголовок стовпців
        fprintf(fid, '│%17s│%17s│%17s│%17s│%17s│\n', ...
            'Моменти', 'α(m×n,δ,ρ)', 'α(m×n,δ,ρ~)', 'α(m×n,δ,ρ*)', 'α(m×n,δ,ρ**)');
        % Роздільник заголовка
        fprintf(fid, '│%17s│%17s│%17s│%17s│%17s│\n', ...
            '================', '================', '================', '================', '================');
        % Рядок "Середнє" для Alpha
        fprintf(fid, '│%17s│%17f│%17f│%17f│%17f│\n', ...
            'Середнє', stat_data.(current_modulation).delta1_rho1.AlfaMean, ...
            stat_data.(current_modulation).delta1_rho2.AlfaMean, ...
            stat_data.(current_modulation).delta1_rho3.AlfaMean, ...
            stat_data.(current_modulation).delta1_rho4.AlfaMean);
        % Рядок "Дисперсія" для Alpha
        fprintf(fid, '│%17s│%17f│%17f│%17f│%17f│\n', ...
            'Дисперсія', stat_data.(current_modulation).delta1_rho1.AlfaDispersion, ...
            stat_data.(current_modulation).delta1_rho2.AlfaDispersion, ...
            stat_data.(current_modulation).delta1_rho3.AlfaDispersion, ...
            stat_data.(current_modulation).delta1_rho4.AlfaDispersion);
        % Рядок "Асиметрія" для Alpha
        fprintf(fid, '│%17s│%17f│%17f│%17f│%17f│\n', ...
            'Асиметрія', stat_data.(current_modulation).delta1_rho1.AlfaAsymmetry, ...
            stat_data.(current_modulation).delta1_rho2.AlfaAsymmetry, ...
            stat_data.(current_modulation).delta1_rho3.AlfaAsymmetry, ...
            stat_data.(current_modulation).delta1_rho4.AlfaAsymmetry);
        % Рядок "Ексцес" для Alpha
        fprintf(fid, '│%17s│%17f│%17f│%17f│%17f│\n', ...
            'Ексцес', stat_data.(current_modulation).delta1_rho1.AlfaExcess, ...
            stat_data.(current_modulation).delta1_rho2.AlfaExcess, ...
            stat_data.(current_modulation).delta1_rho3.AlfaExcess, ...
            stat_data.(current_modulation).delta1_rho4.AlfaExcess);
        % Роздільник між Alpha та Beta
        fprintf(fid, '│%17s│%17s│%17s│%17s│%17s│\n', ...
            '================', '================', '================', '================', '================');
        % Заголовок для Beta
        fprintf(fid, '│%17s│%17s│%17s│%17s│%17s│\n', ...
            'Моменти', 'β(m×n,δ,ρ)', 'β(m×n,δ,ρ~)', 'β(m×n,δ,ρ*)', 'β(m×n,δ,ρ**)');
        % Роздільник заголовка Beta
        fprintf(fid, '│%17s│%17s│%17s│%17s│%17s│\n', ...
            '================', '================', '================', '================', '================');
        % Рядок "Середнє" для Beta
        fprintf(fid, '│%17s│%17f│%17f│%17f│%17f│\n', ...
            'Середнє', stat_data.(current_modulation).delta1_rho1.BettaMean, ...
            stat_data.(current_modulation).delta1_rho2.BettaMean, ...
            stat_data.(current_modulation).delta1_rho3.BettaMean, ...
            stat_data.(current_modulation).delta1_rho4.BettaMean);
        % Рядок "Дисперсія" для Beta
        fprintf(fid, '│%17s│%17f│%17f│%17f│%17f│\n', ...
            'Дисперсія', stat_data.(current_modulation).delta1_rho1.BettaDispersion, ...
            stat_data.(current_modulation).delta1_rho2.BettaDispersion, ...
            stat_data.(current_modulation).delta1_rho3.BettaDispersion, ...
            stat_data.(current_modulation).delta1_rho4.BettaDispersion);
        % Рядок "Асиметрія" для Beta
        fprintf(fid, '│%17s│%17f│%17f│%17f│%17f│\n', ...
            'Асиметрія', stat_data.(current_modulation).delta1_rho1.BettaAsymmetry, ...
            stat_data.(current_modulation).delta1_rho2.BettaAsymmetry, ...
            stat_data.(current_modulation).delta1_rho3.BettaAsymmetry, ...
            stat_data.(current_modulation).delta1_rho4.BettaAsymmetry);
        % Рядок "Ексцес" для Beta
        fprintf(fid, '│%17s│%17f│%17f│%17f│%17f│\n', ...
            'Ексцес', stat_data.(current_modulation).delta1_rho1.BettaExcess, ...
            stat_data.(current_modulation).delta1_rho2.BettaExcess, ...
            stat_data.(current_modulation).delta1_rho3.BettaExcess, ...
            stat_data.(current_modulation).delta1_rho4.BettaExcess);
        % Нижня межа таблиці
        fprintf(fid, '│%17s│%17s│%17s│%17s│%17s│\n', ...
            '================', '================', '================', '================', '================');
        % Закриття файлу
        fclose(fid); 
        % Вивід інформації про створений файл
        fprintf('Таблиця для модуляції %s успішно створена!\n', current_modulation);
        fprintf('Файл збережено: %s\n', filename);
    end