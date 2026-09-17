function [Betta, pathBetta ] = Modeling2025_betta(steps, LB_map, rho_map, full_path, colormap_value, n)
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %  Modelling2025_betta - розрахунок двоточких параметрів азимута поляризації
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
   %   Betta        - структура зі значеннями двоточкових параметрів ел.матр. Мюллера
   %   pathBetta    - шлях до теки куди ми все зберігаємо
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % Ініціалізація
   pathBetta = full_path;
    % Цикл по кроках
   for i = 1:length(steps)
        step = steps(i);  % Задаємо крок по X     
        fprintf(' Крок: %d\n', step)

        subfolder_name = sprintf('Крок сканування %d', step);
        pathBetta = fullfile(full_path, subfolder_name);
        if ~exist(pathBetta, 'dir')
            mkdir(pathBetta);
        end
        fprintf(' Тека: %s\n', pathBetta)

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
        %% --- ДВОТОЧКОВИЙ ПАРАМЕТР ЕЛІПТИЧНОСТІ ----
        % Основная формула эллиптичности
        betta_c = 0.5 * asin(real(SC3) ./ real(SC1));
        Betta = betta_c;
        % Модуль эллиптичности
        betta_c_abs = abs( 0.5 * asin((LB1.*sin(2*rho1) - LB2.*sin(2*rho2))) );
        % Аргумент функции синуса эллиптичности
        theta_sin_betta_c = 0.5 * atan((LB1.*sin(2*rho1) + LB2.*sin(2*rho2)));

            %% ВІЗУАЛІЗАЦІЯ
            % ==== МОДУЛЬ. 3D =====
            figure('Name', 'Модуль двоточкової еліптичності поляризації');
            set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
            % --- Побудова координатної сітки ---
            [X, Y] = meshgrid(1:size(betta_c_abs,2), 1:size(betta_c_abs,1));
            % --- Побудова 3D поверхні ---
            surf(X, Y, betta_c_abs);
            shading interp;              
            view(30, 80);                 
            axis tight;
            axis on;
            grid on;
            colorbar; colormap(colormap_value);
            % --- Підписи ---
            title('3D-представлення. Двоточковий модуль еліптичності ');
            xlabel('X (пікселі)');
            ylabel('Y (пікселі)');
            zlabel('Значення');
                filename = fullfile(pathBetta, sprintf('%s.3D.МОДУЛЬ.png', colormap_value));
                saveas(gcf, filename);
                close(gcf);
            % ==== МОДУЛЬ. 2D =====
            figure('Name', '2D-Модуль двоточкової еліптичності поляризації');
            set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
            imagesc(betta_c_abs);
            axis image;
            axis on;
            grid on;
            colorbar;
            colormap(colormap_value);
            % --- Підписи ---
            title('2D-представлення. Двоточковий модуль еліптичності');
            xlabel('X (пікселі)');
                filename = fullfile(pathBetta, sprintf('%s.2D.МОДУЛЬ.png', colormap_value));
                saveas(gcf, filename);
                close(gcf);

            % ==== АРГУМЕНТ. 3D =====
            figure('Name', '3D-представлення. Аргумент двоточкової еліптичності');
            set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
            % --- Побудова координатної сітки ---
            [X, Y] = meshgrid(1:size(theta_sin_betta_c,2), 1:size(theta_sin_betta_c,1));
            % --- Побудова 3D поверхні ---
            surf(X, Y, theta_sin_betta_c);
            shading interp;              
            view(30, 80);                 
            axis tight;
            axis on;
            grid on;
            colorbar; colormap(colormap_value);
            % --- Підписи ---
            title('3D-представлення. Двоточковий аргумент еліптичності ');
            xlabel('X (пікселі)');
            ylabel('Y (пікселі)');
            zlabel('Значення');
                filename = fullfile(pathBetta, sprintf('%s.3D.АРУГМЕНТ.png', colormap_value));
                saveas(gcf, filename);
                close(gcf);
            % ==== АРГУМЕНТ. 2D =====
            figure('Name', '2D-представлення. Аргумент двоточкової еліптичності');
            set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
            imagesc(theta_sin_betta_c);
            axis image;
            axis on;
            grid on;
            colorbar;
            colormap(colormap_value);
            % --- Підписи ---
            title('2D-представлення. Двоточковий аргумент еліптичності');
            xlabel('X (пікселі)');
                filename = fullfile(pathBetta, sprintf('%s.2D.АРГУМЕНТ.png', colormap_value));
                saveas(gcf, filename);
                close(gcf);
   end%step
end%function