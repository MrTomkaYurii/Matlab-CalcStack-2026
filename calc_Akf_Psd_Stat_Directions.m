function [] = calc_Akf_Psd_Stat_Directions(correlation_matrix, ...
    correlation_matrix_in_polar_coordinate, ...
    step_angle, ...
    work_layer, ...
    saveTomka, ...
    name)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Разрахунок АКФ, PSD, стат. момент╕в для вс╕х напрямк╕в опрацьов. шару
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% correlation_matrix                         %%% двовим╕рна автокреляц╕йна функц╕я
% correlation_matrix_in_polar_coordinate;    %%% зображення представлене у полярн╕й систем╕ координат
% step_angle;                                %%% крок вир╕зки у градусах
% number_of_layer                            %%% номер шару
% saveTomka                                  %%% шлях до збереження
% name                                       %%% ╕мя анал╕зу╓мого зображення  

cd (saveTomka); pause(1);
step_number = 180/step_angle;

[m,n] = size(correlation_matrix_in_polar_coordinate);
POLAR_WORK = zeros (2*m,step_number);   %% матрица в которую пишем нарезки

k=0;
for i = 1 : step_angle : n/2
    k = k+1;
    line1 = correlation_matrix_in_polar_coordinate (:,i);
    line1 = line1(length(line1):-1:1);
    line2 = correlation_matrix_in_polar_coordinate (:,i+180);
    POLAR_WORK (:,k) = [line1;line2];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   AKF PSD STAT РАСЧЕТ

[mm,nn] = size(POLAR_WORK);
MATR_AKF_STAT   = zeros (4,nn);
MATR_PSD_STAT   = zeros (4,nn);

for kk = 1 : nn
    read_line =  POLAR_WORK(:,kk) ;
    LINE_WORK_AKF =  read_line(read_line>0);
    AKF_SER = mean(LINE_WORK_AKF);
    AKF_SKV = std(LINE_WORK_AKF);
    AKF_A   = skewness(LINE_WORK_AKF);
    AKF_E   = kurtosis(LINE_WORK_AKF)-3;
    
    LINE_WORK_PSD = periodogram (LINE_WORK_AKF);
    LINE_WORK_PSD = LINE_WORK_PSD';
    PSD_SER = mean(LINE_WORK_PSD);
    PSD_SKV = std(LINE_WORK_PSD);
    PSD_A   = skewness(LINE_WORK_PSD);
    PSD_E   = kurtosis(LINE_WORK_PSD)-3;
    
    
    MATR_AKF_STAT (1,kk) = AKF_SER;     MATR_PSD_STAT (1,kk) = PSD_SER; 
    MATR_AKF_STAT (2,kk) = AKF_SKV;     MATR_PSD_STAT (2,kk) = PSD_SKV;
    MATR_AKF_STAT (3,kk) = AKF_A;       MATR_PSD_STAT (3,kk) = PSD_A;
    MATR_AKF_STAT (4,kk) = AKF_E;       MATR_PSD_STAT (4,kk) = PSD_E;
    
    akf_str = { ['Mean = ' num2str( MATR_AKF_STAT(1,kk) )], 
                ['Standart Deviation = ' num2str( MATR_AKF_STAT(2,kk) )], 
                ['Asymmetry = ' num2str( MATR_AKF_STAT(3,kk) )], 
                ['Kurtosis = ' num2str( MATR_AKF_STAT(4,kk) )], 
    };
    psd_str = { ['Mean = ' num2str( MATR_PSD_STAT(1,kk) )], 
                ['Standart Deviation = ' num2str( MATR_PSD_STAT(2,kk) )], 
                ['Asymmetry = ' num2str( MATR_PSD_STAT(3,kk) )], 
                ['Kurtosis = ' num2str( MATR_PSD_STAT(4,kk) )], 
    };

    %местоположения легенды на окне графика
    akf_dim = [.325 .325 .1 .1];
    psd_dim = [.76 .8 .1 .1];
  
    
    figure('name',['AKF and PSD for Angle = ' num2str( step_angle*kk ) ';  Layer = ' num2str( work_layer ) ],'units','normalized','outerposition',[0 0 1 1],'Color','white')
    subplot 221; imshow (correlation_matrix); colormap(jet); colorbar
            title ('AKF','Color','r')
            xlabel('X, pixels','Color','r')
            ylabel('Y, pixels','Color','r');
    subplot 222; plot (LINE_WORK_PSD, 'LineWidth', 1.25); grid on;
            axis([ 0 inf min(LINE_WORK_PSD) mean(LINE_WORK_PSD)*4.5 ])
            title (['Layer = ' num2str( work_layer ) ';   Angle = ' num2str( step_angle*kk ) '\circ ;'],'Color','r')  
            xlabel('Direction, pixels ','Color','r')
            ylabel('Power Spectrum Density','Color','r');
            annotation('textbox',psd_dim,'String', psd_str,'FitBoxToText','on','BackgroundColor','blue','FaceAlpha',.2)
    subplot 223; plot   (LINE_WORK_AKF, 'LineWidth', 1.5); grid on;
            title (['Layer = ' num2str( work_layer ) ';   Angle = ' num2str( step_angle*kk ) '\circ ;'],'Color','r')  
            xlabel('Direction, pixels ','Color','r')
            ylabel('AutoCorrelation Function','Color','r');
            annotation('textbox',akf_dim,'String', akf_str,'FitBoxToText','on','BackgroundColor','blue','FaceAlpha',.2)      
    subplot 224; loglog (LINE_WORK_PSD, 'LineWidth', 1.2); grid on;
            title ('PSD','Color','r')
            xlabel('LOG','Color','r')
            ylabel('LOG','Color','r');
    pause(0.0001);
    frame_h = get(handle(gcf),'JavaFrame');
    set(frame_h,'Maximized',1);
        pause(1);
        img = getframe(gcf); imwrite(img.cdata, [['AKF and PSD for Angle = ' num2str( step_angle*kk )], '.jpeg']); pause(1)
    
    clearvars LINE_WORK_AKF;
    clearvars LINE_WORK_PSD;
    
end

% Зведен╕ статистичн╕ моменти по шару
for kk = 1 : nn
    X_vis(kk) = step_angle*kk;
end    


    figure('name','AUTOCORRELATION FUNCTION','units','normalized','outerposition',[0 0 1 1],'Color','white')
    subplot 221; plot   ( X_vis, MATR_AKF_STAT(1,:),'b','LineWidth',1.5); grid on;
            title (['Layer = ' num2str( work_layer ) ';'],'Color','r') 
            xlabel('Angle, degrees ','Color','r')
            ylabel('Mean','Color','r');
    subplot 222; plot   (X_vis,MATR_AKF_STAT(2,:),'b','LineWidth',1.5); grid on;
            title (['Layer = ' num2str( work_layer ) ';'],'Color','r') 
            xlabel('Angle, degrees ','Color','r')
            ylabel('Dispersion','Color','r');
    subplot 223; plot   (X_vis,MATR_AKF_STAT(3,:),'b','LineWidth',1.5); grid on;
            title (['Layer = ' num2str( work_layer ) ';'],'Color','r')  
            xlabel('Angle, degrees ','Color','r')
            ylabel('Asymmetry','Color','r');
    subplot 224; plot   (X_vis,MATR_AKF_STAT(4,:),'b','LineWidth',1.5); grid on;
            title (['Layer = ' num2str( work_layer ) ';'],'Color','r')  
            xlabel('Angle, degrees ','Color','r')
            ylabel('Kurtosis','Color','r');
    pause(0.0001);
    frame_h = get(handle(gcf),'JavaFrame');
    set(frame_h,'Maximized',1);
    pause(1)
    img = getframe(gcf); imwrite(img.cdata, ['AKF_STAT (по всем углам)', '.jpeg']); pause(1)
            
    
    figure('name','POWER SPECTRUM DENSITY','units','normalized','outerposition',[0 0 1 1],'Color','white')
    subplot 221; plot   (X_vis,MATR_PSD_STAT(1,:),'b','LineWidth',1.5); grid on;
            title (['Layer = ' num2str( work_layer ) ';'],'Color','r')  
            xlabel('Angle, degrees ','Color','r')
            ylabel('Mean','Color','r');
    subplot 222; plot   (X_vis,MATR_PSD_STAT(2,:),'b','LineWidth',1.5); grid on;
            title (['Layer = ' num2str( work_layer ) ';'],'Color','r')  
            xlabel('Angle, degrees ','Color','r')
            ylabel('Dispersion','Color','r');
    subplot 223; plot   (X_vis,MATR_PSD_STAT(3,:),'b','LineWidth',1.5); grid on;
            title (['Layer = ' num2str( work_layer ) ';'],'Color','r')  
            xlabel('Angle, degrees ','Color','r')
            ylabel('Asymmetry','Color','r');
    subplot 224; plot   (X_vis,MATR_PSD_STAT(4,:),'b','LineWidth',1.5); grid on;
            title (['Layer = ' num2str( work_layer ) ';'],'Color','r')  
            xlabel('Angle, degrees ','Color','r')
            ylabel('Kurtosis','Color','r');
    pause(0.0001);
    frame_h = get(handle(gcf),'JavaFrame');
    set(frame_h,'Maximized',1);
        pause(1)
        img = getframe(gcf); imwrite(img.cdata, ['PSD_STAT (по всем углам)', '.jpeg']); pause(1)
        
        %------------------------------------------------------------------
        %заполнение структуры данными в виде изобрадения и стат. моментов
        global patch;
        fillDataSet(patch, name, MATR_AKF_STAT, MATR_PSD_STAT)
        %------------------------------------------------------------------
        
    close all;
    pause (3);
end