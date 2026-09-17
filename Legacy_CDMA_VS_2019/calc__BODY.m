
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Формирование структуры для расчетов
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pathForRead  = 'C:\CALCULATION\ZRAZKU';                                    % директива где хранятся образцы
pathForSave  = 'C:\CALCULATION';                                           % директива для сохранения
pathForCode  = fileparts(mfilename('fullpath'));
addpath(pathForCode);
addpath(fullfile(fileparts(pathForCode), 'utils'));                           % директива c програмамми

global data_sets; data_sets = struct();

cd (pathForCode); 
pause (1);

%   samples = {'Желч', 'Кровь', 'Ликвар', 'Матка', 'Миокард', 'Моча', 'Печень', 'Плазма', 'Почка', 'Прямая_кишка', 'Селезенка', 'Синовиальная_жидкость', 'Эндометрий'};
    samples = {'Ликвар', 'Желч'};

%   examples = {'1', '2', '3', '4'};
    examples = {'zrazok_1', 'zrazok_2', 'zrazok_3','zrazok_4'};

for i = 1 : numel(samples)                                                 % прохождение по образцам
    name = char(samples(i));
    cd (pathForSave); mkdir (name); 
    cd ([pathForSave, '\', name, '\']);
    for j = 1 : numel(examples)                                            % прохождение по видам(подпапкам)
    example = char(examples (j));
              %-----------------------------------------------------------
                pause (1);
                mkdir (example);
                savePath = [pathForSave, '\', name, '\', example, '\'];
                readPath = [pathForRead, '\', name, '\', example, '\'];
              %-----------------------------------------------------------

    % -------------------------------------------------------------------------
    % GORSKII (СЧИТЫВАНИЕ ДАННЫХ ИЗ .МАТ ФАЙЛА)
    %     myFolder = [path, '\', name, '\', example, '\mat\'];
    % 
    %     if ~isdir(path)
    %       errorMessage = sprintf('Error: The following folder does not exist:\n%s', myFolder);
    %       uiwait(warndlg(errorMessage));
    %       return;
    %     end
    % 
    %     filePattern = fullfile(myFolder, '*.mat');
    %     matFiles = dir(filePattern);
    %     for k = 1:length(matFiles)
    %       baseFileName = matFiles(k).name;
    % 
    %       if ( length(baseFileName) == 12)
    %           baseFileName2 = baseFileName(1:8); 
    %           fullFileName = fullfile(myFolder, baseFileName);
    %           fprintf(1, 'Now reading %s\n', fullFileName);
    %           VARname = load(fullFileName);
    %           assignin('base', baseFileName2, VARname.rez);
    %       elseif ( length(baseFileName) == 8)
    %           baseFileName2 = baseFileName(1:4); 
    %           fullFileName = fullfile(myFolder, baseFileName);
    %           fprintf(1, 'Now reading %s\n', fullFileName);
    %           VARname = load(fullFileName);
    %           assignin('base', baseFileName2, VARname.tosave);
    %       end
    %     end
    %----------------------------------------------------------------------

    %----------------------------------------------------------------------
       cd (pathForCode); pause(2); calc__INFO_About_Sample(savePath, readPath, pathForCode);    % расчет для самих изображений    
     % cd (pathForCode); pause(2); calc__MULLER(savePath, readPath);                            % расчет элементов матрицы Мюллера
     % cd (pathForCode); pause(2); calc__VS(savePath, readPath);                   % расчет параметров вектора Стокса
     % cd (pathForCode); pause(2); calc__azimuth(savePath, readPath);              % расчет азимутальной поляризационной карты
     % cd (pathForCode); pause(2); calc__ellipticity(savePath, readPath);          % расчет карт эллиптичностей
     % cd (pathForCode); pause(2); calc__delta(savePath, readPath);                % расчет карт фазовых набегов
     % cd (pathForCode); pause(2); calc__VS(savePath, readPath);                   % расчет двоточечных параметров ветора Стокса  
     % cd (pathForCode); pause(2); calc__CDMA(savePath, readPath);                 % расчет CDMA
     % cd (pathForCode); pause(2); calc__CDMP(savePath, readPath);                 % расчет CDMA

    %----------------------------------------------------------------------
    end
end