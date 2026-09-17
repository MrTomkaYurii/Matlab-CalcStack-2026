%% ========================================================================
%  ВІЗУАЛІЗАЦІЯ ОРІЄНТАЦІЇ ОПТИЧНОЇ ОСІ ВЗДОВЖ ФІБРИЛИ
%  ========================================================================
%  Цей код створює одну фібрилу (циліндр) та моделює зміну орієнтації
%  оптичної осі вздовж осі Z за синусоїдальним законом
%  
%  Версія 2: Множинні кольорові схеми + покращена візуалізація
%  Автор: Optical Axis Fibril Model
%  Дата: 2026-02-13
%% ========================================================================

clear; close all; clc;

%% ========================================================================
%  БЛОК КОНФІГУРАЦІЇ - Налаштування параметрів
%  ========================================================================

% Геометричні параметри фібрили
diameter = 56;              % Діаметр фібрили в пікселях
radius = diameter / 2;      % Радіус фібрили
depth_z = 336;              % Довжина фібрили вздовж осі Z (пікселі)

% Параметри синусоїдальної зміни оптичної осі
theta_amplitude = 90;       % Амплітуда коливань кута (градуси) ±90°
theta_period = 112;         % Період синусоїди (пікселі)
theta_offset = 0;           % Початкова фаза (градуси)

% Кольорові схеми для візуалізації
colormaps_list = {'parula', 'gray', 'jet'};

% Параметри збереження
save_path_top = 'C://1';
save_figures = true;

% Створити папку для збереження
if save_figures && ~exist(save_path, 'dir')
    mkdir(save_path);
    fprintf('Created folder: %s\n', save_path);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                                                                        %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%               1. Создание одной фибриллы (ориентация оптических осей)                  %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                                                                        %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ========================================================================
%  РОЗРАХУНОК ОРІЄНТАЦІЇ ОПТИЧНОЇ ОСІ ВЗДОВЖ Z
%  ========================================================================

fprintf('\n=== Calculating Optical Axis Orientation ===\n');
fprintf('Fibril diameter: %d pixels\n', diameter);
fprintf('Fibril length (Z): %d pixels\n', depth_z);
fprintf('Angle amplitude: ±%.1f degrees\n', theta_amplitude);
fprintf('Period: %d pixels\n', theta_period);

% Масив координат Z
z_array = 1:depth_z;

% Розрахунок кута для кожного Z-шару (в градусах)
theta_degrees = theta_offset + theta_amplitude * sin(2*pi*z_array/theta_period);

% Конвертація в радіани для обчислень
theta_radians = deg2rad(theta_degrees);

fprintf('Angle range: %.1f° to %.1f°\n', min(theta_degrees), max(theta_degrees));

%% ========================================================================
%  СТВОРЕННЯ 3D МАСИВУ ОПТИЧНОЇ ОСІ
%  ========================================================================

fprintf('\n=== Creating 3D Optical Axis Array ===\n');

% Ініціалізація 3D масиву (NaN = поза фібрилою)
optical_axis_3D = nan(diameter, diameter, depth_z);

% Створення координатної сітки XY
[X, Y] = meshgrid(1:diameter, 1:diameter);
X_centered = X - (diameter + 1) / 2;
Y_centered = Y - (diameter + 1) / 2;
R = sqrt(X_centered.^2 + Y_centered.^2);

% Маска круга (фібрила в перерізі XY)
circle_mask = R <= radius;

% Заповнення 3D масиву
for z = 1:depth_z
    % Створити зріз XY
    slice = nan(diameter, diameter);
    
    % Всередині круга - одне значення кута для всього зрізу
    slice(circle_mask) = theta_degrees(z);
    
    % Записати зріз у 3D масив
    optical_axis_3D(:, :, z) = slice;
end

fprintf('3D array created: %d x %d x %d voxels\n', diameter, diameter, depth_z);
fprintf('Valid voxels (inside fibril): %d\n', sum(~isnan(optical_axis_3D(:))));


%% ========================================================================
%  СТВОРЕННЯ ПАПКИ ДЛЯ ЗБЕРЕЖЕННЯ
%  ========================================================================

% Створити підпапку "OpticalAxis - Окремий шар"
save_path = fullfile(save_path_top, 'OpticalAxis');

if ~exist(save_path_array, 'dir')
    mkdir(save_path_array);
    fprintf('\nCreated folder: %s\n', save_path);
end

%% ========================================================================
%  ОСНОВНИЙ ЦИКЛ ПО КОЛЬОРОВИМ СХЕМАМ
%  ========================================================================

fprintf('\n=== Starting Visualization Loop ===\n');

for cmap_idx = 1:length(colormaps_list)
    current_cmap = colormaps_list{cmap_idx};
    fprintf('\n--- Processing colormap: %s (%d/%d) ---\n', ...
            current_cmap, cmap_idx, length(colormaps_list));
    
%% ========================================================================
%  ВІЗУАЛІЗАЦІЯ 1: Графік зміни кута вздовж Z
%  ========================================================================

fprintf('Creating Visualization 1: Angle vs Z...\n');

fig1 = figure('Position', [100, 100, 1400, 600]);

% Subplot 1: Кут в градусах
subplot(1, 2, 1);
plot(z_array, theta_degrees, 'b-', 'LineWidth', 2.5);
grid on;
xlabel('Z Position (pixels)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Optical Axis Angle (degrees)', 'FontSize', 12, 'FontWeight', 'bold');
title('Optical Axis Orientation along Fibril (Z axis)', 'FontSize', 14, 'FontWeight', 'bold');
ylim([min(theta_degrees)-10, max(theta_degrees)+10]);

% Позначити ключові точки
hold on;
[~, max_idx] = max(theta_degrees);
[~, min_idx] = min(theta_degrees);
zero_crossings = find(diff(sign(theta_degrees)));

plot(z_array(max_idx), theta_degrees(max_idx), 'ro', 'MarkerSize', 10, ...
     'LineWidth', 2, 'MarkerFaceColor', 'r');
plot(z_array(min_idx), theta_degrees(min_idx), 'gs', 'MarkerSize', 10, ...
     'LineWidth', 2, 'MarkerFaceColor', 'g');

if ~isempty(zero_crossings)
    plot(z_array(zero_crossings(1)), theta_degrees(zero_crossings(1)), 'md', ...
         'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', 'm');
end

legend('Angle variation', sprintf('Maximum (%.1f°)', max(theta_degrees)), ...
       sprintf('Minimum (%.1f°)', min(theta_degrees)), 'Zero crossing', ...
       'Location', 'best', 'FontSize', 10);
hold off;

% Subplot 2: Векторне представлення на декількох зрізах
subplot(1, 2, 2);
num_slices = 8;
z_slices = round(linspace(1, depth_z, num_slices));

hold on;
colors = jet(num_slices);

for i = 1:num_slices
    z = z_slices(i);
    theta = theta_radians(z);
    
    % Координати стрілки (центр фібрили)
    x_center = 0;
    y_center = i * 2;  % Розташувати стрілки вертикально
    
    % Компоненти напрямку
    dx = radius * 0.8 * cos(theta);
    dy = radius * 0.8 * sin(theta);
    
    % Малювання стрілки
    quiver(x_center, y_center, dx, dy, 0, 'Color', colors(i, :), ...
           'LineWidth', 3, 'MaxHeadSize', 1.5);
    
    % Підпис z-координати та кута
    text(radius + 2, y_center, sprintf('Z=%d (%.1f°)', z, theta_degrees(z)), ...
         'FontSize', 10, 'Color', colors(i, :), 'FontWeight', 'bold');
end

axis equal;
grid on;
xlim([-radius-1, radius+15]);
ylim([0, (num_slices+1)*2]);
xlabel('X direction', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Z slice number', 'FontSize', 12, 'FontWeight', 'bold');
title('Optical Axis Direction at Different Z Positions', 'FontSize', 14, 'FontWeight', 'bold');
hold off;

% Загальний заголовок
sgtitle(sprintf('Optical Axis Orientation Analysis (Amplitude: ±%.0f°, Period: %d px)', ...
        theta_amplitude, theta_period), 'FontSize', 16, 'FontWeight', 'bold');

% Збереження
if save_figures
    filename = sprintf('OptAxOr_angle_profile_%s.png', current_cmap);
    saveas(fig1, fullfile(save_path, filename));
    fprintf('Saved: %s\n', filename);
end
close(fig1);

%% ========================================================================
%  ВІЗУАЛІЗАЦІЯ 2: Кольорове кодування кута (XY зрізи на різних Z)
%  ========================================================================

fprintf('Creating Visualization 2: XY Slices with Color Coding...\n');

fig2 = figure('Position', [100, 100, 1600, 1000]);

% Вибрати 9 характерних зрізів
num_slices_display = 9;
z_display = round(linspace(1, depth_z, num_slices_display));

for i = 1:num_slices_display
    z = z_display(i);
    
    subplot(3, 3, i);
    
    % Отримати зріз XY
    slice_data = optical_axis_3D(:, :, z);
    
    % Відобразити з прозорістю для NaN
    h = imagesc(slice_data);
    set(h, 'AlphaData', ~isnan(slice_data));
    
    % Додати контур фібрили
    hold on;
    theta_circle = linspace(0, 2*pi, 200);
    circle_x = (diameter+1)/2 + radius * cos(theta_circle);
    circle_y = (diameter+1)/2 + radius * sin(theta_circle);
    plot(circle_x, circle_y, 'r-', 'LineWidth', 2);
    
    % Додати стрілку орієнтації
    center_x = (diameter+1)/2;
    center_y = (diameter+1)/2;
    arrow_length = radius * 0.6;
    theta_rad = theta_radians(z);
    arrow_dx = arrow_length * cos(theta_rad);
    arrow_dy = arrow_length * sin(theta_rad);
    
    quiver(center_x, center_y, arrow_dx, arrow_dy, 0, 'k-', ...
           'LineWidth', 3, 'MaxHeadSize', 2);
    
    hold off;
    
    colormap(gca, current_cmap);
    caxis([min(theta_degrees), max(theta_degrees)]);
    axis equal tight;
    title(sprintf('Z = %d px (θ = %.1f°)', z, theta_degrees(z)), ...
          'FontSize', 11, 'FontWeight', 'bold');
    set(gca, 'YDir', 'normal', 'FontSize', 9);
    
    if i == num_slices_display
        cb = colorbar;
        cb.Label.String = 'Angle (degrees)';
        cb.Label.FontSize = 10;
    end
end

sgtitle(sprintf('Optical Axis Orientation in XY Cross-Sections (Colormap: %s)', current_cmap), ...
        'FontSize', 15, 'FontWeight', 'bold');

% Збереження
if save_figures
    filename = sprintf('OptAxOr_xy_slices_%s.png', current_cmap);
    saveas(fig2, fullfile(save_path, filename));
    fprintf('Saved: %s\n', filename);
end
close(fig2);

%% ========================================================================
%  ВІЗУАЛІЗАЦІЯ 3: 3D відображення з кольоровим кодуванням (GIBBON)
%  ========================================================================

fprintf('Creating Visualization 3: 3D Visualization with GIBBON...\n');

% Підготовка даних для GIBBON
M = optical_axis_3D;
L_mask = ~isnan(M);  % Маска валідних вокселів
M(isnan(M)) = 0;     % Замінити NaN на 0

% Параметри візуалізації
fontSize = 12;
face_alpha = 0.7;

% Створення 3D патчу
[F, V, C] = im2patch(M, L_mask, 'vb');

% Відображення
fig3 = figure('Position', [100, 100, 1400, 1000]);

subplot(1, 2, 1);
gpatch(F, V, C, 'none', face_alpha);
colormap(gca, current_cmap);
hcb = colorbar;
hcb.Label.String = 'Optical Axis Angle (degrees)';
hcb.Label.FontSize = fontSize;
caxis([min(theta_degrees), max(theta_degrees)]);

lighting gouraud;
camlight('headlight');
material shiny;
axisGeom(gca, fontSize);

xlabel('X (pixels)', 'FontSize', fontSize, 'FontWeight', 'bold');
ylabel('Y (pixels)', 'FontSize', fontSize, 'FontWeight', 'bold');
zlabel('Z (pixels)', 'FontSize', fontSize, 'FontWeight', 'bold');
title(sprintf('3D Fibril - Optical Axis (Colormap: %s)', current_cmap), ...
      'FontSize', 13, 'FontWeight', 'bold');
view([-40, 30]);
axis equal tight;
grid on;

% Вид збоку (вздовж осі Y)
subplot(1, 2, 2);
gpatch(F, V, C, 'none', face_alpha);
colormap(gca, current_cmap);
hcb = colorbar;
hcb.Label.String = 'Optical Axis Angle (degrees)';
hcb.Label.FontSize = fontSize;
caxis([min(theta_degrees), max(theta_degrees)]);

lighting gouraud;
camlight('headlight');
material shiny;
axisGeom(gca, fontSize);

xlabel('X (pixels)', 'FontSize', fontSize, 'FontWeight', 'bold');
ylabel('Y (pixels)', 'FontSize', fontSize, 'FontWeight', 'bold');
zlabel('Z (pixels)', 'FontSize', fontSize, 'FontWeight', 'bold');
title('Side View - Variation along Z', ...
      'FontSize', 13, 'FontWeight', 'bold');
view([0, 0]);  % Вид збоку
axis equal tight;
grid on;

sgtitle(sprintf('3D Fibril Optical Axis Visualization (D=%dpx, L=%dpx, Colormap: %s)', ...
        diameter, depth_z, current_cmap), 'FontSize', 15, 'FontWeight', 'bold');

% Збереження
if save_figures
    filename = sprintf('OptAxOr_3D_gibbon_%s.png', current_cmap);
    saveas(fig3, fullfile(save_path, filename));
    fprintf('Saved: %s\n', filename);
end
close(fig3);

%% ========================================================================
%  ВІЗУАЛІЗАЦІЯ 4: Векторне поле в 3D
%  ========================================================================

fprintf('Creating Visualization 4: 3D Vector Field...\n');

fig4 = figure('Position', [100, 100, 1400, 1000]);

% Вибрати підмножину точок для відображення векторів (щоб не перевантажити)
step_xy = 8;   % Крок по XY
step_z = 20;   % Крок по Z

[X_grid, Y_grid, Z_grid] = meshgrid(1:step_xy:diameter, 1:step_xy:diameter, 1:step_z:depth_z);

% Ініціалізація компонентів векторів
U = zeros(size(X_grid));
V = zeros(size(X_grid));
W = zeros(size(X_grid));

% Заповнення векторів
for i = 1:numel(X_grid)
    x = X_grid(i);
    y = Y_grid(i);
    z = Z_grid(i);
    
    % Перевірка, чи точка всередині фібрили
    x_c = x - (diameter+1)/2;
    y_c = y - (diameter+1)/2;
    r = sqrt(x_c^2 + y_c^2);
    
    if r <= radius
        theta = theta_radians(z);
        U(i) = cos(theta);
        V(i) = sin(theta);
        W(i) = 0;  % Вектор лежить в площині XY
    else
        U(i) = NaN;
        V(i) = NaN;
        W(i) = NaN;
    end
end

% Видалити NaN точки
valid_idx = ~isnan(U);
X_plot = X_grid(valid_idx);
Y_plot = Y_grid(valid_idx);
Z_plot = Z_grid(valid_idx);
U_plot = U(valid_idx);
V_plot = V(valid_idx);
W_plot = W(valid_idx);

% Відображення векторного поля
quiver3(X_plot, Y_plot, Z_plot, U_plot, V_plot, W_plot, 1.5, ...
        'LineWidth', 2, 'Color', 'b', 'MaxHeadSize', 0.5);

hold on;

% Додати контури фібрили на декількох зрізах
num_contours = 5;
z_contours = round(linspace(1, depth_z, num_contours));
theta_circle = linspace(0, 2*pi, 100);

for z = z_contours
    circle_x = (diameter+1)/2 + radius * cos(theta_circle);
    circle_y = (diameter+1)/2 + radius * sin(theta_circle);
    circle_z = z * ones(size(circle_x));
    plot3(circle_x, circle_y, circle_z, 'r-', 'LineWidth', 1.5);
end

hold off;

xlabel('X (pixels)', 'FontSize', fontSize, 'FontWeight', 'bold');
ylabel('Y (pixels)', 'FontSize', fontSize, 'FontWeight', 'bold');
zlabel('Z (pixels)', 'FontSize', fontSize, 'FontWeight', 'bold');
title(sprintf('3D Vector Field - Optical Axis Direction (Colormap: %s)', current_cmap), ...
      'FontSize', 14, 'FontWeight', 'bold');
grid on;
axis equal tight;
view([-40, 30]);

% Збереження
if save_figures
    filename = sprintf('OptAxOr_vector_field_3D_%s.png', current_cmap);
    saveas(fig4, fullfile(save_path, filename));
    fprintf('Saved: %s\n', filename);
end
close(fig4);

%% ========================================================================
%  ВІЗУАЛІЗАЦІЯ 5: Розгортка циліндра (Unwrapped view)
%  ========================================================================

fprintf('Creating Visualization 5: Cylinder Unwrapped View...\n');

fig5 = figure('Position', [100, 100, 1600, 800]);

% Створити розгортку: кутова координата (0-360°) vs Z
num_angles = 180;  % Кількість кутових точок
angle_array = linspace(0, 2*pi, num_angles);

unwrapped = nan(num_angles, depth_z);

for z = 1:depth_z
    for a = 1:num_angles
        % Координати точки на поверхні циліндра
        x = (diameter+1)/2 + radius * cos(angle_array(a));
        y = (diameter+1)/2 + radius * sin(angle_array(a));
        
        % Отримати значення кута оптичної осі
        x_idx = round(x);
        y_idx = round(y);
        
        if x_idx >= 1 && x_idx <= diameter && y_idx >= 1 && y_idx <= diameter
            unwrapped(a, z) = optical_axis_3D(y_idx, x_idx, z);
        end
    end
end

% Subplot 1: Розгортка з кольоровим кодуванням
subplot(2, 1, 1);
imagesc(1:depth_z, rad2deg(angle_array), unwrapped);
colormap(gca, current_cmap);
cb = colorbar;
cb.Label.String = 'Optical Axis Angle (degrees)';
cb.Label.FontSize = 12;
caxis([min(theta_degrees), max(theta_degrees)]);

xlabel('Z Position (pixels)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Angular Position on Cylinder Surface (degrees)', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('Unwrapped Cylinder Surface (Colormap: %s)', current_cmap), ...
      'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'YDir', 'normal');
grid on;

% Subplot 2: Профіль по центральній лінії розгортки
subplot(2, 1, 2);
central_line = unwrapped(round(num_angles/2), :);
plot(1:depth_z, central_line, 'b-', 'LineWidth', 2.5);
grid on;
xlabel('Z Position (pixels)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Optical Axis Angle (degrees)', 'FontSize', 12, 'FontWeight', 'bold');
title('Optical Axis Profile along Central Line of Unwrapped Surface', ...
      'FontSize', 14, 'FontWeight', 'bold');
ylim([min(theta_degrees)-10, max(theta_degrees)+10]);

% Збереження
if save_figures
    filename = sprintf('OptAxOr_unwrapped_cylinder_%s.png', current_cmap);
    saveas(fig5, fullfile(save_path, filename));
    fprintf('Saved: %s\n', filename);
end
close(fig5);

%% ========================================================================
%  НОВА ВІЗУАЛІЗАЦІЯ 6: Комбінований вид (Enhanced comprehension)
%  ========================================================================

fprintf('Creating Visualization 6: Combined Enhanced View...\n');

fig6 = figure('Position', [50, 50, 1800, 1000]);

% Subplot 1: XZ проекція з кольором (вид збоку)
subplot(2, 3, 1);
xz_slice = squeeze(optical_axis_3D(round(diameter/2), :, :));  % Центральний зріз по Y
imagesc(1:depth_z, 1:diameter, xz_slice);
colormap(gca, current_cmap);
cb = colorbar;
cb.Label.String = 'Angle (°)';
caxis([min(theta_degrees), max(theta_degrees)]);
xlabel('Z (pixels)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('X (pixels)', 'FontSize', 11, 'FontWeight', 'bold');
title('XZ Cross-Section (Side View)', 'FontSize', 12, 'FontWeight', 'bold');
set(gca, 'YDir', 'normal');
grid on;

% Subplot 2: YZ проекція з кольором (вид збоку)
subplot(2, 3, 2);
yz_slice = squeeze(optical_axis_3D(:, round(diameter/2), :));  % Центральний зріз по X
imagesc(1:depth_z, 1:diameter, yz_slice);
colormap(gca, current_cmap);
cb = colorbar;
cb.Label.String = 'Angle (°)';
caxis([min(theta_degrees), max(theta_degrees)]);
xlabel('Z (pixels)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Y (pixels)', 'FontSize', 11, 'FontWeight', 'bold');
title('YZ Cross-Section (Side View)', 'FontSize', 12, 'FontWeight', 'bold');
set(gca, 'YDir', 'normal');
grid on;

% Subplot 3: Гістограма розподілу кутів
subplot(2, 3, 3);
valid_angles = optical_axis_3D(~isnan(optical_axis_3D));
histogram(valid_angles, 50, 'FaceColor', [0.2 0.6 0.8], 'EdgeColor', 'k');
xlabel('Optical Axis Angle (degrees)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Frequency (voxels)', 'FontSize', 11, 'FontWeight', 'bold');
title('Angle Distribution Histogram', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

% Subplot 4: 3D ізоповерхні для різних кутових діапазонів
subplot(2, 3, 4);
hold on;

% Три діапазони кутів
angle_ranges = [min(theta_degrees), prctile(theta_degrees, 33), ...
                prctile(theta_degrees, 67), max(theta_degrees)];
colors_iso = [0.8 0.2 0.2; 0.2 0.8 0.2; 0.2 0.2 0.8];

for i = 1:3
    mask_range = (M >= angle_ranges(i)) & (M < angle_ranges(i+1));
    if sum(mask_range(:)) > 100
        [F_iso, V_iso, ~] = im2patch(M, mask_range, 'vb');
        gpatch(F_iso, V_iso, colors_iso(i,:), 'none', 0.5);
    end
end

lighting gouraud;
camlight('headlight');
axisGeom(gca, 10);
xlabel('X', 'FontSize', 10);
ylabel('Y', 'FontSize', 10);
zlabel('Z', 'FontSize', 10);
title('Angle Range Isosurfaces', 'FontSize', 12, 'FontWeight', 'bold');
legend(sprintf('Low (%.0f-%.0f°)', angle_ranges(1), angle_ranges(2)), ...
       sprintf('Mid (%.0f-%.0f°)', angle_ranges(2), angle_ranges(3)), ...
       sprintf('High (%.0f-%.0f°)', angle_ranges(3), angle_ranges(4)), ...
       'Location', 'best', 'FontSize', 9);
view([-40, 30]);
axis equal tight;
hold off;

% Subplot 5: Полярна діаграма орієнтацій
subplot(2, 3, 5);
z_polar = round(linspace(1, depth_z, 16));
theta_polar = theta_radians(z_polar);
r_polar = ones(size(theta_polar));
polarplot(theta_polar, r_polar, 'bo-', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
title('Polar Plot of Orientations', 'FontSize', 12, 'FontWeight', 'bold');
set(gca, 'FontSize', 10);

% Subplot 6: Спектральний аналіз (FFT)
subplot(2, 3, 6);
fft_signal = fft(theta_degrees);
fft_power = abs(fft_signal).^2;
fft_freq = (0:length(fft_power)-1) * (1/depth_z);
plot(fft_freq(1:floor(length(fft_freq)/2)), fft_power(1:floor(length(fft_power)/2)), ...
     'b-', 'LineWidth', 2);
xlabel('Spatial Frequency (1/pixel)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Power Spectrum', 'FontSize', 11, 'FontWeight', 'bold');
title('Fourier Transform - Periodicity Analysis', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
xlim([0, 0.1]);

% Загальний заголовок
sgtitle(sprintf('Enhanced Optical Axis Analysis (Colormap: %s)', current_cmap), ...
        'FontSize', 16, 'FontWeight', 'bold');

% Збереження
if save_figures
    filename = sprintf('OptAxOr_enhanced_combined_%s.png', current_cmap);
    saveas(fig6, fullfile(save_path, filename));
    fprintf('Saved: %s\n', filename);
end
close(fig6);

fprintf('Colormap %s completed!\n', current_cmap);

end  % Кінець циклу по кольоровим схемам

%% ========================================================================
%  ЗБЕРЕЖЕННЯ ДАНИХ
%  ========================================================================

fprintf('\n=== Saving Data ===\n');

% Зберегти змінні у .mat файл
if save_figures
    save(fullfile(save_path, 'OptAxOr_fibril_data.mat'), ...
         'optical_axis_3D', 'theta_degrees', 'theta_radians', 'z_array', ...
         'diameter', 'radius', 'depth_z', 'theta_amplitude', 'theta_period', 'theta_offset');
    fprintf('Saved: OptAxOr_fibril_data.mat\n');
end

%% ========================================================================
%  ФІНАЛЬНИЙ ЗВІТ
%  ========================================================================

fprintf('\n========================================\n');
fprintf('OPTICAL AXIS FIBRIL VISUALIZATION COMPLETE\n');
fprintf('========================================\n');
fprintf('Fibril parameters:\n');
fprintf('  - Diameter: %d pixels\n', diameter);
fprintf('  - Length (Z): %d pixels\n', depth_z);
fprintf('  - Volume: %d voxels\n', sum(~isnan(optical_axis_3D(:))));
fprintf('\nOptical axis variation:\n');
fprintf('  - Amplitude: ±%.1f degrees\n', theta_amplitude);
fprintf('  - Period: %d pixels\n', theta_period);
fprintf('  - Range: %.1f° to %.1f°\n', min(theta_degrees), max(theta_degrees));
fprintf('  - Number of full cycles: %.2f\n', depth_z/theta_period);
fprintf('\nColor schemes processed: %d\n', length(colormaps_list));
fprintf('  - %s\n', strjoin(colormaps_list, ', '));
fprintf('\nVisualization files saved to:\n');
fprintf('  %s\n', save_path);
fprintf('Total figures generated: %d per colormap\n', 6);
fprintf('========================================\n');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                                                                        %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%               2. Создание ряда фибрилл (ориентация оптических осей)                    %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                                                                        %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

save_path = 'C://1//';

%% ========================================================================
%  СТВОРЕННЯ МАСИВУ ФІБРИЛ З ОРІЄНТАЦІЄЮ ОПТИЧНОЇ ОСІ
%  ========================================================================
%  Цей блок дублює одиночну фібрилу вздовж осі X для створення
%  ряду фібрил з однаковою орієнтацією оптичної осі
%  ========================================================================

fprintf('\n\n');
fprintf('========================================\n');
fprintf('CREATING FIBRIL ARRAY ALONG X AXIS\n');
fprintf('========================================\n');

%% ========================================================================
%  ПАРАМЕТРИ МАСИВУ ФІБРИЛ
%  ========================================================================

number_of_fibrils_in_row = 6;  % Кількість фібрил у ряду (вздовж X)

fprintf('Creating array of %d fibrils...\n', number_of_fibrils_in_row);
fprintf('Each fibril: %d x %d x %d voxels\n', diameter, diameter, depth_z);

%% ========================================================================
%  СТВОРЕННЯ МАСИВУ - ДУБЛЮВАННЯ ВЗДОВЖ X
%  ========================================================================

% Розміри масиву фібрил
array_width = diameter * number_of_fibrils_in_row;  % Розмір вздовж X
array_height = diameter;                             % Розмір вздовж Y
array_depth = depth_z;                               % Розмір вздовж Z

% Ініціалізація 3D масиву для ряду фібрил
optical_axis_array_3D = nan(array_height, array_width, array_depth);

fprintf('\nArray dimensions: %d (Y) x %d (X) x %d (Z) voxels\n', ...
        array_height, array_width, array_depth);

% Дублювання фібрили вздовж осі X
for fibril_idx = 1:number_of_fibrils_in_row
    % Розрахунок діапазону стовпців для цієї фібрили
    col_start = (fibril_idx - 1) * diameter + 1;
    col_end = fibril_idx * diameter;
    
    fprintf('  Fibril #%d: columns %d-%d\n', fibril_idx, col_start, col_end);
    
    % Копіювання одиночної фібрили в відповідну позицію
    optical_axis_array_3D(:, col_start:col_end, :) = optical_axis_3D;
end

fprintf('Array created successfully!\n');
fprintf('Total voxels: %d\n', numel(optical_axis_array_3D));
fprintf('Valid voxels (inside fibrils): %d\n', sum(~isnan(optical_axis_array_3D(:))));

%% ========================================================================
%  СТВОРЕННЯ ПАПКИ ДЛЯ ЗБЕРЕЖЕННЯ
%  ========================================================================

% Створити підпапку "OpticalAxis - Окремий шар"
save_path_array = fullfile(save_path, 'OpticalAxis - Окремий шар');

if ~exist(save_path_array, 'dir')
    mkdir(save_path_array);
    fprintf('\nCreated folder: %s\n', save_path_array);
end

%% ========================================================================
%  СТВОРЕННЯ КОНТУРІВ ДЛЯ ВСІХ ФІБРИЛ
%  ========================================================================

% Параметри кола
theta_contour = linspace(0, 2*pi, 200);

% Масиви для збереження всіх контурів
all_circles_x = [];
all_circles_y = [];

for fibril_idx = 1:number_of_fibrils_in_row
    % Розрахунок центру цієї фібрили
    center_x = (fibril_idx - 1) * diameter + (diameter + 1) / 2;
    center_y = (diameter + 1) / 2;
    
    % Створення контуру круга
    circle_x_temp = center_x + radius * cos(theta_contour);
    circle_y_temp = center_y + radius * sin(theta_contour);
    
    % Додавання до загального масиву
    all_circles_x = [all_circles_x; circle_x_temp(:)];
    all_circles_y = [all_circles_y; circle_y_temp(:)];
end

%% ========================================================================
%  ОСНОВНИЙ ЦИКЛ ВІЗУАЛІЗАЦІЇ ПО КОЛЬОРОВИМ СХЕМАМ
%  ========================================================================

fprintf('\n=== Starting Array Visualization Loop ===\n');

for cmap_idx = 1:length(colormaps_list)
    current_cmap = colormaps_list{cmap_idx};
    fprintf('\n--- Processing array with colormap: %s (%d/%d) ---\n', ...
            current_cmap, cmap_idx, length(colormaps_list));

%% ========================================================================
%  ВІЗУАЛІЗАЦІЯ 1: XY зріз на різних Z (масив фібрил)
%  ========================================================================

fprintf('Creating Array Visualization 1: XY slices array...\n');

fig_arr1 = figure('Position', [50, 50, 1800, 1000]);

% Вибрати 6 характерних Z-зрізів
num_z_slices = 6;
z_slices_display = round(linspace(1, depth_z, num_z_slices));

for i = 1:num_z_slices
    z = z_slices_display(i);
    
    subplot(2, 3, i);
    
    % Отримати XY зріз масиву на цьому Z
    slice_array = optical_axis_array_3D(:, :, z);
    
    % Відобразити з прозорістю для NaN
    h = imagesc(slice_array);
    set(h, 'AlphaData', ~isnan(slice_array));
    
    hold on;
    
    % Додати контури всіх фібрил
    for fib = 1:number_of_fibrils_in_row
        start_idx = (fib - 1) * length(theta_contour) + 1;
        end_idx = fib * length(theta_contour);
        plot(all_circles_x(start_idx:end_idx), all_circles_y(start_idx:end_idx), ...
             'r-', 'LineWidth', 1.5);
    end
    
    % Додати стрілки орієнтації для кожної фібрили
    arrow_length = radius * 0.5;
    theta_rad = theta_radians(z);
    
    for fib = 1:number_of_fibrils_in_row
        center_x = (fib - 1) * diameter + (diameter + 1) / 2;
        center_y = (diameter + 1) / 2;
        arrow_dx = arrow_length * cos(theta_rad);
        arrow_dy = arrow_length * sin(theta_rad);
        
        quiver(center_x, center_y, arrow_dx, arrow_dy, 0, 'k-', ...
               'LineWidth', 2.5, 'MaxHeadSize', 2);
    end
    
    hold off;
    
    colormap(gca, current_cmap);
    caxis([min(theta_degrees), max(theta_degrees)]);
    axis equal tight;
    title(sprintf('Z = %d px (θ = %.1f°)', z, theta_degrees(z)), ...
          'FontSize', 11, 'FontWeight', 'bold');
    set(gca, 'YDir', 'normal', 'FontSize', 9);
    xlabel('X (pixels)', 'FontSize', 10);
    ylabel('Y (pixels)', 'FontSize', 10);
    
    if i == num_z_slices
        cb = colorbar;
        cb.Label.String = 'Angle (°)';
        cb.Label.FontSize = 10;
    end
end

sgtitle(sprintf('Fibril Array - XY Cross-Sections at Different Z (n=%d, Colormap: %s)', ...
        number_of_fibrils_in_row, current_cmap), 'FontSize', 15, 'FontWeight', 'bold');

% Збереження
if save_figures
    filename = sprintf('OptAxOr_array_xy_slices_n%d_%s.png', number_of_fibrils_in_row, current_cmap);
    saveas(fig_arr1, fullfile(save_path_array, filename));
    fprintf('Saved: %s\n', filename);
end
close(fig_arr1);

%% ========================================================================
%  ВІЗУАЛІЗАЦІЯ 2: 3D масив всіх фібрил (GIBBON)
%  ========================================================================

fprintf('Creating Array Visualization 2: 3D array with GIBBON...\n');

% Підготовка даних
M_array = optical_axis_array_3D;
L_mask_array = ~isnan(M_array);
M_array(isnan(M_array)) = 0;

% Створення 3D патчу
[F_array, V_array, C_array] = im2patch(M_array, L_mask_array, 'vb');

% Параметри візуалізації
fontSize = 12;
face_alpha = 0.6;

fig_arr2 = figure('Position', [50, 50, 1600, 1000]);

% Subplot 1: Загальний вид (перспектива)
subplot(1, 2, 1);
gpatch(F_array, V_array, C_array, 'none', face_alpha);
colormap(gca, current_cmap);
hcb = colorbar;
hcb.Label.String = 'Optical Axis Angle (degrees)';
hcb.Label.FontSize = fontSize;
caxis([min(theta_degrees), max(theta_degrees)]);

lighting gouraud;
camlight('headlight');
material shiny;
axisGeom(gca, fontSize);

xlabel('X (pixels)', 'FontSize', fontSize, 'FontWeight', 'bold');
ylabel('Y (pixels)', 'FontSize', fontSize, 'FontWeight', 'bold');
zlabel('Z (pixels)', 'FontSize', fontSize, 'FontWeight', 'bold');
title(sprintf('3D Fibril Array (n=%d, Colormap: %s)', number_of_fibrils_in_row, current_cmap), ...
      'FontSize', 13, 'FontWeight', 'bold');
view([-40, 30]);
axis equal tight;
grid on;

% Subplot 2: Вид зверху (вздовж Z)
subplot(1, 2, 2);
gpatch(F_array, V_array, C_array, 'none', face_alpha);
colormap(gca, current_cmap);
hcb = colorbar;
hcb.Label.String = 'Optical Axis Angle (degrees)';
hcb.Label.FontSize = fontSize;
caxis([min(theta_degrees), max(theta_degrees)]);

lighting gouraud;
camlight('headlight');
material shiny;
axisGeom(gca, fontSize);

xlabel('X (pixels)', 'FontSize', fontSize, 'FontWeight', 'bold');
ylabel('Y (pixels)', 'FontSize', fontSize, 'FontWeight', 'bold');
zlabel('Z (pixels)', 'FontSize', fontSize, 'FontWeight', 'bold');
title('Top View (along Z axis)', 'FontSize', 13, 'FontWeight', 'bold');
view([0, 90]);  % Вид зверху
axis equal tight;
grid on;

sgtitle(sprintf('3D Fibril Array Visualization (D=%dpx, L=%dpx, n=%d)', ...
        diameter, depth_z, number_of_fibrils_in_row), 'FontSize', 15, 'FontWeight', 'bold');

% Збереження
if save_figures
    filename = sprintf('OptAxOr_array_3D_full_n%d_%s.png', number_of_fibrils_in_row, current_cmap);
    saveas(fig_arr2, fullfile(save_path_array, filename));
    fprintf('Saved: %s\n', filename);
end
close(fig_arr2);

%% ========================================================================
%  ВІЗУАЛІЗАЦІЯ 3: Окремі фібрили (individual fibrils)
%  ========================================================================

fprintf('Creating Array Visualization 3: Individual fibrils...\n');

fig_arr3 = figure('Position', [50, 50, 1800, 1000]);

% Створити subplot для кожної фібрили
for fib_idx = 1:number_of_fibrils_in_row
    subplot(2, 3, fib_idx);
    
    % Витягти дані цієї фібрили
    col_start = (fib_idx - 1) * diameter + 1;
    col_end = fib_idx * diameter;
    
    fibril_data = optical_axis_array_3D(:, col_start:col_end, :);
    
    % Маска для цієї фібрили
    L_mask_fib = ~isnan(fibril_data);
    fibril_data(isnan(fibril_data)) = 0;
    
    % Створити патч
    [F_fib, V_fib, C_fib] = im2patch(fibril_data, L_mask_fib, 'vb');
    
    gpatch(F_fib, V_fib, C_fib, 'none', 0.7);
    colormap(gca, current_cmap);
    caxis([min(theta_degrees), max(theta_degrees)]);
    
    lighting gouraud;
    camlight('headlight');
    material shiny;
    axisGeom(gca, 10);
    
    xlabel('X', 'FontSize', 10);
    ylabel('Y', 'FontSize', 10);
    zlabel('Z', 'FontSize', 10);
    title(sprintf('Fibril #%d', fib_idx), 'FontSize', 12, 'FontWeight', 'bold');
    view([-40, 30]);
    axis equal tight;
    grid on;
end

sgtitle(sprintf('Individual Fibrils in Array (Colormap: %s)', current_cmap), ...
        'FontSize', 15, 'FontWeight', 'bold');

% Збереження
if save_figures
    filename = sprintf('OptAxOr_array_individual_n%d_%s.png', number_of_fibrils_in_row, current_cmap);
    saveas(fig_arr3, fullfile(save_path_array, filename));
    fprintf('Saved: %s\n', filename);
end
close(fig_arr3);

%% ========================================================================
%  ВІЗУАЛІЗАЦІЯ 4: Розгортки всіх фібрил (unwrapped comparison)
%  ========================================================================

fprintf('Creating Array Visualization 4: Unwrapped comparison...\n');

fig_arr4 = figure('Position', [50, 50, 1800, 1000]);

% Створити розгортку для кожної фібрили
for fib_idx = 1:number_of_fibrils_in_row
    subplot(number_of_fibrils_in_row, 1, fib_idx);
    
    % Діапазон стовпців для цієї фібрили
    col_start = (fib_idx - 1) * diameter + 1;
    col_end = fib_idx * diameter;
    
    % Створити розгортку
    num_angles_unwrap = 180;
    angle_array_unwrap = linspace(0, 2*pi, num_angles_unwrap);
    unwrapped_fib = nan(num_angles_unwrap, depth_z);
    
    for z = 1:depth_z
        for a = 1:num_angles_unwrap
            % Координати на поверхні циліндра (відносно цієї фібрили)
            x_local = (diameter+1)/2 + radius * cos(angle_array_unwrap(a));
            y_local = (diameter+1)/2 + radius * sin(angle_array_unwrap(a));
            
            x_idx = round(x_local) + col_start - 1;
            y_idx = round(y_local);
            
            if x_idx >= col_start && x_idx <= col_end && y_idx >= 1 && y_idx <= diameter
                unwrapped_fib(a, z) = optical_axis_array_3D(y_idx, x_idx, z);
            end
        end
    end
    
    % Відобразити розгортку
    imagesc(1:depth_z, rad2deg(angle_array_unwrap), unwrapped_fib);
    colormap(gca, current_cmap);
    caxis([min(theta_degrees), max(theta_degrees)]);
    
    if fib_idx == number_of_fibrils_in_row
        xlabel('Z Position (pixels)', 'FontSize', 11, 'FontWeight', 'bold');
    end
    ylabel('Angular Pos (°)', 'FontSize', 10, 'FontWeight', 'bold');
    title(sprintf('Fibril #%d Unwrapped', fib_idx), 'FontSize', 11, 'FontWeight', 'bold');
    set(gca, 'YDir', 'normal', 'FontSize', 9);
    
    if fib_idx == 1
        cb = colorbar;
        cb.Label.String = 'Angle (°)';
        cb.Label.FontSize = 10;
    end
end

sgtitle(sprintf('Unwrapped Cylinder Surfaces - All Fibrils (Colormap: %s)', current_cmap), ...
        'FontSize', 15, 'FontWeight', 'bold');

% Збереження
if save_figures
    filename = sprintf('OptAxOr_array_unwrapped_n%d_%s.png', number_of_fibrils_in_row, current_cmap);
    saveas(fig_arr4, fullfile(save_path_array, filename));
    fprintf('Saved: %s\n', filename);
end
close(fig_arr4);

%% ========================================================================
%  ВІЗУАЛІЗАЦІЯ 5: Зрізи вздовж різних площин
%  ========================================================================

fprintf('Creating Array Visualization 5: Multi-planar slices...\n');

fig_arr5 = figure('Position', [50, 50, 1600, 1200]);

% Subplot 1: XY зріз (центральний по Z)
subplot(2, 2, 1);
z_mid = round(depth_z / 2);
xy_slice = optical_axis_array_3D(:, :, z_mid);
h = imagesc(xy_slice);
set(h, 'AlphaData', ~isnan(xy_slice));
hold on;
for fib = 1:number_of_fibrils_in_row
    start_idx = (fib - 1) * length(theta_contour) + 1;
    end_idx = fib * length(theta_contour);
    plot(all_circles_x(start_idx:end_idx), all_circles_y(start_idx:end_idx), 'r-', 'LineWidth', 1.5);
end
hold off;
colormap(gca, current_cmap);
cb = colorbar;
cb.Label.String = 'Angle (°)';
caxis([min(theta_degrees), max(theta_degrees)]);
axis equal tight;
title(sprintf('XY Slice (Z = %d)', z_mid), 'FontSize', 12, 'FontWeight', 'bold');
xlabel('X (pixels)', 'FontSize', 10);
ylabel('Y (pixels)', 'FontSize', 10);
set(gca, 'YDir', 'normal');

% Subplot 2: XZ зріз (центральний по Y)
subplot(2, 2, 2);
y_mid = round(diameter / 2);
xz_slice = squeeze(optical_axis_array_3D(y_mid, :, :))';
imagesc(1:array_width, 1:depth_z, xz_slice);
colormap(gca, current_cmap);
cb = colorbar;
cb.Label.String = 'Angle (°)';
caxis([min(theta_degrees), max(theta_degrees)]);
title(sprintf('XZ Slice (Y = %d)', y_mid), 'FontSize', 12, 'FontWeight', 'bold');
xlabel('X (pixels)', 'FontSize', 10);
ylabel('Z (pixels)', 'FontSize', 10);
set(gca, 'YDir', 'normal');

% Subplot 3: YZ зріз (через центр першої фібрили)
subplot(2, 2, 3);
x_first_center = round(diameter / 2);
yz_slice = squeeze(optical_axis_array_3D(:, x_first_center, :))';
imagesc(1:diameter, 1:depth_z, yz_slice);
colormap(gca, current_cmap);
cb = colorbar;
cb.Label.String = 'Angle (°)';
caxis([min(theta_degrees), max(theta_degrees)]);
title(sprintf('YZ Slice (X = %d, Fibril #1)', x_first_center), 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Y (pixels)', 'FontSize', 10);
ylabel('Z (pixels)', 'FontSize', 10);
set(gca, 'YDir', 'normal');

% Subplot 4: Профілі через центри всіх фібрил
subplot(2, 2, 4);
hold on;
colors_profile = jet(number_of_fibrils_in_row);
for fib_idx = 1:number_of_fibrils_in_row
    x_center = (fib_idx - 1) * diameter + round(diameter / 2);
    y_center = round(diameter / 2);
    
    profile_z = squeeze(optical_axis_array_3D(y_center, x_center, :));
    plot(1:depth_z, profile_z, '-', 'Color', colors_profile(fib_idx, :), ...
         'LineWidth', 2, 'DisplayName', sprintf('Fibril #%d', fib_idx));
end
hold off;
grid on;
xlabel('Z Position (pixels)', 'FontSize', 10, 'FontWeight', 'bold');
ylabel('Optical Axis Angle (degrees)', 'FontSize', 10, 'FontWeight', 'bold');
title('Central Profiles - All Fibrils', 'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 9);
ylim([min(theta_degrees)-10, max(theta_degrees)+10]);

sgtitle(sprintf('Multi-Planar Slice Analysis (Colormap: %s)', current_cmap), ...
        'FontSize', 15, 'FontWeight', 'bold');

% Збереження
if save_figures
    filename = sprintf('OptAxOr_array_slices_n%d_%s.png', number_of_fibrils_in_row, current_cmap);
    saveas(fig_arr5, fullfile(save_path_array, filename));
    fprintf('Saved: %s\n', filename);
end
close(fig_arr5);

%% ========================================================================
%  ВІЗУАЛІЗАЦІЯ 6: 3D з різними діапазонами кутів
%  ========================================================================

fprintf('Creating Array Visualization 6: Angular range separation...\n');

fig_arr6 = figure('Position', [50, 50, 1600, 1000]);

% Розділити на три діапазони кутів
angle_low = min(theta_degrees);
angle_high = max(theta_degrees);
angle_range = angle_high - angle_low;

threshold_low = angle_low + angle_range / 3;
threshold_high = angle_low + 2 * angle_range / 3;

% Маски для трьох діапазонів
L_mask_low = L_mask_array & (M_array >= angle_low) & (M_array < threshold_low);
L_mask_mid = L_mask_array & (M_array >= threshold_low) & (M_array < threshold_high);
L_mask_high = L_mask_array & (M_array >= threshold_high) & (M_array <= angle_high);

% Subplot 1: Низькі кути
subplot(1, 3, 1);
if sum(L_mask_low(:)) > 0
    [F_low, V_low, C_low] = im2patch(M_array, L_mask_low, 'vb');
    gpatch(F_low, V_low, C_low, 'none', 0.7);
    colormap(gca, current_cmap);
    caxis([min(theta_degrees), max(theta_degrees)]);
    lighting gouraud; camlight('headlight'); material shiny;
    axisGeom(gca, 10);
    title(sprintf('Low Angles (%.1f-%.1f°)', angle_low, threshold_low), ...
          'FontSize', 12, 'FontWeight', 'bold');
    xlabel('X', 'FontSize', 10);
    ylabel('Y', 'FontSize', 10);
    zlabel('Z', 'FontSize', 10);
    view([-40, 30]);
    axis equal tight;
    grid on;
end

% Subplot 2: Середні кути
subplot(1, 3, 2);
if sum(L_mask_mid(:)) > 0
    [F_mid, V_mid, C_mid] = im2patch(M_array, L_mask_mid, 'vb');
    gpatch(F_mid, V_mid, C_mid, 'none', 0.7);
    colormap(gca, current_cmap);
    caxis([min(theta_degrees), max(theta_degrees)]);
    cb = colorbar;
    cb.Label.String = 'Angle (°)';
    lighting gouraud; camlight('headlight'); material shiny;
    axisGeom(gca, 10);
    title(sprintf('Mid Angles (%.1f-%.1f°)', threshold_low, threshold_high), ...
          'FontSize', 12, 'FontWeight', 'bold');
    xlabel('X', 'FontSize', 10);
    ylabel('Y', 'FontSize', 10);
    zlabel('Z', 'FontSize', 10);
    view([-40, 30]);
    axis equal tight;
    grid on;
end

% Subplot 3: Високі кути
subplot(1, 3, 3);
if sum(L_mask_high(:)) > 0
    [F_high, V_high, C_high] = im2patch(M_array, L_mask_high, 'vb');
    gpatch(F_high, V_high, C_high, 'none', 0.7);
    colormap(gca, current_cmap);
    caxis([min(theta_degrees), max(theta_degrees)]);
    lighting gouraud; camlight('headlight'); material shiny;
    axisGeom(gca, 10);
    title(sprintf('High Angles (%.1f-%.1f°)', threshold_high, angle_high), ...
          'FontSize', 12, 'FontWeight', 'bold');
    xlabel('X', 'FontSize', 10);
    ylabel('Y', 'FontSize', 10);
    zlabel('Z', 'FontSize', 10);
    view([-40, 30]);
    axis equal tight;
    grid on;
end

sgtitle(sprintf('Fibril Array - Angular Range Separation (Colormap: %s)', current_cmap), ...
        'FontSize', 15, 'FontWeight', 'bold');

% Збереження
if save_figures
    filename = sprintf('OptAxOr_array_angular_ranges_n%d_%s.png', number_of_fibrils_in_row, current_cmap);
    saveas(fig_arr6, fullfile(save_path_array, filename));
    fprintf('Saved: %s\n', filename);
end
close(fig_arr6);

fprintf('Colormap %s completed for array!\n', current_cmap);

end  % Кінець циклу по кольоровим схемам для масиву

%% ========================================================================
%  ЗБЕРЕЖЕННЯ ДАНИХ МАСИВУ
%  ========================================================================

fprintf('\n=== Saving Array Data ===\n');

% Зберегти змінні у .mat файл
if save_figures
    save(fullfile(save_path_array, 'OptAxOr_array_data.mat'), ...
         'optical_axis_array_3D', 'number_of_fibrils_in_row', ...
         'theta_degrees', 'theta_radians', 'z_array', ...
         'diameter', 'radius', 'depth_z', 'theta_amplitude', 'theta_period', 'theta_offset');
    fprintf('Saved: OptAxOr_array_data.mat\n');
end

%% ========================================================================
%  ФІНАЛЬНИЙ ЗВІТ ДЛЯ МАСИВУ
%  ========================================================================

fprintf('\n========================================\n');
fprintf('FIBRIL ARRAY VISUALIZATION COMPLETE\n');
fprintf('========================================\n');
fprintf('Array parameters:\n');
fprintf('  - Number of fibrils: %d\n', number_of_fibrils_in_row);
fprintf('  - Array dimensions: %d x %d x %d voxels\n', array_height, array_width, array_depth);
fprintf('  - Total volume: %d voxels\n', numel(optical_axis_array_3D));
fprintf('  - Valid voxels: %d\n', sum(~isnan(optical_axis_array_3D(:))));
fprintf('\nEach fibril:\n');
fprintf('  - Diameter: %d pixels\n', diameter);
fprintf('  - Length (Z): %d pixels\n', depth_z);
fprintf('  - Optical axis amplitude: ±%.1f degrees\n', theta_amplitude);
fprintf('  - Period: %d pixels\n', theta_period);
fprintf('\nColor schemes processed: %d\n', length(colormaps_list));
fprintf('  - %s\n', strjoin(colormaps_list, ', '));
fprintf('\nVisualization files saved to:\n');
fprintf('  %s\n', save_path_array);
fprintf('Total figures per colormap: 6\n');
fprintf('Total figures generated: %d\n', 6 * length(colormaps_list));
fprintf('========================================\n');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                                                                        %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%               3. Создание шара фибрилл (ориентация оптических осей)                    %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                                                                        %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% ========================================================================
%  СТВОРЕННЯ ТРЬОХШАРОВОЇ СТРУКТУРИ ФІБРИЛ
%  ========================================================================
%  Цей блок дублює масив фібрил вздовж осі Y для створення
%  багатошарової 3D структури з орієнтацією оптичної осі
%  ========================================================================

fprintf('\n\n');
fprintf('========================================\n');
fprintf('CREATING THREE-LAYER FIBRIL STRUCTURE\n');
fprintf('========================================\n');

%% ========================================================================
%  ПАРАМЕТРИ ТРЬОХШАРОВОЇ СТРУКТУРИ
%  ========================================================================

number_of_layers = 3;  % Кількість шарів вздовж Y

fprintf('Creating %d-layer structure along Y axis...\n', number_of_layers);
fprintf('Each layer: %d x %d x %d voxels\n', array_height, array_width, array_depth);

%% ========================================================================
%  СТВОРЕННЯ ТРЬОХШАРОВОЇ СТРУКТУРИ - ДУБЛЮВАННЯ ВЗДОВЖ Y
%  ========================================================================

% Розміри трьохшарової структури
multilayer_height = array_height * number_of_layers;   % Y (потроюється)
multilayer_width = array_width;                        % X (не змінюється)
multilayer_depth = array_depth;                        % Z (не змінюється)

% Ініціалізація 3D масиву для трьохшарової структури
optical_axis_multilayer_3D = nan(multilayer_height, multilayer_width, multilayer_depth);

fprintf('\nMultilayer dimensions: %d (Y) x %d (X) x %d (Z) voxels\n', ...
        multilayer_height, multilayer_width, multilayer_depth);

% Дублювання шару вздовж осі Y
for layer_idx = 1:number_of_layers
    % Розрахунок діапазону рядків для цього шару
    y_start = (layer_idx - 1) * array_height + 1;
    y_end = layer_idx * array_height;
    
    fprintf('  Layer #%d: Y-range %d-%d\n', layer_idx, y_start, y_end);
    
    % Копіювання шару масиву фібрил у відповідну Y-позицію
    optical_axis_multilayer_3D(y_start:y_end, :, :) = optical_axis_array_3D;
end

fprintf('Multilayer structure created successfully!\n');
fprintf('Total voxels: %d\n', numel(optical_axis_multilayer_3D));
fprintf('Valid voxels (inside fibrils): %d\n', sum(~isnan(optical_axis_multilayer_3D(:))));

%% ========================================================================
%  СТВОРЕННЯ КОНТУРІВ ДЛЯ ВСІХ ФІБРИЛ У ВСІХ ШАРАХ
%  ========================================================================

% Масиви для збереження всіх контурів
all_circles_multilayer_x = [];
all_circles_multilayer_y = [];

for layer_idx = 1:number_of_layers
    for fib_idx = 1:number_of_fibrils_in_row
        % Розрахунок центру цієї фібрили
        center_x = (fib_idx - 1) * diameter + (diameter + 1) / 2;
        center_y = (layer_idx - 1) * array_height + (diameter + 1) / 2;
        
        % Створення контуру круга
        circle_x_temp = center_x + radius * cos(theta_contour);
        circle_y_temp = center_y + radius * sin(theta_contour);
        
        % Додавання до загального масиву
        all_circles_multilayer_x = [all_circles_multilayer_x; circle_x_temp(:)];
        all_circles_multilayer_y = [all_circles_multilayer_y; circle_y_temp(:)];
    end
end

% ========================================================================
%  СТВОРЕННЯ ПАПКИ ДЛЯ ЗБЕРЕЖЕННЯ
%  ========================================================================

% Створити підпапку "OpticalAxis - Трьохшарова структура"
save_path_multilayer = fullfile(save_path_top, 'OpticalAxis - Трьохшарова структура');

if ~exist(save_path_multilayer, 'dir')
    mkdir(save_path_multilayer);
    fprintf('\nCreated folder: %s\n', save_path_multilayer);
end

%% ========================================================================
%  ОСНОВНИЙ ЦИКЛ ВІЗУАЛІЗАЦІЇ ПО КОЛЬОРОВИМ СХЕМАМ
%  ========================================================================

fprintf('\n=== Starting Multilayer Visualization Loop ===\n');

for cmap_idx = 1:length(colormaps_list)
    current_cmap = colormaps_list{cmap_idx};
    fprintf('\n--- Processing multilayer with colormap: %s (%d/%d) ---\n', ...
            current_cmap, cmap_idx, length(colormaps_list));

%% ========================================================================
%  ВІЗУАЛІЗАЦІЯ 1: Повна 3D структура (GIBBON) - різні види
%  ========================================================================

fprintf('Creating Multilayer Visualization 1: Full 3D structure...\n');

% Підготовка даних
M_multi = optical_axis_multilayer_3D;
L_mask_multi = ~isnan(M_multi);
M_multi(isnan(M_multi)) = 0;

% Створення 3D патчу
[F_multi, V_multi, C_multi] = im2patch(M_multi, L_mask_multi, 'vb');

% Параметри візуалізації
fontSize = 11;
face_alpha = 0.5;

fig_ml1 = figure('Position', [50, 50, 1800, 1200]);

% Subplot 1: Перспектива (загальний вид)
subplot(2, 3, 1);
gpatch(F_multi, V_multi, C_multi, 'none', face_alpha);
colormap(gca, current_cmap);
hcb = colorbar;
hcb.Label.String = 'Angle (°)';
hcb.Label.FontSize = 10;
caxis([min(theta_degrees), max(theta_degrees)]);
lighting gouraud; camlight('headlight'); material shiny;
axisGeom(gca, 10);
xlabel('X', 'FontSize', 10); ylabel('Y', 'FontSize', 10); zlabel('Z', 'FontSize', 10);
title(sprintf('Perspective View (n=%d fibrils, %d layers)', number_of_fibrils_in_row, number_of_layers), ...
      'FontSize', 11, 'FontWeight', 'bold');
view([-40, 30]);
axis equal tight; grid on;

% Subplot 2: Вид зверху (вздовж Z)
subplot(2, 3, 2);
gpatch(F_multi, V_multi, C_multi, 'none', face_alpha);
colormap(gca, current_cmap);
caxis([min(theta_degrees), max(theta_degrees)]);
lighting gouraud; camlight('headlight'); material shiny;
axisGeom(gca, 10);
xlabel('X', 'FontSize', 10); ylabel('Y', 'FontSize', 10); zlabel('Z', 'FontSize', 10);
title('Top View (along Z)', 'FontSize', 11, 'FontWeight', 'bold');
view([0, 90]);
axis equal tight; grid on;

% Subplot 3: Вид збоку (вздовж X)
subplot(2, 3, 3);
gpatch(F_multi, V_multi, C_multi, 'none', face_alpha);
colormap(gca, current_cmap);
caxis([min(theta_degrees), max(theta_degrees)]);
lighting gouraud; camlight('headlight'); material shiny;
axisGeom(gca, 10);
xlabel('X', 'FontSize', 10); ylabel('Y', 'FontSize', 10); zlabel('Z', 'FontSize', 10);
title('Side View (along X)', 'FontSize', 11, 'FontWeight', 'bold');
view([90, 0]);
axis equal tight; grid on;

% Subplot 4: Вид спереду (вздовж Y)
subplot(2, 3, 4);
gpatch(F_multi, V_multi, C_multi, 'none', face_alpha);
colormap(gca, current_cmap);
caxis([min(theta_degrees), max(theta_degrees)]);
lighting gouraud; camlight('headlight'); material shiny;
axisGeom(gca, 10);
xlabel('X', 'FontSize', 10); ylabel('Y', 'FontSize', 10); zlabel('Z', 'FontSize', 10);
title('Front View (along Y)', 'FontSize', 11, 'FontWeight', 'bold');
view([0, 0]);
axis equal tight; grid on;

% Subplot 5: Ізометричний вид 1
subplot(2, 3, 5);
gpatch(F_multi, V_multi, C_multi, 'none', face_alpha);
colormap(gca, current_cmap);
caxis([min(theta_degrees), max(theta_degrees)]);
lighting gouraud; camlight('headlight'); material shiny;
axisGeom(gca, 10);
xlabel('X', 'FontSize', 10); ylabel('Y', 'FontSize', 10); zlabel('Z', 'FontSize', 10);
title('Isometric View 1', 'FontSize', 11, 'FontWeight', 'bold');
view([45, 35]);
axis equal tight; grid on;

% Subplot 6: Ізометричний вид 2
subplot(2, 3, 6);
gpatch(F_multi, V_multi, C_multi, 'none', face_alpha);
colormap(gca, current_cmap);
hcb = colorbar;
hcb.Label.String = 'Angle (°)';
hcb.Label.FontSize = 10;
caxis([min(theta_degrees), max(theta_degrees)]);
lighting gouraud; camlight('headlight'); material shiny;
axisGeom(gca, 10);
xlabel('X', 'FontSize', 10); ylabel('Y', 'FontSize', 10); zlabel('Z', 'FontSize', 10);
title('Isometric View 2', 'FontSize', 11, 'FontWeight', 'bold');
view([-135, 35]);
axis equal tight; grid on;

sgtitle(sprintf('3D Multilayer Structure - Multiple Views (Colormap: %s)', current_cmap), ...
        'FontSize', 14, 'FontWeight', 'bold');

% Збереження
if save_figures
    filename = sprintf('OptAxOr_multilayer_full_3D_views_L%d_%s.png', number_of_layers, current_cmap);
    saveas(fig_ml1, fullfile(save_path_multilayer, filename));
    fprintf('Saved: %s\n', filename);
end
close(fig_ml1);

%% ========================================================================
%  ВІЗУАЛІЗАЦІЯ 2: Окремі шари (layer separation)
%  ========================================================================

fprintf('Creating Multilayer Visualization 2: Individual layers...\n');

fig_ml2 = figure('Position', [50, 50, 1800, 600]);

for layer_idx = 1:number_of_layers
    subplot(1, number_of_layers, layer_idx);
    
    % Витягти дані цього шару
    y_start = (layer_idx - 1) * array_height + 1;
    y_end = layer_idx * array_height;
    
    layer_data = optical_axis_multilayer_3D(y_start:y_end, :, :);
    
    % Маска для цього шару
    L_mask_layer = ~isnan(layer_data);
    layer_data(isnan(layer_data)) = 0;
    
    % Створити патч
    [F_layer, V_layer, C_layer] = im2patch(layer_data, L_mask_layer, 'vb');
    
    % Зміщення по Y для візуалізації (щоб показати на правильній висоті)
    V_layer(:, 1) = V_layer(:, 1) + y_start - 1;
    
    gpatch(F_layer, V_layer, C_layer, 'none', 0.6);
    colormap(gca, current_cmap);
    caxis([min(theta_degrees), max(theta_degrees)]);
    
    if layer_idx == number_of_layers
        hcb = colorbar;
        hcb.Label.String = 'Angle (°)';
        hcb.Label.FontSize = 10;
    end
    
    lighting gouraud; camlight('headlight'); material shiny;
    axisGeom(gca, 10);
    
    xlabel('X', 'FontSize', 10);
    ylabel('Y', 'FontSize', 10);
    zlabel('Z', 'FontSize', 10);
    title(sprintf('Layer #%d (Y: %d-%d)', layer_idx, y_start, y_end), ...
          'FontSize', 11, 'FontWeight', 'bold');
    view([-40, 30]);
    axis equal tight;
    grid on;
    
    % Встановити однакові межі осей для всіх subplot
    xlim([1, multilayer_width]);
    ylim([1, multilayer_height]);
    zlim([1, multilayer_depth]);
end

sgtitle(sprintf('Individual Layers Separated (Colormap: %s)', current_cmap), ...
        'FontSize', 14, 'FontWeight', 'bold');

% Збереження
if save_figures
    filename = sprintf('OptAxOr_multilayer_individual_layers_L%d_%s.png', number_of_layers, current_cmap);
    saveas(fig_ml2, fullfile(save_path_multilayer, filename));
    fprintf('Saved: %s\n', filename);
end
close(fig_ml2);

%% ========================================================================
%  ВІЗУАЛІЗАЦІЯ 3: Зрізи через всі шари (cross-sections)
%  ========================================================================

fprintf('Creating Multilayer Visualization 3: Cross-sections through layers...\n');

fig_ml3 = figure('Position', [50, 50, 1600, 1200]);

% Subplot 1: XY зріз (центральний по Z)
subplot(2, 2, 1);
z_mid = round(multilayer_depth / 2);
xy_slice = optical_axis_multilayer_3D(:, :, z_mid);
h = imagesc(xy_slice);
set(h, 'AlphaData', ~isnan(xy_slice));

hold on;
% Додати контури всіх фібрил у всіх шарах
for layer_idx = 1:number_of_layers
    for fib_idx = 1:number_of_fibrils_in_row
        idx = (layer_idx - 1) * number_of_fibrils_in_row + fib_idx;
        start_idx = (idx - 1) * length(theta_contour) + 1;
        end_idx = idx * length(theta_contour);
        plot(all_circles_multilayer_x(start_idx:end_idx), ...
             all_circles_multilayer_y(start_idx:end_idx), 'r-', 'LineWidth', 1.5);
    end
end

% Додати лінії розділення шарів
for layer_idx = 1:(number_of_layers-1)
    y_boundary = layer_idx * array_height + 0.5;
    plot([1, multilayer_width], [y_boundary, y_boundary], 'w--', 'LineWidth', 2.5);
    text(5, y_boundary - 3, sprintf('Layer %d/%d boundary', layer_idx, layer_idx+1), ...
         'Color', 'w', 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', 'k');
end
hold off;

colormap(gca, current_cmap);
cb = colorbar;
cb.Label.String = 'Angle (°)';
caxis([min(theta_degrees), max(theta_degrees)]);
axis equal tight;
title(sprintf('XY Cross-Section (Z = %d)', z_mid), 'FontSize', 12, 'FontWeight', 'bold');
xlabel('X (pixels)', 'FontSize', 10);
ylabel('Y (pixels)', 'FontSize', 10);
set(gca, 'YDir', 'normal');

% Subplot 2: XZ зріз (через центр середнього шару по Y)
subplot(2, 2, 2);
y_mid_layer = round(number_of_layers / 2) * array_height - round(array_height / 2);
xz_slice = squeeze(optical_axis_multilayer_3D(y_mid_layer, :, :))';
imagesc(1:multilayer_width, 1:multilayer_depth, xz_slice);
colormap(gca, current_cmap);
cb = colorbar;
cb.Label.String = 'Angle (°)';
caxis([min(theta_degrees), max(theta_degrees)]);
title(sprintf('XZ Cross-Section (Y = %d, middle layer)', y_mid_layer), ...
      'FontSize', 12, 'FontWeight', 'bold');
xlabel('X (pixels)', 'FontSize', 10);
ylabel('Z (pixels)', 'FontSize', 10);
set(gca, 'YDir', 'normal');

% Subplot 3: YZ зріз (через центр середньої фібрили)
subplot(2, 2, 3);
x_mid_fibril = round(number_of_fibrils_in_row / 2) * diameter - round(diameter / 2);
yz_slice = squeeze(optical_axis_multilayer_3D(:, x_mid_fibril, :))';
imagesc(1:multilayer_height, 1:multilayer_depth, yz_slice);
colormap(gca, current_cmap);
cb = colorbar;
cb.Label.String = 'Angle (°)';
caxis([min(theta_degrees), max(theta_degrees)]);

hold on;
% Додати лінії розділення шарів
for layer_idx = 1:(number_of_layers-1)
    y_boundary = layer_idx * array_height + 0.5;
    plot([y_boundary, y_boundary], [1, multilayer_depth], 'w--', 'LineWidth', 2.5);
end
hold off;

title(sprintf('YZ Cross-Section (X = %d, middle fibril)', x_mid_fibril), ...
      'FontSize', 12, 'FontWeight', 'bold');
xlabel('Y (pixels)', 'FontSize', 10);
ylabel('Z (pixels)', 'FontSize', 10);
set(gca, 'YDir', 'normal');

% Subplot 4: Профілі вздовж Z для кожного шару (центральна фібрила)
subplot(2, 2, 4);
hold on;
colors_profile = jet(number_of_layers);
x_center = round(number_of_fibrils_in_row / 2) * diameter - round(diameter / 2);

for layer_idx = 1:number_of_layers
    y_center = (layer_idx - 1) * array_height + round(array_height / 2);
    
    profile_z = squeeze(optical_axis_multilayer_3D(y_center, x_center, :));
    plot(1:multilayer_depth, profile_z, '-', 'Color', colors_profile(layer_idx, :), ...
         'LineWidth', 2.5, 'DisplayName', sprintf('Layer #%d', layer_idx));
end
hold off;
grid on;
xlabel('Z Position (pixels)', 'FontSize', 10, 'FontWeight', 'bold');
ylabel('Optical Axis Angle (degrees)', 'FontSize', 10, 'FontWeight', 'bold');
title('Angle Profiles Along Z - All Layers (center fibril)', 'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 9);
ylim([min(theta_degrees)-10, max(theta_degrees)+10]);

sgtitle(sprintf('Multi-Planar Cross-Sections Through All Layers (Colormap: %s)', current_cmap), ...
        'FontSize', 14, 'FontWeight', 'bold');

% Збереження
if save_figures
    filename = sprintf('OptAxOr_multilayer_cross_sections_L%d_%s.png', number_of_layers, current_cmap);
    saveas(fig_ml3, fullfile(save_path_multilayer, filename));
    fprintf('Saved: %s\n', filename);
end
close(fig_ml3);

%% ========================================================================
%  ВІЗУАЛІЗАЦІЯ 4: Вибрані Z-зрізи XY (показ всіх шарів)
%  ========================================================================

fprintf('Creating Multilayer Visualization 4: Selected Z-slices...\n');

fig_ml4 = figure('Position', [50, 50, 1800, 1000]);

% Вибрати 6 характерних Z-зрізів
num_z_slices_display = 6;
z_slices_selected = round(linspace(1, multilayer_depth, num_z_slices_display));

for i = 1:num_z_slices_display
    z = z_slices_selected(i);
    subplot(2, 3, i);
    
    % Отримати зріз
    xy_slice = optical_axis_multilayer_3D(:, :, z);
    
    % Відобразити
    h = imagesc(xy_slice);
    set(h, 'AlphaData', ~isnan(xy_slice));
    
    hold on;
    % Контури всіх фібрил у всіх шарах
    for layer_idx = 1:number_of_layers
        for fib_idx = 1:number_of_fibrils_in_row
            idx = (layer_idx - 1) * number_of_fibrils_in_row + fib_idx;
            start_idx = (idx - 1) * length(theta_contour) + 1;
            end_idx = idx * length(theta_contour);
            plot(all_circles_multilayer_x(start_idx:end_idx), ...
                 all_circles_multilayer_y(start_idx:end_idx), 'r-', 'LineWidth', 1.2);
        end
    end
    
    % Границі шарів
    for layer_idx = 1:(number_of_layers-1)
        y_boundary = layer_idx * array_height + 0.5;
        plot([1, multilayer_width], [y_boundary, y_boundary], 'w--', 'LineWidth', 2);
    end
    
    % Стрілки орієнтації для всіх фібрил
    theta_rad = theta_radians(z);
    arrow_length = radius * 0.4;
    for layer_idx = 1:number_of_layers
        for fib_idx = 1:number_of_fibrils_in_row
            center_x = (fib_idx - 1) * diameter + (diameter + 1) / 2;
            center_y = (layer_idx - 1) * array_height + (diameter + 1) / 2;
            quiver(center_x, center_y, arrow_length * cos(theta_rad), ...
                   arrow_length * sin(theta_rad), 0, 'k-', 'LineWidth', 2, 'MaxHeadSize', 1.5);
        end
    end
    hold off;
    
    colormap(gca, current_cmap);
    caxis([min(theta_degrees), max(theta_degrees)]);
    axis equal tight;
    title(sprintf('Z=%d (θ=%.1f°)', z, theta_degrees(z)), ...
          'FontSize', 11, 'FontWeight', 'bold');
    set(gca, 'YDir', 'normal', 'FontSize', 8);
    xlabel('X', 'FontSize', 9); ylabel('Y', 'FontSize', 9);
    
    if i == num_z_slices_display
        cb = colorbar;
        cb.Label.String = 'Angle (°)';
        cb.Label.FontSize = 9;
    end
end

sgtitle(sprintf('XY Slices at Different Z - All %d Layers Visible (Colormap: %s)', ...
        number_of_layers, current_cmap), 'FontSize', 14, 'FontWeight', 'bold');

% Збереження
if save_figures
    filename = sprintf('OptAxOr_multilayer_z_slices_L%d_%s.png', number_of_layers, current_cmap);
    saveas(fig_ml4, fullfile(save_path_multilayer, filename));
    fprintf('Saved: %s\n', filename);
end
close(fig_ml4);

%% ========================================================================
%  ВІЗУАЛІЗАЦІЯ 5: Кутові діапазони у 3D
%  ========================================================================

fprintf('Creating Multilayer Visualization 5: Angular range 3D separation...\n');

fig_ml5 = figure('Position', [50, 50, 1800, 600]);

% Розділити на три діапазони
angle_low = min(theta_degrees);
angle_high = max(theta_degrees);
angle_range = angle_high - angle_low;

threshold_low = angle_low + angle_range / 3;
threshold_high = angle_low + 2 * angle_range / 3;

% Маски
L_mask_low_ml = L_mask_multi & (M_multi >= angle_low) & (M_multi < threshold_low);
L_mask_mid_ml = L_mask_multi & (M_multi >= threshold_low) & (M_multi < threshold_high);
L_mask_high_ml = L_mask_multi & (M_multi >= threshold_high) & (M_multi <= angle_high);

% Subplot 1: Low angles
subplot(1, 3, 1);
if sum(L_mask_low_ml(:)) > 0
    [F_low_ml, V_low_ml, C_low_ml] = im2patch(M_multi, L_mask_low_ml, 'vb');
    gpatch(F_low_ml, V_low_ml, C_low_ml, 'none', 0.6);
    colormap(gca, current_cmap);
    caxis([min(theta_degrees), max(theta_degrees)]);
    lighting gouraud; camlight('headlight'); material shiny;
    axisGeom(gca, 10);
    title(sprintf('Low Angles (%.1f-%.1f°)', angle_low, threshold_low), ...
          'FontSize', 11, 'FontWeight', 'bold');
    xlabel('X', 'FontSize', 10); ylabel('Y', 'FontSize', 10); zlabel('Z', 'FontSize', 10);
    view([-40, 30]);
    axis equal tight; grid on;
end

% Subplot 2: Mid angles
subplot(1, 3, 2);
if sum(L_mask_mid_ml(:)) > 0
    [F_mid_ml, V_mid_ml, C_mid_ml] = im2patch(M_multi, L_mask_mid_ml, 'vb');
    gpatch(F_mid_ml, V_mid_ml, C_mid_ml, 'none', 0.6);
    colormap(gca, current_cmap);
    hcb = colorbar;
    hcb.Label.String = 'Angle (°)';
    hcb.Label.FontSize = 10;
    caxis([min(theta_degrees), max(theta_degrees)]);
    lighting gouraud; camlight('headlight'); material shiny;
    axisGeom(gca, 10);
    title(sprintf('Mid Angles (%.1f-%.1f°)', threshold_low, threshold_high), ...
          'FontSize', 11, 'FontWeight', 'bold');
    xlabel('X', 'FontSize', 10); ylabel('Y', 'FontSize', 10); zlabel('Z', 'FontSize', 10);
    view([-40, 30]);
    axis equal tight; grid on;
end

% Subplot 3: High angles
subplot(1, 3, 3);
if sum(L_mask_high_ml(:)) > 0
    [F_high_ml, V_high_ml, C_high_ml] = im2patch(M_multi, L_mask_high_ml, 'vb');
    gpatch(F_high_ml, V_high_ml, C_high_ml, 'none', 0.6);
    colormap(gca, current_cmap);
    caxis([min(theta_degrees), max(theta_degrees)]);
    lighting gouraud; camlight('headlight'); material shiny;
    axisGeom(gca, 10);
    title(sprintf('High Angles (%.1f-%.1f°)', threshold_high, angle_high), ...
          'FontSize', 11, 'FontWeight', 'bold');
    xlabel('X', 'FontSize', 10); ylabel('Y', 'FontSize', 10); zlabel('Z', 'FontSize', 10);
    view([-40, 30]);
    axis equal tight; grid on;
end

sgtitle(sprintf('Multilayer Structure - Angular Range Separation (Colormap: %s)', current_cmap), ...
        'FontSize', 14, 'FontWeight', 'bold');

% Збереження
if save_figures
    filename = sprintf('OptAxOr_multilayer_angular_ranges_L%d_%s.png', number_of_layers, current_cmap);
    saveas(fig_ml5, fullfile(save_path_multilayer, filename));
    fprintf('Saved: %s\n', filename);
end
close(fig_ml5);

%% ========================================================================
%  ВІЗУАЛІЗАЦІЯ 6: Статистика та аналіз
%  ========================================================================

fprintf('Creating Multilayer Visualization 6: Statistics and analysis...\n');

fig_ml6 = figure('Position', [50, 50, 1600, 1200]);

% Subplot 1: 3D гістограма кольорів
subplot(2, 3, 1);
valid_angles_ml = M_multi(L_mask_multi);
histogram(valid_angles_ml, 50, 'FaceColor', [0.3 0.6 0.9], 'EdgeColor', 'k');
xlabel('Optical Axis Angle (degrees)', 'FontSize', 10, 'FontWeight', 'bold');
ylabel('Frequency (voxels)', 'FontSize', 10, 'FontWeight', 'bold');
title('Angle Distribution - All Layers', 'FontSize', 11, 'FontWeight', 'bold');
grid on;

% Subplot 2: Статистика по шарах
subplot(2, 3, 2);
layer_stats = zeros(number_of_layers, 4);  % mean, std, min, max
for layer_idx = 1:number_of_layers
    y_start = (layer_idx - 1) * array_height + 1;
    y_end = layer_idx * array_height;
    layer_angles = optical_axis_multilayer_3D(y_start:y_end, :, :);
    layer_angles_valid = layer_angles(~isnan(layer_angles));
    
    layer_stats(layer_idx, 1) = mean(layer_angles_valid);
    layer_stats(layer_idx, 2) = std(layer_angles_valid);
    layer_stats(layer_idx, 3) = min(layer_angles_valid);
    layer_stats(layer_idx, 4) = max(layer_angles_valid);
end

x_layers = 1:number_of_layers;
bar(x_layers, layer_stats(:, 1));
hold on;
errorbar(x_layers, layer_stats(:, 1), layer_stats(:, 2), 'k.', 'LineWidth', 2);
hold off;
xlabel('Layer Number', 'FontSize', 10, 'FontWeight', 'bold');
ylabel('Mean Angle (degrees)', 'FontSize', 10, 'FontWeight', 'bold');
title('Mean Angle per Layer (±std)', 'FontSize', 11, 'FontWeight', 'bold');
grid on;
xticks(1:number_of_layers);

% Subplot 3: Об'єм по кутових діапазонах
subplot(2, 3, 3);
volume_low = sum(L_mask_low_ml(:));
volume_mid = sum(L_mask_mid_ml(:));
volume_high = sum(L_mask_high_ml(:));
bar([1 2 3], [volume_low, volume_mid, volume_high]);
set(gca, 'XTickLabel', {'Low', 'Mid', 'High'});
ylabel('Volume (voxels)', 'FontSize', 10, 'FontWeight', 'bold');
title('Voxel Count by Angular Range', 'FontSize', 11, 'FontWeight', 'bold');
grid on;

% Subplot 4: Максимальна інтенсивність проекція (MIP) - XY
subplot(2, 3, 4);
mip_xy = squeeze(max(optical_axis_multilayer_3D, [], 3, 'omitnan'));
imagesc(mip_xy);
colormap(gca, current_cmap);
cb = colorbar;
cb.Label.String = 'Max Angle (°)';
caxis([min(theta_degrees), max(theta_degrees)]);

hold on;
% Границі шарів
for layer_idx = 1:(number_of_layers-1)
    y_boundary = layer_idx * array_height + 0.5;
    plot([1, multilayer_width], [y_boundary, y_boundary], 'r--', 'LineWidth', 2);
end
hold off;

axis equal tight;
title('MIP - XY Projection (along Z)', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('X', 'FontSize', 10); ylabel('Y', 'FontSize', 10);
set(gca, 'YDir', 'normal');

% Subplot 5: MIP - XZ
subplot(2, 3, 5);
mip_xz = squeeze(max(optical_axis_multilayer_3D, [], 1, 'omitnan'))';
imagesc(mip_xz);
colormap(gca, current_cmap);
cb = colorbar;
cb.Label.String = 'Max Angle (°)';
caxis([min(theta_degrees), max(theta_degrees)]);
title('MIP - XZ Projection (along Y)', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('X', 'FontSize', 10); ylabel('Z', 'FontSize', 10);
set(gca, 'YDir', 'normal');

% Subplot 6: MIP - YZ
subplot(2, 3, 6);
mip_yz = squeeze(max(optical_axis_multilayer_3D, [], 2, 'omitnan'))';
imagesc(mip_yz);
colormap(gca, current_cmap);
cb = colorbar;
cb.Label.String = 'Max Angle (°)';
caxis([min(theta_degrees), max(theta_degrees)]);

hold on;
% Границі шарів
for layer_idx = 1:(number_of_layers-1)
    y_boundary = layer_idx * array_height + 0.5;
    plot([y_boundary, y_boundary], [1, multilayer_depth], 'r--', 'LineWidth', 2);
end
hold off;

title('MIP - YZ Projection (along X)', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Y', 'FontSize', 10); ylabel('Z', 'FontSize', 10);
set(gca, 'YDir', 'normal');

sgtitle(sprintf('Multilayer Statistics and Projections (Colormap: %s)', current_cmap), ...
        'FontSize', 14, 'FontWeight', 'bold');

% Збереження
if save_figures
    filename = sprintf('OptAxOr_multilayer_statistics_L%d_%s.png', number_of_layers, current_cmap);
    saveas(fig_ml6, fullfile(save_path_multilayer, filename));
    fprintf('Saved: %s\n', filename);
end
close(fig_ml6);

fprintf('Colormap %s completed for multilayer!\n', current_cmap);

end  % Кінець циклу по кольоровим схемам для трьохшарової структури

%% ========================================================================
%  ЗБЕРЕЖЕННЯ ДАНИХ ТРЬОХШАРОВОЇ СТРУКТУРИ
%  ========================================================================

fprintf('\n=== Saving Multilayer Data ===\n');

% Зберегти змінні у .mat файл
if save_figures
    save(fullfile(save_path_multilayer, 'OptAxOr_multilayer_data.mat'), ...
         'optical_axis_multilayer_3D', 'number_of_layers', 'number_of_fibrils_in_row', ...
         'theta_degrees', 'theta_radians', 'z_array', ...
         'diameter', 'radius', 'array_depth', 'theta_amplitude', 'theta_period', 'theta_offset', ...
         'multilayer_height', 'multilayer_width', 'multilayer_depth');
    fprintf('Saved: OptAxOr_multilayer_data.mat\n');
end

%% ========================================================================
%  ФІНАЛЬНИЙ ЗВІТ ДЛЯ ТРЬОХШАРОВОЇ СТРУКТУРИ
%  ========================================================================

fprintf('\n========================================\n');
fprintf('MULTILAYER STRUCTURE VISUALIZATION COMPLETE\n');
fprintf('========================================\n');
fprintf('Multilayer parameters:\n');
fprintf('  - Number of layers (along Y): %d\n', number_of_layers);
fprintf('  - Fibrils per layer: %d\n', number_of_fibrils_in_row);
fprintf('  - Total fibrils: %d\n', number_of_layers * number_of_fibrils_in_row);
fprintf('  - Structure dimensions: %d (Y) x %d (X) x %d (Z) voxels\n', ...
        multilayer_height, multilayer_width, multilayer_depth);
fprintf('  - Total volume: %d voxels\n', numel(optical_axis_multilayer_3D));
fprintf('  - Valid voxels: %d\n', sum(~isnan(optical_axis_multilayer_3D(:))));
fprintf('\nEach fibril:\n');
fprintf('  - Diameter: %d pixels\n', diameter);
fprintf('  - Length along Z: %d pixels\n', array_depth);
fprintf('  - Optical axis amplitude: ±%.1f degrees\n', theta_amplitude);
fprintf('  - Period: %d pixels\n', theta_period);
fprintf('\nColor schemes processed: %d\n', length(colormaps_list));
fprintf('  - %s\n', strjoin(colormaps_list, ', '));
fprintf('\nVisualization files saved to:\n');
fprintf('  %s\n', save_path_multilayer);
fprintf('Total figures per colormap: 6\n');
fprintf('Total figures generated: %d\n', 6 * length(colormaps_list));
fprintf('========================================\n');
fprintf('\n🎉 ALL OPTICAL AXIS VISUALIZATIONS COMPLETED! 🎉\n');
fprintf('========================================\n');

%% ========================================================================
%  ІНІЦІАЛІЗАЦІЯ ГЛОБАЛЬНИХ ЗМІННИХ
%  ========================================================================

global optical_axis_3D;              % Одна фібрила
global optical_axis_array_3D;        % Масив фібрил (вздовж X)
global optical_axis_multilayer_3D;   % Трьохшарова структура (вздовж Y)

fprintf('Global variables initialized.\n');