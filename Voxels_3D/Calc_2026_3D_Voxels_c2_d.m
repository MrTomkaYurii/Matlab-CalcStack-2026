%% ========================================================================
%  CONFIGURATION BLOCK - Adjust parameters here
%  ========================================================================

% Fibril parameters
diameter = 56;              % Fibril diameter in pixels
radius = diameter / 2;      % Fibril radius

number_of_fibrils_in_row = 6;
XOY_slice_of_fibrils = nan(diameter, diameter .* number_of_fibrils_in_row);
%_________________________________________________________________________________________________
% case 1 - ізотропний
% ro = 0;     %орієнтація оптичних осей
% case 2 - анізотропний (інший блок коду)
        % global optical_axis_3D;              % Одна фібрила
        % global optical_axis_array_3D;        % Масив фібрил (вздовж X)
        % global optical_axis_multilayer_3D;   % Трьохшарова структура (вздовж Y)
%_________________________________________________________________________________________________
% Color maps to use for visualization
colormaps_list = {'parula', 'gray', 'jet' };%, 'hot', 'cool', 'hsv'};

% Save parameters
save_path_top = 'C://1';        % Folder path to save figures
save_figures = true;        % Set to false to disable saving

% Create save directory if it doesn't exist
if save_figures && ~exist(save_path, 'dir')
    mkdir(save_path);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                                                                        %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                          1. Создание фазового набега                                   %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                                                                        %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% ========================================================================
%  PHASE SHIFT CALCULATION
%  ========================================================================

% Create coordinate grid
[X, Y] = meshgrid(1:diameter, 1:diameter);

% Center coordinates (fibril center at array center)
X_centered = X - (diameter + 1) / 2;
Y_centered = Y - (diameter + 1) / 2;

% Calculate distance from center for each point
R = sqrt(X_centered.^2 + Y_centered.^2);

% Initialize phase shift array
phase_shift_single = NaN(diameter, diameter);

% Fill phase shifts inside the fibril
% Fill phase shifts inside the fibril
for i = 1:diameter
    for j = 1:diameter
        if R(i, j) <= radius
            y_local = Y_centered(i, j);
            
            if abs(y_local) < radius
                % Maximum half-chord at this height
                max_half_chord = sqrt(radius^2 - y_local^2);
                
                % Full chord length (total thickness at this Y)
                full_chord = 2 * max_half_chord;
                
                % Current position along X axis relative to center
                x_local = X_centered(i, j);
                
                if abs(x_local) <= max_half_chord
                    % Distance from LEFT edge of circle to current point
                    distance_from_left = max_half_chord + x_local;
                    
                    % Phase per pixel (constant rate for homogeneous material)
                    phase_per_pixel = (2 * pi * full_chord / (2 * radius)) / full_chord;
                    
                    % Total phase = distance × phase_per_pixel
                    phase_shift_single(i, j) = distance_from_left * phase_per_pixel;
                end
            end
        end
    end
end

% Create fibril contour for visualization
theta = linspace(0, 2*pi, 200);
circle_x = radius + radius * cos(theta) + 0.5;
circle_y = radius + radius * sin(theta) + 0.5;

% Calculate center index for profiles
center_idx = round(diameter / 2);

% ========================================================================
%  СТВОРЕННЯ ПАПКИ ДЛЯ ЗБЕРЕЖЕННЯ
%  ========================================================================
save_path = fullfile(save_path_top, 'Фаз.Зсув - Зрізи');

if ~exist(save_path_multilayer, 'dir')
    mkdir(save_path_multilayer);
    fprintf('\nCreated folder: %s\n', save_path_multilayer);
end

%% ========================================================================
%  VISUALIZATION LOOP - Generate figures for each colormap
%  ========================================================================

for cmap_idx = 1:length(colormaps_list)
    current_cmap = colormaps_list{cmap_idx};
    
    % Create figure with all visualizations
    fig = figure('Position', [100, 100, 1600, 1000]);

    % =====================================================================
    % Subplot 1: 2D Phase Shift Map (with NaN as background)
    % =====================================================================
    subplot(2, 2, 1);
    
    % Use pcolor or imagesc with AlphaData for transparency
    h = imagesc(phase_shift_single);
    set(h, 'AlphaData', ~isnan(phase_shift_single)); % Make NaN transparent
    
    hold on;
    plot(circle_x, circle_y, 'r-', 'LineWidth', 2);
    hold off;
    
    colormap(gca, current_cmap);
    cb1 = colorbar;
    cb1.Label.String = 'Phase Shift (rad)';
    cb1.Label.FontSize = 11;
    cb1.Ticks = [0, pi/2, pi, 3*pi/2, 2*pi];
    cb1.TickLabels = {'0', '\pi/2', '\pi', '3\pi/2', '2\pi'};
    caxis([0, 2*pi]);
    
    axis equal tight;
    title(sprintf('Phase Shift in Fibril Cross-Section (Colormap: %s)', current_cmap), ...
          'FontSize', 13, 'FontWeight', 'bold');
    xlabel('X (pixels)', 'FontSize', 11);
    ylabel('Y (pixels)', 'FontSize', 11);
    set(gca, 'YDir', 'normal', 'FontSize', 10, 'Color', 'white');
    grid on;
    
    % =====================================================================
    % Subplot 2: 3D Surface Representation
    % =====================================================================
    subplot(2, 2, 2);
    surf(X, Y, phase_shift_single, 'EdgeColor', 'none', 'FaceAlpha', 0.9);
    hold on;
    % Fibril contour on 3D plot
    circle_z = zeros(size(circle_x));
    plot3(circle_x, circle_y, circle_z, 'r-', 'LineWidth', 2.5);
    hold off;
    colormap(gca, current_cmap);
    cb2 = colorbar;
    cb2.Label.String = 'Phase Shift (rad)';
    cb2.Label.FontSize = 11;
    cb2.Ticks = [0, pi/2, pi, 3*pi/2, 2*pi];
    cb2.TickLabels = {'0', '\pi/2', '\pi', '3\pi/2', '2\pi'};
    caxis([0, 2*pi]);
    title('3D Phase Shift Visualization', 'FontSize', 13, 'FontWeight', 'bold');
    xlabel('X (pixels)', 'FontSize', 11);
    ylabel('Y (pixels)', 'FontSize', 11);
    zlabel('Phase Shift (rad)', 'FontSize', 11);
    view(-20, 65);
    grid on;
    set(gca, 'FontSize', 10);
    lighting gouraud;
    camlight('headlight');
    
    % =====================================================================
    % Subplot 3: Central Line Profile (Y = 0)
    % =====================================================================
    subplot(2, 2, 3);
    profile_x = phase_shift_single(center_idx, :);
    plot(1:diameter, profile_x, 'b-', 'LineWidth', 3);
    hold on;
    % Mark important points
    plot(1, 0, 'gs', 'MarkerSize', 12, 'LineWidth', 2.5, 'MarkerFaceColor', 'g');
    plot(diameter/2, pi, 'ro', 'MarkerSize', 12, 'LineWidth', 2.5, 'MarkerFaceColor', 'r');
    plot(diameter, 2*pi, 'ms', 'MarkerSize', 12, 'LineWidth', 2.5, 'MarkerFaceColor', 'm');
    % Vertical lines at fibril boundaries
    xline((diameter+1)/2 - radius, 'r--', 'LineWidth', 2, 'Alpha', 0.6);
    xline((diameter+1)/2 + radius, 'r--', 'LineWidth', 2, 'Alpha', 0.6);
    hold off;
    grid on;
    title('Phase Shift Profile along Central Line (Y = 0)', ...
          'FontSize', 13, 'FontWeight', 'bold');
    xlabel('X (pixels)', 'FontSize', 11);
    ylabel('Phase Shift (rad)', 'FontSize', 11);
    ylim([-0.3, 2*pi + 0.5]);
    yticks([0, pi/2, pi, 3*pi/2, 2*pi]);
    yticklabels({'0', '\pi/2', '\pi', '3\pi/2', '2\pi'});
    legend('Phase Profile', 'Left Edge (0)', 'Center (\pi)', 'Right Edge (2\pi)', ...
           'Location', 'northwest', 'FontSize', 10);
    set(gca, 'FontSize', 10);
    
    % =====================================================================
    % Subplot 4: Profiles at Different Heights
    % =====================================================================
    subplot(2, 2, 4);
    hold on;
    heights = [0, radius*0.3, radius*0.6, radius*0.85];
    colors = {[0 0.4470 0.7410], [0.8500 0.3250 0.0980], ...
              [0.9290 0.6940 0.1250], [0.4940 0.1840 0.5560]};
    line_widths = [3, 2.5, 2.5, 2.5];
    
    for k = 1:length(heights)
        h_idx = round(diameter/2 + heights(k));
        if h_idx <= diameter
            profile = phase_shift_single(h_idx, :);
            plot(1:diameter, profile, 'Color', colors{k}, ...
                'LineWidth', line_widths(k), ...
                'DisplayName', sprintf('Y = %.1f px (y/r = %.2f)', heights(k), heights(k)/radius));
        end
    end
    
    grid on;
    title('Phase Profiles at Different Heights', 'FontSize', 13, 'FontWeight', 'bold');
    xlabel('X (pixels)', 'FontSize', 11);
    ylabel('Phase Shift (rad)', 'FontSize', 11);
    ylim([0, 2*pi + 0.5]);
    yticks([0, pi/2, pi, 3*pi/2, 2*pi]);
    yticklabels({'0', '\pi/2', '\pi', '3\pi/2', '2\pi'});
    legend('Location', 'northwest', 'FontSize', 10);
    set(gca, 'FontSize', 10);
    hold off;
    
    % Add overall figure title
    sgtitle(sprintf('Fibril Phase Shift Analysis (Diameter = %d px, Colormap: %s)', ...
            diameter, current_cmap), 'FontSize', 15, 'FontWeight', 'bold');
    
    % =====================================================================
    % Save Figure
    % =====================================================================
    if save_figures
        filename = sprintf('fibril_phase_d%d_%s.png', diameter, current_cmap);
        filepath = fullfile(save_path, filename);
        saveas(fig, filepath);
        fprintf('Saved: %s\n', filepath);
    end
    close(fig);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                                                                        %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%    2. Создание ряда срезов фибрилл (фазовый набег) путем дублирования вдоль оси ОХ                          %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                                                                        %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% ========================================================================
%  CREATE ARRAY OF FIBRILS WITH CUMULATIVE PHASE SHIFT
%  ========================================================================

fprintf('\nCreating array of %d fibrils with cumulative phase shift...\n', number_of_fibrils_in_row);

% Array to store the accumulated phase at the EXIT of each row (Y coordinate)
accumulated_phase_per_row = zeros(diameter, 1);

for fibril_idx = 1:number_of_fibrils_in_row
    % Calculate column range for this fibril
    col_start = (fibril_idx - 1) * diameter + 1;
    col_end = fibril_idx * diameter;
    
    fprintf('  Fibril %d: columns %d-%d\n', fibril_idx, col_start, col_end);
    
    % For each row (Y coordinate / horizontal line)
    for row = 1:diameter
        % Get the single fibril pattern for this row
        single_row_pattern = phase_shift_single(row, :);
        
        % Find valid (non-NaN) values in this row
        valid_mask = ~isnan(single_row_pattern);
        
        if any(valid_mask)
            % There are valid points in this row (inside the circle)
            
            % Add accumulated phase from previous fibrils to this row's pattern
            row_with_offset = single_row_pattern + accumulated_phase_per_row(row);
            
            % Write to the big array
            XOY_slice_of_fibrils(row, col_start:col_end) = row_with_offset;
            
            % Find the LAST valid point (rightmost point inside circle) - this is the EXIT
            valid_indices = find(valid_mask);
            last_valid_idx = valid_indices(end);
            
            % Update accumulated phase for this row (phase at exit of this fibril)
            accumulated_phase_per_row(row) = row_with_offset(last_valid_idx);
        else
            % No valid points (outside circle) - just copy NaN
            XOY_slice_of_fibrils(row, col_start:col_end) = single_row_pattern;
        end
    end
end

% Check center line accumulated phase
center_phase_end = accumulated_phase_per_row(center_idx);
fprintf('\nTotal accumulated phase at center line (Y=%d): %.2fπ (%.2f rad)\n', ...
        center_idx, center_phase_end/pi, center_phase_end);
fprintf('Total accumulated phase at edges should be 0\n');

%% ========================================================================
%  CREATE CONTOURS FOR ALL FIBRILS
%  ========================================================================

% Theta for circles (reusing existing theta)
theta_array = linspace(0, 2*pi, 200);

% Arrays to store all circle contours
all_circles_x = [];
all_circles_y = [];

for fibril_idx = 1:number_of_fibrils_in_row
    % Calculate center position for this fibril
    center_x = (fibril_idx - 1) * diameter + diameter/2 + 0.5;
    center_y = diameter/2 + 0.5;
    
    % Create circle for this fibril
    circle_x_temp = center_x + radius * cos(theta_array);
    circle_y_temp = center_y + radius * sin(theta_array);
    
    all_circles_x = [all_circles_x; circle_x_temp(:)];
    all_circles_y = [all_circles_y; circle_y_temp(:)];
end

% ========================================================================
%  СТВОРЕННЯ ПАПКИ ДЛЯ ЗБЕРЕЖЕННЯ
%  ========================================================================
save_path = fullfile(save_path_top, 'Фаз.Зсув - Зрізи');

if ~exist(save_path_multilayer, 'dir')
    mkdir(save_path_multilayer);
    fprintf('\nCreated folder: %s\n', save_path_multilayer);
end

%% ========================================================================
%  ARRAY VISUALIZATION LOOP - Generate figures for each colormap
%  ========================================================================

for cmap_idx = 1:length(colormaps_list)
    current_cmap = colormaps_list{cmap_idx};
    
    % Create figure with all visualizations
    fig = figure('Position', [50, 50, 1800, 1000]);
    
    % =====================================================================
    % Subplot 1: 2D Phase Shift Map (with NaN as background)
    % =====================================================================
    subplot(2, 2, 1);
    
    % Use imagesc with AlphaData for transparency
    h = imagesc(XOY_slice_of_fibrils);
    set(h, 'AlphaData', ~isnan(XOY_slice_of_fibrils)); % Make NaN transparent
    
    hold on;
    % Plot all fibril contours
    for fibril_idx = 1:number_of_fibrils_in_row
        start_idx = (fibril_idx - 1) * length(theta_array) + 1;
        end_idx = fibril_idx * length(theta_array);
        plot(all_circles_x(start_idx:end_idx), all_circles_y(start_idx:end_idx), ...
             'r-', 'LineWidth', 1.5);
    end
    hold off;
    
    colormap(gca, current_cmap);
    cb1 = colorbar;
    cb1.Label.String = 'Phase Shift (rad)';
    cb1.Label.FontSize = 11;
    
    max_phase = number_of_fibrils_in_row * 2 * pi;
    caxis([0, max_phase]);
    
    axis equal tight;
    title(sprintf('Phase Shift in %d Fibrils Array (Colormap: %s)', ...
                  number_of_fibrils_in_row, current_cmap), ...
          'FontSize', 13, 'FontWeight', 'bold');
    xlabel('X (pixels)', 'FontSize', 11);
    ylabel('Y (pixels)', 'FontSize', 11);
    set(gca, 'YDir', 'normal', 'FontSize', 10, 'Color', 'white');
    grid on;
    
    % =====================================================================
    % Subplot 2: 3D Surface Representation
    % =====================================================================
    subplot(2, 2, 2);
    [X_full, Y_full] = meshgrid(1:size(XOY_slice_of_fibrils, 2), ...
                                 1:size(XOY_slice_of_fibrils, 1));
    surf(X_full, Y_full, XOY_slice_of_fibrils, 'EdgeColor', 'none', 'FaceAlpha', 0.9);
    
    hold on;
    % Plot all fibril contours on 3D
    for fibril_idx = 1:number_of_fibrils_in_row
        start_idx = (fibril_idx - 1) * length(theta_array) + 1;
        end_idx = fibril_idx * length(theta_array);
        circle_z = zeros(size(all_circles_x(start_idx:end_idx)));
        plot3(all_circles_x(start_idx:end_idx), all_circles_y(start_idx:end_idx), ...
              circle_z, 'r-', 'LineWidth', 2);
    end
    hold off;
    
    colormap(gca, current_cmap);
    cb2 = colorbar;
    cb2.Label.String = 'Phase Shift (rad)';
    cb2.Label.FontSize = 11;
    caxis([0, max_phase]);
    
    title('3D Phase Shift Visualization', 'FontSize', 13, 'FontWeight', 'bold');
    xlabel('X (pixels)', 'FontSize', 11);
    ylabel('Y (pixels)', 'FontSize', 11);
    zlabel('Phase Shift (rad)', 'FontSize', 11);
    view(-30, 60);
    grid on;
    set(gca, 'FontSize', 10);
    lighting gouraud;
    camlight('headlight');
    
    % =====================================================================
    % Subplot 3: Central Line Profile (Y = 0) - All Fibrils
    % =====================================================================
    subplot(2, 2, 3);
    profile_x_full = XOY_slice_of_fibrils(center_idx, :);
    plot(1:length(profile_x_full), profile_x_full, 'b-', 'LineWidth', 2.5);
    hold on;
    
    % Mark boundaries and important points for each fibril
    for fibril_idx = 1:number_of_fibrils_in_row
        col_start = (fibril_idx - 1) * diameter + 1;
        col_center = (fibril_idx - 1) * diameter + diameter/2;
        col_end = fibril_idx * diameter;
        
        phase_offset = (fibril_idx - 1) * 2 * pi;
        
        % Vertical lines at fibril boundaries
        if fibril_idx > 1
            xline(col_start, 'k--', 'LineWidth', 1, 'Alpha', 0.3);
        end
        
        % Mark center of each fibril
        plot(col_center, phase_offset + pi, 'ro', 'MarkerSize', 8, ...
             'LineWidth', 1.5, 'MarkerFaceColor', 'r');
    end
    
    % Mark fibril edges with red dashed lines
    for fibril_idx = 1:number_of_fibrils_in_row
        left_edge = (fibril_idx - 1) * diameter + (diameter/2 - radius);
        right_edge = (fibril_idx - 1) * diameter + (diameter/2 + radius);
        xline(left_edge, 'r--', 'LineWidth', 1.5, 'Alpha', 0.5);
        xline(right_edge, 'r--', 'LineWidth', 1.5, 'Alpha', 0.5);
    end
    
    hold off;
    grid on;
    title('Phase Shift Profile along Central Line (Y = 0)', ...
          'FontSize', 13, 'FontWeight', 'bold');
    xlabel('X (pixels)', 'FontSize', 11);
    ylabel('Phase Shift (rad)', 'FontSize', 11);
    ylim([0, max_phase + 1]);
    set(gca, 'FontSize', 10);
    
    % =====================================================================
    % Subplot 4: Individual Fibril Profiles Overlay
    % =====================================================================
    subplot(2, 2, 4);
    hold on;
    
    colors_array = jet(number_of_fibrils_in_row);
    
    for fibril_idx = 1:number_of_fibrils_in_row
        col_start = (fibril_idx - 1) * diameter + 1;
        col_end = fibril_idx * diameter;
        
        profile_segment = XOY_slice_of_fibrils(center_idx, col_start:col_end);
        
        plot(1:diameter, profile_segment, 'Color', colors_array(fibril_idx, :), ...
             'LineWidth', 2.5, ...
             'DisplayName', sprintf('Fibril %d (%.0fπ to %.0fπ)', ...
                                    fibril_idx, (fibril_idx-1)*2, fibril_idx*2));
    end
    
    grid on;
    title('Individual Fibril Phase Profiles', 'FontSize', 13, 'FontWeight', 'bold');
    xlabel('X relative (pixels)', 'FontSize', 11);
    ylabel('Phase Shift (rad)', 'FontSize', 11);
    legend('Location', 'northwest', 'FontSize', 9);
    set(gca, 'FontSize', 10);
    hold off;
    
    % Add overall figure title
    sgtitle(sprintf('Fibril Array Phase Analysis (%d fibrils, D=%dpx, Total: 0→%.0fπ, Colormap: %s)', ...
            number_of_fibrils_in_row, diameter, number_of_fibrils_in_row*2, current_cmap), ...
            'FontSize', 15, 'FontWeight', 'bold');
    
    % =====================================================================
    % Save Figure
    % =====================================================================
    if save_figures
        filename = sprintf('fibril_array_n%d_d%d_%s.png', ...
                          number_of_fibrils_in_row, diameter, current_cmap);
        filepath = fullfile(save_path, filename);
        saveas(fig, filepath);
        fprintf('Saved: %s\n', filepath);
    end
    close(fig);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                                                                        %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%            3. Дублирование среза фибрил вдоль оси ОZ (шар фибрил)                      %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                                                                        %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% ========================================================================
%  CREATE 3D FIBRIL STRUCTURE (FIBRILS LYING ALONG Z AXIS)
%  ========================================================================

fprintf('\n=== Creating 3D Fibril Structure (fibrils lying along Z axis) ===\n');

% Get dimensions of the 2D array
[height, width] = size(XOY_slice_of_fibrils);

% XOY plane contains circles (fibrils cross-sections)
% We replicate along Z axis (depth, fibrils extend)

depth_z = width; % Number of layers along Z

% Initialize 3D array: (X, Y, Z)
% X - horizontal (rows of original)
% Y - vertical (columns of original) 
% Z - depth (fibrils extend along this axis)

fibril_3D = nan(height, width, depth_z);

% Replicate the XOY slice along Z-axis
fprintf('Replicating XOY plane (circles) along Z axis...\n');
fprintf('Original 2D array (XOY): %d (X/rows) x %d (Y/cols)\n', height, width);

for z_idx = 1:depth_z
    % Each Z-layer contains the same XOY cross-section
    fibril_3D(:, :, z_idx) = XOY_slice_of_fibrils;
end

fprintf('3D structure created: %d (X) x %d (Y) x %d (Z) voxels\n', ...
        size(fibril_3D, 1), size(fibril_3D, 2), size(fibril_3D, 3));
fprintf('XOY plane contains circles (fibril cross-sections)\n');
fprintf('Fibrils EXTEND along Z axis (lying down)\n');
fprintf('Total voxels: %d\n', numel(fibril_3D));
fprintf('Valid voxels (inside fibrils): %d\n', sum(~isnan(fibril_3D(:))));

%% ========================================================================
%  CREATE OUTPUT FOLDER
%  ========================================================================

% Create subfolder "Окремий шар" inside save_path
output_base_folder = save_path_top;
output_subfolder = fullfile(output_base_folder, 'Фаз.Зсув - Окремий шар');

if ~exist(output_base_folder, 'dir')
    mkdir(output_base_folder);
end

if ~exist(output_subfolder, 'dir')
    mkdir(output_subfolder);
    fprintf('Created folder: %s\n', output_subfolder);
end

%% ========================================================================
%  3D VISUALIZATION USING GIBBON WITH MULTIPLE COLORMAPS (FIXED NO CROP)
%  ========================================================================

fprintf('\n=== Starting 3D Visualization with GIBBON ===\n');

% Visualization parameters
fontSize = 12;
face_alpha = 0.5; % Transparency

% Prepare data
M = fibril_3D;
L_mask_all = ~isnan(M); % Mask for all valid voxels
M(isnan(M)) = 0; % Replace NaN with 0 for visualization

max_phase = number_of_fibrils_in_row * 2 * pi;

fprintf('Max phase: %.2f rad (%.2fπ)\n', max_phase, max_phase/pi);

%% --- Loop through colormaps ---
for cmap_idx = 1:length(colormaps_list)
    cmap_name = colormaps_list{cmap_idx};
    fprintf('\n--- Processing colormap: %s (%d/%d) ---\n', ...
            cmap_name, cmap_idx, length(colormaps_list));
    
    cmap = eval(sprintf('%s(256)', cmap_name)); % Generate colormap
    
    %% Visualization 1: ALL FIBRILS
    fprintf('Creating visualization: All fibrils with %s colormap...\n', cmap_name);
    fig_all = figure('Visible', 'off', 'Position', [100, 100, 1400, 1000]);
    title(sprintf('3D Fibril Array - Phase Distribution'), ...
          'FontSize', fontSize+2, 'FontWeight', 'bold');
    xlabel('X - Columns (fibrils)', 'FontSize', fontSize); 
    ylabel('Y - Rows', 'FontSize', fontSize); 
    zlabel('Z - Depth (layers)', 'FontSize', fontSize);
    hold on;
    
    % Build 3D patch
    [F_all, V_all, C_all] = im2patch(M, L_mask_all, 'vb');
    gpatch(F_all, V_all, C_all, 'none', face_alpha);
    
    % Visualization settings
    colormap(cmap);
    hcb = colorbar;
    hcb.Label.String = 'Phase Shift (rad)';
    hcb.Label.FontSize = fontSize;
    caxis([0, max_phase]);
    
    lighting gouraud;
    camlight('headlight');
    material shiny;
    axisGeom(gca, fontSize);
    view([-40, 30]); % Angle from third example (no cropping)
    axis equal; axis tight;
    grid on;
    
    % Save figure
    output_file = fullfile(output_subfolder, ...
                          sprintf('fibril_3D_all_n%d_cmap_%s.png', ...
                                  number_of_fibrils_in_row, cmap_name));
    saveas(fig_all, output_file);
    fprintf('Saved: %s\n', output_file);
    close(fig_all);
    
    %% Visualization 2: PHASE RANGES
    
    % Define phase thresholds
    low_threshold = prctile(M(L_mask_all), 33.3);
    high_threshold = prctile(M(L_mask_all), 66.6);
    
    fprintf('Phase thresholds: Low=%.2fπ, High=%.2fπ\n', ...
            low_threshold/pi, high_threshold/pi);
    
    % Create masks
    L_mask_low = L_mask_all & (M <= low_threshold);
    L_mask_mid = L_mask_all & (M > low_threshold) & (M < high_threshold);
    L_mask_high = L_mask_all & (M >= high_threshold);
    
    % LOW PHASE
    if sum(L_mask_low(:)) > 0
        fprintf('Creating low phase visualization with %s...\n', cmap_name);
        fig_low = figure('Visible', 'off', 'Position', [100, 100, 1400, 1000]);
        title('3D Fibril Array - Low Phase (0-33%)', 'FontSize', fontSize+2, 'FontWeight', 'bold');
        xlabel('X - Columns', 'FontSize', fontSize); 
        ylabel('Y - Rows', 'FontSize', fontSize); 
        zlabel('Z - Depth', 'FontSize', fontSize);
        hold on;
        
        [F_low, V_low, C_low] = im2patch(M, L_mask_low, 'vb');
        gpatch(F_low, V_low, C_low, 'none', face_alpha);
        
        colormap(cmap);
        hcb = colorbar;
        hcb.Label.String = 'Phase Shift (rad)';
        caxis([0, max_phase]);
        lighting gouraud; camlight('headlight'); material shiny;
        axisGeom(gca, fontSize);
        view([-40, 30]);
        axis equal; axis tight; grid on;
        
        output_file = fullfile(output_subfolder, ...
                              sprintf('fibril_3D_low_phase_n%d_cmap_%s.png', ...
                                      number_of_fibrils_in_row, cmap_name));
        saveas(fig_low, output_file);
        fprintf('Saved: %s\n', output_file);
        close(fig_low);
    end
    
    % MEDIUM PHASE
    if sum(L_mask_mid(:)) > 0
        fprintf('Creating medium phase visualization with %s...\n', cmap_name);
        fig_mid = figure('Visible', 'off', 'Position', [100, 100, 1400, 1000]);
        title('3D Fibril Array - Medium Phase (33-66%)', 'FontSize', fontSize+2, 'FontWeight', 'bold');
        xlabel('X - Columns', 'FontSize', fontSize); 
        ylabel('Y - Rows', 'FontSize', fontSize); 
        zlabel('Z - Depth', 'FontSize', fontSize);
        hold on;
        
        [F_mid, V_mid, C_mid] = im2patch(M, L_mask_mid, 'vb');
        gpatch(F_mid, V_mid, C_mid, 'none', face_alpha);
        
        colormap(cmap);
        hcb = colorbar;
        hcb.Label.String = 'Phase Shift (rad)';
        caxis([0, max_phase]);
        lighting gouraud; camlight('headlight'); material shiny;
        axisGeom(gca, fontSize);
        view([-40, 30]);
        axis equal; axis tight; grid on;
        
        output_file = fullfile(output_subfolder, ...
                              sprintf('fibril_3D_mid_phase_n%d_cmap_%s.png', ...
                                      number_of_fibrils_in_row, cmap_name));
        saveas(fig_mid, output_file);
        fprintf('Saved: %s\n', output_file);
        close(fig_mid);
    end
    
    % HIGH PHASE
    if sum(L_mask_high(:)) > 0
        fprintf('Creating high phase visualization with %s...\n', cmap_name);
        fig_high = figure('Visible', 'off', 'Position', [100, 100, 1400, 1000]);
        title('3D Fibril Array - High Phase (66-100%)', 'FontSize', fontSize+2, 'FontWeight', 'bold');
        xlabel('X - Columns', 'FontSize', fontSize); 
        ylabel('Y - Rows', 'FontSize', fontSize); 
        zlabel('Z - Depth', 'FontSize', fontSize);
        hold on;
        
        [F_high, V_high, C_high] = im2patch(M, L_mask_high, 'vb');
        gpatch(F_high, V_high, C_high, 'none', face_alpha);
        
        colormap(cmap);
        hcb = colorbar;
        hcb.Label.String = 'Phase Shift (rad)';
        caxis([0, max_phase]);
        lighting gouraud; camlight('headlight'); material shiny;
        axisGeom(gca, fontSize);
        view([-40, 30]);
        axis equal; axis tight; grid on;
        
        output_file = fullfile(output_subfolder, ...
                              sprintf('fibril_3D_high_phase_n%d_cmap_%s.png', ...
                                      number_of_fibrils_in_row, cmap_name));
        saveas(fig_high, output_file);
        fprintf('Saved: %s\n', output_file);
        close(fig_high);
    end
    
    %% Visualization 4: INDIVIDUAL FIBRILS (only with first colormap)
    if cmap_idx == 1
        fprintf('\n--- Creating individual fibril visualizations ---\n');
        cmap_name = colormaps_list{1};
        cmap = eval(sprintf('%s(256)', cmap_name));
        
        for fibril_idx = 1:number_of_fibrils_in_row
            col_start = (fibril_idx - 1) * diameter + 1;
            col_end = fibril_idx * diameter;
            
            % Create mask for this specific fibril (along Y axis, as in third example where no cropping occurred)
            L_mask_fibril = false(size(M));
            L_mask_fibril(:, col_start:col_end, :) = ~isnan(fibril_3D(:, col_start:col_end, :));
            
            if sum(L_mask_fibril(:)) == 0
                continue;
            end
            
            fprintf('Creating fibril %d/%d...\n', fibril_idx, number_of_fibrils_in_row);
            
            fig_fib = figure('Visible', 'off', 'Position', [100, 100, 1400, 1000]);
            title(sprintf('3D Fibril #%d - Phase Range: %.0fπ to %.0fπ', ...
                          fibril_idx, (fibril_idx-1)*2, fibril_idx*2), ...
                  'FontSize', fontSize+2, 'FontWeight', 'bold');
            xlabel('X - Columns', 'FontSize', fontSize); 
            ylabel('Y - Rows', 'FontSize', fontSize); 
            zlabel('Z - Depth', 'FontSize', fontSize);
            hold on;
            
            [F_fib, V_fib, C_fib] = im2patch(M, L_mask_fibril, 'vb');
            gpatch(F_fib, V_fib, C_fib, 'none', 0.5);
            
            colormap(cmap);
            hcb = colorbar;
            hcb.Label.String = 'Phase Shift (rad)';
            caxis([0, max_phase]);
            lighting gouraud; camlight('headlight'); material shiny;
            axisGeom(gca, fontSize);
            view([-40, 30]);
            axis equal; axis tight; grid on;
            
            output_file = fullfile(output_subfolder, ...
                                  sprintf('fibril_3D_single_%d_n%d_cmap_%s.png', ...
                                          fibril_idx, number_of_fibrils_in_row, cmap_name));
            saveas(fig_fib, output_file);
            fprintf('Saved fibril %d\n', fibril_idx);
            close(fig_fib);
        end
    end
    
end

fprintf('\n=== 3D Visualization Complete ===\n');
fprintf('All images saved to: %s\n', output_subfolder);
fprintf('Total colormaps processed: %d\n', length(colormaps_list));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                                                                        %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                            4                                           %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                                                                        %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Количество дублирований
num_duplications = 3;
% Создаем трехслойную конструкцию одной командой
fibril_3D_layers = repmat(fibril_3D, num_duplications, 1, 1);
% Визуализация трехслойной структуры fibril_3D_layers с помощью Gibbon

% Предполагаем, что fibril_3D_layers уже создан (размер 168x336x336)
% и у вас есть массив colormaps_list с цветовыми картами

%% ========================================================================
%  CREATE OUTPUT FOLDER
%  ========================================================================

% Create subfolder "Трьохшарова структура" inside save_path
output_base_folder = save_path_top;
output_subfolder = fullfile(output_base_folder, 'Фаз.Зсув - Трьохшарова структура');

if ~exist(output_base_folder, 'dir')
    mkdir(output_base_folder);
end

if ~exist(output_subfolder, 'dir')
    mkdir(output_subfolder);
    fprintf('Created folder: %s\n', output_subfolder);
end

%% ========================================================================
%  3D VISUALIZATION OF THREE-LAYER STRUCTURE
%  ========================================================================

fprintf('\n=== Starting 3D Visualization of fibril_3D_layers ===\n');

% Visualization parameters
fontSize = 12;
face_alpha = 0.5; % Transparency
num_layers = 3;
layer_depth = size(fibril_3D, 1); % 56

% Prepare data
M = fibril_3D_layers;
L_mask_all = ~isnan(M); % Mask for all valid voxels
M(isnan(M)) = 0; % Replace NaN with 0 for visualization

max_phase = number_of_fibrils_in_row * 2 * pi;

fprintf('Structure size: %d x %d x %d\n', size(M));
fprintf('Number of layers: %d\n', num_layers);
fprintf('Layer depth: %d\n', layer_depth);
fprintf('Max phase: %.2f rad (%.2fπ)\n', max_phase, max_phase/pi);

%% --- Loop through colormaps ---
for cmap_idx = 1:length(colormaps_list)
    cmap_name = colormaps_list{cmap_idx};
    fprintf('\n--- Processing colormap: %s (%d/%d) ---\n', ...
            cmap_name, cmap_idx, length(colormaps_list));
    
    cmap = eval(sprintf('%s(256)', cmap_name)); % Generate colormap
    
    %% Visualization 1: ALL THREE LAYERS TOGETHER
    fprintf('Creating visualization: All 3 layers with %s colormap...\n', cmap_name);
    fig_all = figure('Visible', 'off', 'Position', [100, 100, 1400, 1000]);
    title(sprintf('3D Three-Layer Fibril Structure - Phase Distribution'), ...
          'FontSize', fontSize+2, 'FontWeight', 'bold');
    xlabel('X - Columns (fibrils)', 'FontSize', fontSize); 
    ylabel('Y - Rows', 'FontSize', fontSize); 
    zlabel('Z - Depth (3 layers)', 'FontSize', fontSize);
    hold on;
    
    % Build 3D patch for ALL layers
    [F_all, V_all, C_all] = im2patch(M, L_mask_all, 'vb');
    gpatch(F_all, V_all, C_all, 'none', face_alpha);
    
    % Visualization settings
    colormap(cmap);
    hcb = colorbar;
    hcb.Label.String = 'Phase Shift (rad)';
    hcb.Label.FontSize = fontSize;
    caxis([0, max_phase]);
    
    lighting gouraud;
    camlight('headlight');
    material shiny;
    axisGeom(gca, fontSize);
    view([-40, 30]);
    axis equal; axis tight;
    grid on;
    
    % Save figure
    output_file = fullfile(output_subfolder, ...
                          sprintf('fibril_3D_layers_all_n%d_cmap_%s.png', ...
                                  number_of_fibrils_in_row, cmap_name));
    saveas(fig_all, output_file);
    fprintf('Saved: %s\n', output_file);
    close(fig_all);
    
    %% Visualization 2: EACH LAYER SEPARATELY
    fprintf('Creating separate visualizations for each layer...\n');
    
    for layer = 1:num_layers
        % Extract current layer
        start_idx = (layer - 1) * layer_depth + 1;
        end_idx = layer * layer_depth;
        M_layer = M(start_idx:end_idx, :, :);
        L_mask_layer = L_mask_all(start_idx:end_idx, :, :);
        
        if sum(L_mask_layer(:)) == 0
            continue;
        end
        
        fprintf('Creating layer %d/%d visualization...\n', layer, num_layers);
        
        fig_layer = figure('Visible', 'off', 'Position', [100, 100, 1400, 1000]);
        title(sprintf('3D Fibril Structure - Layer %d of %d', layer, num_layers), ...
              'FontSize', fontSize+2, 'FontWeight', 'bold');
        xlabel('X - Columns', 'FontSize', fontSize); 
        ylabel('Y - Rows', 'FontSize', fontSize); 
        zlabel('Z - Depth', 'FontSize', fontSize);
        hold on;
        
        % Build 3D patch for current layer
        [F_layer, V_layer, C_layer] = im2patch(M_layer, L_mask_layer, 'vb');
        
        % Shift Z coordinates for proper positioning in 3D space
        V_layer(:, 3) = V_layer(:, 3) + (layer - 1) * layer_depth;
        
        gpatch(F_layer, V_layer, C_layer, 'none', face_alpha);
        
        % Visualization settings
        colormap(cmap);
        hcb = colorbar;
        hcb.Label.String = 'Phase Shift (rad)';
        hcb.Label.FontSize = fontSize;
        caxis([0, max_phase]);
        
        lighting gouraud;
        camlight('headlight');
        material shiny;
        axisGeom(gca, fontSize);
        view([-40, 30]);
        axis equal; axis tight;
        grid on;
        
        % Save figure
        output_file = fullfile(output_subfolder, ...
                              sprintf('fibril_3D_layers_layer%d_n%d_cmap_%s.png', ...
                                      layer, number_of_fibrils_in_row, cmap_name));
        saveas(fig_layer, output_file);
        fprintf('Saved layer %d: %s\n', layer, output_file);
        close(fig_layer);
    end
    
    %% Visualization 3: PHASE RANGES ACROSS ALL LAYERS
    
    % Define phase thresholds
    valid_values = M(L_mask_all);
    low_threshold = prctile(valid_values, 33.3);
    high_threshold = prctile(valid_values, 66.6);
    
    fprintf('Phase thresholds: Low=%.2fπ, High=%.2fπ\n', ...
            low_threshold/pi, high_threshold/pi);
    
    % Create masks
    L_mask_low = L_mask_all & (M <= low_threshold);
    L_mask_mid = L_mask_all & (M > low_threshold) & (M < high_threshold);
    L_mask_high = L_mask_all & (M >= high_threshold);
    
    % LOW PHASE
    if sum(L_mask_low(:)) > 0
        fprintf('Creating low phase visualization (all layers)...\n');
        fig_low = figure('Visible', 'off', 'Position', [100, 100, 1400, 1000]);
        title('3D Three-Layer Structure - Low Phase (0-33%)', ...
              'FontSize', fontSize+2, 'FontWeight', 'bold');
        xlabel('X - Columns', 'FontSize', fontSize); 
        ylabel('Y - Rows', 'FontSize', fontSize); 
        zlabel('Z - Depth', 'FontSize', fontSize);
        hold on;
        
        [F_low, V_low, C_low] = im2patch(M, L_mask_low, 'vb');
        gpatch(F_low, V_low, C_low, 'none', face_alpha);
        
        colormap(cmap);
        hcb = colorbar;
        hcb.Label.String = 'Phase Shift (rad)';
        caxis([0, max_phase]);
        lighting gouraud; camlight('headlight'); material shiny;
        axisGeom(gca, fontSize);
        view([-40, 30]);
        axis equal; axis tight; grid on;
        
        output_file = fullfile(output_subfolder, ...
                              sprintf('fibril_3D_layers_low_phase_n%d_cmap_%s.png', ...
                                      number_of_fibrils_in_row, cmap_name));
        saveas(fig_low, output_file);
        fprintf('Saved: %s\n', output_file);
        close(fig_low);
    end
    
    % MEDIUM PHASE
    if sum(L_mask_mid(:)) > 0
        fprintf('Creating medium phase visualization (all layers)...\n');
        fig_mid = figure('Visible', 'off', 'Position', [100, 100, 1400, 1000]);
        title('3D Three-Layer Structure - Medium Phase (33-66%)', ...
              'FontSize', fontSize+2, 'FontWeight', 'bold');
        xlabel('X - Columns', 'FontSize', fontSize); 
        ylabel('Y - Rows', 'FontSize', fontSize); 
        zlabel('Z - Depth', 'FontSize', fontSize);
        hold on;
        
        [F_mid, V_mid, C_mid] = im2patch(M, L_mask_mid, 'vb');
        gpatch(F_mid, V_mid, C_mid, 'none', face_alpha);
        
        colormap(cmap);
        hcb = colorbar;
        hcb.Label.String = 'Phase Shift (rad)';
        caxis([0, max_phase]);
        lighting gouraud; camlight('headlight'); material shiny;
        axisGeom(gca, fontSize);
        view([-40, 30]);
        axis equal; axis tight; grid on;
        
        output_file = fullfile(output_subfolder, ...
                              sprintf('fibril_3D_layers_mid_phase_n%d_cmap_%s.png', ...
                                      number_of_fibrils_in_row, cmap_name));
        saveas(fig_mid, output_file);
        fprintf('Saved: %s\n', output_file);
        close(fig_mid);
    end
    
    % HIGH PHASE
    if sum(L_mask_high(:)) > 0
        fprintf('Creating high phase visualization (all layers)...\n');
        fig_high = figure('Visible', 'off', 'Position', [100, 100, 1400, 1000]);
        title('3D Three-Layer Structure - High Phase (66-100%)', ...
              'FontSize', fontSize+2, 'FontWeight', 'bold');
        xlabel('X - Columns', 'FontSize', fontSize); 
        ylabel('Y - Rows', 'FontSize', fontSize); 
        zlabel('Z - Depth', 'FontSize', fontSize);
        hold on;
        
        [F_high, V_high, C_high] = im2patch(M, L_mask_high, 'vb');
        gpatch(F_high, V_high, C_high, 'none', face_alpha);
        
        colormap(cmap);
        hcb = colorbar;
        hcb.Label.String = 'Phase Shift (rad)';
        caxis([0, max_phase]);
        lighting gouraud; camlight('headlight'); material shiny;
        axisGeom(gca, fontSize);
        view([-40, 30]);
        axis equal; axis tight; grid on;
        
        output_file = fullfile(output_subfolder, ...
                              sprintf('fibril_3D_layers_high_phase_n%d_cmap_%s.png', ...
                                      number_of_fibrils_in_row, cmap_name));
        saveas(fig_high, output_file);
        fprintf('Saved: %s\n', output_file);
        close(fig_high);
    end
    
end

fprintf('\n=== Visualization Complete ===\n');
fprintf('Total files saved in: %s\n', output_subfolder);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                                                                        %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                            5                                           %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                                                                        %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% Базова папка для збереження
save_path = 'C://1';
% Вхідні дані
phase_3D_layers = fibril_3D_layers;

        %__________________________________________________________________________
        % CASE 1 - ізотропні фібрілли
        % ro_3D_layers = ones(size(phase_3D_layers)) * ro;
        % CASE 2 - анізотропні фібрілли
          ro_3D_layers = optical_axis_multilayer_3D;
        %__________________________________________________________________________

% Параметри зсуву (step)
step_values = [1, 5, 10, 20];
% Отримуємо розміри з вхідних 3D масивів
[rows, cols, n_layers] = size(phase_3D_layers);
% Імена полів матриці Мююллера
field_names = {'f11', 'f12', 'f21', 'f22', 'f23', 'f24', 'f32', 'f33', 'f34', 'f42', 'f43', 'f44'};
% Параметри візуалізації
fontSize = 12;
face_alpha = 0.5; % Прозорість вокселів 

% ==============================================================================
% НАЛАШТУВАННЯ ЗМЕНШЕННЯ ВОКСЕЛІВ
% Закоментуйте наступний рядок, щоб відобразити ВСІ воксели
% ==============================================================================
%voxel_reduction_factor = 100; % Зменшення кількості вокселів у 100 разів
voxel_reduction_factor = []; % Розкоментуйте цей рядок для відображення ВСІХ вокселів

% ==============================================================================
% ПРАВКА 1: ЗОВНІШНІЙ ЦИКЛ ПО КОЛОРМАПАХ
% ==============================================================================

for cmap_idx = 1:length(colormaps_list)
    current_cmap_name = colormaps_list{cmap_idx};
    cmap = feval(current_cmap_name, 256);
    
    fprintf('\n########################################\n');
    fprintf('COLORMAP: %s (%d/%d)\n', current_cmap_name, cmap_idx, length(colormaps_list));
    fprintf('########################################\n');

    % ==============================================================================
    % ОСНОВНИЙ ЦИКЛ ПО КРОКАХ (STEP)
    % ==============================================================================

    for step_idx = 1:length(step_values)
        current_step = step_values(step_idx);
        
        fprintf('\n========================================\n');
        fprintf('Processing step = %d (colormap: %s)\n', current_step, current_cmap_name);
        fprintf('========================================\n');
        
        % ==== ПЕРЕВІРКА: step не повинен перевищувати розмір масиву ====
        if current_step >= cols
            warning('Step (%d) must be less than number of columns (%d). Skipping.', current_step, cols);
            continue;
        end
        
        % ПРАВКА 1: Створення підпапки з урахуванням колормапу
        step_folder = fullfile(save_path, sprintf('step_%d', current_step));
        if ~exist(step_folder, 'dir')
            mkdir(step_folder);
            fprintf('Created folder: %s\n', step_folder);
        end
        
        % ==============================================================================
        % СТВОРЕННЯ МАСКИ NaN З ВХІДНИХ ДАНИХ
        % ==============================================================================
        
        % Створюємо маску де NaN = false, валідні значення = true
        valid_mask_original = ~isnan(phase_3D_layers);
        
        % Зменшуємо маску відповідно до нового розміру (new_cols)
        new_cols = cols - current_step;
        valid_mask = valid_mask_original(:, 1:new_cols, :);
        
        fprintf('Valid data mask created\n');
        fprintf('Number of valid voxels in mask: %d\n', sum(valid_mask(:)));
        fprintf('Number of NaN voxels: %d\n', sum(~valid_mask(:)));
        
        % ==============================================================================
        % ОБЧИСЛЕННЯ МАТРИЦІ МЮЛЛЕРА
        % ==============================================================================
        
        % Попереднє виділення пам'яті
        M = struct();
        
        for i = 1:length(field_names)
            M.(field_names{i}) = zeros(rows, new_cols, n_layers);
        end
        
        % ==== Головний цикл по шарах ====
        for idx = 1:n_layers
            LB_map = squeeze(phase_3D_layers(:, :, idx));
            rho_map = squeeze(ro_3D_layers(:, :, idx));
            
            % ==== ОБРОБКА NaN: заміна на 0 ====
            LB_map(isnan(LB_map)) = 0;
            rho_map(isnan(rho_map)) = 0;
            
            % Витягуємо пари значень
            LB1  = LB_map(:, 1:new_cols);
            LB2  = LB_map(:, (1+current_step):cols);
            rho1 = rho_map(:, 1:new_cols);
            rho2 = rho_map(:, (1+current_step):cols);
            
            % ==== Обчислення елементів матриці Мюллера ====
            M.f11(:, :, idx) = 1 + 0.25 * LB1 .* LB2 .* cos(2 * (rho1 - rho2));
            M.f12(:, :, idx) = 1 - 0.25 * LB1 .* LB2 .* sin(2*rho1) .* sin(2*rho2);
            M.f21(:, :, idx) = 1 - 0.25 * LB1 .* LB2 .* sin(2*rho1) .* sin(2*rho2);
            M.f22(:, :, idx) = 1 + 0.25 * LB1 .* LB2 .* cos(2 * (rho1 + rho2));
            M.f23(:, :, idx) = 0.25 * (LB1 .* sin(2*rho1) + LB2 .* sin(2*rho2));
            M.f24(:, :, idx) = 0.25 * LB1 .* LB2 .* sin(2*(rho1 + rho2));
            
            M.f32(:, :, idx) = -M.f23(:, :, idx);
            M.f33(:, :, idx) = 1 - 0.25 * LB1 .* LB2 .* cos(2 * (rho1 + rho2));
            M.f34(:, :, idx) = 0.25 * LB1 .* LB2 .* cos(2*(rho1 - rho2));
            
            M.f42(:, :, idx) = -M.f24(:, :, idx);
            M.f43(:, :, idx) = -M.f34(:, :, idx);
            M.f44(:, :, idx) = 1 - 0.25 * LB1 .* LB2 .* cos(2 * (rho1 - rho2));
        end
        
        fprintf('Input size: %d x %d x %d\n', rows, cols, n_layers);
        fprintf('Output size M.fXX: %d x %d x %d\n', rows, new_cols, n_layers);
        
        % ==============================================================================
        % ОБРОБКА КОЖНОГО ПОЛЯ
        % ==============================================================================
        
        for field_idx = 1:length(field_names)
            current_field = field_names{field_idx};
            
            fprintf('\n--- Processing field: %s ---\n', current_field);
            
            % Створення підпапки для поточного поля
            field_folder = fullfile(step_folder, current_field);
            if ~exist(field_folder, 'dir')
                mkdir(field_folder);
                fprintf('Created folder: %s\n', field_folder);
            end
            
            % Отримання даних поточного поля
            field_data = M.(current_field);
            
            % ==============================================================================
            % ПІДГОТОВКА ДАНИХ ДЛЯ ВІЗУАЛІЗАЦІЇ
            % ==============================================================================
            
            fprintf('=== Preparing for visualization ===\n');
            fprintf('Data size: %d x %d x %d\n', size(field_data, 1), size(field_data, 2), size(field_data, 3));
            
            % ==== ЗАСТОСУВАННЯ МАСКИ NaN ====
            % Створюємо базову маску тільки для валідних даних (де не було NaN)
            L_mask_all = valid_mask;
            
            fprintf('NaN mask applied\n');
            fprintf('Number of voxels after NaN mask: %d\n', sum(L_mask_all(:)));
            
            % Обчислення діапазону даних ТІЛЬКИ для валідних вокселів
            valid_data = field_data(L_mask_all);
            
            if isempty(valid_data)
                fprintf('WARNING: No valid data after applying NaN mask\n');
                continue;
            end
            
            data_min = min(valid_data);
            data_max = max(valid_data);
            data_range = data_max - data_min;
            data_mean = mean(valid_data);
            
            fprintf('Minimum: %.4f\n', data_min);
            fprintf('Maximum: %.4f\n', data_max);
            fprintf('Mean: %.4f\n', data_mean);
            fprintf('Range: %.4f\n', data_range);
            
            % ==== ПЕРЕВІРКА: якщо всі значення однакові ====
            if abs(data_range) < eps
                fprintf('WARNING: All values are identical (%.4f), skipping visualization\n', data_min);
                continue;
            end
            
            total_voxels = sum(L_mask_all(:));
            
            % ==============================================================================
            % ВИЗНАЧЕННЯ ПОРОГІВ ДЛЯ ДІАПАЗОНІВ
            % ==============================================================================
            
            % LOW: від мінімуму до мінімум + 10% діапазону (0-10%)
            low_min = data_min;
            low_max = data_min + 0.10 * data_range;
            
            % MID: середнє ±5% діапазону (45-55%)
            mid_min = data_mean - 0.05 * data_range;
            mid_max = data_mean + 0.05 * data_range;
            
            % HIGH: від максимум - 10% до максимуму (90-100%)
            high_min = data_max - 0.10 * data_range;
            high_max = data_max;
            
            fprintf('\nThreshold ranges:\n');
            fprintf('  LOW  (0-10%%):   %.4f - %.4f\n', low_min, low_max);
            fprintf('  MID  (45-55%%):  %.4f - %.4f\n', mid_min, mid_max);
            fprintf('  HIGH (90-100%%): %.4f - %.4f\n', high_min, high_max);
            
            % Створення масок для діапазонів
            L_mask_low = L_mask_all & (field_data >= low_min) & (field_data <= low_max);
            L_mask_mid = L_mask_all & (field_data >= mid_min) & (field_data <= mid_max);
            L_mask_high = L_mask_all & (field_data >= high_min) & (field_data <= high_max);
            
            fprintf('Number of voxels: LOW=%d, MID=%d, HIGH=%d\n', ...
                sum(L_mask_low(:)), sum(L_mask_mid(:)), sum(L_mask_high(:)));
            
            % ==============================================================================
            % ВІЗУАЛІЗАЦІЯ 1: MAIN - ВСІ ДАНІ
            % ==============================================================================
            
            fprintf('\nCreating MAIN visualization (all data)...\n');
            
            if sum(L_mask_all(:)) > 0
                fig_main = figure('Visible', 'off', 'Position', [100, 100, 1400, 1000]);
                title(sprintf('%s (step=%d, colormap=%s) - All Data', current_field, current_step, current_cmap_name), ...
                      'FontSize', fontSize+2, 'FontWeight', 'bold');
                xlabel('X - Columns', 'FontSize', fontSize); 
                ylabel('Y - Rows', 'FontSize', fontSize); 
                zlabel('Z - Layers', 'FontSize', fontSize);
                hold on;
                
                [F_all, V_all, C_all] = im2patch(field_data, L_mask_all, 'vb');
                gpatch(F_all, V_all, C_all, 'none', face_alpha);
                
                colormap(cmap);
                hcb = colorbar;
                hcb.Label.String = sprintf('%s Value', current_field);
                hcb.Label.FontSize = fontSize;
                caxis([data_min, data_max]);
                
                lighting gouraud;
                camlight('headlight');
                material shiny;
                
                if exist('axisGeom', 'file')
                    axisGeom(gca, fontSize);
                else
                    set(gca, 'FontSize', fontSize);
                end
                
                % ПРАВКА 3: Встановлюємо повний діапазон осей
                xlim([0, new_cols]);
                ylim([0, rows]);
                zlim([0, n_layers]);
                
                view([-45, 45]);
                axis equal; axis tight; grid on;
                
                % ПРАВКА 1: Додаємо ім'я колормапу до файлу
                output_file = fullfile(field_folder, ...
                    sprintf('%s_step_%d_main_%s.png', current_field, current_step, current_cmap_name));
                saveas(fig_main, output_file);
                fprintf('Saved: %s\n', output_file);
                close(fig_main);
            end
            
            % ==============================================================================
            % ВІЗУАЛІЗАЦІЯ 2: LOW - НИЗЬКІ ЗНАЧЕННЯ (0-10%)
            % ==============================================================================
            
            if sum(L_mask_low(:)) > 0
                fprintf('Creating LOW visualization (0-10%%)...\n');
                
                fig_low = figure('Visible', 'off', 'Position', [100, 100, 1400, 1000]);
                title(sprintf('%s (step=%d, colormap=%s) - Low Values (0-10%%, %.4f-%.4f)', ...
                      current_field, current_step, current_cmap_name, low_min, low_max), ...
                      'FontSize', fontSize+2, 'FontWeight', 'bold');
                xlabel('X - Columns', 'FontSize', fontSize); 
                ylabel('Y - Rows', 'FontSize', fontSize); 
                zlabel('Z - Layers', 'FontSize', fontSize);
                hold on;
                
                [F_low, V_low, C_low] = im2patch(field_data, L_mask_low, 'vb');
                gpatch(F_low, V_low, C_low, 'none', face_alpha);
                
                colormap(cmap);
                hcb = colorbar;
                hcb.Label.String = sprintf('%s Value', current_field);
                hcb.Label.FontSize = fontSize;
                caxis([data_min, data_max]);
                
                lighting gouraud; 
                camlight('headlight'); 
                material shiny;
                
                if exist('axisGeom', 'file')
                    axisGeom(gca, fontSize);
                else
                    set(gca, 'FontSize', fontSize);
                end
                
                % ПРАВКА 3: Встановлюємо повний діапазон осей
                axis([0, new_cols, 0, rows, 0, n_layers]);
                view([-45, 45]);
                grid on;
                
                % ПРАВКА 1: Додаємо ім'я колормапу до файлу
                output_file = fullfile(field_folder, ...
                    sprintf('%s_step_%d_low_%s.png', current_field, current_step, current_cmap_name));
                saveas(fig_low, output_file);
                fprintf('Saved: %s\n', output_file);
                close(fig_low);
            else
                fprintf('WARNING: No voxels for LOW range\n');
            end
            
            % ==============================================================================
            % ВІЗУАЛІЗАЦІЯ 3: MID - СЕРЕДНІ ЗНАЧЕННЯ (45-55%)
            % ==============================================================================
            
            if sum(L_mask_mid(:)) > 0
                fprintf('Creating MID visualization (45-55%%)...\n');
                
                fig_mid = figure('Visible', 'off', 'Position', [100, 100, 1400, 1000]);
                title(sprintf('%s (step=%d, colormap=%s) - Medium Values (45-55%%, %.4f-%.4f)', ...
                      current_field, current_step, current_cmap_name, mid_min, mid_max), ...
                      'FontSize', fontSize+2, 'FontWeight', 'bold');
                xlabel('X - Columns', 'FontSize', fontSize); 
                ylabel('Y - Rows', 'FontSize', fontSize); 
                zlabel('Z - Layers', 'FontSize', fontSize);
                hold on;
                
                [F_mid, V_mid, C_mid] = im2patch(field_data, L_mask_mid, 'vb');
                gpatch(F_mid, V_mid, C_mid, 'none', face_alpha);
                
                colormap(cmap);
                hcb = colorbar;
                hcb.Label.String = sprintf('%s Value', current_field);
                hcb.Label.FontSize = fontSize;
                caxis([data_min, data_max]);
                
                lighting gouraud; 
                camlight('headlight'); 
                material shiny;
                
                if exist('axisGeom', 'file')
                    axisGeom(gca, fontSize);
                else
                    set(gca, 'FontSize', fontSize);
                end
                
                % ПРАВКА 3: Встановлюємо повний діапазон осей
                axis([0, new_cols, 0, rows, 0, n_layers]);
                view([-45, 45]);
                grid on;
                
                % ПРАВКА 1: Додаємо ім'я колормапу до файлу
                output_file = fullfile(field_folder, ...
                    sprintf('%s_step_%d_mid_%s.png', current_field, current_step, current_cmap_name));
                saveas(fig_mid, output_file);
                fprintf('Saved: %s\n', output_file);
                close(fig_mid);
            else
                fprintf('WARNING: No voxels for MID range\n');
            end
            
            % ==============================================================================
            % ВІЗУАЛІЗАЦІЯ 4: HIGH - ВИСОКІ ЗНАЧЕННЯ (90-100%)
            % ==============================================================================
            
            if sum(L_mask_high(:)) > 0
                fprintf('Creating HIGH visualization (90-100%%)...\n');
                
                fig_high = figure('Visible', 'off', 'Position', [100, 100, 1400, 1000]);
                title(sprintf('%s (step=%d, colormap=%s) - High Values (90-100%%, %.4f-%.4f)', ...
                      current_field, current_step, current_cmap_name, high_min, high_max), ...
                      'FontSize', fontSize+2, 'FontWeight', 'bold');
                xlabel('X - Columns', 'FontSize', fontSize); 
                ylabel('Y - Rows', 'FontSize', fontSize); 
                zlabel('Z - Layers', 'FontSize', fontSize);
                hold on;
                
                [F_high, V_high, C_high] = im2patch(field_data, L_mask_high, 'vb');
                gpatch(F_high, V_high, C_high, 'none', face_alpha);
                
                colormap(cmap);
                hcb = colorbar;
                hcb.Label.String = sprintf('%s Value', current_field);
                hcb.Label.FontSize = fontSize;
                caxis([data_min, data_max]);
                
                lighting gouraud; 
                camlight('headlight'); 
                material shiny;
                
                if exist('axisGeom', 'file')
                    axisGeom(gca, fontSize);
                else
                    set(gca, 'FontSize', fontSize);
                end
                
                % ПРАВКА 3: Встановлюємо повний діапазон осей
                axis([0, new_cols, 0, rows, 0, n_layers]);
                view([-45, 45]);
                grid on;
                
                % ПРАВКА 1: Додаємо ім'я колормапу до файлу
                output_file = fullfile(field_folder, ...
                    sprintf('%s_step_%d_high_%s.png', current_field, current_step, current_cmap_name));
                saveas(fig_high, output_file);
                fprintf('Saved: %s\n', output_file);
                close(fig_high);
            else
                fprintf('WARNING: No voxels for HIGH range\n');
            end
            
            fprintf('Visualization completed for: %s\n', current_field);
        end
        
        fprintf('\n========================================\n');
        fprintf('Completed step = %d (colormap: %s)\n', current_step, current_cmap_name);
        fprintf('========================================\n');
    end
    
    fprintf('\n########################################\n');
    fprintf('COMPLETED COLORMAP: %s\n', current_cmap_name);
    fprintf('########################################\n');

end % Кінець циклу по колормапах

fprintf('\n=== PROCESSING COMPLETED ===\n');


















