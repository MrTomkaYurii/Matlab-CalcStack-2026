en='.bmp';                                               % расширение файла
readTomka = evalin('base',  'readTomka');
saveTomka = evalin('base',  'saveTomka');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1 - Зчитування зображень
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[Z00,mapZ00]=imread([readTomka, '0-0', en]);
[Z045,mapZ045]=imread([readTomka, '0-45', en]);
[Z090,mapZ090]=imread([readTomka, '0-90', en]);
[Z0135,mapZ0135]=imread([readTomka, '0-135', en]);
[Z0180,mapZ0180]=imread([readTomka, '0-prav', en]);
[Z0225,mapZ0225]=imread([readTomka, '0-liv', en]);

[Z450,mapZ450]=imread([readTomka, '45-0', en]);
[Z4545,mapZ4545]=imread([readTomka, '45-45', en]);
[Z4590,mapZ4590]=imread([readTomka, '45-90', en]);
[Z45135,mapZ45135]=imread([readTomka, '45-135', en]);
[Z45180,mapZ45180]=imread([readTomka, '45-prav', en]);
[Z45225,mapZ45225]=imread([readTomka, '45-liv', en]);

[Z900,mapZ900]=imread([readTomka, '90-0', en]);
[Z9045,mapZ9045]=imread([readTomka, '90-45', en]);
[Z9090,mapZ9090]=imread([readTomka, '90-90', en]);
[Z90135,mapZ90135]=imread([readTomka, '90-135', en]);
[Z90180,mapZ90180]=imread([readTomka, '90-prav', en]);
[Z90225,mapZ90225]=imread([readTomka, '90-liv', en]);

[Zprav0,mapZprav0]=imread([readTomka, 'prav-0', en]);
[Zprav45,mapZprav45]=imread([readTomka, 'prav-45', en]);
[Zprav90,mapZprav90]=imread([readTomka, 'prav-90', en]);
[Zprav135,mapZprav135]=imread([readTomka, 'prav-135', en]);
[Zprav180,mapZprav180]=imread([readTomka, 'prav-prav', en]);
[Zprav225,mapZprav225]=imread([readTomka, 'prav-liv', en]);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Z00=rgb2gray(Z00);
Z045=rgb2gray(Z045);
Z090=rgb2gray(Z090);
Z0135=rgb2gray(Z0135);
Z0180=rgb2gray(Z0180);
Z0225=rgb2gray(Z0225);

Z450=rgb2gray(Z450);
Z4545=rgb2gray(Z4545);
Z4590=rgb2gray(Z4590);
Z45135=rgb2gray(Z45135);
Z45180=rgb2gray(Z45180);
Z45225=rgb2gray(Z45225);

Z900=rgb2gray(Z900);
Z9045=rgb2gray(Z9045);
Z9090=rgb2gray(Z9090);
Z90135=rgb2gray(Z90135);
Z90180=rgb2gray(Z90180);
Z90225=rgb2gray(Z90225);

Zprav0=rgb2gray(Zprav0);
Zprav45=rgb2gray(Zprav45);
Zprav90=rgb2gray(Zprav90);
Zprav135=rgb2gray(Zprav135);
Zprav180=rgb2gray(Zprav180);
Zprav225=rgb2gray(Zprav225);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Z00=double(Z00);
Z090=double(Z090);
Z045=double(Z045);
Z0135=double(Z0135);
Z0180=double(Z0180);
Z0225=double(Z0225);

Z900=double(Z900);
Z9090=double(Z9090);
Z9045=double(Z9045);
Z90135=double(Z90135);
Z90180=double(Z90180);
Z90225=double(Z90225);

Z450=double(Z450);
Z4590=double(Z4590);
Z4545=double(Z4545);
Z45135=double(Z45135);
Z45180=double(Z45180);
Z45225=double(Z45225);

Zprav0=double(Zprav0);
Zprav90=double(Zprav90);
Zprav45=double(Zprav45);
Zprav135=double(Zprav135);
Zprav180=double(Zprav180);
Zprav225=double(Zprav225);

Zprav0=Zprav0./(2);
Zprav90=(Zprav90./(2));
Zprav45=(Zprav45)./(2);
Zprav135=(Zprav135)./(2);
Zprav180=(Zprav180)./(2);
Zprav225=(Zprav225)./(2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2 - розрахунок параметр╕в вектора Стокса 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Розрахунок параметр╕в Стокса S1-S4 (на вход╕ 0);
S10=Z00+Z090;
S20=(Z00-Z090);
S30=(Z045-Z0135);
S40=(Z0180-Z0225);
% Розрахунок параметр╕в Стокса S1-S4 (на вход╕ 45);
S145=(Z450+Z4590);
S245=(Z450-Z4590);
S345=(Z4545-Z45135);
S445=(Z45180-Z45225);
% Розрахунок параметр╕в Стокса S1-S4 (на вход╕ 90);
S190=(Z900+Z9090);
S290=(Z900-Z9090);
S390=(Z9045-Z90135);
S490=(Z90180-Z90225);
% Розрахунок параметр╕в Стокса S1-S4 (на вход╕ prav);
S1prav=(Zprav0+Zprav90);
S2prav=(Zprav0-Zprav90);
S3prav=(Zprav45-Zprav135);
S4prav=(Zprav180-Zprav225);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2 - розрахунок Матриц╕ Мюллера 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

M11k = (S10 + S190)/2;
M12k = (S10 - S190)/2;
M13k = (S145 - M11k);
M14k = (S1prav - M11k);


M21k = (S20 + S290)/2;
M22k = (S20 - S290)/2;
M23k = (S245 - M21k);
M24k = (S2prav - M21k);

M31k = (S30 + S390)/2;
M32k = (S30 - S390)/2;
M33k = (S345 - M31k);
M34k = (S3prav - M31k);

M41k = (S40 + S490)/2;
M42k = (S40 - S490)/2;
M43k = (S445 - M41k);
M44k = (S4prav - M41k);  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MM11max = max(max(M11k));
MM11=M11k;

M11=(M11k./MM11);
M12=(M12k./MM11);
M13=(M13k./MM11);
M14=(M14k./MM11);

M21=(M21k./MM11);
M22=(M22k./MM11);
M23=(M23k./MM11);
M24=(M24k./MM11);

M31=(M31k./MM11);
M32=(M32k./MM11);
M33=(M33k./MM11);
M34=(M34k./MM11);

M41=(M41k./MM11);
M42=(M42k./MM11);
M43=(M43k./MM11);
M44=(M44k./MM11);
       
[m,n] = size(M11);
for i=1:m
    for j=1:n
        
            if     (M12(i,j) > 1)  M12(i,j) = 1;
            elseif (M12(i,j) < -1) M12(i,j) = -1;  
            end
            if     (M13(i,j) > 1)  M13(i,j) = 1;
            elseif (M13(i,j) < -1) M13(i,j) = -1;  
            end
            if     (M14(i,j) > 1)  M14(i,j) = 1;
            elseif (M14(i,j) < -1) M14(i,j) = -1;  
            end
            
            if     (M21(i,j) > 1)  M21(i,j) = 1;
            elseif (M21(i,j) < -1) M21(i,j) = -1;  
            end
            if     (M22(i,j) > 1)  M22(i,j) = 1;
            elseif (M22(i,j) < -1) M22(i,j) = -1;  
            end
            if     (M23(i,j) > 1)  M23(i,j) = 1;
            elseif (M23(i,j) < -1) M23(i,j) = -1;  
            end
            if     (M24(i,j) > 1)  M24(i,j) = 1;
            elseif (M24(i,j) < -1) M24(i,j) = -1;  
            end
            
            if     (M31(i,j) > 1)  M31(i,j) = 1;
            elseif (M31(i,j) < -1) M31(i,j) = -1;  
            end
            if     (M32(i,j) > 1)  M32(i,j) = 1;
            elseif (M32(i,j) < -1) M32(i,j) = -1;  
            end
            if     (M33(i,j) > 1)  M33(i,j) = 1;
            elseif (M33(i,j) < -1) M33(i,j) = -1;  
            end
            if     (M34(i,j) > 1)  M34(i,j) = 1;
            elseif (M34(i,j) < -1) M34(i,j) = -1;  
            end
            
            if     (M41(i,j) > 1)  M41(i,j) = 1;
            elseif (M41(i,j) < -1) M41(i,j) = -1;  
            end
            if     (M42(i,j) > 1)  M42(i,j) = 1;
            elseif (M42(i,j) < -1) M42(i,j) = -1;  
            end
            if     (M43(i,j) > 1)  M43(i,j) = 1;
            elseif (M43(i,j) < -1) M43(i,j) = -1;  
            end
            if     (M44(i,j) > 1)  M44(i,j) = 1;
            elseif (M44(i,j) < -1) M44(i,j) = -1;  
            end
            
    end
end


cd(saveTomka);

 figure('name','Матр.Мюллера(gray)','units','normalized','outerposition',[0 0 1 1],'Color','white')
    subplot (4,4,1);   imshow(M11, 'DisplayRange', [-1 1]); colormap (gray); colorbar; title ('M11','Color','b')
    subplot (4,4,2);   imshow(M12, 'DisplayRange', [-1 1]); colormap (gray); colorbar; title ('M12','Color','b')
    subplot (4,4,3);   imshow(M13, 'DisplayRange', [-1 1]); colormap (gray); colorbar; title ('M13','Color','b')
    subplot (4,4,4);   imshow(M14, 'DisplayRange', [-1 1]); colormap (gray); colorbar; title ('M14','Color','b')
    
    subplot (4,4,5);   imshow(M21, 'DisplayRange', [-1 1]); colormap (gray); colorbar; title ('M21','Color','b')
    subplot (4,4,6);   imshow(M22, 'DisplayRange', [-1 1]); colormap (gray); colorbar; title ('M22','Color','b')
    subplot (4,4,7);   imshow(M23, 'DisplayRange', [-1 1]); colormap (gray); colorbar; title ('M23','Color','b')
    subplot (4,4,8);   imshow(M24, 'DisplayRange', [-1 1]); colormap (gray); colorbar; title ('M24','Color','b')
    
    subplot (4,4,9);   imshow(M31, 'DisplayRange', [-1 1]); colormap (gray); colorbar; title ('M31','Color','b')
    subplot (4,4,10);  imshow(M32, 'DisplayRange', [-1 1]); colormap (gray); colorbar; title ('M32','Color','b')
    subplot (4,4,11);  imshow(M33, 'DisplayRange', [-1 1]); colormap (gray); colorbar; title ('M33','Color','b')
    subplot (4,4,12);  imshow(M34, 'DisplayRange', [-1 1]); colormap (gray); colorbar; title ('M34','Color','b')
    
    subplot (4,4,13);  imshow(M41, 'DisplayRange', [-1 1]); colormap (gray); colorbar; title ('M41','Color','b')
    subplot (4,4,14);  imshow(M42, 'DisplayRange', [-1 1]); colormap (gray); colorbar; title ('M42','Color','b')
    subplot (4,4,15);  imshow(M43, 'DisplayRange', [-1 1]); colormap (gray); colorbar; title ('M43','Color','b')
    subplot (4,4,16);  imshow(M44, 'DisplayRange', [-1 1]); colormap (gray); colorbar; title ('M44','Color','b')
    
        pause(0.0001);
        frame_h = get(handle(gcf),'JavaFrame');
        set(frame_h,'Maximized',1);
        img = getframe(gcf); imwrite(img.cdata, ['Muller-matrix', '(gray).jpeg']); pause(0.1)  
    
        pause (1);
        
    figure('name','Матр.Мюллера(jet)','units','normalized','outerposition',[0 0 1 1],'Color','white')
    subplot (4,4,1);   imshow(M11, 'DisplayRange', [-1 1]); colormap (jet); colorbar; title ('M11','Color','b')
    subplot (4,4,2);   imshow(M12, 'DisplayRange', [-1 1]); colormap (jet); colorbar; title ('M12','Color','b')
    subplot (4,4,3);   imshow(M13, 'DisplayRange', [-1 1]); colormap (jet); colorbar; title ('M13','Color','b')
    subplot (4,4,4);   imshow(M14, 'DisplayRange', [-1 1]); colormap (jet); colorbar; title ('M14','Color','b')
    
    subplot (4,4,5);   imshow(M21, 'DisplayRange', [-1 1]); colormap (jet); colorbar; title ('M21','Color','b')
    subplot (4,4,6);   imshow(M22, 'DisplayRange', [-1 1]); colormap (jet); colorbar; title ('M22','Color','b')
    subplot (4,4,7);   imshow(M23, 'DisplayRange', [-1 1]); colormap (jet); colorbar; title ('M23','Color','b')
    subplot (4,4,8);   imshow(M24, 'DisplayRange', [-1 1]); colormap (jet); colorbar; title ('M24','Color','b')
    
    subplot (4,4,9);   imshow(M31, 'DisplayRange', [-1 1]); colormap (jet); colorbar; title ('M31','Color','b')
    subplot (4,4,10);  imshow(M32, 'DisplayRange', [-1 1]); colormap (jet); colorbar; title ('M32','Color','b')
    subplot (4,4,11);  imshow(M33, 'DisplayRange', [-1 1]); colormap (jet); colorbar; title ('M33','Color','b')
    subplot (4,4,12);  imshow(M34, 'DisplayRange', [-1 1]); colormap (jet); colorbar; title ('M34','Color','b')
    
    subplot (4,4,13);  imshow(M41, 'DisplayRange', [-1 1]); colormap (jet); colorbar; title ('M41','Color','b')
    subplot (4,4,14);  imshow(M42, 'DisplayRange', [-1 1]); colormap (jet); colorbar; title ('M42','Color','b')
    subplot (4,4,15);  imshow(M43, 'DisplayRange', [-1 1]); colormap (jet); colorbar; title ('M43','Color','b')
    subplot (4,4,16);  imshow(M44, 'DisplayRange', [-1 1]); colormap (jet); colorbar; title ('M44','Color','b')
    
        pause(0.0001);
        frame_h = get(handle(gcf),'JavaFrame');
        set(frame_h,'Maximized',1);
        img = getframe(gcf); imwrite(img.cdata, ['Muller-matrix', '(jet).jpeg']); pause(0.1)  
        
        close all;