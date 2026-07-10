clear; close all; clc;

% Базовий шлях до папок
base_path = 'C:\Users\Yurii\Desktop\Results_10_30_tomka\';
% Список імен файлів для обробки
file_names = {
    'alpha_0_argument'
    'alpha_0_module'
    'alpha_45_argument'
    'alpha_45_module'
    'beta_0_argument'
    'beta_0_module'
    'beta_45_argument'
    'beta_45_module'
    'r_12_amplitude'
    'r_12_phase'
    'r_14_amplitude'
    'r_14_phase'
    'r_23_amplitude'
    'r_23_phase'
    'r_24_amplitude'
    'r_24_phase'
};
% Ініціалізація структури
data_struct = struct();
% Кількість кроків
num_steps = 31; % від 0 до 30 (включно)
% Проходимо по кожному файлу
for f = 1:length(file_names)
    current_file = file_names{f};
    fprintf('Обробка файлу: %s\n', current_file);
    
    % Ініціалізація 3D масиву для поточного файлу
    temp_3d = [];
    
    % Проходимо по всіх папках (кроках)
    for step = 0:30
        % Формуємо шлях до файлу
        folder_name = sprintf('phase_range_0_2pi_minus_%dsteps', step);
        file_path = fullfile(base_path, folder_name, [current_file '.mat']);
        
        % Перевіряємо чи існує файл
        if exist(file_path, 'file')
            % Завантажуємо дані
            loaded_data = load(file_path);
            
            % Отримуємо назву змінної
            var_names = fieldnames(loaded_data);
            current_slice = loaded_data.(var_names{1});
            
            % Обрізаємо область 100x100 з центру
            [h, w] = size(current_slice);
            start_row = round((h - 100) / 2);
            start_col = round((w - 100) / 2);
            current_slice = current_slice(start_row:start_row+99, start_col:start_col+99);
            
            % Додаємо як новий шар до 3D структури
            if isempty(temp_3d)
                % Перший шар - ініціалізуємо розмір
                [rows, cols] = size(current_slice);
                temp_3d = zeros(rows, cols, num_steps);
            end
            
            % Записуємо шар
            temp_3d(:, :, step+1) = current_slice;
        else
            warning('Файл не знайдено: %s', file_path);
        end
    end
    
    % Зберігаємо 3D масив у структуру з відповідним ключем
    data_struct.(current_file) = temp_3d;
    fprintf('  Розмір: %d x %d x %d\n\n', size(temp_3d, 1), size(temp_3d, 2), size(temp_3d, 3));
end

% Зберігаємо результат
save('combined_3d_structure.mat', 'data_struct');
fprintf('Всі дані збережено у файл: combined_3d_structure.mat\n');

% Виводимо інформацію про структуру
fprintf('\n=== Доступні ключі у структурі ===\n');
disp(fieldnames(data_struct));

% Приклад доступу до даних
fprintf('\n=== Приклад використання ===\n');
fprintf('Доступ до r_12_phase: data_struct.r_12_phase\n');
fprintf('Розмір r_12_phase: %d x %d x %d\n', size(data_struct.r_12_phase));


%==============================================================================================================================
%== CASE 01
%==============================================================================================================================
% Візуалізація прикладу
figure;

% Знайти загальний діапазон значень для однакової колірної шкали
data_min = min([min(data_struct.r_24_phase(:,:,1), [], 'all'), ...
                min(data_struct.r_24_phase(:,:,26), [], 'all')]);
data_max = max([max(data_struct.r_24_phase(:,:,1), [], 'all'), ...
                max(data_struct.r_24_phase(:,:,26), [], 'all')]);
% Перший підграфік
subplot(1,2,1);
imagesc(data_struct.r_24_phase(:,: ,1));
axis equal;  % Пропорційні осі
axis tight;  % Підганяти розмір до даних
colorbar;
caxis([data_min data_max]);  % Однаковий діапазон кольорів
title('r\_24\_phase: перший шар (0steps)');
% Другий підграфік
subplot(1,2,2);
imagesc(data_struct.r_24_phase(:,:,26));
axis equal;  % Пропорційні осі
axis tight;  % Підганяти розмір до даних
colorbar;
caxis([data_min data_max]);  % Однаковий діапазон кольорів
title('r\_24\_phase: останній шар (30steps)');
        % Параметри візуалізації
        cMap=parula(250);       
        faceAlpha1=1;
        faceAlpha2=0.5;
        edgeColor1='none';
        edgeColor2='none';
        fontSize=15;
%==============================================================================================================================
%==CASE 02
%==============================================================================================================================        
        % Беремо 3D масив r_24_phase
        M = data_struct.r_24_phase;
        fprintf('Розмір даних r_24_phase: %d x %d x %d\n', size(M,1), size(M,2), size(M,3));
        % Creating and plotting combined voxel and slice patch data
        cFigure;
        title('Combined voxel and slice plotting: r\_24\_phase');
        xlabel('J - columns'); ylabel('I - rows'); zlabel('K - slices'); hold on;
        % Setting up indices for I direction slices
        S=round(size(M,1)./2); %Selection of middle slice
        L_plot=false(size(M)); L_plot(S,:,:)=1;
        indPatch=find(L_plot);
        [F,V,C]=im2patch(M,indPatch,'si'); %Creating patch data for y mid-voxel slices
        gpatch(F,V,C,'none',faceAlpha2);
        % Setting up indices for J direction slices
        S=round(size(M,2)./2); %Selection of middle slice
        L_plot=false(size(M)); L_plot(:,S,:)=1;
        indPatch=find(L_plot);
        [F,V,C]=im2patch(M,indPatch,'sj'); %Creating patch data for x mid-voxel slices
        gpatch(F,V,C,'none',faceAlpha2);
        % Setting up indices for K direction slices
        S=round(size(M,3)./2); %Selection of middle slice
        L_plot=false(size(M)); L_plot(:,:,S)=1;
        indPatch=find(L_plot);
            [F,V,C]=im2patch(M,indPatch,'sk'); %Creating patch data for z mid-voxel slices
            gpatch(F,V,C,'none',faceAlpha2);
        % Setting up indices for voxels to plot
        % Можна налаштувати порогові значення залежно від ваших даних
        threshold_low = prctile(M(:), 90);  % Перцентиль
        threshold_high = max(M(:));
        L_mask = M >= threshold_low & M <= threshold_high;
        [F,V,C]=im2patch(M,L_mask,'vb'); %Creating patch data for selection of high voxels
        gpatch(F,V,C,'none',faceAlpha2);
        colormap(cMap); colorbar; caxis([min(M(:)) max(M(:))]);
        axisGeom(gca,fontSize); camlight headlight;
        drawnow;
        fprintf('Візуалізація завершена!\n');
        fprintf('Діапазон значень: %.4f до %.4f\n', min(M(:)), max(M(:)));
        fprintf('Поріг для вокселів: %.4f до %.4f\n', threshold_low, threshold_high);
%==============================================================================================================================
%== CASE 03
%==============================================================================================================================
% Параметри візуалізації
cMap=parula(250);
faceAlpha1=1;
faceAlpha2=0.5;
edgeColor1='none';
edgeColor2='none';
fontSize=15;

% Беремо 3D масив r_24_phase та обрізаємо до 100x100
M_full = data_struct.r_24_phase;
M = M_full(1:100, 1:100, :);  % Беремо 100x100 точRetryYбаз ліній маю на увазі на рівні вокселяmatlab% Параметри візуалізації
cMap=parula(250);
faceAlpha1=1;
faceAlpha2=0.5;
edgeColor1='none';
edgeColor2='none';
fontSize=15;

% Беремо 3D масив r_24_phase та обрізаємо до 100x100
M_full = data_struct.r_24_phase;
M = M_full(1:100, 1:100, :);  % Беремо 100x100 точок від початку

fprintf('Розмір даних r_24_phase: %d x %d x %d\n', size(M,1), size(M,2), size(M,3));

% Creating and plotting combined voxel and slice patch data
cFigure;
title('Combined voxel and slice plotting: r\_24\_phase');
xlabel('J - columns');ylabel('I - rows'); zlabel('K - slices'); hold on;

% Setting up indices for voxels to plot
% Можна налаштувати порогові значення залежно від ваших даних
threshold_low = prctile(M(:), 80);  % 75-й перцентиль
threshold_high = max(M(:));
L_mask = M >= threshold_low & M <= threshold_high;

[F,V,C]=im2patch(M,L_mask,'vb'); %Creating patch data for selection of high voxels
gpatch(F,V,C,'none',faceAlpha2);  % 'none' замість 'k' - без ліній
colormap(cMap); colorbar; caxis([min(M(:)) max(M(:))]);
axisGeom(gca,fontSize); camlight headlight;
drawnow;

fprintf('Візуалізація завершена!\n');
fprintf('Діапазон значень: %.4f до %.4f\n', min(M(:)), max(M(:)));
fprintf('Поріг для вокселів: %.4f до %.4f\n', threshold_low, threshold_high);

%==============================================================================================================================
%== CASE 04
%==============================================================================================================================
         % Беремо 3D масив r_24_phase
        M = data_struct.r_24_phase;
        fprintf('Розмір даних r_24_phase:  %d x %d x %d\n', size(M,1), size(M,2), size(M,3));
        
        % Creating and plotting combined voxel and slice patch data
        cFigure;
        title('Combined voxel and slice plotting: r\_24\_phase with boundaries');
        xlabel('J - columns'); ylabel('I - rows'); zlabel('K - slices'); hold on;
        
        % Setting up indices for I direction slices
        S = round(size(M,1)./2); % Selection of middle slice
        L_plot = false(size(M)); L_plot(S,:,:) = 1;
        indPatch = find(L_plot);
        [F,V,C] = im2patch(M,indPatch,'si'); % Creating patch data for y mid-voxel slices
        hp = gpatch(F,V,C,'k',faceAlpha2);
        set(hp,'EdgeColor','none');
        
        % Setting up indices for J direction slices
        S = round(size(M,2)./2); % Selection of middle slice
        L_plot = false(size(M)); L_plot(:,S,:) = 1;
        indPatch = find(L_plot);
        [F,V,C] = im2patch(M,indPatch,'sj'); % Creating patch data for x mid-voxel slices
        hp = gpatch(F,V,C,'k',faceAlpha2);
        set(hp,'EdgeColor','none');
        
        % Setting up indices for K direction slices
        S = round(size(M,3)./2); % Selection of middle slice
        L_plot = false(size(M)); L_plot(:,:,S) = 1;
        indPatch = find(L_plot);
        [F,V,C] = im2patch(M,indPatch,'sk'); % Creating patch data for z mid-voxel slices
        hp = gpatch(F,V,C,'k',faceAlpha2);
        set(hp,'EdgeColor','none');
        
        % ====== ГРАДІЄНТ - ВИЗНАВАННЯ ГРАНИЦЬ ======
        fprintf('\nОбчислення градієнта...\n');
        
        % Вычисляємо градієнт по всім напрямкам
        [Gx, Gy, Gz] = gradient(M);
        
        % Обчислюємо магнітуду градієнта (величину скачка)
        Gmag = sqrt(Gx.^2 + Gy.^2 + Gz.^2);
        
        fprintf('Діапазон градієнта: %.4f до %.4f\n', min(Gmag(: )), max(Gmag(:)));
        
        % Знаходимо вокселі з резкими скачками (границі)
        threshold_grad = prctile(Gmag(:), 80);  % Топ 20% найрізкіших переходів
        L_mask_grad = Gmag >= threshold_grad;
        
        fprintf('Порог градієнта: %.4f\n', threshold_grad);
        fprintf('Кількість вокселів на границі: %d\n', sum(L_mask_grad(:)));
        
        % Візуалізуємо вокселі границь
        [F, V, C] = im2patch(M, L_mask_grad, 'vb');
        hp = gpatch(F, V, C, 'k', faceAlpha1);
        set(hp,'EdgeColor','none');
        
        colormap(cMap);
        colorbar;
        caxis([min(M(: )) max(M(:))]);
        axisGeom(gca, fontSize);
        camlight headlight;
        drawnow;
        
        fprintf('\nВізуалізація завершена!\n');
        fprintf('Діапазон значень:  %.4f до %.4f\n', min(M(:)), max(M(:)));
        fprintf('Показані вокселі на границях переходів\n');


%==============================================================================================================================
%== CASE 05
%==============================================================================================================================
% Беремо 3D масив r_24_phase
M = data_struct.r_24_phase;
fprintf('Розмір даних r_24_phase:  %d x %d x %d\n', size(M,1), size(M,2), size(M,3));

% Creating and plotting combined voxel and slice patch data
cFigure;
title('Combined voxel and slice plotting: r\_24\_phase with boundaries');
xlabel('J - columns'); ylabel('I - rows'); zlabel('K - slices'); hold on;

% Параметр розсування шарів (можна змінювати)
slice_spacing = 0.5;  % Відстань між шарами (0 = без розсування)

% Setting up indices for I direction slices
S = round(size(M,1)./2); % Selection of middle slice
L_plot = false(size(M)); L_plot(S,:,:) = 1;
indPatch = find(L_plot);
[F,V,C] = im2patch(M,indPatch,'si'); % Creating patch data for y mid-voxel slices
hp = gpatch(F,V,C,'k',faceAlpha2);
set(hp,'EdgeColor','none');

% Setting up indices for J direction slices
S = round(size(M,2)./2); % Selection of middle slice
L_plot = false(size(M)); L_plot(:,S,:) = 1;
indPatch = find(L_plot);
[F,V,C] = im2patch(M,indPatch,'sj'); % Creating patch data for x mid-voxel slices
hp = gpatch(F,V,C,'k',faceAlpha2);
set(hp,'EdgeColor','none');

% Setting up indices for K direction slices
S = round(size(M,3)./2); % Selection of middle slice
L_plot = false(size(M)); L_plot(:,:,S) = 1;
indPatch = find(L_plot);
[F,V,C] = im2patch(M,indPatch,'sk'); % Creating patch data for z mid-voxel slices
hp = gpatch(F,V,C,'k',faceAlpha2);
set(hp,'EdgeColor','none');

% ====== ГРАДІЄНТ - ВИЗНАВАННЯ ГРАНИЦЬ ======
fprintf('\nОбчислення градієнта.. .\n');

% Вычисляємо градієнт по всім напрямкам
[Gx, Gy, Gz] = gradient(M);

% Обчислюємо магнітуду градієнта (величину скачка)
Gmag = sqrt(Gx.^2 + Gy.^2 + Gz.^2);

fprintf('Діапазон градієнта: %.4f до %.4f\n', min(Gmag(: )), max(Gmag(:)));

% Знаходимо вокселі з резкими скачками (границі)
threshold_grad = prctile(Gmag(:), 80);  % Топ 20% найрізкіших переходів
L_mask_grad = Gmag >= threshold_grad;

fprintf('Порог градієнта: %.4f\n', threshold_grad);
fprintf('Кількість вокселів на границі: %d\n', sum(L_mask_grad(:)));

% Візуалізуємо вокселі границь З РОЗСУВАННЯМ ПО ШАРАМ
fprintf('Візуалізація з розсуванням шарів (spacing = %.2f)...\n', slice_spacing);

% Отримуємо всі індекси вокселів на границях
[I_ind, J_ind, K_ind] = ind2sub(size(M), find(L_mask_grad));

% Проходимо по кожному шару окремо
for k = 1:size(M, 3)
    % Знаходимо вокселі в поточному шарі
    slice_mask = (K_ind == k);
    
    if sum(slice_mask) > 0  % Якщо є вокселі в цьому шарі
        % Створюємо маску тільки для цього шару
        L_current_slice = false(size(M));
        linear_ind = sub2ind(size(M), I_ind(slice_mask), J_ind(slice_mask), K_ind(slice_mask));
        L_current_slice(linear_ind) = true;
        
        % Створюємо патч для цього шару
        [F, V, C] = im2patch(M, L_current_slice, 'vb');
        
        % Додаємо зсув по Z координаті
        V(: , 3) = V(:, 3) + (k - 1) * slice_spacing;
        
        % Малюємо патч
        hp = gpatch(F, V, C, 'k', faceAlpha1);
        set(hp, 'EdgeColor', 'none');
    end
end

colormap(cMap);
colorbar;
caxis([min(M(:)) max(M(:))]);
axisGeom(gca, fontSize);
camlight headlight;
drawnow;

fprintf('\nВізуалізація завершена!\n');
fprintf('Діапазон значень: %.4f до %.4f\n', min(M(:)), max(M(:)));
fprintf('Показані вокселі на границях переходів з розсуванням шарів\n');


%==============================================================================================================================
%== CASE 06
%==============================================================================================================================
    % Беремо 3D масив r_24_phase
    M = data_struct.r_24_phase;
    fprintf('Розмір даних r_24_phase:  %d x %d x %d\n', size(M,1), size(M,2), size(M,3));
    
    % Creating and plotting combined voxel and slice patch data
    cFigure;
    title('Combined voxel and slice plotting: r\_24\_phase with vertical trajectories');
    xlabel('J - columns'); ylabel('I - rows'); zlabel('K - slices'); hold on;
    
    % Параметр розсування шарів (можна змінювати)
    slice_spacing = 0.5;  % Відстань між шарами (0 = без розсування)
    
    % Setting up indices for I direction slices
    S = round(size(M,1)./2); % Selection of middle slice
    L_plot = false(size(M)); L_plot(S,:,:) = 1;
    indPatch = find(L_plot);
    [F,V,C] = im2patch(M,indPatch,'si'); % Creating patch data for y mid-voxel slices
    hp = gpatch(F,V,C,'k',faceAlpha2);
    set(hp,'EdgeColor','none');
    
    % Setting up indices for J direction slices
    S = round(size(M,2)./2); % Selection of middle slice
    L_plot = false(size(M)); L_plot(:,S,:) = 1;
    indPatch = find(L_plot);
    [F,V,C] = im2patch(M,indPatch,'sj'); % Creating patch data for x mid-voxel slices
    hp = gpatch(F,V,C,'k',faceAlpha2);
    set(hp,'EdgeColor','none');
    
    % Setting up indices for K direction slices
    S = round(size(M,3)./2); % Selection of middle slice
    L_plot = false(size(M)); L_plot(:,:,S) = 1;
    indPatch = find(L_plot);
    [F,V,C] = im2patch(M,indPatch,'sk'); % Creating patch data for z mid-voxel slices
    hp = gpatch(F,V,C,'k',faceAlpha2);
    set(hp,'EdgeColor','none');
    
    % ====== ГРАДІЄНТ - ВИЗНАВАННЯ ГРАНИЦЬ ======
    fprintf('\nОбчислення градієнта.. .\n');
    
    % Вычисляємо градієнт по всім напрямкам
    [Gx, Gy, Gz] = gradient(M);
    
    % Обчислюємо магнітуду градієнта (величину скачка)
    Gmag = sqrt(Gx.^2 + Gy.^2 + Gz.^2);
    
    fprintf('Діапазон градієнта: %.4f до %.4f\n', min(Gmag(: )), max(Gmag(:)));
    
    % Знаходимо вокселі з резкими скачками (границі)
    threshold_grad = prctile(Gmag(:), 80);  % Топ 20% найрізкіших переходів
    L_mask_grad = Gmag >= threshold_grad;
    
    fprintf('Порог градієнта: %.4f\n', threshold_grad);
    fprintf('Кількість вокселів на границі: %d\n', sum(L_mask_grad(:)));
    
    % Отримуємо всі індекси вокселів на границях
    [I_ind, J_ind, K_ind] = ind2sub(size(M), find(L_mask_grad));
    
    % ====== МАЛЮВАННЯ ВЕРТИКАЛЬНИХ ТРАЄКТОРІЙ ======
    fprintf('\nМалювання вертикальних траєкторій через всі шари...\n');
    
    % Параметри для ліній
    line_width = 3;
    line_alpha = 0.8;
    
    % Знаходимо унікальні позиції (I, J) - стовпчики
    unique_positions = unique([I_ind, J_ind], 'rows');
    
    fprintf('Знайдено унікальних позицій: %d\n', size(unique_positions, 1));
    
    % Отримуємо діапазон значень для нормалізації кольорів
    M_min = min(M(:));
    M_max = max(M(:));
    
    % Для кожної унікальної позиції малюємо вертикальну лінію
    for i = 1:size(unique_positions, 1)
        curr_i = unique_positions(i, 1);
        curr_j = unique_positions(i, 2);
        
        % Знаходимо всі шари, де є воксель на цій позиції
        mask = (I_ind == curr_i) & (J_ind == curr_j);
        k_values = K_ind(mask);
        
        if ~isempty(k_values)
            % Знаходимо мінімальний та максимальний шар
            k_min = min(k_values);
            k_max = max(k_values);
            
            % Беремо середнє значення з матриці M для цієї позиції
            values_at_position = [];
            for kk = 1:length(k_values)
                values_at_position(kk) = M(curr_i, curr_j, k_values(kk));
            end
            avg_value = mean(values_at_position);
            
            % Нормалізуємо значення до діапазону [0, 1]
            normalized_value = (avg_value - M_min) / (M_max - M_min);
            
            % Отримуємо колір з поточної colormap
            line_color = cMap(max(1, min(size(cMap, 1), round(normalized_value * size(cMap, 1)))), :);
            
            % Обчислюємо Z координати з урахуванням зсуву
            z_min = k_min + (k_min - 1) * slice_spacing;
            z_max = k_max + (k_max - 1) * slice_spacing;
            
            % Малюємо вертикальну лінію від найнижчого до найвищого шару
            plot3([curr_j, curr_j], ... 
                  [curr_i, curr_i], ...
                  [z_min, z_max], ...  
                  'Color', [line_color, line_alpha], ...  
                  'LineWidth', line_width);
        end
    end
    
    fprintf('Намальовано вертикальних ліній: %d\n', size(unique_positions, 1));
    
    colormap(cMap);
    colorbar;
    caxis([M_min M_max]);
    axisGeom(gca, fontSize);
    camlight headlight;
    drawnow;
    
    fprintf('\nВізуалізація завершена!\n');
    fprintf('Діапазон значень: %. 4f до %.4f\n', M_min, M_max);
    fprintf('Показані вертикальні траєкторії через шари з кольорами відповідно до значень\n');