%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   функция для расчета вейвлета
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [] = calc_Wavelet(IM, saveWAVELET, name)
    
    cd (saveWAVELET); pause(1);
    
    %расчет вейвлета%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    lower_bound = 1;    % нижняя границы (низ по маштабн. коефициенту)
    upper_bound = 41;   % верхняя граница (вершина по маштабному коеф.)
    STEP_next = 2;      % шаг с которым двигаемся (по масштабноиму коефициенту)


    STEP_angle = 10;  % маштабний коеф╕ц╕╓нт
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    mkdir ('WAVELET');
    saveWAVELET = [saveWAVELET, 'WAVELET', '\'];
    cd (saveWAVELET); 

   % перевод в полярную систему координат

    POLAR_OUT = calc_To_Polar_Coordinates(IM, '-',  saveWAVELET, name);

    for h = 0 : STEP_angle : 179
    WAVElet=cwt(POLAR_OUT(h+1,:), lower_bound:1:upper_bound,'gaus 2');

    cd (saveWAVELET); 
    mkdir ( [num2str(h), ' - град(кут)'] );
    saveWAVELETangle = [saveWAVELET, num2str(h), ' - град(кут)', '\'];
    cd (saveWAVELETangle); 
    pause(1);

    
        for k = lower_bound : STEP_next : upper_bound
        WAVEline = WAVElet(k,:);
        
        WAVEline = WAVEline + abs(min(WAVEline));
        
        ELEM_SER = mean(WAVEline);
        ELEM_SKV = std(WAVEline);
        ELEM_A   = skewness(WAVEline);
        ELEM_E   = kurtosis(WAVEline)-3;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        AKF_WAVEline = xcorr (WAVEline);
        if (AKF_WAVEline(:)<0)
        AKF_WAVEline = AKF_WAVEline + abs( min(min(AKF_WAVEline)) );
        end
        AKF_WAVEline = AKF_WAVEline./(max(max(AKF_WAVEline)));

        AKF_SER = mean(AKF_WAVEline);
        AKF_SKV = std(AKF_WAVEline);
        AKF_A   = skewness(AKF_WAVEline);
        AKF_E   = kurtosis(AKF_WAVEline)-3;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        PSD_WAVEline = periodogram (AKF_WAVEline);
        PSD_SER = mean(PSD_WAVEline);
        PSD_SKV = std(PSD_WAVEline);
        PSD_A   = skewness(PSD_WAVEline);
        PSD_E   = kurtosis(PSD_WAVEline)-3;
        
        elm_str = { ['Mean = ' num2str( ELEM_SER )], 
                    ['Standart Deviation = ' num2str( ELEM_SKV)], 
                    ['Asymmetry = ' num2str( ELEM_A )], 
                    ['Kurtosis = '  num2str( ELEM_E )], 
        };
        akf_str = { ['Mean = ' num2str( AKF_SER )], 
                    ['Standart Deviation = ' num2str( AKF_SKV)], 
                    ['Asymmetry = ' num2str( AKF_A )], 
                    ['Kurtosis = '  num2str( AKF_E )], 
        };
        psd_str = { ['Mean = ' num2str( PSD_SER )], 
                    ['Standart Deviation = ' num2str( PSD_SKV )], 
                    ['Asymmetry = ' num2str( PSD_A )], 
                    ['Kurtosis = '  num2str( PSD_E )], 
        };

        %местоположения легенды на окне графика
        elm_dim = [.765 .815 .1 .1];
        akf_dim = [.325 .34 .1 .1];
        psd_dim = [.575 .12 .1 .1];
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        figure('name',['WAVELET for ' name '; SCALE a = ' num2str( k ) ],'units','normalized','outerposition',[0 0 1 1],'Color','white')
        subplot 221; Sc1=cwt(IM,0.2:0.2:upper_bound,'gaus 2','plot'); colormap (gray);
                title (['W_{a,b}'],'Color','b');
                xlabel('b','Color','b');
                ylabel('a','Color','b')
        subplot 222; plot (WAVEline, 'LineWidth', 1.5); grid on;
                title (['WAVELET - ' name '; for a = ' num2str( k ) ],'Color','b');
                xlabel('b','Color','b');
                ylabel('value','Color','b')
                annotation('textbox',elm_dim,'String', elm_str,'FitBoxToText','on','BackgroundColor','white','FaceAlpha',.9)
        subplot 223; plot   (AKF_WAVEline, 'LineWidth', 1.5); grid on;
                title (['AKF for a = ' num2str( k ) ],'Color','b')  
                xlabel('Direction, pixels ','Color','b')
                ylabel('AutoCorrelation Function','Color','b');
                annotation('textbox',akf_dim,'String', akf_str,'FitBoxToText','on','BackgroundColor','blue','FaceAlpha',.2)      
        subplot 224; loglog (PSD_WAVEline, 'LineWidth', 1.1); grid on;
                title (['PSD for a = ' num2str( k ) ],'Color','b')
                xlabel('LOG','Color','b')
                ylabel('LOG','Color','b');
                annotation('textbox',psd_dim,'String', psd_str,'FitBoxToText','on','BackgroundColor','blue','FaceAlpha',.2)
        pause(0.0001);
        frame_h = get(handle(gcf),'JavaFrame');
        set(frame_h,'Maximized',1);
            pause(1);
            img = getframe(gcf); imwrite(img.cdata, [['WAVELET for ' name '; SCALE a = ' num2str( k ) ], '.jpeg']); pause(1)   
            pause(0.5);
            
            close all;
            pause(0.5); 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        end
    end
end