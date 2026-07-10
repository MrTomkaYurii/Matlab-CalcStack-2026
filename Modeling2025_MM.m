
function [M, pathM ] = Modeling2025_MM(steps, LB_map, rho_map, full_path, colormap_value, n)
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %  Modelling2025_MМ - розрахунок двоточких параметрів елементів матриці
   %  Мюллера. Перебираємо кроки тільки. v.1.0
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
   %   М        - структура зі значеннями двоточкових параметрів ел.матр. Мюллера
   %   pathM    - шлях до теки куди ми все зберігали.
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   % Ініціалізація
   M = struct();
   pathM = full_path;

   % Цикл по кроках
   for i = 1:length(steps)
        step = steps(i);  % Задаємо довільний крок по X     
        fprintf(' Крок: %d\n', step)

        subfolder_name = sprintf('Крок сканування %d', step);
        pathM = fullfile(full_path, subfolder_name);
        if ~exist(pathM, 'dir')
            mkdir(pathM);
        end
        fprintf(' Тека: %s\n', pathM);
       
        % ==== Формування пар r_i та r_{i+step} ====
        valid_range = 1:(n - step);  % обмежимося допустимим діапазоном
        % Витягуємо LB1, LB2, rho1, rho2
        LB1  = LB_map(:, valid_range);
        LB2  = LB_map(:, valid_range + step);
        rho1 = rho_map(:, valid_range);
        rho2 = rho_map(:, valid_range + step); 
        % ==== Обчислення двоточкових елементів матриці Мюллера ====
        M.f11 = 1 + 0.25 * LB1 .* LB2 .* cos(2 * (rho1 - rho2));
        M.f12 = 1 - 0.25 * LB1 .* LB2 .* sin(2*rho1) .* sin(2*rho2);
        M.f21 = 1 - 0.25 * LB1 .* LB2 .* sin(2*rho1) .* sin(2*rho2);       
        M.f22 = 1 + 0.25 * LB1 .* LB2 .* cos(2 * (rho1 + rho2));
        M.f23 =  0.25 * (LB1 .* sin(2*rho1) + LB2 .* sin(2*rho2));
        M.f24 =  0.25 * LB1 .* LB2 .* sin(2*(rho1 + rho2));
        M.f32 = -M.f23;
        M.f33 = 1 - 0.25 * LB1 .* LB2 .* cos(2 * (rho1 + rho2));
        M.f34 =  0.25 * LB1 .* LB2 .* cos(2*(rho1 - rho2));
        M.f43 = -M.f34;
        M.f44 = 1 - 0.25 * LB1 .* LB2 .* cos(2 * (rho1 - rho2));
        M.f42 = -M.f24;
                           % ==== Візуалізація всіх ====
                           fields = fieldnames(M);
                           num_fields = numel(fields);
                           %---
                           figure('Name', ['Двоточкові елементи матриці Мюллера для кроку = ', num2str(step)]);
                           for k = 1:num_fields
                               set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
                               colormap (colormap_value);
                               subplot(4,3,k);
                               imagesc(M.(fields{k}));
                               axis image off;
                               title(fields{k});
                               colorbar;
                           end
                                filename = fullfile(pathM, sprintf('%s.2D.Двоточкові_ММ_КРОК_%d_.png', colormap_value, step));
                                saveas(gcf, filename);
                                close(gcf);
                            %---
                            figure('Name', ['3D-представлення Мюллерових елементів для кроку = ', num2str(step)]);
                            set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
                            for k = 1:num_fields
                                subplot(4, 3, k);
                                data = M.(fields{k});
                                [X, Y] = meshgrid(1:size(data,2), 1:size(data,1));
                                surf(X, Y, data);
                                shading interp;
                                view(3);
                                axis tight;
                                axis off;
                                title(fields{k}, 'Interpreter', 'none');
                                colormap(colormap_value); colorbar;
                                view(30, 80);
                            end
                                filename = fullfile(pathM, sprintf('%s.3D.Двоточкові_ММ_КРОК_%d.png', colormap_value, step));
                                saveas(gcf, filename);
                                close(gcf);
                           % ==== Візуаліація окремих двоточкових елементів ==== 
                           for k = 1:num_fields
                               data = M.(fields{k});
                               %---
                               figure('Name', ['Двоточковий_Елемент_ММ_', fields{k}]);
                               set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
                               imagesc(data);
                               axis image;            % зберігає співвідношення осей
                               axis on;               % вмикає осі
                               grid on;               % додає сітку
                               colorbar; colormap(colormap_value); 
                               title(['2D-представлення. Двоточковий елемент ', fields{k}]);
                               xlabel('X (пікселі)');
                               ylabel('Y (пікселі)'); 
                               % Встановлення шкали осей
                               xticks(0:100:size(data,2));
                               yticks(0:100:size(data,1));
                                 filename = fullfile(pathM, sprintf('%s.%s.2D.png', colormap_value, fields{k}));
                                 saveas(gcf, filename);
                                 close(gcf);
                           end
                           %---
                           for k = 1:num_fields
                                data = M.(fields{k});
                                figure('Name', ['Двоточковий_Елемент_ММ_', fields{k}]);
                                set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
                                % --- Побудова координатної сітки ---
                                [X, Y] = meshgrid(1:size(data,2), 1:size(data,1));
                                % --- Побудова 3D поверхні ---
                                surf(X, Y, data);
                                shading interp;              
                                view(30, 80);                 
                                axis tight;
                                axis on;
                                grid on;
                                colorbar; colormap(colormap_value);
                                % --- Підписи ---
                                title(['3D-представлення. Двоточковий елемент ', fields{k}]);
                                xlabel('X (пікселі)');
                                ylabel('Y (пікселі)');
                                zlabel('Значення');
                                    filename = fullfile(pathM, sprintf('%s.%s.3D.png', colormap_value, fields{k}));
                                    saveas(gcf, filename);
                                    close(gcf);
                           end
   end %end of steps
end %end of function