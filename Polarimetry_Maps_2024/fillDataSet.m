%----------------------------------------------------------------------------------
% Функция для заполнения структуры данными
function fillDataSet(image_Data, dataSetIterationName, MATR_AKF_STAT, MATR_PSD_STAT)
% image_Data            - данные про сегмент изображения/само изображение
% dataSetIterationName  - имя сегмента изображения
% MATR_AKF_STAT         - набор значений по углам для АКF
% MATR_PSD_STAT         - набор значений по углам для PSD
    global data_sets;
    
    % Создаем имя для текущего набора данных
    dataSetName = sprintf(dataSetIterationName);
    
    % Заполняем матрицу матрицей изображения
    data_sets.('all_images').(dataSetIterationName) = image_Data;

    % Заполняем матрицу матрицей изображения
    data_sets.(dataSetName).('image') = image_Data;
    
    % Заполняем 8 массивов статических моментов
    data_sets.(dataSetName).('akf_mean') = MATR_AKF_STAT(1,:);
    data_sets.(dataSetName).('akf_dispersion') = MATR_AKF_STAT(2,:);
    data_sets.(dataSetName).('akf_asymmetry') = MATR_AKF_STAT(3,:);
    data_sets.(dataSetName).('akf_kurtosis') = MATR_AKF_STAT(4,:);
    data_sets.(dataSetName).('psd_mean') = MATR_PSD_STAT(1,:);
    data_sets.(dataSetName).('psd_dispersion') = MATR_PSD_STAT(2,:);
    data_sets.(dataSetName).('psd_asymmetry') = MATR_PSD_STAT(3,:);
    data_sets.(dataSetName).('psd_kurtosis') = MATR_PSD_STAT(4,:);

end
%-----------------------------------------------------------------------------------