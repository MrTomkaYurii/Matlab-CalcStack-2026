%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Формирование структуры для расчетов
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pathForRead  = 'C:\[TOMKA] - Modelling\ЕТАП №05 - реальні БТ і БР\Зразки'; % директива где хранятся образцы
pathForSave  = 'C:\[TOMKA] - Modelling\ЕТАП №05 - реальні БТ і БР';        % директива для сохранения
pathForCode  = fileparts(mfilename('fullpath'));                            % директива c програмами
addpath(pathForCode);
addpath(fullfile(fileparts(pathForCode), 'utils'));

global data_sets; data_sets = struct();
global Results; Results = struct();

cd (pathForCode); pause (0.5);
        
    samples = {'Ендометрій', 'Жовч','Ліквар', 'Міокард', 'Мозок', 'Печінка', 'Плазма', 'Простата', 'Синовіальна рідина', 'Шийка матки'};
    examples = {'1'};
    steps = [1, 5, 10];
    crop_size = 450;

for i = 1 : numel(samples)                                                 % прохождение по образцам
    name = char(samples(i));
    cd (pathForSave); mkdir (name); 
    cd ([pathForSave, '\', name, '\']);
    for j = 1 : numel(examples)                                            % прохождение по видам(подпапкам)
    example = char(examples (j));
              %-----------------------------------------------------------
                pause (0.5);
                mkdir (example);
                % savePath = [pathForSave, '\', name, '\', example, '\'];
                % readPath = [pathForRead, '\', name, '\', example, '\'];
                    savePath = fullfile(pathForSave, name, example);
                    readPath = fullfile(pathForRead, name, example)
              %-----------------------------------------------------------

    % Функции расчета частей ТЗ
    %----------------------------------------------------------------------
            %   вывод информации про само изображение
            %   cd (pathForCode); pause(2); calc__INFO_About_Sample_Circular(savePath, readPath, pathForCode);    % расчет для самих изображений (кружок)
            %   cd (pathForCode); pause(2); calc__INFO_About_Sample(savePath, readPath, pathForCode);             % расчет для самих изображений
            % -- -- --   

        for k = 1:length(steps)
            step = steps(k);
            fprintf('Текущий шаг = %d\n', step);
            % расчет двуточечных параметров
                  cd (pathForCode); pause(2); calc_2025_DvotMM_1D_Circular (savePath, readPath, pathForCode, crop_size, step);          % расчет элементов матрицы Мюллера по траектории круга
            %     cd (pathForCode); pause(2); calc_2025_DvotMM_1D_OX (savePath, readPath, pathForCode, crop_size, step);                % расчет элементов матрицы Мюллера в OX направлении
            %     cd (pathForCode); pause(2); calc_2025_DvotMM_Azimuth_Ellipticity (savePath, readPath, pathForCode, crop_size, step);  % расчет элементов  аз. и ел. в OX направлении
            %     cd (pathForCode); pause(2); calc_2025_DvotMM_2D_RealBT (savePath, readPath, pathForCode, crop_size, step);            % расчет элементов матрицы Мюллера по АКФ
        end
        % % -- -- --
     %----------------------------------------------------------------------
    end
end