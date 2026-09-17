function [delta, rho] = harmonic_modulation(colormap_name, matrix_size, m_values, save_path, distribution_type)
% Функція для побудови гармонічних модуляцій орієнтації осей
% Входи:
%   colormap_name    - назва кольорової мапи ('jet', 'hot', 'cool', тощо)
%   matrix_size      - розмір матриці (наприклад, 400)
%   m_values         - масив значень m (наприклад, [1, 5, 20])
%   save_path        - шлях до теки для збереження графіків
%   distribution_type - тип розподілу (1 або 2)
%                      1: δ = 0.1π(1+sin(...)), ρ = 0.5π(1+sin(...))
%                      2: δ = 0.1π(1+sin(...)), ρ = π*exp(-0.5*x²)
% Виходи:
%   delta           - двовимірний розподіл δ (структура з полями для кожного m)
%   rho             - двовимірний розподіл ρ (структура з полями для кожного m)
% Перевірка входів
if nargin < 5
    error('Потрібно 5 параметрів: colormap_name, matrix_size, m_values, save_path, distribution_type');
end

% Створення теки якщо не існує
if ~exist(save_path, 'dir')
    mkdir(save_path);
end

    % % ------------------------------------------------------------------------
    % % Параметри для ліній
    % n = matrix_size;
    % % Створення координатної сітки для 2D розподілів
    % [X, Y] = meshgrid(0:n-1, 0:n-1);
    % % Ініціалізація структур для виходу (2D матриці)
    % delta = struct();
    % rho = struct();
    % % Заморозка дельта для частного случая (вариант 1 и 2)
    % m_delta = m_values(1);
    % -------------------------------------------------------------------------
    % % ЛІНІЇ
    % % Обчислення 2D розподілів для кожного m
    % for m_idx = 1:length(m_values)
    %     m = m_values(m_idx);    
    %     % Обчислення δ та ρ в залежності від типу розподілу - 2D матриця
    %     if distribution_type == 1
    %         % Тип 1: ρ = 0.5π(1 + sin(2π/100...))
    %         rho_2d = 0.5 * pi * (1 + sin(2*pi/100 * m * X));
    %         delta_2d = 0.1 * pi * (1 + sin(2*pi/100 * m_delta * X));
    %     elseif distribution_type == 2
    %         % Тип 2: ρ = 0.5π(1 + sin(2π/80 ...))
    %         rho_2d = 0.5 * pi * (1 + sin(2*pi/80 * m * X));
    %         delta_2d = 0.1 * pi * (1 + sin(2*pi/100 * m_delta * X));
    %     elseif distribution_type == 3
    %         % Тип 3: ρ = π*exp(-0.5*x²)
    %         % Нормалізуємо X для експоненти
    %         X_norm = (X - n/2) / (n/4);
    %         rho_exp = exp(-0.5 * X_norm.^2);  % от некоторого минимума до 1
    %         rho_min = min(rho_exp(:));
    %         rho_max = max(rho_exp(:));
    %         rho_2d = pi * (rho_exp - rho_min) / (rho_max - rho_min);  % от 0 до π
    %         delta_2d = 0.1 * pi * (1 + sin(2*pi/100 * m * X));
    %     elseif distribution_type == 4
    %         % Тип 4: ρ = π*exp(-0.4*x²)
    %         % Нормалізуємо X для експоненти
    %         X_norm = (X - n/2) / (n/4);
    %         rho_exp = exp(-0.4 * X_norm.^2);
    %         rho_min = min(rho_exp(:));
    %         rho_max = max(rho_exp(:));
    %         rho_2d = pi * (rho_exp - rho_min) / (rho_max - rho_min);  % от 0 до π
    %         delta_2d = 0.1 * pi * (1 + sin(2*pi/100 * m * X));
    %     else
    %         error('distribution_type має бути 1, 2, 3 або 4');
    %     end
    % 
    %     % Збереження 2D матриць у структури
    %     field_name = sprintf('m_%d', m);
    %     delta.(field_name) = delta_2d;
    %     rho.(field_name) = rho_2d;
    % end

        % -------------------------------------------------------------------------
        % Параметри
        % Обчислення 2D розподілів для кожного m з концентричними кільцями
        % Створюємо радіальну координату від центру зображення
        n = matrix_size;
        center_x = n/2;
        center_y = n/2;
        [Y, X] = meshgrid(1:n, 1:n);
        R = sqrt((X - center_x).^2 + (Y - center_y).^2); % Радіальна відстань від центру
        % Ініціалізація структур для виходу (2D матриці)
        delta = struct();
        rho = struct();
        % Заморозка дельта для частного случая (вариант 1 и 2)
        m_delta = m_values(1);
        % -------------------------------------------------------------------------
        % РАДІАЛЬНІ КІЛЬЦЯ
        % Обчислення 2D розподілів для кожного m з концентричними кільцями
        for m_idx = 1:length(m_values)
            m = m_values(m_idx);
            % Обчислення δ та ρ в залежності від типу розподілу - концентричні кільця
            if distribution_type == 1
                % Тип 1: ρ = 0.5π(1 + sin(2π/100...)) - концентричні кільця
                rho_2d = 0.5 * pi * (1 + sin(2*pi/100 * m * R));
                delta_2d = 0.1 * pi * (1 + sin(2*pi/100 * m_delta * R));
            elseif distribution_type == 2
                % Тип 2: ρ = 0.5π(1 + sin(2π/80 ...)) - концентричні кільця
                rho_2d = 0.5 * pi * (1 + sin(2*pi/80 * m * R));
                delta_2d = 0.1 * pi * (1 + sin(2*pi/100 * m_delta * R));
            elseif distribution_type == 3
                % Тип 3: ρ = π*exp(-0.5*r²) - радіальний гауссів розподіл
                % Нормалізуємо R для експоненти
                R_norm = R / (n/4);
                rho_exp = exp(-0.5 * R_norm.^2);
                rho_min = min(rho_exp(:));
                rho_max = max(rho_exp(:));
                rho_2d = pi * (rho_exp - rho_min) / (rho_max - rho_min); % від 0 до π
                delta_2d = 0.1 * pi * (1 + sin(2*pi/100 * m * R));
            elseif distribution_type == 4
                % Тип 4: ρ = π*exp(-0.4*r²) - радіальний гауссів розподіл
                % Нормалізуємо R для експоненти
                R_norm = R / (n/4);
                rho_exp = exp(-0.4 * R_norm.^2);
                rho_min = min(rho_exp(:));
                rho_max = max(rho_exp(:));
                rho_2d = pi * (rho_exp - rho_min) / (rho_max - rho_min); % від 0 до π
                delta_2d = 0.1 * pi * (1 + sin(2*pi/100 * m * R));
            else
                error('distribution_type має бути 1, 2, 3 або 4');
            end
            
            % Збереження 2D матриць у структури
            field_name = sprintf('m_%d', m);
            delta.(field_name) = delta_2d;
            rho.(field_name) = rho_2d;
        end




    % =====================================================================
    %% Створення 1D графіків для візуалізації (але повертаємо 2D матриці)
    figure('Units', 'normalized', 'Position', [0 0 1 1]);
    subplot_idx = 1;
    % 1D візуалізація (перетин по центру 2D матриці)
    x = 0:n-1;
    for m_idx = 1:length(m_values)
        m = m_values(m_idx);
        field_name = sprintf('m_%d', m);
        % Беремо центральний рядок 2D матриці для 1D візуалізації
        center_row = round(n/2);
        delta_1d = delta.(field_name)(center_row, :);
        rho_1d = rho.(field_name)(center_row, :);
        
        % Графік для δ
        subplot(3, 2, subplot_idx);
        plot(x, delta_1d, 'LineWidth', 2, 'Color', [0.2, 0.4, 0.8]);
        grid on;
                if distribution_type == 1 || distribution_type == 2
                title(sprintf('$\\delta = 0.2\\pi \\sin\\left(\\frac{2\\pi}{100} \\cdot %d \\cdot x\\right)$', m_delta), ...
                      'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
                else
                title(sprintf('$\\delta = 0.2\\pi \\sin\\left(\\frac{2\\pi}{100} \\cdot %d \\cdot x\\right)$', m), ...
                      'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
                end
        xlabel('x', 'FontSize', 12);
        ylabel('$\delta$', 'FontSize', 12, 'Interpreter', 'latex');
        ylim([0, 0.2*pi]);
        % Додаємо горизонтальні лінії для меж
        hold on;
        yline(0, 'r--', 'LineWidth', 1, 'Alpha', 0.7);
        yline(0.2*pi, 'r--', 'LineWidth', 1, 'Alpha', 0.7);
        text(0.8*n, 0.05, '0', 'FontSize', 10, 'Color', 'red');
        text(0.8*n, 0.2*pi-0.05, '$0.2\pi$', 'FontSize', 10, 'Color', 'red', 'Interpreter', 'latex');
        hold off;
        
        % Графік для ρ
        subplot(3, 2, subplot_idx + 1);
        plot(x, rho_1d, 'LineWidth', 2, 'Color', [0.8, 0.2, 0.4]);
        grid on;
        if distribution_type == 1
            title(sprintf('$\\rho = \\pi \\sin\\left(\\frac{2\\pi}{100} \\cdot %d \\cdot x\\right)$', m), ...
                  'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
            ylim([0, pi]);
            yline(pi, 'r--', 'LineWidth', 1, 'Alpha', 0.7);
            text(0.8*n, pi-0.1, '$\pi$', 'FontSize', 10, 'Color', 'red', 'Interpreter', 'latex');
        elseif distribution_type == 2
            title(sprintf('$\\rho = \\pi \\sin\\left(\\frac{2\\pi}{80} \\cdot %d \\cdot x\\right)$', m), ...
                  'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
            ylim([0, pi]);
            yline(pi, 'r--', 'LineWidth', 1, 'Alpha', 0.7);
            text(0.8*n, pi-0.1, '$\pi$', 'FontSize', 10, 'Color', 'red', 'Interpreter', 'latex');
        elseif distribution_type == 3
            title(sprintf('$\\rho = \\pi \\cdot e^{-0.5x^2}$'), ...
                  'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
            ylim([0, pi]);
            yline(pi, 'r--', 'LineWidth', 1, 'Alpha', 0.7);
            text(0.8*n, pi-0.1, '$\pi$', 'FontSize', 10, 'Color', 'red', 'Interpreter', 'latex');
        elseif distribution_type == 4
            title(sprintf('$\\rho = \\pi \\cdot e^{-0.4x^2}$'), ...
                  'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
            ylim([0, pi]);
            yline(pi, 'r--', 'LineWidth', 1, 'Alpha', 0.7);
            text(0.8*n, pi-0.1, '$\pi$', 'FontSize', 10, 'Color', 'red', 'Interpreter', 'latex');
        end
        xlabel('x', 'FontSize', 12);
        ylabel('$\rho$', 'FontSize', 12, 'Interpreter', 'latex');
         % Додаємо горизонтальні лінії для меж
        hold on;
        yline(0, 'r--', 'LineWidth', 1, 'Alpha', 0.7);
        text(0.8*n, 0.1, '0', 'FontSize', 10, 'Color', 'red');
        hold off;
        
        subplot_idx = subplot_idx + 2;
    end
    
    % Загальний заголовок
    if distribution_type == 1
        sgtitle(sprintf('Гармонічні модуляції орієнтацей осей (Тип 1) - %d×%d', n, n), ...
                'FontSize', 14, 'FontWeight', 'bold');
    elseif distribution_type == 2
        sgtitle(sprintf('Гармонічні модуляції орієнтацей осей (Тип 2) - %d×%d', n, n), ...
                'FontSize', 14, 'FontWeight', 'bold');
    elseif distribution_type == 3
        sgtitle(sprintf('Нормальні розподіли орієнтацей осей (Тип 3) - %d×%d', n, n), ...
                'FontSize', 14, 'FontWeight', 'bold');
    elseif distribution_type == 4
        sgtitle(sprintf('Нормальні розподіли орієнтацей осей (Тип 4) - %d×%d', n, n), ...
                'FontSize', 14, 'FontWeight', 'bold');
    end
    % Збереження 1D графіків
    saveas(gcf, fullfile(save_path, sprintf('%s_1D_plots_case_%d.png', colormap_name, distribution_type)));
    close(gcf);


    % =====================================================================
    %% Створення 2D візуалізації
    figure('Units', 'normalized', 'Position', [0 0 1 1]);
    subplot_idx = 1;
    
    % 2D візуалізація для кожного m
    for m_idx = 1:length(m_values)
        m = m_values(m_idx);
        field_name = sprintf('m_%d', m);
        
        % Візуалізація δ
        subplot(2, 3, subplot_idx);
        imagesc(delta.(field_name));
        colormap(gca, colormap_name);
        colorbar;
                if distribution_type == 1 || distribution_type == 2
                title(sprintf('$\\delta = 0.2\\pi \\sin\\left(\\frac{2\\pi}{100} \\cdot %d \\cdot x\\right)$', m_delta), ...
                      'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
                else
                title(sprintf('$\\delta = 0.2\\pi \\sin\\left(\\frac{2\\pi}{100} \\cdot %d \\cdot x\\right)$', m), ...
                      'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
                end
        xlabel('x', 'FontSize', 12);
        ylabel('y', 'FontSize', 12);
        axis equal tight;
        
        % Візуалізація ρ
        subplot(2, 3, subplot_idx + 3);
        imagesc(rho.(field_name));
        colormap(gca, colormap_name);
        colorbar;
        if distribution_type == 1
            title(sprintf('$\\rho = \\pi \\sin\\left(\\frac{2\\pi}{100} \\cdot %d \\cdot x\\right)$', m), ...
                  'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
        elseif distribution_type == 2
            title(sprintf('$\\rho = \\pi \\sin\\left(\\frac{2\\pi}{80} \\cdot %d \\cdot x\\right)$', m), ...
                  'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
        elseif distribution_type == 3
            title(sprintf('$\\rho = \\pi \\cdot e^{-0.5x^2}$'), ...
                  'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
        elseif distribution_type == 4
            title(sprintf('$\\rho = \\pi \\cdot e^{-0.4x^2}$'), ...
                  'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
        end
        xlabel('x', 'FontSize', 12);
        ylabel('y', 'FontSize', 12);
        axis equal tight;
        
        subplot_idx = subplot_idx + 1;
    end
    
    % Загальний заголовок
    if distribution_type == 1
        sgtitle(sprintf('Гармонічні модуляції орієнтацей осей (Тип 1) - %d×%d', n, n), ...
                'FontSize', 14, 'FontWeight', 'bold');
    elseif distribution_type == 2
        sgtitle(sprintf('Гармонічні модуляції орієнтацей осей (Тип 2) - %d×%d', n, n), ...
                'FontSize', 14, 'FontWeight', 'bold');
    elseif distribution_type == 3
        sgtitle(sprintf('Нормальні розподіли орієнтацей осей (Тип 3) - %d×%d', n, n), ...
                'FontSize', 14, 'FontWeight', 'bold');
    elseif distribution_type == 4
        sgtitle(sprintf('Нормальні розподіли орієнтацей осей (Тип 4) - %d×%d', n, n), ...
                'FontSize', 14, 'FontWeight', 'bold');
    end
    % Збереження 2D графіків
    saveas(gcf, fullfile(save_path, sprintf('%s_2D_plots_case_%d.png', colormap_name, distribution_type)));
    close(gcf);


    % =====================================================================
    %% Створення 3D візуалізації
    figure('Units', 'normalized', 'Position', [0 0 1 1]);
    
    % 3D поверхні для кожного m
    for m_idx = 1:length(m_values)
        m = m_values(m_idx);
        field_name = sprintf('m_%d', m);
        % Використовуємо менший розмір для 3D візуалізації (для швидкості)
        % x_3d = 0:4:n-1;
        % y_3d = 0:4:n-1;
        % [X_3d, Y_3d] = meshgrid(x_3d, y_3d);
        % % Інтерполяція для 3D візуалізації
        % delta_3d = interp2(X, Y, delta.(field_name), X_3d, Y_3d, 'linear');
        % rho_3d = interp2(X, Y, rho.(field_name), X_3d, Y_3d, 'linear');
        
        % 3D поверхня для δ
        subplot(2, 3, m_idx);
        surf(X, Y, delta.(field_name));
        colormap(gca, colormap_name);
        shading interp;
                if distribution_type == 1 || distribution_type == 2
                title(sprintf('$\\delta = 0.2\\pi \\sin\\left(\\frac{2\\pi}{100} \\cdot %d \\cdot x\\right)$', m_delta), ...
                      'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
                else
                title(sprintf('$\\delta = 0.2\\pi \\sin\\left(\\frac{2\\pi}{100} \\cdot %d \\cdot x\\right)$', m), ...
                      'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
                end
        xlabel('x', 'FontSize', 12);
        ylabel('y', 'FontSize', 12);
        zlabel('$\delta$', 'FontSize', 12, 'Interpreter', 'latex');
    
        % 3D поверхня для ρ
        subplot(2, 3, m_idx + 3);
        surf(X, Y, rho.(field_name));
        colormap(gca, colormap_name);
        shading interp;
        if distribution_type == 1
            title(sprintf('$\\rho = \\pi \\sin\\left(\\frac{2\\pi}{100} \\cdot %d \\cdot x\\right)$', m), ...
                  'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
        elseif distribution_type == 2
            title(sprintf('$\\rho = \\pi \\sin\\left(\\frac{2\\pi}{80} \\cdot %d \\cdot x\\right)$', m), ...
                  'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
        elseif distribution_type == 3
            title(sprintf('$\\rho = \\pi \\cdot e^{-0.5x^2}$'), ...
                  'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
        elseif distribution_type == 4
            title(sprintf('$\\rho = \\pi \\cdot e^{-0.4x^2}$'), ...
                  'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
        end
        xlabel('x', 'FontSize', 12);
        ylabel('y', 'FontSize', 12);
        zlabel('$\rho$', 'FontSize', 12, 'Interpreter', 'latex');
    end
    % Загальний заголовок
    if distribution_type == 1
        sgtitle(sprintf('Гармонічні модуляції орієнтацей осей (Тип 1) - %d×%d', n, n), ...
                'FontSize', 14, 'FontWeight', 'bold');
    elseif distribution_type == 2
        sgtitle(sprintf('Гармонічні модуляції орієнтацей осей (Тип 2) - %d×%d', n, n), ...
                'FontSize', 14, 'FontWeight', 'bold');
    elseif distribution_type == 3
        sgtitle(sprintf('Нормальні розподіли орієнтацей осей (Тип 3) - %d×%d', n, n), ...
                'FontSize', 14, 'FontWeight', 'bold');
    elseif distribution_type == 4
        sgtitle(sprintf('Нормальні розподіли орієнтацей осей (Тип 4) - %d×%d', n, n), ...
                'FontSize', 14, 'FontWeight', 'bold');
    end
    % Збереження 3D графіків
    saveas(gcf, fullfile(save_path, sprintf('%s_3D_plots_case_%d.png', colormap_name, distribution_type)));
    close(gcf);
    

    % =====================================================================
    %% Створення додаткового порівняльного аналізу
    figure('Units', 'normalized', 'Position', [0 0 1 1]);
    
    % Порівняльний аналіз (центральний переріз)
    x = 0:n-1;
    center_row = round(n/2);
    
    subplot(1, 2, 1);
    hold on;
    colors = ['r', 'g', 'b'];
    for m_idx = 1:length(m_values)
        m = m_values(m_idx);
        field_name = sprintf('m_%d', m);
        delta_1d = delta.(field_name)(center_row, :);
        plot(x, delta_1d, 'Color', colors(mod(m_idx-1, 3)+1), 'LineWidth', 1, ...
             'DisplayName', sprintf('m = %d', m));
    end
    grid on;
    title(sprintf('$\\delta = 0.2\\pi \\sin\\left(\\frac{2\\pi}{100} \\cdot m \\cdot x\\right)$'), ...
          'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
    xlabel('x', 'FontSize', 12);
    ylabel('$\delta$', 'FontSize', 12, 'Interpreter', 'latex');
    hold off;
    
    subplot(1, 2, 2);
    hold on;
    for m_idx = 1:length(m_values)
        m = m_values(m_idx);
        field_name = sprintf('m_%d', m);
        rho_1d = rho.(field_name)(center_row, :);
        plot(x, rho_1d, 'Color', colors(mod(m_idx-1, 3)+1), 'LineWidth', 1, ...
             'DisplayName', sprintf('m = %d', m));
    end
    grid on;
        if distribution_type == 1
            title(sprintf('$\\rho = \\pi \\sin\\left(\\frac{2\\pi}{100} \\cdot m \\cdot x\\right)$'), ...
                  'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
        elseif distribution_type == 2
            title(sprintf('$\\rho = \\pi \\sin\\left(\\frac{2\\pi}{80} \\cdot m \\cdot x\\right)$'), ...
                  'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
        elseif distribution_type == 3
            title(sprintf('$\\rho = \\pi \\cdot e^{-0.5x^2}$'), ...
                  'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
        elseif distribution_type == 4
            title(sprintf('$\\rho = \\pi \\cdot e^{-0.4x^2}$'), ...
                  'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
        end
    xlabel('x', 'FontSize', 12);
    ylabel('$\rho$', 'FontSize', 12, 'Interpreter', 'latex');
    
    hold off;
    % Загальний заголовок
    if distribution_type == 1
        sgtitle(sprintf('Гармонічні модуляції орієнтацей осей (Тип 1) - %d×%d', n, n), ...
                'FontSize', 14, 'FontWeight', 'bold');
    elseif distribution_type == 2
        sgtitle(sprintf('Гармонічні модуляції орієнтацей осей (Тип 2) - %d×%d', n, n), ...
                'FontSize', 14, 'FontWeight', 'bold');
    elseif distribution_type == 3
        sgtitle(sprintf('Нормальні розподіли орієнтацей осей (Тип 3) - %d×%d', n, n), ...
                'FontSize', 14, 'FontWeight', 'bold');
    elseif distribution_type == 4
        sgtitle(sprintf('Нормальні розподіли орієнтацей осей (Тип 4) - %d×%d', n, n), ...
                'FontSize', 14, 'FontWeight', 'bold');
    end
    % Збереження порівняльного аналізу
    saveas(gcf, fullfile(save_path, sprintf('%s_comparison_case_%d.png', colormap_name, distribution_type)));
    close(gcf);



%% Виведення статистики
fprintf('Функція harmonic_modulation завершена успішно!\n');
fprintf('Значення m: %s\n', mat2str(m_values));
fprintf('Тип розподілу: %d\n', distribution_type);
fprintf('Кольорова мапа: %s\n', colormap_name);
fprintf('Графіки збережено в: %s\n', save_path);
fprintf('Діапазон δ: [0, %.4f]\n', 0.2*pi);
if distribution_type == 1
    fprintf('Діапазон ρ: [0, %.4f]\n', pi);
else
    fprintf('Діапазон ρ: [0, %.4f] (Гаусс)\n', pi);
end
fprintf('Повернуто 2D матриці розмірів %d × %d для кожного m\n', n, n);
end

% ==================== ПРИКЛАДИ ВИКЛИКУ ====================
% Приклад 1: Тип 1 (синус для обох δ та ρ)
% [delta1, rho1] = harmonic_modulation('jet', 400, [1, 5, 20], './results_type1', 1);
% Приклад 2: Тип 2 (δ - синус, ρ - Гаусс)
% [delta2, rho2] = harmonic_modulation('hot', 400, [1, 5, 20], './results_type2', 2);
% Приклад 3: Різні параметри
% [delta3, rho3] = harmonic_modulation('cool', 300, [2, 10, 15], './my_results', 1);
% Приклад 4: Малий розмір для тестування
% [delta4, rho4] = harmonic_modulation('viridis', 100, [1, 3], './test_results', 2);
% Доступ до 2D матриць:
% delta1.m_1   % 2D матриця δ для m=1 (розмір matrix_size × matrix_size)
% delta1.m_5   % 2D матриця δ для m=5 (розмір matrix_size × matrix_size)
% delta1.m_20  % 2D матриця δ для m=20 (розмір matrix_size × matrix_size)
% rho1.m_1     % 2D матриця ρ для m=1 (розмір matrix_size × matrix_size)