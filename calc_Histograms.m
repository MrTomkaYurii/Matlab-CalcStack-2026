function calc_Histograms(data_sets, saveTomka)

%--------------------------------------------------------------------------

% ИССЛЕДУЕМЫЕ ЧАСТИ ИЗОБРАЖЕНИЯ
fields = fieldnames(data_sets.all_images);
num_fields = numel(fields);

% Создание общего изображения для всех 12 частей
figure('name','Image - Gray','units','normalized','outerposition',[0 0 1 1],'Color','white')
for i = 1:num_fields
    subplot(3, 4, i); % Расположение каждой части на изображении 3x4
    field_name = fields{i};
    matrix_uint8 = data_sets.all_images.(field_name);
    matrix_double = double(matrix_uint8);
    imagesc(matrix_double); % Отображение изображения
    colormap(gray); % Установка цветовой карты в черно-белую
    title(strrep(field_name, '_', '-')); % Заголовок с именем поля
    axis off; % Отключение осей координат
end
   pause(0.0001);
   frame_h = get(handle(gcf),'JavaFrame');
   set(frame_h,'Maximized',1);
        pause(1);
        img = getframe(gcf); imwrite(img.cdata, [ 'Image Parts - Gray', '.jpeg']); pause(1);


figure('name','Image - JET','units','normalized','outerposition',[0 0 1 1],'Color','white')
for i = 1:num_fields
    subplot(3, 4, i); % Расположение каждой части на изображении 3x4
    field_name = fields{i};
    matrix_uint8 = data_sets.all_images.(field_name);
    matrix_double = double(matrix_uint8);
    imagesc(matrix_double); % Отображение изображения
    colormap(jet); % Установка цветовой карты в черно-белую
    title(strrep(field_name, '_', '-')); % Заголовок с именем поля
    axis off; % Отключение осей координат
end
   pause(0.0001);
   frame_h = get(handle(gcf),'JavaFrame');
   set(frame_h,'Maximized',1);
        pause(1);
        img = getframe(gcf); imwrite(img.cdata, [ 'Image Parts - Jet', '.jpeg']); pause(1);
%--------------------------------------------------------------------------

% ГИСТОГРАММЫ ДЛЯ ЧАСТЕЙ ДЛЯ ИЗОБРАЖЕНИЯ (5 значений в колонке)

figure('name','Histogram for sections (step5)','units','normalized','outerposition',[0 0 1 1],'Color','white')
hold on;
% Получение всех полей вложенной структуры all_images
fields = fieldnames(data_sets.all_images);
colors = jet(numel(fields)); % Генерация цветовой карты

for i = 1:numel(fields)
    % Получение поля Field и значения Value из вложенной структуры
    field_name = fields{i};
    matrix_uint8 = data_sets.all_images.(field_name);
    matrix_double = double(matrix_uint8);
    histogram(matrix_double(:), 'DisplayName', strrep(field_name, '_', '-'), 'FaceColor', colors(i,:)); % Использование цвета из цветовой карты
end

legend('show');
xlabel('Значення');
ylabel('Частота');
title('Гістограми значень досліджуваних частин зображення');
hold off;
   pause(0.0001);
   frame_h = get(handle(gcf),'JavaFrame');
   set(frame_h,'Maximized',1);
        pause(1);
        img = getframe(gcf); imwrite(img.cdata, [ 'Histograms of parts of investigation image (step 5)', '.jpeg']); pause(1);

%--------------------------------------------------------------------------

% ГИСТОГРАМЫ ДЛЯ ЧАСТЕЙ ИЗОБРАЖЕНИЯ (1 значение в колонке)
figure('name','Histogram for sections (step1)','units','normalized','outerposition',[0 0 1 1],'Color','white')
hold on;

% Получение всех полей вложенной структуры all_images
fields = fieldnames(data_sets.all_images);
colors = jet(numel(fields)); % Генерация цветовой карты

% Определение общего количества уникальных значений по оси X
total_values = [];
for i = 1:numel(fields)
    field_name = fields{i};
    matrix_uint8 = data_sets.all_images.(field_name);
    total_values = [total_values; matrix_uint8(:)];
end
unique_values = unique(total_values);

% Построение гистограммы с интервалом в 1 значение по оси X
for i = 1:numel(fields)
    field_name = fields{i};
    matrix_uint8 = data_sets.all_images.(field_name);
    matrix_double = double(matrix_uint8);
    histogram(matrix_double(:), 'DisplayName', strrep(field_name, '_', '-'), 'FaceColor', colors(i,:), 'BinEdges', unique_values); % Установка интервала в 1 значение
end

legend('show');
xlabel('Значення');
ylabel('Частота');
title('Гістограми значень досліджуваних частин зображення');
hold off;
    pause(0.0001);
    frame_h = get(handle(gcf),'JavaFrame');
    set(frame_h,'Maximized',1);
        pause(1);
        img = getframe(gcf); imwrite(img.cdata, [ 'Histograms of parts of investigation image (step 1)', '.jpeg']); pause(1);

%--------------------------------------------------------------------------

% ГИСТОГРАМЫ ДЛЯ ЧАСТЕЙ ИЗОБРАЖЕНИЯ (1 значение в колонке)
figure('name','nhist (step1)','units','normalized','outerposition',[0 0 1 1],'Color','white')
hold on;
% Получение всех полей вложенной структуры all_images
fields = fieldnames(data_sets.all_images);
num_fields = numel(fields);
% Итерация по каждому изображению в структуре all_images
for i = 1:num_fields
    subplot(3, 4, i);
    nhist(data_sets.all_images.(fields{i}), 'bins', 1);
    grid on;
    xlabel('Значення');
    ylabel('Частота');
    title(['Гістограма для ' strrep(fields(i), '_', '-')]); % Добавление заголовка с именем текущего поля данных
end
hold off;
    pause(0.0001);
    frame_h = get(handle(gcf),'JavaFrame');
    set(frame_h,'Maximized',1);
        pause(1);
        img = getframe(gcf); imwrite(img.cdata, [ 'All-In-One Histograms of parts of investigation image', '.jpeg']); pause(1);

%--------------------------------------------------------------------------

% ДВУМЕРНЫЕ ГИСТОГРАМЫ ДЛЯ ИЗОБРАЖЕНИЯ (1 значение в колонке)

% Получение всех полей вложенной структуры all_images
fields = fieldnames(data_sets.all_images);
num_fields = numel(fields);
colors = jet(num_fields); % Генерация цветовой карты

xs = 1:10:num_fields*10;
% Построение двумерных гистограмм
for i = 1:num_fields
    field_name = fields{i};
    matrix_uint8 = data_sets.all_images.(field_name);
    matrix_double = double(matrix_uint8);
    vector_matrix(i,:) = matrix_double(:);
        histogram2( repmat(xs(i),1,size(vector_matrix,2)), vector_matrix(i,:),  'FaceColor', colors(i,:), 'BinWidth', 1, 'EdgeColor', 'none'); 
        hold on
end
% Настройка меток осей и легенды
xlabel('X-axis');
    xticks(xs);
    xticklabels(strrep(fields, '_', '-'));
ylabel('Y-axis');
zlabel('Кількість');
title('2D гістограми досліджуваних частей зображення');
legend(strrep(fields, '_', '-'), 'Location', 'best');
view(45, 45);
hold off;

pause(0.0001);
frame_h = get(handle(gcf),'JavaFrame');
set(frame_h,'Maximized',1);
    pause(1);
    img = getframe(gcf);
    imwrite(img.cdata, ['2D histograms of parts of investigation image (step 1).jpeg']);

%--------------------------------------------------------------------------

% BOXPLOT СТАТИСТИКА ДЛЯ ИЗОБРАЖЕНИЙ

fields = fieldnames(data_sets.all_images);
% Рассчитать статистику и построить гистограммы для каждого изображения
for i = 1:numel(fields)
    % Получение поля Field и значения Value из вложенной структуры
    field_name = fields{i};
    matrix_uint8 = data_sets.all_images.(field_name);
    matrix_double = double(matrix_uint8);
        vector_double(:,i) = matrix_double(:);
end
    % Построить ящики с усами
    figure('name',' Statistic. BoxPlot (parts of image)','units','normalized','outerposition',[0 0 1 1],'Color','white');
    h = boxplot(vector_double, 'Labels', fields);
    grid on;
    title('Box Plot для статичних моментів для частин зображень');
    ylabel('Значення');
    xlabel('Частини зображення');
    % Установить стиль и цвет линий
    set(h, {'linew'},{2});
    pause(0.0001);
    frame_h = get(handle(gcf),'JavaFrame');
    set(frame_h,'Maximized',1);
        pause(1);
        img = getframe(gcf); imwrite(img.cdata, [ 'BoxPlot. Parts of image', '.jpeg']); pause(1);

%--------------------------------------------------------------------------

figure('name',' Statistic. BoxPlot (parts of image)','units','normalized','outerposition',[0 0 1 1],'Color','white');
hold on;

mean_value = cell(numel(fields), 1);
std_dev = cell(numel(fields), 1);
max_value = cell(numel(fields), 1);
min_value = cell(numel(fields), 1);
Q1 = cell(numel(fields), 1);
Q3 = cell(numel(fields), 1);
box_data = cell(numel(fields), 1); % Создаем ячейковый массив для хранения данных для каждого поля
labels = cell(numel(fields), 1);   % Создаем ячейковый массив для хранения меток для каждого поля


fields = fieldnames(data_sets.all_images);
for i = 1:numel(fields)
    field_name = fields{i};
    matrix_uint8 = data_sets.all_images.(field_name);
    matrix_double = double(matrix_uint8);
    dataHistogram = reshape(matrix_double, 1, []);

    vector_double(:,i) = matrix_double(:);
    % Рассчитать статистические моменты
        mean_value{i} = mean(dataHistogram);
        std_dev{i} = std(dataHistogram);
        min_value{i} = min(dataHistogram);
        max_value{i} = max(dataHistogram);
        Q1{i} = prctile(dataHistogram, 25);
        Q3{i} = prctile(dataHistogram, 75);
        box_data{i} = dataHistogram;
        labels{i} = field_name;
end
    % Построить ящик с усами с использованием функции boxplot
    boxplot(vector_double, 'Labels', labels, 'Notch', 'on', 'Symbol', 'o');
    title('Box Plot для статичних моментів для частин зображень');
    ylabel('Значення');
    xlabel('Частини зображення');
    hold on;
    for i = 1:numel(mean_value)
        text(i, mean_value{i}, num2str(mean_value{i}), 'Color', 'r', 'FontSize', 8,'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
        plot(i, mean_value{i}, 'r*', 'MarkerSize', 12); % среднее значение
        errorbar(i, mean_value{i}, std_dev{i}, 'r', 'LineWidth', 2); % стандартное отклонение
        for i = 1:numel(Q1)
            line([i i], [Q1{i} Q3{i}], 'Color', 'b', 'LineWidth', 2); % ящик
        %    line([i i], [min_value{i} max_value{i}], 'Color', 'k', 'LineWidth', 2); % усы
        end
    end
    grid on;
    hold off;
    pause(0.0001);
    frame_h = get(handle(gcf),'JavaFrame');
    set(frame_h,'Maximized',1);
        pause(1);
        img = getframe(gcf); imwrite(img.cdata, [ 'Statistic.BoxPlot.v2.Parts of image', '.jpeg']); pause(1);

%--------------------------------------------------------------------------

end
