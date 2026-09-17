%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Расчет для элементов матрицы Мюллера
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = calc__ellipticity(saveTomka)
%--------------------------------------------------------------------------
VS = evalin('base',  'e_stocks');
for i = 1 : 4
    if (i == 1)      VS_inp = VS.s0;     EL_Folder_name = 'На вході - 0';
    elseif (i == 2)  VS_inp = VS.s45;    EL_Folder_name = 'На вході - 45';
    elseif (i == 3)  VS_inp = VS.s90;    EL_Folder_name = 'На вході - 90';
    %elseif (i == 4)  VS_inp = VS.s135;   EL_Folder_name = 'На вході - 135';
    elseif (i == 4)  VS_inp = VS.sprav;  EL_Folder_name = 'На вході - правий циркуль';
    %elseif (i == 6)  VS_inp = VS.sliv;   EL_Folder_name = 'На вході - лівий циркуль';
    end
    cd (saveTomka);     mkdir ('Ellipticity');      saveTomka_EL = [saveTomka, 'Ellipticity\']; pause (1);
    cd (saveTomka_EL);  mkdir (EL_Folder_name);     saveTomka_EL_inp = [saveTomka_EL, EL_Folder_name, '\']; pause (1);
    
    %---------------------------------------------------------------------- 
    image_3d = real(0.5*asin(VS_inp.s4(:,:)./(VS_inp.s1(:,:)+0.0001))); %поляризационная карта эллиптичности
    %----------------------------------------------------------------------
        %доступ до шару зразка
        for l = 1 : 1
            if (l == 1)     EL_layer = 'шар_1';
            elseif (l == 2) EL_layer = 'шар_2';
            elseif (l == 3) EL_layer = 'шар_3';
            elseif (l == 4) EL_layer = 'шар_4';
            end
                      
            cd (saveTomka_EL_inp);  mkdir (EL_layer);  saveTomka_EL_layer = [saveTomka_EL_inp, EL_layer, '\']; pause (1);
            cd (saveTomka_EL_layer);
            
%                     figure('name',['Ellipticity - ',EL_Folder_name],'units','normalized','outerposition',[0 0 1 1],'Color','white')
%                     imshow(image_3d(:,:,l), 'DisplayRange', [min(min(image_3d(:,:,l))) max(max(image_3d(:,:,l)))]); colormap (jet); colorbar; 
%                     title (['2D Ellipticity - ' EL_Folder_name],'Color','r')
%                     xlabel('X-direction, pixels ','Color','r')
%                     ylabel('Y-direction, pixels ','Color','r')
%                         pause(0.0001);
%                         frame_h = get(handle(gcf),'JavaFrame');
%                         set(frame_h,'Maximized',1);
%                     img = getframe(gcf); imwrite(img.cdata, ['Ellipticity - ',EL_Folder_name, '(jet).jpeg']); pause(0.1)    
% 
%                     figure('name',['Ellipticity - ',EL_Folder_name],'units','normalized','outerposition',[0 0 1 1],'Color','white')
%                     imshow(image_3d(:,:,l), 'DisplayRange', [min(min(image_3d(:,:,l))) max(max(image_3d(:,:,l)))]); colormap (gray); colorbar; 
%                     title (['2D Ellipticity - ' EL_Folder_name],'Color','r')
%                     xlabel('X-direction, pixels ','Color','r')
%                     ylabel('Y-direction, pixels ','Color','r')
%                         pause(0.0001);
%                         frame_h = get(handle(gcf),'JavaFrame');
%                         set(frame_h,'Maximized',1);
%                     img = getframe(gcf); imwrite(img.cdata, ['Ellipticity - ',EL_Folder_name, '(gray).jpeg']); pause(0.1) 
                     
                     
            programspath = evalin('base',  'programspath');
            cd (programspath);
            pause(2);

            body_akf_psd_stat(image_3d, l, saveTomka_EL_layer, 'Ellipticity');
        end

end

end
