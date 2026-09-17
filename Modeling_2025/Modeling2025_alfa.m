
function [Alfa, pathAlfa ] = Modeling2025_alfa(steps, LB_map, rho_map, full_path, colormap_value, n)
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %  Modelling2025_alfa - розрахунок двоточких параметрів азимута поляризації
   %  Перебираємо кроки тільки. v.1.0
   %
   %  Синтаксис:
   %   result = your_function_name(steps, var1, var2, var3)
   %
   %  Вхідні параметри:
   %   steps          - масив кроків для сканування двоточкових параметрів [5, 10, 20]
   %   LB_map         - мапа-розподіл фазових зсувів
   %   rho_map        - мапа-розподіл орієнтацій оптичних осей  
   %   full_path      - шлях до поточної теки де ми будемо створювати підтеки або просто зберігати результати
   %   colormap_value - мапа кольорыв для зображення
   %   n              - розмірність квадрату зображення
   %
   %  Вихідні параметри:
   %   Alfa        - структура зі значеннями двоточкових параметрів ел.матр. Мюллера
   %   pathAlfa    - шлях до теки куди ми все зберігали.
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   

   % Ініціалізація
   pathAlfa = full_path;
    % Цикл по кроках
   for i = 1:length(steps)
        step = steps(i);  % Задаємо крок по X     
        fprintf(' Крок: %d\n', step)

        subfolder_name = sprintf('Крок сканування %d', step);
        pathAlfa = fullfile(full_path, subfolder_name);
        if ~exist(pathAlfa, 'dir')
            mkdir(pathAlfa);
        end
        fprintf(' Тека: %s\n', pathAlfa)

        % ==== Формування пар r_i та r_{i+step} ====
        valid_range = 1:(n - step);  % обмежимося допустимим діапазоном
        % Витягуємо LB1, LB2, rho1, rho2
        LB1  = LB_map(:, valid_range);
        LB2  = LB_map(:, valid_range + step);
        rho1 = rho_map(:, valid_range);
        rho2 = rho_map(:, valid_range + step); 
        %% ---- ДВОТОЧКОВІ ПАРАМЕТРИ ВЕКТОРА СТОКСА ----
        SC1 = 1 + 0.5*i*(LB2.*cos(2*rho2) - LB1.*cos(2*rho1));
        SC2 = 1 - 0.5*i*(LB2.*cos(2*rho2) - LB1.*cos(2*rho1));
        SC3 = 0.5*i*(LB1.*sin(2*rho1) - LB2.*sin(2*rho2));
        SC4 = -0.5*(LB1.*sin(2*rho1) + LB2.*sin(2*rho2));
        %% ---- ДВОТОЧКОВИЙ АЗИМУТ ПОЛЯРИЗАЦИИ ----
        alpha_c = 0.5 * atan((SC3) ./ (SC2));
        Alfa = alpha_c;
        %% ---- МОДУЛЬ та АРГУМЕНТ ДВОТОЧКОГОВОГО АЗИМУТА ПОЛЯРИЗАЦІЇ ----
        % Модуль
            global alpha_c_abs;
            alpha_c_abs = 0.5 * atan(0.5 * (LB1.*sin(2*rho1) - LB2.*sin(2*rho2)));
        % Аргумент
            global theta_2alpha_c;
            % Обчислення знаменника
            denominator = LB2 .* cos(2 * rho2) - LB1 .* cos(2 * rho1);   
            % Маска сингулярностей
            epsilon = 1e-6;
            sing_mask = abs(denominator) < epsilon;
            % Заміна малих значень, щоб уникнути поділу на нуль
            denominator(sing_mask) = sign(denominator(sing_mask)) * epsilon;
            % Обчислення theta(2α_c)
            theta_2alpha_c = 1 ./ denominator;
                                
                                %% ==== МОДУЛЬ =====
                                figure('Name', 'Модуль двоточкового азимуту поляризації');
                                set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
                                % --- Побудова координатної сітки ---
                                [X, Y] = meshgrid(1:size(alpha_c_abs,2), 1:size(alpha_c_abs,1));
                                % --- Побудова 3D поверхні ---
                                surf(X, Y, alpha_c_abs);
                                shading interp;              
                                view(30, 80);                 
                                axis tight;
                                axis on;
                                grid on;
                                colorbar; colormap(colormap_value);
                                % --- Підписи ---
                                title('3D-представлення. Двоточковий ел-т модуля азимуту ');
                                xlabel('X (пікселі)');
                                ylabel('Y (пікселі)');
                                zlabel('Значення');
                                    filename = fullfile(pathAlfa, sprintf('%s.3D.МОДУЛЬ.png', colormap_value));
                                    saveas(gcf, filename);
                                    close(gcf);

                                %% ==== АРГУМЕНТ =====
                                % ==== Візуалізація розподілу сингулярностей ====
                                theta_max = max(theta_2alpha_c(:));
                                theta_min = min(theta_2alpha_c(:));
                                min_matrix = (theta_2alpha_c <= -5000);  % логическая матрица минимумов
                                max_matrix = (theta_2alpha_c >= +5000);  % логическая матрица максимумов
                                [rows, cols] = size(theta_2alpha_c);
                                figure('Name', 'Розподіл сингулярностей по аргументу двот. азимуту поляризації'); 
                                set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
                                colormap (colormap_value);
                                subplot(1,2,1)
                                % Витягуємо координати максимумів (червоні кружки)
                                [max_y, max_x] = find(max_matrix);
                                plot(max_x, max_y, 'ro', 'MarkerSize', 6, 'LineWidth', 1.5);
                                title('Сингулярності +∞');
                                xlabel('x');
                                ylabel('y');
                                grid on;
                                subplot(1,2,2)
                                % Витягуємо координати мінімумів (сині кружки)
                                [min_y, min_x] = find(min_matrix);
                                plot(min_x, min_y, 'bo', 'MarkerSize', 6, 'LineWidth', 1.5);
                                title('Сингулярності -∞');
                                xlabel('x');
                                ylabel('y');
                                grid on;
                                    filename = fullfile(pathAlfa, sprintf('%s.2D.РозподілСингулярностей_АРГУМЕНТ_КРОК_%d_.png', colormap_value, step));
                                    saveas(gcf, filename);
                                    close(gcf);


                                % ==== Візуалізація 3D представлення двоточкового аргумента поляризації із розподілом сингулярностей ====
                                [X, Y] = meshgrid(1:size(theta_2alpha_c, 2), 1:size(theta_2alpha_c, 1));
                                figure('Name', 'Аргумент двоточкового азимуту поляризації. Повна шкала'); 
                                set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
                                colormap (colormap_value);
                                surf(X, Y, theta_2alpha_c, ...
                                    'EdgeColor', 'none', ...
                                    'FaceLighting', 'gouraud');
                                colorbar;
                                caxis([theta_min, theta_max]);  % кольори у межах даних
                                zlim([theta_min, theta_max]);   % Z-межі строго по даним
                                % ==== Покращення графіки ====
                                shading interp;
                                camlight headlight;
                                material dull;
                                axis tight;
                                view(45, 30);
                                % ==== Відображення сингулярностей ====
                                [y_sing, x_sing] = find(sing_mask);
                                z_sing = theta_2alpha_c(sing_mask);  % беремо значення після всіх обчислень
                                hold on;
                                plot3(x_sing, y_sing, z_sing, 'ro', 'MarkerSize', 6, 'MarkerFaceColor', 'r');
                                hold off;
                                % ==== Підпис ====
                                title('\theta_{2\alpha_c} — двоточковий азимут');
                                xlabel('X'); ylabel('Y'); zlabel('\theta_{2\alpha_c}');
                                legend('Поверхня \theta_{2\alpha_c}', 'Сингулярності');
                                    filename = fullfile(pathAlfa, sprintf('%s.3D.АРГУМЕНТ_КРОК_%d_.png', colormap_value, step));
                                    saveas(gcf, filename);
                                    close(gcf);

                                % ==== 3D представлення двоточкового аргумента поляризації із розподілом сингулярностей (відкорегован межі) ====
                                % Создаем маску для обычных значений (без сингулярностей)
                                normal_mask = ~(min_matrix | max_matrix);
                                normal_values = theta_2alpha_c(normal_mask);
                                % Находим минимум и максимум среди обычных значений
                                theta_min_normal = min(normal_values);
                                theta_max_normal = max(normal_values);
                                % ==== Создание модифицированной матрицы ====
                                theta_2alpha_modified = theta_2alpha_c; % копируем исходную матрицу
                                % Заменяем экстремальные значения на найденные min/max
                                theta_2alpha_modified(max_matrix) = theta_max_normal; % заменяем большие значения на максимум
                                theta_2alpha_modified(min_matrix) = theta_min_normal; % заменяем малые значения на минимум
                                % ==== Создание координатной сетки ====
                                [X, Y] = meshgrid(1:size(theta_2alpha_c, 2), 1:size(theta_2alpha_c, 1));
                                % ==== Визуализация ====
                                figure('Name', 'Аргумент двоточкового азимуту поляризації. Обрізана шкала'); 
                                set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
                                colormap (colormap_value);
                                surf(X, Y, theta_2alpha_modified, ...
                                    'EdgeColor', 'none', ...
                                    'FaceLighting', 'gouraud');
                                colorbar;
                                caxis([theta_min_normal, theta_max_normal]); % цвета в пределах нормальных данных
                                zlim([theta_min_normal, theta_max_normal]);  % Z-пределы по нормальным данным
                                % ==== Улучшение графики ====
                                shading interp;
                                camlight headlight;
                                material dull;
                                axis tight;
                                view(5, 10);
                                % ==== Отображение сингулярностей ====
                                % Координаты максимумов
                                [y_max, x_max] = find(max_matrix);
                                z_max = repmat(theta_max_normal, length(x_max), 1); % все на уровне максимума
                                % Координаты минимумов  
                                [y_min, x_min] = find(min_matrix);
                                z_min = repmat(theta_min_normal, length(x_min), 1); % все на уровне минимума
                                hold on;
                                plot3(x_max, y_max, z_max, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r');
                                plot3(x_min, y_min, z_min, 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b');
                                hold off;
                                % ==== Подписи ====
                                title('\theta_{2\alpha_c} — аргумент двоточкового азимута поляризації');
                                xlabel('X'); ylabel('Y'); zlabel('\theta_{2\alpha_c}');
                                legend('Поверхня \theta_{2\alpha_c}', 'Сингулярність (+∞)', 'Сингулярність (-∞)');
                                    filename = fullfile(pathAlfa, sprintf('%s.3D.АРГУМЕНТ_РОЗПОДІЛ_КРОК_%d_.png', colormap_value, step));
                                    saveas(gcf, filename);
                                    close(gcf);
   end  %of steps
end     %of function