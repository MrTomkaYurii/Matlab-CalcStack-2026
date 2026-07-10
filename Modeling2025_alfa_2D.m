colormaps = {'jet', 'gray'};            % 🔧 Масив назв colormap'ів
m = 400;                                % 🔧 кількість рядків
n = 400;                                % 🔧 кількість стовпців

T_LB_periods = [50, 100, 200];          % 🔧 ПЕРІОД для LB (фазові зсуви)
T_rho_periods = [50, 100, 150];         % 🔧 ПЕРІОД для rho (орієнтація оптичних осей)

steps = [20, 10, 5, 1];                 % 🔧 кроки сканування

global alfa_betta_K;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       
    %---------------------------------------------------------------------------------------------------------------------------
    for i = 1:length(T_LB_periods) % Цикл по T_LB_period
        T_LB = T_LB_periods(i);
        fprintf('--- T_LB = %d ---\n', T_LB);
        %-----------------------------------------------------------------------------------------------------------------------
        for j = 1:length(T_rho_periods) %Цикл по T_rho_period
            T_rho = T_rho_periods(j);
            fprintf(' T_rho = %d\n', T_rho);

            % створення теки
            folder_name = sprintf('ФазовийЗсувПеріод-%d - ОптичнаВісьПеріод-%d', T_LB, T_rho);
            full_path = fullfile('C:\[TOMKA] - Modelling', folder_name);
            if ~exist(full_path, 'dir')
                mkdir(full_path);
            end
            
                        %>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                        %% ---- ФИГУРА (концентрические кольца, гаусовы пятна и т.д.) ----

                        % ---- 1. КОНЦЕНТРИЧЕСКИЕ КОЛЬЦА ----
                        [X, Y] = meshgrid(1:n, 1:m);
                        centerX = n/2; centerY = m/2;
                        R = sqrt((X - centerX).^2 + (Y - centerY).^2);
                        LB_map = pi * (1 + sin(2 * pi * R / T_LB));
                        rho_map = (pi/2) * (1 + sin(2 * pi * R / T_rho));
                        cols = (0:n-1);

                        % % ---- 2. ГАУСОВЫЕ КОЛЬЦА ----
                        % [X, Y] = meshgrid(1:n, 1:m);
                        % % Несколько центров активности
                        % centers = [n/3, m/3; 2*n/3, 2*m/3; n/2, m/4];
                        % LB_map = zeros(m, n);
                        % rho_map = zeros(m, n);
                        % for k = 1:size(centers, 1)
                        %     R = sqrt((X - centers(k,1)).^2 + (Y - centers(k,2)).^2);
                        %     weight = exp(-R.^2 / (2 * (50)^2));
                        % 
                        %     LB_map = LB_map + pi * weight .* (1 + sin(2 * pi * R / T_LB));
                        %     rho_map = rho_map + (pi/2) * weight .* (1 + sin(2 * pi * R / T_rho));
                        % end
                        % % Правильная нормализация - растягиваем от текущего диапазона к целевому
                        % max_LB = max(LB_map(:));
                        % max_rho = max(rho_map(:));
                        % if max_LB > 0
                        %     LB_map = LB_map * (2*pi) / max_LB;   % Растягиваем до [0, 2π]
                        % end
                        % if max_rho > 0
                        %     rho_map = rho_map * pi / max_rho;    % Растягиваем до [0, π]
                        % end

                        % % ---- 3. ШАХМАТНАЯ ДОСКА С ГРАДИЕНТОМ ----                     
                        % % Размер клетки (в пикселях)
                        % cell_size = 50;  % крупные клетки 50x50
                        % % Создаем сетку координат
                        % [X, Y] = meshgrid(1:n, 1:m);
                        % % Создаем шахматную доску (крупные клетки)
                        % checker_X = floor((X-1) / cell_size);
                        % checker_Y = floor((Y-1) / cell_size);
                        % checker_pattern = mod(checker_X + checker_Y, 2);  % 0 или 1
                        % % Координаты внутри каждой клетки (от 0 до cell_size-1)
                        % local_X = mod(X-1, cell_size);
                        % local_Y = mod(Y-1, cell_size);
                        % % Нормализованные координаты внутри клетки (от 0 до 1)
                        % norm_X = local_X / (cell_size - 1);
                        % norm_Y = local_Y / (cell_size - 1);
                        % % Расстояние от центра клетки (для радиального градиента)
                        % center_dist = sqrt((norm_X - 0.5).^2 + (norm_Y - 0.5).^2);
                        % % Нормализуем расстояние (0 в центре, 1 в углах)
                        % center_dist = center_dist / (sqrt(2) * 0.5);
                        % % Создаем индекс для формул (меняется от клетки к клетке)
                        % cell_index = checker_X + checker_Y * ceil(n/cell_size);
                        % % Применяем формулы с градиентом внутри клеток
                        % % В белых клетках (checker_pattern = 0): максимум в центре, минимум по краям
                        % % В черных клетках (checker_pattern = 1): минимум в центре, максимум по краям
                        % % Для LB_map: [0, 2π]
                        % LB_base = pi * (1 + sin(2 * pi * cell_index / T_LB));
                        % LB_gradient = zeros(size(checker_pattern));
                        % % Белые клетки: максимум в центре
                        % white_mask = (checker_pattern == 0);
                        % LB_gradient(white_mask) = LB_base(white_mask) .* (1 - 0.8 * center_dist(white_mask));
                        % % Черные клетки: минимум в центре  
                        % black_mask = (checker_pattern == 1);
                        % LB_gradient(black_mask) = LB_base(black_mask) .* (0.2 + 0.8 * center_dist(black_mask));
                        % LB_map = LB_gradient;
                        % % Для rho_map: [0, π]
                        % rho_base = (pi/2) * (1 + sin(2 * pi * cell_index / T_rho));
                        % rho_gradient = zeros(size(checker_pattern));
                        % % Белые клетки: максимум в центре
                        % rho_gradient(white_mask) = rho_base(white_mask) .* (1 - 0.8 * center_dist(white_mask));
                        % % Черные клетки: минимум в центре
                        % rho_gradient(black_mask) = rho_base(black_mask) .* (0.2 + 0.8 * center_dist(black_mask));
                        % rho_map = rho_gradient;
                        % % -----
                        % % 2D-Визуализация результатов
                        % figure;
                        % set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
                        % subplot(1,3,1);
                        % imagesc(LB_map);
                        % axis image;
                        % title('LB_{map} [0, 2\pi]');
                        % colorbar;
                        % colormap(gca, 'hot');
                        % subplot(1,3,2);
                        % imagesc(rho_map);
                        % axis image;
                        % title('\rho_{map} [0, \pi]');
                        % colorbar;
                        % colormap(gca, 'cool');
                        % subplot(1,3,3);
                        % imagesc(checker_pattern);
                        % axis image;
                        % title('Шахматный паттерн (референс)');
                        % colorbar;
                        % colormap(gca, 'gray');
                        %     filename = fullfile(full_path, sprintf('2D.Поверхні_зразків_Tlb_%d_Trho_%d.png', T_LB, T_rho));
                        %     saveas(gcf, filename);
                        %     close(gcf);
                        % % -----
                        % % 3D-ВИЗУАЛИЗАЦИЯ
                        % figure
                        % set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
                        % subplot(1,2,1);
                        % [X_3d, Y_3d] = meshgrid(1:10:n, 1:10:m);  % Прореживание для скорости
                        % LB_3d = LB_map(1:10:m, 1:10:n);
                        % surf(X_3d, Y_3d, LB_3d);
                        % xlabel('X');
                        % ylabel('Y');
                        % zlabel('LB значения');
                        % title('3D поверхность LB_{map}');
                        % colorbar;
                        % colormap(gca, 'hot');
                        % shading interp;
                        % view(52, 64);
                        % % 3D поверхность для rho_map
                        % subplot(1,2,2);
                        % rho_3d = rho_map(1:10:m, 1:10:n);
                        % surf(X_3d, Y_3d, rho_3d);
                        % xlabel('X');
                        % ylabel('Y');
                        % zlabel('\rho значения');
                        % title('3D поверхность \rho_{map}');
                        % colorbar;
                        % colormap(gca, 'cool');
                        % shading interp;
                        % view(52, 64);
                        %     filename = fullfile(full_path, sprintf('3D.Поверхні_зразків_Tlb_%d_Trho_%d.png', T_LB, T_rho));
                        %     saveas(gcf, filename);
                        %     close(gcf);
                        % % -----
                        % % Комбинированная поверхность
                        % combined = LB_map .* cos(rho_map);  % Комбинируем LB и rho
                        % figure
                        % set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
                        % subplot(1, 2, 1);
                        % imagesc(combined);  % або: pcolor(combined); shading interp;
                        % axis image;          % Зберегти пропорції
                        % xlabel('X'); ylabel('Y');
                        % title('2D представлення: LB \times cos(\rho)');
                        % colorbar; colormap('jet');
                        % subplot(1,2,2);
                        % surf(X_3d, Y_3d, combined(1:10:m, 1:10:n));
                        % xlabel('X'); ylabel('Y'); zlabel('LB \times cos(\rho)');
                        % title('Комбинированная поверхность');
                        % colorbar; colormap('jet');
                        % shading interp;
                        % view(-30, 45);
                        %     filename = fullfile(full_path, sprintf('Комбінована_поверхня_Tlb_%d_Trho_%d.png', T_LB, T_rho));
                        %     saveas(gcf, filename);
                        %     close(gcf);
                        
                        % % ---- 4. ПРОСТЫЕ ЛИНИИ ---- 
                        % % Індекси по стовпцях (0-based)
                        % cols = (0:n-1);  % вектор-рядок
                        % % Формули з переходом до потрібного діапазону
                        % LB = pi * (1 + sin(2 * pi * cols / T_LB));        % [0, 2π]
                        % rho = (pi/2) * (1 + sin(2 * pi * cols / T_rho));  % [0, π]
                        % % Розподіл по всій області
                        % LB_map = repmat(LB, m, 1);
                        % rho_map = repmat(rho, m, 1);
                        %>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


            % >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            % ВІЗУАЛІЗАЦІЯ ЯДЕР КОРЕЛЯЦІЇ 
            % >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            % Обираємо рядок для перерізу (по осі OX)
             cols = (0:n-1);  % вектор-рядок
             row_idx = m/2;  
             LB_slice = LB_map(row_idx, :);
             rho_slice = rho_map(row_idx, :);
            for cm = 1:length(colormaps) % Цикл по colormap
            colormap_value = colormaps{cm};
                figure('Name', sprintf('2D. Періоди: T_LB = %d, T_rho = %d', T_LB, T_rho));
                set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
                colormap (colormap_value);
                    % --- Верхній ряд: перерізи по OX ---
                    subplot(2,2,1);
                    plot(cols, LB_slice, 'b', 'LineWidth', 1.5);
                    title(sprintf('Переріз LB по осі OX (рядок %d)', row_idx));
                    xlabel('X (пікселі)'); ylabel('LB');
                    grid on;
                    xlim([0 n-1]);
                    subplot(2,2,2);
                    plot(cols, rho_slice, 'b', 'LineWidth', 1.5);
                    title(sprintf('Переріз \rho по осі OX (рядок %d)', row_idx));
                    xlabel('X (пікселі)');
                    ylabel('\rho');
                    grid on;
                    xlim([0 n-1]);
                    % --- Нижній ряд: повні розподіли ---
                    subplot(2,2,3);
                    imagesc(LB_map);
                    colorbar; 
                    title(sprintf('2D. Період: T_{LB} = %d', T_LB));
                    xlabel('Стовпець (X)'); ylabel('Рядок (Y)');
                    axis equal;  axis tight;
                    subplot(2,2,4);
                    imagesc(rho_map);
                    colorbar; 
                    title(sprintf('2D. Період: T_{\\rho} = %d', T_rho));
                    xlabel('Стовпець (X)');
                    ylabel('Рядок (Y)');
                    axis equal;  axis tight;
                        filename = fullfile(full_path, sprintf('%s.2D_Periods_Tlb_%d_Trho_%d.png', colormap_value, T_LB, T_rho));
                        % Збереження фігури у файл PNG
                        saveas(gcf, filename);
                        close(gcf);
                % ---------------------------------------
                % Сітка координат
                [X, Y] = meshgrid(1:n, 1:m);
                 % Переріз по осі OX (рядок 500)
                row_idx = m/2;
                Z_LB_slice = LB_map(row_idx, :);
                Z_rho_slice = rho_map(row_idx, :);
                X_slice = 1:n;
                Y_slice = row_idx * ones(1, n);  % Y = посередині  
                % === ВІЗУАЛІЗАЦІЯ ===
                figure('Name', sprintf('3D. Періоди: T_LB = %d, T_rho = %d', T_LB, T_rho));
                set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
                colormap (colormap_value);
                    % Верхній лівий: 3D-переріз LB
                    subplot(2,2,1);
                    plot3(X_slice, Y_slice, Z_LB_slice, 'b', 'LineWidth', 2);
                    grid on;
                    title(sprintf('3D-переріз LB по осі OX (рядок %d)', row_idx))
                    xlabel('X (Стовпець)');
                    ylabel('Y = 500');
                    zlabel('LB');
                    xlim([1 n]);
                    view(45, 25); 
                    % Верхній правий: 3D-переріз rho
                    subplot(2,2,2);
                    plot3(X_slice, Y_slice, Z_rho_slice, 'b', 'LineWidth', 2);
                    grid on;
                    title(sprintf('3D-переріз \rho по осі OX (рядок %d)', row_idx))
                    xlabel('X (Стовпець)');
                    ylabel('Y = 500');
                    zlabel('\rho');
                    xlim([1 n]);
                    view(45, 25);
                    % Нижній лівий: Повна 3D-поверхня LB
                    subplot(2,2,3);
                    surf(X, Y, LB_map, 'EdgeColor', 'none');
                    colorbar;
                    title(sprintf('3D. Період: T_{LB} = %d', T_LB));
                    xlabel('X'); ylabel('Y'); zlabel('LB');
                    view(45, 30);
                    axis tight;
                    % Нижній правий: Повна 3D-поверхня rho
                    subplot(2,2,4);
                    surf(X, Y, rho_map, 'EdgeColor', 'none');
                    colorbar;
                    title(sprintf('3D. Період: T_{\\rho} = %d', T_rho));
                    xlabel('X'); ylabel('Y');
                    zlabel('\rho');
                    view(45, 30);
                    axis tight;
                        filename = fullfile(full_path, sprintf('%s.3D_Periods_Tlb_%d_Trho_%d.png', colormap_value, T_LB, T_rho));
                        % Збереження фігури у файл PNG
                        saveas(gcf, filename);
                        close(gcf);
            end %colormap


               %----------------------------------------------------------------------------
               for s = 1:length(steps) %% Цикл по кроках
                    step = steps(s);   
                    fprintf(' Крок: %d\n', step)
                    subfolder_name = sprintf('Крок сканування %d', step);
                    pathAlfaBetta = fullfile(full_path, subfolder_name);
                    if ~exist(pathAlfaBetta, 'dir')
                        mkdir(pathAlfaBetta);
                    end
                    fprintf(' Тека: %s\n', pathAlfaBetta);
                    
                    %%  ===================================================================               
                    %% РОЗРАХУНОК ДВОТОЧКОВОГО МОДУЛЯ ТА АРГУМЕНТУ АЗИМУТА ТА ЕЛЛІПТИЧНОСТІ
                    % === 1. Діапазони допустимих зсувів ===
                    dx_range = -(n-1):step:(n-1);
                    dy_range = -(m-1):step:(m-1);
                    % === 2. Розмір псевдокореляційного ядра ===
                    KsizeX = length(dx_range);
                    KsizeY = length(dy_range);
                    % === 3. Центральний зсув (нульовий) ===
                    centerX = ceil(KsizeX / 2);
                    centerY = ceil(KsizeY / 2);
                    % === 4. Предварительное выделение памяти ===
                    results_alpha_c_abs = zeros(KsizeY, KsizeX);
                    results_theta_2alpha_c = zeros(KsizeY, KsizeX);
                    results_betta_c_abs = zeros(KsizeY, KsizeX);
                    results_theta_sin_betta_c = zeros(KsizeY, KsizeX);
                    % === 5. Основний цикл по сдвигам ===
                    parfor ii = 1:length(dx_range)
                        dx = dx_range(ii);
                        temp_alpha_c_abs = zeros(length(dy_range), 1);
                        temp_theta_2alpha_c = zeros(length(dy_range), 1);
                        temp_betta_c_abs = zeros(length(dy_range), 1);
                        temp_theta_sin_betta_c = zeros(length(dy_range), 1);
                        for jj = 1:length(dy_range)
                            dy = dy_range(jj);
                            x1 = max(1, 1 - dx) : min(n, n - dx);
                            y1 = max(1, 1 - dy) : min(m, m - dy);
                            x2 = x1 + dx;
                            y2 = y1 + dy;
                            LB1 = LB_map(y1, x1);
                            LB2 = LB_map(y2, x2);
                            rho1 = rho_map(y1, x1);
                            rho2 = rho_map(y2, x2);
                            % === Обчислення величин ===
                            alpha_c_abs = 0.5 * atan(0.5 * (LB1 .* sin(2*rho1) - LB2 .* sin(2*rho2)));
                            denominator = LB2 .* cos(2*rho2) - LB1 .* cos(2*rho1);
                            epsilon = 1e-6;
                            sing_mask = abs(denominator) < epsilon;
                            denominator(sing_mask) = sign(denominator(sing_mask)) * epsilon;
                            theta_2alpha_c = 1 ./ denominator;
                            betta_c_abs = abs(0.5 * asin(LB1 .* sin(2*rho1) - LB2 .* sin(2*rho2)));
                            theta_sin_betta_c = 0.5 * atan(LB1 .* sin(2*rho1) + LB2 .* sin(2*rho2));
                            temp_alpha_c_abs(jj) = mean(alpha_c_abs(:));
                            temp_theta_2alpha_c(jj) = mean(theta_2alpha_c(:));
                            temp_betta_c_abs(jj) = mean(betta_c_abs(:));
                            temp_theta_sin_betta_c(jj) = mean(theta_sin_betta_c(:));
                        end
                        results_alpha_c_abs(:, ii) = temp_alpha_c_abs;
                        results_theta_2alpha_c(:, ii) = temp_theta_2alpha_c;
                        results_betta_c_abs(:, ii) = temp_betta_c_abs;
                        results_theta_sin_betta_c(:, ii) = temp_theta_sin_betta_c;
                    end
                    alfa_betta_K = struct();
                    alfa_betta_K.alpha_c_abs = struct();
                    alfa_betta_K.alpha_c_abs.description = 'Модуль двот. азимута';
                    alfa_betta_K.alpha_c_abs.kernel_full_alpha_c_abs = results_alpha_c_abs;
                    alfa_betta_K.theta_2alpha_c = struct();
                    alfa_betta_K.theta_2alpha_c.description = 'Аргумент двот. азимута';
                    alfa_betta_K.theta_2alpha_c.kernel_full_theta_2alpha_c = results_theta_2alpha_c;
                    alfa_betta_K.betta_c_abs = struct();
                    alfa_betta_K.betta_c_abs.description = 'Модуль двот. еліптичності';
                    alfa_betta_K.betta_c_abs.kernel_full_betta_c_abs = results_betta_c_abs;
                    alfa_betta_K.theta_sin_betta_c = struct();
                    alfa_betta_K.theta_sin_betta_c.description = 'Аргумент двот. еліптичності';
                    alfa_betta_K.theta_sin_betta_c.kernel_full_theta_sin_betta_c = results_theta_sin_betta_c;

                   %% ==== ВІЗУАЛІЗАЦІЯ ALFA
                   for cm = 1:length(colormaps) % Цикл по colormap
                   colormap_value = colormaps{cm};  

                        fields = fieldnames(alfa_betta_K);
                        num_fields = numel(fields);
                        all_descriptions = {};
                        for k = 1:num_fields-2
                            field_name = fields{k};
                            description = alfa_betta_K.(field_name).description;
                            all_descriptions{end+1} = description;
                        end
                        combined_descriptions = strjoin(all_descriptions, ', ');

                        % =1=== 2D Візуалізація всіх ====
                        figure('Name', ['2D-представлення двоточкової елліптичності для кроку = ', num2str(step)]);
                        % Строим графики для каждого поля
                        for k = 1:num_fields-2
                            set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
                            colormap(colormap_value);
                            subplot(1, 2, k);
                            field_name = fields{k};
                            data_field_names = fieldnames(alfa_betta_K.(field_name));
                            % Находим поле, которое не является description
                            data_field_name = '';
                            for z = 1:length(data_field_names)
                                if ~strcmp(data_field_names{z}, 'description')
                                    data_field_name = data_field_names{z};
                                    break;
                                end
                            end
                            % Получаем данные и описание
                            data_matrix = alfa_betta_K.(field_name).(data_field_name);
                            description = alfa_betta_K.(field_name).description; 
                            % Строим график
                                if k == 2 && strcmp(description, 'Аргумент двот. азимута')
                                    hImg = imagesc(data_matrix);
                                    axis image;
                                    colorbar;
                                    xlabel('\Delta x');
                                    ylabel('\Delta y');
                                    title(description, 'Interpreter', 'none');
                                    alphaData = ones(size(data_matrix));
                                    alphaData(data_matrix < -100 | data_matrix > 100) = 1;
                                    set(hImg, 'AlphaData', alphaData);
                                else
                                    imagesc(data_matrix);
                                    axis image;
                                    xlabel('\Delta x');
                                    ylabel('\Delta y');
                                    title(description, 'Interpreter', 'none');
                                    grid on; set(gca, 'GridAlpha', 0.2);
                                    colorbar;
                                end
                        end
                        filename = fullfile(pathAlfaBetta, sprintf('%s.2D.Псевдокореляційні_%s_КРОК_%d_.png', ...
                            colormap_value, strrep(combined_descriptions, ' ', '_'), step));
                        saveas(gcf, filename);
                        close(gcf);
    
                        % =2=== 3D Візуалізація всіх псевдокореляційних параметрів ====
                        fields = fieldnames(alfa_betta_K);
                        num_fields = numel(fields);
                        
                        figure('Name', ['3D-представлення псевдокореляційних параметрів для кроку = ', num2str(step)]);
                        set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
                        all_descriptions = {};
                        for k = 1:num_fields-2
                            all_descriptions{end+1} = alfa_betta_K.(fields{k}).description;
                        end
                        combined_descriptions = strjoin(all_descriptions, ', ');
                        for k = 1:num_fields-2
                            subplot(1, 2, k);
                            % Назва поля, наприклад: alpha_c_abs
                            field_name = fields{k};
                            % Знаходимо поле з даними (яке не description)
                            data_field_names = fieldnames(alfa_betta_K.(field_name));
                            data_field_name = '';
                            for z = 1:length(data_field_names)
                                if ~strcmp(data_field_names{z}, 'description')
                                    data_field_name = data_field_names{z};
                                    break;
                                end
                            end
                            % Дані і опис
                            data = alfa_betta_K.(field_name).(data_field_name);
                            description = alfa_betta_K.(field_name).description;
                            % Розміри матриці
                            [rows, cols] = size(data);
                            center_x = ceil(cols / 2);
                            center_y = ceil(rows / 2);
                            % Вектори координат
                            x_coords = ((1:cols) - center_x) * step;
                            y_coords = ((1:rows) - center_y) * step;
                            [X, Y] = meshgrid(x_coords, y_coords);
                            surf(X, Y, data);
                            shading interp;
                            view(30, 80);
                            axis tight;
                            colormap(colormap_value);
                            colorbar;
                            grid on; %set(gca, 'GridAlpha', 0.3);
                            xlabel('\Delta x');
                            ylabel('\Delta y');
                            zlabel('Значення');
                            title(['3D: ', description], 'Interpreter', 'none');
                        end
                        filename = fullfile(pathAlfaBetta, sprintf('%s.3D.Псевдокореляційні_%s_КРОК_%d.png', ...
                            colormap_value, strrep(combined_descriptions, ' ', '_'), step));
                        saveas(gcf, filename);
                        close(gcf);
    
                        % =3=== 2D Візуалізація окремого кожного поля ====
                        fields = fieldnames(alfa_betta_K);
                        num_fields = numel(fields);
                        for k = 1:num_fields-2
                            % Опис поля (не обробляємо поле, якщо воно description)
                            if isfield(alfa_betta_K.(fields{k}), 'description')
                                % Знаходимо поле з даними, окрім 'description'
                                data_fields = fieldnames(alfa_betta_K.(fields{k}));
                                data_field_name = '';
                                for z = 1:length(data_fields)
                                    if ~strcmp(data_fields{z}, 'description')
                                        data_field_name = data_fields{z};
                                        break;
                                    end
                                end
                                % Витягуємо матрицю даних
                                data = alfa_betta_K.(fields{k}).(data_field_name);
                                [rows, cols] = size(data);
                                % Центр матриці
                                center_x = ceil(cols / 2);
                                center_y = ceil(rows / 2);
                                % Визначаємо координати для вісі з урахуванням кроку step
                                x_coords = ((1:cols) - center_x) * step;
                                y_coords = ((1:rows) - center_y) * step; 
                                
                                % Створюємо фігуру
                                figure('Name', ['2D Псевдокореляція ', strrep(fields{k}, 'kernel_full_', ''), ' (крок = ', num2str(step), ')']);
                                set(gcf, 'Units', 'normalized', 'OuterPosition', [0.1 0.1 0.8 0.8]);
                                % Візуалізація з віссю x_coords, y_coords
                                imagesc(x_coords, y_coords, data);
                                axis image;
                                colormap(colormap_value);
                                colorbar;
                                % Підписи осей
                                xlabel('\Delta x', 'FontWeight', 'bold');
                                ylabel('\Delta y', 'FontWeight', 'bold');
                                % Заголовок з описом поля
                                title(['2D представлення псевдокореляційного ядра для ', alfa_betta_K.(fields{k}).description], 'FontSize', 14);  
                                % Відображення сітки
                                grid on;
                                set(gca, 'GridAlpha', 0.3);

                                % Збереження фігури
                                safe_name = strrep(alfa_betta_K.(fields{k}).description, ' ', '_');
                                filename_separate = fullfile(pathAlfaBetta, sprintf('%s.2D.Псевдокореляція_%s_КРОК_%d.png', ...
                                    colormap_value, safe_name, step));
                                saveas(gcf, filename_separate);
                                close(gcf);
                            end
                        end

                        % =4=== 3D Візуалізація окремого псевдокореляційного ядра ====
                        for k = 1:num_fields-2
                            % Назва поля, наприклад: alpha_c_abs
                            field_name = fields{k};
                            % Знаходимо внутрішнє поле з даними
                            data_field_names = fieldnames(alfa_betta_K.(field_name));
                            data_field_name = '';
                            for z = 1:length(data_field_names)
                                if ~strcmp(data_field_names{z}, 'description')
                                    data_field_name = data_field_names{z};
                                    break;
                                end
                            end
                            % Дані та опис
                            data = alfa_betta_K.(field_name).(data_field_name);
                            description = alfa_betta_K.(field_name).description;
                            % Центровані координати
                            [rows, cols] = size(data);
                            center_x = ceil(cols / 2);
                            center_y = ceil(rows / 2);
                            x_coords = ((1:cols) - center_x) * step;
                            y_coords = ((1:rows) - center_y) * step;
                            [X, Y] = meshgrid(x_coords, y_coords);
                            % Створення фігури
                            figure('Name', ['3D Псевдокореляція ', description, ' (крок = ', num2str(step), ')']);
                            set(gcf, 'Units', 'normalized', 'OuterPosition', [0.1 0.1 0.8 0.8]);
                            % Візуалізація
                            surf(X, Y, data);
                            shading interp;
                            view(30, 80);
                            axis tight;
                            colormap(colormap_value);
                            colorbar;
                            % Підписи
                            xlabel('\Delta x');
                            ylabel('\Delta y');
                            zlabel('Значення');
                            title(['3D представлення псевдокореляційного ядра: ', description], 'FontSize', 14);
                            % Сітка
                            grid on;
                            set(gca, 'GridAlpha', 0.3);
                            % Збереження
                            component_name = strrep(field_name, '_', '-');
                            filename_separate = fullfile(pathAlfaBetta, sprintf('%s.3D.Псевдокореляція_%s_КРОК_%d.png', colormap_value, component_name, step));
                            saveas(gcf, filename_separate);
                            close(gcf);
                        end
                    end %colormap
                   %%  ===================================================================
               end %steps
        end %T_rho_period
    end %T_LB_period
