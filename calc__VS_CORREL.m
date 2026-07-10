%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Расчет 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = calc__VS_CORREL(saveTomka)
%--------------------------------------------------------------------------
VS = evalin('base',  'e_stocks');
for i = 1 : 6
    clear A1; clear A2; 
    clear B1; clear B2; 
    clear C1; clear C2;
    clear S2_CORR; 
    clear S3_CORR; 
    clear S4_CORR;
    if (i == 1)      VS_inp = VS.s0;     VS_Folder_name = 'На вході - 0';
    elseif (i == 2)  VS_inp = VS.s45;    VS_Folder_name = 'На вході - 45';
    elseif (i == 3)  VS_inp = VS.s90;    VS_Folder_name = 'На вході - 90';
    elseif (i == 4)  VS_inp = VS.s135;   VS_Folder_name = 'На вході - 135';
    elseif (i == 5)  VS_inp = VS.sprav;  VS_Folder_name = 'На вході - правий циркуль';
    elseif (i == 6)  VS_inp = VS.sliv;   VS_Folder_name = 'На вході - лівий циркуль';
    end
    cd (saveTomka);     mkdir ('Stokes Cross-Correlation');    saveTomka_VS = [saveTomka, 'Stokes Cross-Correlation\']; pause (1);
    cd (saveTomka_VS);  mkdir (VS_Folder_name);                saveTomka_VS_inp = [saveTomka_VS, VS_Folder_name, '\'];  pause (1);
    
    %---------------------------------------------------------------------
        Z0    = 0.5*(VS_inp.s1 + VS_inp.s2);
        Z90   = 0.5*(VS_inp.s1 - VS_inp.s2);
        Z45   = 0.5*(VS_inp.s1 + VS_inp.s3);
        Z135  = 0.5*(VS_inp.s1 - VS_inp.s3);
        Z180  = 0.5*(VS_inp.s1 + VS_inp.s4);
        Z225  = 0.5*(VS_inp.s1 - VS_inp.s4);

        programspath = evalin('base',  'programspath');
        cd(programspath); pause(1);
        
        %-----------------------------------------------------------------
        NAPIVSH_AKF = corr_func_2D_NAPIVshuruna(VS_inp, '1_2_3_4_shar', saveTomka, 'Напів_ширина_АКФ');

        [Xdim,Ydim,Zdim]=size(Z0);

       for jj = 1 : Zdim
        for kk = 1 : Xdim
            for zz = 1 : (Ydim-round(NAPIVSH_AKF.S2(jj)))
            %S2
            A1(kk,zz,jj)=sqrt( Z0(kk,zz,jj).*  Z0 (kk,zz+round(NAPIVSH_AKF.S2(jj)),jj) );
            A2(kk,zz,jj)=sqrt( Z90(kk,zz,jj).* Z90(kk,zz+round(NAPIVSH_AKF.S2(jj)),jj) );
            end
            for zz = 1:(Ydim-round(NAPIVSH_AKF.S3(jj)))
            %S3
            B1(kk,zz,jj)=sqrt( Z45(kk,zz,jj).*  Z45 (kk,zz+round(NAPIVSH_AKF.S3(jj)),jj) );
            B2(kk,zz,jj)=sqrt( Z135(kk,zz,jj).* Z135(kk,zz+round(NAPIVSH_AKF.S3(jj)),jj) ); 
            end            
            for zz = 1:(Ydim-round(NAPIVSH_AKF.S4(jj)))
            %S4
            C1(kk,zz,jj)=sqrt(  Z180(kk,zz,jj).* Z180(kk,zz+round(NAPIVSH_AKF.S4(jj)),jj) );
            C2(kk,zz,jj)=sqrt(  Z225(kk,zz,jj).* Z225(kk,zz+round(NAPIVSH_AKF.S4(jj)),jj) );
            end
        end
       end
 
        S2_CORR = (A1-A2)./(A1+A2); S2_CORR(isnan(S2_CORR)) = 0;
        S3_CORR = (B1-B2)./(B1+B2); S3_CORR(isnan(S3_CORR)) = 0;
        S4_CORR = (C1-C2)./(C1+C2); S4_CORR(isnan(S4_CORR)) = 0;
    %---------------------------------------------------------------------
    for p = 1 : 3
    if (p == 1)      
        image_3d = S2_CORR;  VS_Folder_name_Si = 'S2(cross-correlation)'; LOL = NAPIVSH_AKF.S2;
    elseif (p == 2)  
        image_3d = S3_CORR;  VS_Folder_name_Si = 'S3(cross-correlation)'; LOL = NAPIVSH_AKF.S3;
    elseif (p == 3)  
        image_3d = S4_CORR;  VS_Folder_name_Si = 'S4(cross-correlation)'; LOL = NAPIVSH_AKF.S4;
    end
    cd (saveTomka_VS_inp);  mkdir (VS_Folder_name_Si); saveTomka_VS_inp_Si = [saveTomka_VS_inp, VS_Folder_name_Si, '\']; pause (1);
    assignin('base','VS_Folder_name_Si',VS_Folder_name_Si);   
    
        for j = 1 : 4
            if (j == 1)      VS_Si_layer = 'шар_1'; 
            elseif (j == 2)  VS_Si_layer = 'шар_2';
            elseif (j == 3)  VS_Si_layer = 'шар_3';
            elseif (j == 4)  VS_Si_layer = 'шар_4';
            end
            assignin('base','XXX',image_3d);
            ZZZ = num2str (round (LOL(j)));

                    IM_reshape = reshape (image_3d(:,:,j), 1, []);
                    IM_SER = mean(IM_reshape);
                    IM_SKV = std(IM_reshape);
                    IM_A   = skewness(IM_reshape);
                    IM_E   = kurtosis(IM_reshape)-3;
                    STAT_str = {['Mean = ' num2str( IM_SER )], 
                                ['Standart Deviation = ' num2str( IM_SKV )], 
                                ['Asymmetry = ' num2str( IM_A )], 
                                ['Kurtosis = ' num2str( IM_E )], 
                    };
                    location_dim = [.78 .82 .1 .1];
            
            
            cd (saveTomka_VS_inp_Si); mkdir (VS_Si_layer);  saveTomka_VS_inp_Si_layer = [saveTomka_VS_inp_Si, VS_Si_layer, '\']; pause (1);
            cd (saveTomka_VS_inp_Si_layer);
            
                    figure('name',[VS_Folder_name_Si],'units','normalized','outerposition',[0 0 1 1],'Color','white')
                    imshow(image_3d(:,:,j), 'DisplayRange', [min(min(image_3d(:,:,j))) max(max(image_3d(:,:,j)))]); colormap (jet); colorbar; 
                    title (['Двухточечный параметр вектора Стокса - ' VS_Folder_name_Si ' для кроку = ' ZZZ '(color)'],'Color','r')
                    xlabel('X-direction, pixels ','Color','r')
                    ylabel('Y-direction, pixels ','Color','r')
                    annotation('textbox',location_dim,'String', STAT_str,'FitBoxToText','on','BackgroundColor','blue','FaceAlpha',.2)
                        pause(0.0001);
                        frame_h = get(handle(gcf),'JavaFrame');
                        set(frame_h,'Maximized',1);
                        img = getframe(gcf); imwrite(img.cdata, [VS_Folder_name_Si, '(color).jpeg']); pause(0.1)    
                    
                    pause(0.5);
                    
                    figure('name',[VS_Folder_name_Si],'units','normalized','outerposition',[0 0 1 1],'Color','white')
                    imshow(image_3d(:,:,j), 'DisplayRange', [min(min(image_3d(:,:,j))) max(max(image_3d(:,:,j)))]); colormap (gray); colorbar; 
                    title (['Двухточечный параметр вектора Стокса - ' VS_Folder_name_Si ' для кроку = ' ZZZ '(gray)' ],'Color','r')
                    xlabel('X-direction, pixels ','Color','r')
                    ylabel('Y-direction, pixels ','Color','r')
                    annotation('textbox',location_dim,'String', STAT_str,'FitBoxToText','on','BackgroundColor','blue','FaceAlpha',.2)
                        pause(0.0001);
                        frame_h = get(handle(gcf),'JavaFrame');
                        set(frame_h,'Maximized',1);
                        img = getframe(gcf); imwrite(img.cdata, [VS_Folder_name_Si, '(gray).jpeg']); pause(0.1)  

            cd (programspath);
            close all;
            pause(1);
            
            body_akf_psd_stat(image_3d, j, saveTomka_VS_inp_Si_layer, VS_Folder_name_Si);
        end
        
    end
    
end


end
