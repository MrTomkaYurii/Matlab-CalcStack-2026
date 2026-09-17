colormaps = {'jet', 'gray'};            % 🔧 Масив назв colormap'ів
m = 400;                                % 🔧 кількість рядків
n = 400;                                % 🔧 кількість стовпців

T_LB_periods = [50, 100, 200];     % 🔧 ПЕРІОД для LB (фазові зсуви)
T_rho_periods = [50, 100, 150];    % 🔧 ПЕРІОД для rho (орієнтація оптичних осей)

steps = [1, 5, 10, 20];                % 🔧 кроки сканування

global MK; MK = struct();
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for cm = 1:length(colormaps) % Цикл по colormap
    colormap_value = colormaps{cm};          
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
            %>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            
                        %% ---- ФИГУРА (концентрические кольца, гаусовы пятна и т.д.) ----

                        % % ---- 1. КОНЦЕНТРИЧЕСКИЕ КОЛЬЦА ----
                        % [X, Y] = meshgrid(1:n, 1:m);
                        % centerX = n/2; centerY = m/2;
                        % R = sqrt((X - centerX).^2 + (Y - centerY).^2);
                        % LB_map = pi * (1 + sin(2 * pi * R / T_LB));
                        % rho_map = (pi/2) * (1 + sin(2 * pi * R / T_rho));
                        
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
                        
                        % ---- 4. ПРОСТЫЕ ЛИНИИ ---- 
                        % Індекси по стовпцях (0-based)
                        cols = (0:n-1);  % вектор-рядок
                        % Формули з переходом до потрібного діапазону
                        LB = pi * (1 + sin(2 * pi * cols / T_LB));        % [0, 2π]
                        rho = (pi/2) * (1 + sin(2 * pi * cols / T_rho));  % [0, π]
                        % Розподіл по всій області
                        LB_map = repmat(LB, m, 1);
                        rho_map = repmat(rho, m, 1);

            %>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            % === ВІЗУАЛІЗАЦІЯ ЯДЕР КОРЕЛЯЦІЇ===
            % Обираємо рядок для перерізу (по осі OX)
            row_idx = m/2;  % центральний рядок
            LB_slice = LB_map(row_idx, :);
            rho_slice = rho_map(row_idx, :);
            figure('Name', sprintf('2D. Періоди: T_LB = %d, T_rho = %d', T_LB, T_rho));
            set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
            colormap (colormap_value);
                % --- Верхній ряд: перерізи по OX ---
                subplot(2,2,1);
                plot(cols, LB_slice, 'b', 'LineWidth', 1.5);
                title(sprintf('Переріз LB по осі OX (рядок %d)', row_idx));
                xlabel('X (пікселі)');
                ylabel('LB');
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
                xlabel('Стовпець (X)');
                ylabel('Рядок (Y)');
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
                xlabel('X');
                ylabel('Y');
                zlabel('LB');
                view(45, 30);
                axis tight;
                % Нижній правий: Повна 3D-поверхня rho
                subplot(2,2,4);
                surf(X, Y, rho_map, 'EdgeColor', 'none');
                colorbar;
                title(sprintf('3D. Період: T_{\\rho} = %d', T_rho));
                xlabel('X');
                ylabel('Y');
                zlabel('\rho');
                view(45, 30);
                axis tight;
                    filename = fullfile(full_path, sprintf('%s.3D_Periods_Tlb_%d_Trho_%d.png', colormap_value, T_LB, T_rho));
                    % Збереження фігури у файл PNG
                    saveas(gcf, filename);
                    close(gcf);

               %----------------------------------------------------------------------------------------------------------------
               for s = 1:length(steps) %% Цикл по кроках
                    step = steps(s);   
                    fprintf(' Крок: %d\n', step)
                    subfolder_name = sprintf('Крок сканування %d', step);
                    pathM = fullfile(full_path, subfolder_name);
                    if ~exist(pathM, 'dir')
                        mkdir(pathM);
                    end
                    fprintf(' Тека: %s\n', pathM);


                    %% РОЗРАХУНОК MK
                    % Розмір кореляційного ядра (повне 2D ядро)
                    KsizeY = 2 * ceil((m-1)/step) + 1;
                    KsizeX = 2 * ceil((n-1)/step) + 1;
                    % Центральний зсув (нульовий)
                    centerY = ceil(KsizeY/2);
                    centerX = ceil(KsizeX/2);
                    % повний прохід по всіх зсувах Δx, Δy з кроком step
                    dx_range = -(n-1):step:(n-1);
                    dy_range = -(m-1):step:(m-1);
                    % Предварительное выделение памяти для результатов (окремі масиви)
                    results_f11 = zeros(length(dy_range), length(dx_range));
                    results_f12 = zeros(length(dy_range), length(dx_range));
                    results_f21 = zeros(length(dy_range), length(dx_range));
                    results_f22 = zeros(length(dy_range), length(dx_range));
                    results_f23 = zeros(length(dy_range), length(dx_range));
                    results_f24 = zeros(length(dy_range), length(dx_range));
                    results_f32 = zeros(length(dy_range), length(dx_range));
                    results_f33 = zeros(length(dy_range), length(dx_range));
                    results_f34 = zeros(length(dy_range), length(dx_range));
                    results_f42 = zeros(length(dy_range), length(dx_range));
                    results_f43 = zeros(length(dy_range), length(dx_range));
                    results_f44 = zeros(length(dy_range), length(dx_range));
                    parfor ii = 1:length(dx_range)
                        dx = dx_range(ii);
                        % Тимчасові колонки для всіх компонентів
                        temp_f11 = zeros(length(dy_range), 1);
                        temp_f12 = zeros(length(dy_range), 1);
                        temp_f21 = zeros(length(dy_range), 1);
                        temp_f22 = zeros(length(dy_range), 1);
                        temp_f23 = zeros(length(dy_range), 1);
                        temp_f24 = zeros(length(dy_range), 1);
                        temp_f32 = zeros(length(dy_range), 1);
                        temp_f33 = zeros(length(dy_range), 1);
                        temp_f34 = zeros(length(dy_range), 1);
                        temp_f42 = zeros(length(dy_range), 1);
                        temp_f43 = zeros(length(dy_range), 1);
                        temp_f44 = zeros(length(dy_range), 1);
                        
                        for jj = 1:length(dy_range)
                            dy = dy_range(jj);
                            % Обчислюємо допустимі координати
                            x1 = max(1, 1 - dx) : min(n, n - dx);
                            y1 = max(1, 1 - dy) : min(m, m - dy);
                            x2 = x1 + dx;
                            y2 = y1 + dy;
                            % Дістаємо відповідні підматриці
                            LB1 = LB_map(y1, x1);
                            LB2 = LB_map(y2, x2);
                            rho1 = rho_map(y1, x1);
                            rho2 = rho_map(y2, x2);
                            % Розрахунок всіх кореляційних значень
                            f11 = 1 + 0.25 * LB1 .* LB2 .* cos(2 * (rho1 - rho2));
                            f12 = 1 - 0.25 * LB1 .* LB2 .* sin(2*rho1) .* sin(2*rho2);
                            f21 = 1 - 0.25 * LB1 .* LB2 .* sin(2*rho1) .* sin(2*rho2);
                            f22 = 1 + 0.25 * LB1 .* LB2 .* cos(2 * (rho1 + rho2));
                            f23 = 0.25 * (LB1 .* sin(2*rho1) + LB2 .* sin(2*rho2));
                            f24 = 0.25 * LB1 .* LB2 .* sin(2*(rho1 + rho2));
                            f32 = -f23; 
                            f33 = 1 - 0.25 * LB1 .* LB2 .* cos(2 * (rho1 + rho2));
                            f34 = 0.25 * LB1 .* LB2 .* cos(2*(rho1 - rho2));
                            f42 = -f24; 
                            f43 = -f34;  
                            f44 = 1 - 0.25 * LB1 .* LB2 .* cos(2 * (rho1 - rho2));
                            % Зберігаємо середні значення для кожного компонента
                            temp_f11(jj) = mean(f11(:));
                            temp_f12(jj) = mean(f12(:));
                            temp_f21(jj) = mean(f21(:));
                            temp_f22(jj) = mean(f22(:));
                            temp_f23(jj) = mean(f23(:));
                            temp_f24(jj) = mean(f24(:));
                            temp_f32(jj) = mean(f32(:));
                            temp_f33(jj) = mean(f33(:));
                            temp_f34(jj) = mean(f34(:));
                            temp_f42(jj) = mean(f42(:));
                            temp_f43(jj) = mean(f43(:));
                            temp_f44(jj) = mean(f44(:));
                        end
                        % Копіюємо результати
                        results_f11(:, ii) = temp_f11;
                        results_f12(:, ii) = temp_f12;
                        results_f21(:, ii) = temp_f21;
                        results_f22(:, ii) = temp_f22;
                        results_f23(:, ii) = temp_f23;
                        results_f24(:, ii) = temp_f24;
                        results_f32(:, ii) = temp_f32;
                        results_f33(:, ii) = temp_f33;
                        results_f34(:, ii) = temp_f34;
                        results_f42(:, ii) = temp_f42;
                        results_f43(:, ii) = temp_f43;
                        results_f44(:, ii) = temp_f44;
                    end
                    % Ініціалізація структури MK з усіма ядрами
                    MK = struct();
                    MK.kernel_full_f11 = zeros(KsizeY, KsizeX);
                    MK.kernel_full_f12 = zeros(KsizeY, KsizeX);
                    MK.kernel_full_f21 = zeros(KsizeY, KsizeX);
                    MK.kernel_full_f22 = zeros(KsizeY, KsizeX);
                    MK.kernel_full_f23 = zeros(KsizeY, KsizeX);
                    MK.kernel_full_f24 = zeros(KsizeY, KsizeX);
                    MK.kernel_full_f32 = zeros(KsizeY, KsizeX);
                    MK.kernel_full_f33 = zeros(KsizeY, KsizeX);
                    MK.kernel_full_f34 = zeros(KsizeY, KsizeX);
                    MK.kernel_full_f42 = zeros(KsizeY, KsizeX);
                    MK.kernel_full_f43 = zeros(KsizeY, KsizeX);
                    MK.kernel_full_f44 = zeros(KsizeY, KsizeX);
                    % Копіюємо результати в kernel_full для всіх компонентів
                    for ii = 1:length(dx_range)
                        for jj = 1:length(dy_range)
                            dx = dx_range(ii);
                            dy = dy_range(jj);
                            % Індекси в ядрі з урахуванням кроку
                            kernel_x = round(dx/step) + centerX;
                            kernel_y = round(dy/step) + centerY;
                            MK.kernel_full_f11(kernel_y, kernel_x) = results_f11(jj, ii);
                            MK.kernel_full_f12(kernel_y, kernel_x) = results_f12(jj, ii);
                            MK.kernel_full_f21(kernel_y, kernel_x) = results_f21(jj, ii);
                            MK.kernel_full_f22(kernel_y, kernel_x) = results_f22(jj, ii);
                            MK.kernel_full_f23(kernel_y, kernel_x) = results_f23(jj, ii);
                            MK.kernel_full_f24(kernel_y, kernel_x) = results_f24(jj, ii);
                            MK.kernel_full_f32(kernel_y, kernel_x) = results_f32(jj, ii);
                            MK.kernel_full_f33(kernel_y, kernel_x) = results_f33(jj, ii);
                            MK.kernel_full_f34(kernel_y, kernel_x) = results_f34(jj, ii);
                            MK.kernel_full_f42(kernel_y, kernel_x) = results_f42(jj, ii);
                            MK.kernel_full_f43(kernel_y, kernel_x) = results_f43(jj, ii);
                            MK.kernel_full_f44(kernel_y, kernel_x) = results_f44(jj, ii);
                        end
                    end

                   % ==== ВІЗУАЛІЗАЦІЯ Mcor ===
                   % ==== 2D Візуалізація всіх ====
                       fields = fieldnames(MK);
                       num_fields = numel(fields);
                   %---
                   figure('Name', ['2D-представлення псевдокореляційних ядер Мюллера для кроку  = ', num2str(step)]);
                   for k = 1:num_fields
                       set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
                       colormap (colormap_value);
                       subplot(4,3,k);
                       imagesc(MK.(fields{k}));
                       axis image off;
                       title(fields{k}, 'Interpreter', 'none');
                       colorbar;
                   end
                        filename = fullfile(pathM, sprintf('%s.2D.Псевдокореляційні_ММ_КРОК_%d_.png', colormap_value, step));
                        saveas(gcf, filename);
                        close(gcf);

                    % ==== 3D Візуалізація ВСІХ псевдокореляційних параметрів ====
                        fields = fieldnames(MK);
                        num_fields = numel(fields);
                    figure('Name', ['3D-представлення псевдокореляційних ядер Мюллера для кроку = ', num2str(step)]);
                    set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
                    for k = 1:num_fields
                        subplot(4, 3, k);
                        data = MK.(fields{k});
                        % Отримуємо реальні розміри даних
                        [rows, cols] = size(data);
                        % Створюємо діапазони на основі розмірів матриці даних
                        % Центр матриці відповідає нульовому зсуву
                        center_x = ceil(cols/2);
                        center_y = ceil(rows/2);
                        % Створюємо вектори координат
                        x_coords = ((1:cols) - center_x) * step;
                        y_coords = ((1:rows) - center_y) * step;
                        % Створюємо сітку
                        [X, Y] = meshgrid(x_coords, y_coords);
                        surf(X, Y, data);
                        shading interp;
                        view(3);
                        axis tight;
                        % Додаємо підписи осей
                        xlabel('\Delta x');
                        ylabel('\Delta y');
                        % Витягуємо назву компонента з назви поля
                        component_name = strrep(fields{k}, 'kernel_full_', '');
                        title(['3D. Псевдокореляція ', component_name], 'Interpreter', 'none'); 
                        colormap(colormap_value); 
                        colorbar;
                        view(30, 80);
                        % Додаємо сітку для кращої читабельності
                        grid on;
                        set(gca, 'GridAlpha', 0.3);
                    end
                        % Збереження результату
                        filename = fullfile(pathM, sprintf('%s.3D.Псевдокореляційні_ММ_КРОК_%d.png', colormap_value, step));
                        saveas(gcf, filename);
                        close(gcf);

                    % ==== 2D Візуалізація окремого ====
                    for k = 1:num_fields
                        % Підготовка даних
                        data = MK.(fields{k});
                        [rows, cols] = size(data);
                        center_x = ceil(cols / 2);
                        center_y = ceil(rows / 2);
                        x_coords = ((1:cols) - center_x) * step;
                        y_coords = ((1:rows) - center_y) * step;
                        % Створення фігури
                        figure('Name', ['2D Псевдокореляція ', strrep(fields{k}, 'kernel_full_', ''), ' (крок = ', num2str(step), ')']);
                        set(gcf, 'Units', 'normalized', 'OuterPosition', [0.1 0.1 0.8 0.8]);
                        % Візуалізація
                        imagesc(x_coords, y_coords, data);
                        axis image;
                        colormap(colormap_value);
                        colorbar;
                        % Підписи
                        xlabel('\Delta x');
                        ylabel('\Delta y');
                        component_name = strrep(fields{k}, 'kernel_full_', '');
                        title(['2D представлення псевдокореляційного ядра для ', component_name], 'FontSize', 14);
                        % Відображення сітки
                        grid on;
                        set(gca, 'GridAlpha', 0.3);
                        % Збереження
                        filename_separate = fullfile(pathM, sprintf('%s.2D.Псевдокореляція_%s_КРОК_%d.png', colormap_value, component_name, step));
                        saveas(gcf, filename_separate);
                        close(gcf);
                    end

                    % ==== 3D Візуалізація окремого ====
                    for k = 1:num_fields
                        figure('Name', ['3D Псевдокореляція ', strrep(fields{k}, 'kernel_full_', ''), ' (крок = ', num2str(step), ')']);
                        set(gcf, 'Units', 'normalized', 'OuterPosition', [0.1 0.1 0.8 0.8]);
                        data = MK.(fields{k});
                        [rows, cols] = size(data);
                        % Створюємо діапазони на основі розмірів матриці даних
                        center_x = ceil(cols/2);
                        center_y = ceil(rows/2);
                        x_coords = ((1:cols) - center_x) * step;
                        y_coords = ((1:rows) - center_y) * step;
                        [X, Y] = meshgrid(x_coords, y_coords);
                        surf(X, Y, data);
                        shading interp;
                        xlabel('\Delta x');
                        ylabel('\Delta y');
                        component_name = strrep(fields{k}, 'kernel_full_', '');
                        title(['3D представлення псевдокореляційного ядра для ', component_name], 'FontSize', 14);
                        colormap(colormap_value);
                        colorbar;
                        % Налаштування перегляду
                        view(45, 60);
                        axis tight;
                        grid on;
                        set(gca, 'GridAlpha', 0.3);
                        % Додаємо освітлення для кращого вигляду
                        %lighting gouraud;
                        %camlight headlight;
                        % Збереження окремого файлу
                        filename_separate = fullfile(pathM, sprintf('%s.3D.Псевдокореляція_%s_КРОК_%d.png', colormap_value, component_name, step));
                        saveas(gcf, filename_separate);
                        close(gcf);
                    end

               end %steps
        end %T_rho_period
    end %T_LB_period
end %colormap