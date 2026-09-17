function CORR_MATRIX_2D = calc_Corr_Func_2D_2024(matrix_from_layer, ...
    work_layer, ...
    saveTomka, ...
    name)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2D автокореляц╕йна функц╕я
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd (saveTomka); pause(1);
CORR_MATRIX_2D = xcorr2(matrix_from_layer);
CORR_MATRIX_2D = CORR_MATRIX_2D + abs( min(min(CORR_MATRIX_2D)) );
CORR_MATRIX_2D = CORR_MATRIX_2D./(max(max(CORR_MATRIX_2D)));

assignin('base','CORR_MATRIX_2D',CORR_MATRIX_2D)

    % 2D AUTOCORRELATION FUNCTION     
    figure('name','2D AutoCorrelation Function','units','normalized','outerposition',[0 0 1 1],'Color','white')
    imshow (CORR_MATRIX_2D); colorbar; colormap(jet); 
    % Добавляем горизонтальные линии сетки
    hold on;
    for i = 1:40:size(CORR_MATRIX_2D, 1)
        line([1, size(CORR_MATRIX_2D, 2)], [i, i], 'Color', 'w', 'LineWidth', 0.5);
    end
    % Добавляем вертикальные линии сетки
    for j = 1:40:size(CORR_MATRIX_2D, 2)
        line([j, j], [1, size(CORR_MATRIX_2D, 1)], 'Color', 'w', 'LineWidth', 0.5);
    end
    hold off;
    title ('2D AutoCorrelation Function','Color','r');
    xlabel('x, pixels (step 40px for grid)');
    ylabel('y, pixels (step 40px for grid)');
        axis equal tight;
        pause(0.0001);
        frame_h = get(handle(gcf),'JavaFrame');
        set(frame_h,'Maximized',1);
        pause(1);
        img = getframe(gcf); imwrite(img.cdata, [ name,' - 2D-AKF [JET]', '.jpeg']); pause(1);


    % 2D AUTOCORRELATION FUNCTION WITH COUNTOUR LEVELS (10 slices)
    figure('name', '2D-AKF with Contour Levels', 'units', 'normalized', 'outerposition', [0 0 1 1], 'Color', 'white')
    contourLevels = linspace(0, 1, 10); 
    hold on;
    contour(CORR_MATRIX_2D, contourLevels, 'k', 'LineWidth', 1);
    hold off;
    h = clabel(contour(CORR_MATRIX_2D, contourLevels, 'LineColor', 'k', 'LineWidth', 1), 'FontSize', 10);
    hold on; 
    grid on;
    title('2D AKF with Contour Levels (10 slices)', 'Color', 'r');
    xlabel('x, pixels');
    ylabel('y, pixels');
    axis equal tight;
        pause(0.0001);
        frame_h = get(handle(gcf),'JavaFrame');
        set(frame_h,'Maximized',1);
        pause(1);
        img = getframe(gcf); imwrite(img.cdata, [ name,' - 2D-AKF [COUNTOURS]', '.jpeg']); pause(1);
    

  % 2D AUTOCORRELATION FUNCTION ONLY COUNTOUR LEVELS (0.5)
    figure('name', '2D AKF 0.5', 'Color', 'white', 'SizeChangedFcn', @resizeFigure);
    imagesc(CORR_MATRIX_2D);
    contourLevels = 0:0.25:1; 
    contour(CORR_MATRIX_2D, contourLevels, 'LineColor', 'k', 'LineWidth', 1);
    colorbar; colormap(jet);
    title('2D AutoCorrelation Function', 'Color', 'r');
    h = clabel(contour(CORR_MATRIX_2D, contourLevels, 'LineColor', 'r', 'LineWidth', 1), 'FontSize', 8);
    grid on;
    title('2D AKF with Contour Levels (4 slices)', 'Color', 'r');
    xlabel('x, pixels');
    ylabel('y, pixels');
    axis equal tight;
        pause(0.0001);
        frame_h = get(handle(gcf),'JavaFrame');
        set(frame_h,'Maximized',1);
        pause(1);
        img = getframe(gcf); imwrite(img.cdata, [ name,' - 2D-AKF [0.25 0.5 0.75]', '.jpeg']); pause(1);

  
  % 3D AUTOCORRELATION FUNCTION
    figure('name', '3D AutoCorrelation Function', 'Color', 'white');
    % Создаем сетку для 3D поверхности
    [m, n] = size(CORR_MATRIX_2D);
    [X, Y] = meshgrid(1:n, 1:m);
    surf(X, Y, CORR_MATRIX_2D, 'EdgeColor', 'none');
        % Добавляем легенду с помощью colorbar и устанавливаем толщину
        h = colorbar;
        ylabel(h, 'Intensity');
        h.LineWidth = h.LineWidth / 2; % Устанавливаем толщину в два раза меньше
        % Размещаем colorbar в центре картинки и подгоняем размеры
        ax = gca;
        colorbarHeight = 1/2 * ax.Position(4); % Высота colorbar как 3/4 от высоты изображения
        set(h, 'Units', 'normalized', 'Position', [0.88, 0.31, 0.02, colorbarHeight]);
    colormap(jet); 
    title('3D AutoCorrelation Function', 'Color', 'r');
    xlabel('x, pixels');
    ylabel('y, pixels');
        pause(0.0001);
        frame_h = get(handle(gcf),'JavaFrame');
        set(frame_h,'Maximized',1);
        pause(1);
        img = getframe(gcf); imwrite(img.cdata, [ name,' - 2D-AKF [3D VISUALIZATION]', '.jpeg']); pause(1);


    %  2D AKF Slice from Top to Bottom
    figure('name', 'Slice from Top to Bottom', 'Color', 'white');
    contourf(X, Y, CORR_MATRIX_2D, 'LineColor', 'none');
    colorbar;colormap(jet);
    title('2D-AKF - Slices from Top to Bottom', 'Color', 'r');
    xlabel('x, pixels');
    ylabel('y, pixels');
    axis equal tight;
        pause(0.0001);
        frame_h = get(handle(gcf),'JavaFrame');
        set(frame_h,'Maximized',1);
        pause(1);
        img = getframe(gcf); imwrite(img.cdata, [ name,' - 2D-AKF [Slices]', '.jpeg']); pause(1);


    % Vertical Slices    
    % Добавляем перпендикулярный срез (по направлению X, например)
    [m, n] = size(CORR_MATRIX_2D);
    % Шаг по оси x
    step = 40;
    % Создание вектора индексов для выборки каждого step-го элемента
    x_indices = 1:step:n;
    % Вывод срезов
    figure;
    hold on;
    for i = x_indices
        plot((0:m-1)', CORR_MATRIX_2D(:, i), 'LineWidth', 2,'DisplayName', sprintf('Slice at x = %d', i-1));
    end
    title('Зр╕зи 2D-AKF по ос╕ x у 2D предствленн╕');
    xlabel('y, pixels');
    ylabel('AutoCorrelation Function');
    legend('show');
    hold off;
            pause(0.0001);
            frame_h = get(handle(gcf),'JavaFrame');
            set(frame_h,'Maximized',1);
            pause(1);
            img = getframe(gcf); imwrite(img.cdata, [ name,' - 2D-AKF [Vertical Slices]', '.jpeg']); pause(1);


    % 3D Vertical Slices
    % Размеры матрицы
    [m, n] = size(CORR_MATRIX_2D);
    % Создание сетки X и Y
    [X, Y] = meshgrid(1:20:n, 1:m);
    % Настройка отображения
    view_angle = [-37.5, 30]; % Измените угол обзора, чтобы получить лучший вид
    % Построение массива графиков plot3 вместо surf
    figure;
    hold on;
    for i = 1:20:n
        Z_slice = CORR_MATRIX_2D(:, i);
        plot3(ones(size(Z_slice))*i, 1:m, Z_slice, 'b-', 'LineWidth', 2);
    end
    hold off;
    title('Зр╕зи 2D-AKF у 3D-предсталвенн╕');
    xlabel('В╕сь X (крок 20px)');
    ylabel('В╕сь Y');
    zlabel('Значения автокореляц╕╖');
    grid on;
    % Настройка отображения
    view(view_angle);
            pause(0.0001);
            frame_h = get(handle(gcf),'JavaFrame');
            set(frame_h,'Maximized',1);
            pause(1);
            img = getframe(gcf); imwrite(img.cdata, [ name,' - 2D-AKF [3D Vertical Slices]', '.jpeg']); pause(1);


    % 2D AKF - Отображение векторов градиента
    % Вычисление градиента
    [px, py] = gradient(CORR_MATRIX_2D);
    % Размер блока
    block_size = 10;
    % Усреднение векторов градиента внутри блоков
    avg_px = blockproc(px, [block_size block_size], @(block_struct) mean(block_struct.data(:)));
    avg_py = blockproc(py, [block_size block_size], @(block_struct) mean(block_struct.data(:)));
    % Создание координат блоков
    [X, Y] = meshgrid(1:block_size:size(CORR_MATRIX_2D, 2), 1:block_size:size(CORR_MATRIX_2D, 1));
    figure('Name', '2D-AKF - Block-Averaged Gradient Visualization', 'Color', 'white');
    quiver(X(:), Y(:), avg_px(:), avg_py(:));
    title('Block-Averaged Gradient Visualization');
    xlabel('X, pixels');
    ylabel('Y, pixels');
    axis tight;
    grid on;
    axis equal tight;
            pause(0.0001);
            frame_h = get(handle(gcf),'JavaFrame');
            set(frame_h,'Maximized',1);
            pause(1);
            img = getframe(gcf); imwrite(img.cdata, [ name,' - 2D-AKF [Vector Gradient]', '.jpeg']); pause(1);
    %---------
    function resizeFigure(~,~)
    % Функция вызывается при изменении размера окна
    axis equal tight;  % Установка размеров осей при изменении размера окна
    end
    %---------
    close all
    pause (2)
end