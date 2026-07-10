%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Расчет для элементов матрицы Мюллера
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = calc__VS(saveTomka)
%--------------------------------------------------------------------------
VS = evalin('base',  'e_stocks');
for i = 1 : 4
    if (i == 1)      VS_inp = VS.s0;     VS_Folder_name = 'На вході - 0';
    elseif (i == 2)  VS_inp = VS.s45;    VS_Folder_name = 'На вході - 45';
    elseif (i == 3)  VS_inp = VS.s90;    VS_Folder_name = 'На вході - 90';
    %elseif (i == 4)  VS_inp = VS.s135;   VS_Folder_name = 'На вході - 135';
    elseif (i == 4)  VS_inp = VS.sprav;  VS_Folder_name = 'На вході - правий циркуль';
    %elseif (i == 6)  VS_inp = VS.sliv;   VS_Folder_name = 'На вході - лівий циркуль';
    end
    cd (saveTomka);     mkdir ('Вектор Стокса');    saveTomka_VS = [saveTomka, 'Вектор Стокса\']; pause (1);
    cd (saveTomka_VS);  mkdir (VS_Folder_name);     saveTomka_VS_inp = [saveTomka_VS, VS_Folder_name, '\']; pause (1);
    
    for p = 1 : 4
    if (p == 1)      image_3d = VS_inp.s1;  VS_Folder_name_Si = 's1';
    elseif (p == 2)  image_3d = VS_inp.s2;  VS_Folder_name_Si = 's2';
    elseif (p == 3)  image_3d = VS_inp.s3;  VS_Folder_name_Si = 's3';
    elseif (p == 4)  image_3d = VS_inp.s4;  VS_Folder_name_Si = 's4';
    end
    cd (saveTomka_VS_inp);  mkdir (VS_Folder_name_Si); saveTomka_VS_inp_Si = [saveTomka_VS_inp, VS_Folder_name_Si, '\']; pause (1);
    assignin('base','VS_Folder_name_Si',VS_Folder_name_Si);
        
        %доступ до шару зразка
        for j = 1 : 1
            if (j == 1)     VS_Si_layer = 'шар_1';
            elseif (j == 2) VS_Si_layer = 'шар_2';
            elseif (j == 3) VS_Si_layer = 'шар_3';
            elseif (j == 4) VS_Si_layer = 'шар_4';
            end

            cd (saveTomka_VS_inp_Si); mkdir (VS_Si_layer);  saveTomka_VS_inp_Si_layer = [saveTomka_VS_inp_Si, VS_Si_layer, '\']; pause (1);
            cd (saveTomka_VS_inp_Si_layer);
            
%                     figure('name',[VS_Folder_name_Si],'units','normalized','outerposition',[0 0 1 1],'Color','white')
%                     imshow(image_3d(:,:,j), 'DisplayRange', [min(min(image_3d(:,:,j))) max(max(image_3d(:,:,j)))]); colormap (jet); colorbar; 
%                     title (['Параметр вектора Стокса - ' VS_Folder_name_Si],'Color','r')
%                     xlabel('X-direction, pixels ','Color','r')
%                     ylabel('Y-direction, pixels ','Color','r')
%                         pause(0.0001);
%                         frame_h = get(handle(gcf),'JavaFrame');
%                         set(frame_h,'Maximized',1);
%                     img = getframe(gcf); imwrite(img.cdata, [VS_Folder_name_Si, '.jpeg']); pause(0.1)    

            programspath = evalin('base',  'programspath');
            cd (programspath);
            pause(2);

            body_akf_psd_stat(image_3d, j, saveTomka_VS_inp_Si_layer, VS_Folder_name_Si);
        end
        
    end
    
end


end
