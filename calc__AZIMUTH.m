%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Расчет для элементов матрицы Мюллера
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = calc__Azimuth(saveTomka)
%--------------------------------------------------------------------------
VS = evalin('base',  'e_stocks');
for i = 1 : 4
    if (i == 1)      VS_inp = VS.s0;     AZ_Folder_name = 'На вході - 0';
    elseif (i == 2)  VS_inp = VS.s45;    AZ_Folder_name = 'На вході - 45';
    elseif (i == 3)  VS_inp = VS.s90;    AZ_Folder_name = 'На вході - 90';
    %elseif (i == 4)  VS_inp = VS.s135;   AZ_Folder_name = 'На вході - 135';
    elseif (i == 4)  VS_inp = VS.sprav;  AZ_Folder_name = 'На вході - правий циркуль';
    %elseif (i == 6)  VS_inp = VS.sliv;   AZ_Folder_name = 'На вході - лівий циркуль';
    end
    cd (saveTomka);     mkdir ('Azimuth');          saveTomka_AZ = [saveTomka, 'Azimuth\']; pause (1);
    cd (saveTomka_AZ);  mkdir (AZ_Folder_name);     saveTomka_AZ_inp = [saveTomka_AZ, AZ_Folder_name, '\']; pause (1);
      
    image_3d  = 0.5*atan(VS_inp.s3(:,:)./(VS_inp.s2(:,:)+0.0001));  %поляризационная карта
    
        %доступ до шару зразка
        for ll = 1 : 1
            if (ll == 1)     AZ_layer = 'шар_1';
            elseif (ll == 2) AZ_layer = 'шар_2';
            elseif (ll == 3) AZ_layer = 'шар_3';
            elseif (ll == 4) AZ_layer = 'шар_4';
            end
                      
            cd (saveTomka_AZ_inp);  mkdir (AZ_layer);  saveTomka_AZ_layer = [saveTomka_AZ_inp, AZ_layer, '\']; pause (1);
            cd (saveTomka_AZ_layer);
            
%                     figure('name',['Azimuth - ',AZ_Folder_name],'units','normalized','outerposition',[0 0 1 1],'Color','white')
%                     imshow(image_3d(:,:,ll), 'DisplayRange', [min(min(image_3d(:,:,ll))) max(max(image_3d(:,:,ll)))]); colormap (jet); colorbar; 
%                     title (['2D Azimuth - ' AZ_Folder_name],'Color','r')
%                     xlabel('X-direction, pixels ','Color','r')
%                     ylabel('Y-direction, pixels ','Color','r')
%                         pause(0.0001);
%                         frame_h = get(handle(gcf),'JavaFrame');
%                         set(frame_h,'Maximized',1);
%                     img = getframe(gcf); imwrite(img.cdata, ['Azimuth - ',AZ_Folder_name, '(jet).jpeg']); pause(0.1)    
% 
%                     figure('name',['Azimuth - ',AZ_Folder_name],'units','normalized','outerposition',[0 0 1 1],'Color','white')
%                     imshow(image_3d(:,:,ll), 'DisplayRange', [min(min(image_3d(:,:,ll))) max(max(image_3d(:,:,ll)))]); colormap (gray); colorbar; 
%                     title (['2D Azimuth - ' AZ_Folder_name],'Color','r')
%                     xlabel('X-direction, pixels ','Color','r')
%                     ylabel('Y-direction, pixels ','Color','r')
%                         pause(0.0001);
%                         frame_h = get(handle(gcf),'JavaFrame');
%                         set(frame_h,'Maximized',1);
%                     img = getframe(gcf); imwrite(img.cdata, ['Azimuth - ',AZ_Folder_name, '(gray).jpeg']); pause(0.1) 
                    
                    
            programspath = evalin('base',  'programspath');
            cd (programspath);
            pause(2);

            body_akf_psd_stat(image_3d, ll, saveTomka_AZ_layer, 'azimuth');
        end

end

end
