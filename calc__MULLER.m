%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Расчет для элементов матрицы Мюллера
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = calc__MULLER(saveTomka)

calc_Muller_Matrix_Elements;                                                %подсчет элементов матрицы Мюллера

pause(5);
%--------------------------------------------------------------------------
for i = 12 : 12                                                             %прохождение по всем элементам матрицы Мюллера
%(СЧИТЫВАНИЕ ДАННЫХ ИЗ ИЗОБРАЖЕНИЯ)
     if (i == 1)      image_3d = M11; MM_Folder_name = 'M11';
     elseif (i == 2)  image_3d = M12; MM_Folder_name = 'M12';
     elseif (i == 3)  image_3d = M13; MM_Folder_name = 'M13';
     elseif (i == 4)  image_3d = M14; MM_Folder_name = 'M14';
     elseif (i == 5)  image_3d = M21; MM_Folder_name = 'M21';
     elseif (i == 6)  image_3d = M22; MM_Folder_name = 'M22';
     elseif (i == 7)  image_3d = M23; MM_Folder_name = 'M23';
     elseif (i == 8)  image_3d = M24; MM_Folder_name = 'M24';
     elseif (i == 9)  image_3d = M31; MM_Folder_name = 'M31';
     elseif (i == 10) image_3d = M32; MM_Folder_name = 'M32';
     elseif (i == 11) image_3d = M33; MM_Folder_name = 'M33';
     elseif (i == 12) image_3d = M34; MM_Folder_name = 'M34';
     elseif (i == 13) image_3d = M41; MM_Folder_name = 'M41';
     elseif (i == 14) image_3d = M42; MM_Folder_name = 'M42';
     elseif (i == 15) image_3d = M43; MM_Folder_name = 'M43';
     elseif (i == 16) image_3d = M44; MM_Folder_name = 'M44';
     end
    
    cd (saveTomka); mkdir ('Muller matrix'); saveTomka_MM = [saveTomka, 'Muller matrix\']; pause (1);
    cd (saveTomka_MM); mkdir (MM_Folder_name); saveTomka_MM_ik = [saveTomka_MM, MM_Folder_name, '\']; pause (1);
    assignin('base','MM_Folder_name',MM_Folder_name)
    

    %%------------------------------------------------------------------------------------------------------------
    %%% прохождение по шарам

    for j = 1 : 1
        if (j == 1)     MM_Folder_layer = 'default_layer';              %править
        elseif (j == 2) MM_Folder_layer = 'шар_2';                      %править
        elseif (j == 3) MM_Folder_layer = 'шар_3';                      %править
        elseif (j == 4) MM_Folder_layer = 'шар_4';                      %править
        end
        
        cd (saveTomka_MM_ik); mkdir (MM_Folder_layer);  saveTomka_MM_ik_layer = [saveTomka_MM_ik, MM_Folder_layer, '\']; pause (1);
        cd (saveTomka_MM_ik_layer);
 
%                figure('name',[MM_Folder_name],'units','normalized','outerposition',[0 0 1 1],'Color','white')
%                imshow(image_3d(:,:,j), 'DisplayRange', [min(min(image_3d(:,:,j))) max(max(image_3d(:,:,j)))]); colormap (jet); colorbar; 
%                title (['Мюллер-матричний елемент - ' MM_Folder_name],'Color','r')
%                xlabel('X-direction, pixels ','Color','r')
%                ylabel('Y-direction, pixels ','Color','r')
%                    pause(0.0001);
%                    frame_h = get(handle(gcf),'JavaFrame');
%                    set(frame_h,'Maximized',1);
%                img = getframe(gcf); imwrite(img.cdata, [MM_Folder_name, '.jpeg']); pause(0.1)    
       
        programspath = evalin('base',  'programspath');
        cd (programspath);
        pause(2);

        %------------------------------------------------------------------------------------------------------------
        
        calc_Full_Information(image_3d, j, saveTomka_MM_ik_layer, MM_Folder_name);
    end

end

end
