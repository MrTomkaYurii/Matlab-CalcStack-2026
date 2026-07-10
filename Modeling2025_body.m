%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% -------- Вхідні параметри
colormap_value = 'jet';                  % 🔧 Мапа кольорів

m = 400;                                % 🔧 кількість рядків
n = 400;                                % 🔧 кількість стовпців

% Періоди
T_LB_periods = [50, 100, 200];      % 🔧 ПЕРІОД для LB (фазові зсуви)
T_rho_periods = [50, 100, 150];     % 🔧 ПЕРІОД для rho (орієнтація оптичних осей)

steps = [5, 10, 20];                % 🔧 кроки сканування

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Формування розподілів фазових зсувів та оптичних осей
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:length(T_LB_periods)
    T_LB = T_LB_periods(i);
    fprintf('--- T_LB = %d ---\n', T_LB);
    
    for j = 1:length(T_rho_periods)
        T_rho = T_rho_periods(j);
        fprintf(' T_rho = %d\n', T_rho);
        
        % створення теки
        folder_name = sprintf('ФазовийЗсувПеріод-%d - ОптичнаВісьПеріод-%d', T_LB, T_rho);
        full_path = fullfile('C:\[TOMKA] - Modelling', folder_name);
        if ~exist(full_path, 'dir')
            mkdir(full_path);
        end

        % Індекси по стовпцях (0-based)
        cols = (0:n-1);  % вектор-рядок
        % Формули з переходом до потрібного діапазону
        LB = pi * (1 + sin(2 * pi * cols / T_LB));        % [0, 2π]
        rho = (pi/2) * (1 + sin(2 * pi * cols / T_rho));  % [0, π]
    
        % Розподіл по всій області
        LB_map = repmat(LB, m, 1);
        rho_map = repmat(rho, m, 1);
        
        % ---------------------------------------
        % Обираємо рядок для перерізу (по осі OX)
        row_idx = m/2;  % центральний рядок
        LB_slice = LB_map(row_idx, :);
        rho_slice = rho_map(row_idx, :);
                                % === ВІЗУАЛІЗАЦІЯ ===
                                figure('Name', sprintf('2D. Періоди: T_LB = %d, T_rho = %d', T_LB, T_rho));
                                set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
                                colormap (colormap_value);
                                    % --- Верхній ряд: перерізи по OX ---
                                    subplot(2,2,1);
                                    plot(cols, LB_slice, 'b', 'LineWidth', 1.5);
                                    title('Переріз LB по осі OX (рядок 500)');
                                    xlabel('X (пікселі)');
                                    ylabel('LB');
                                    grid on;
                                    xlim([0 n-1]);
                                    subplot(2,2,2);
                                    plot(cols, rho_slice, 'b', 'LineWidth', 1.5);
                                    title('Переріз \rho по осі OX (рядок 500)');
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
                                    subplot(2,2,4);
                                    imagesc(rho_map);
                                    colorbar; 
                                    title(sprintf('2D. Період: T_{\\rho} = %d', T_rho));
                                    xlabel('Стовпець (X)');
                                    ylabel('Рядок (Y)');
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
                                    title('3D-переріз LB по рядку 500');
                                    xlabel('X (Стовпець)');
                                    ylabel('Y = 500');
                                    zlabel('LB');
                                    xlim([1 n]);
                                    view(45, 25); 
                                    % Верхній правий: 3D-переріз rho
                                    subplot(2,2,2);
                                    plot3(X_slice, Y_slice, Z_rho_slice, 'b', 'LineWidth', 2);
                                    grid on;
                                    title('3D-переріз \rho по рядку 500');
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
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Виклик функції для розріхунку едементів матриці Мюллера 
        % двоточкових параметрів
        % [M, pathM] = Modeling2025_MM(steps, LB_map, rho_map, full_path, colormap_value, n);

        %[M, pathM] = Modeling2025_MM(steps, LB_map, rho_map, full_path, 'gray', n);
        %[M, pathM] = Modeling2025_MM(steps, LB_map, rho_map, full_path, 'jet', n);

        %[Alfa, pathAlfa] = Modeling2025_alfa(steps, LB_map, rho_map, full_path, 'gray', n);
        %[Alfa, pathAlfa] = Modeling2025_alfa(steps, LB_map, rho_map, full_path, 'jet', n);

        %[Betta, pathBetta] = Modeling2025_betta(steps, LB_map, rho_map, full_path, 'gray', n);
        [Betta, pathBetta] = Modeling2025_betta(steps, LB_map, rho_map, full_path, 'jet', n);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
end