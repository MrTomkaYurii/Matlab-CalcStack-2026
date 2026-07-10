function POLAR_OUT = calc_To_Polar_Coordinates(correlation_matrix, ...
    work_layer, ...
    saveTomka, ...
    name)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% перев╕д в POLAR_OUT полярну систему координат
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% correlation_matrix                  %%% двовим╕рна автокреляц╕йна функц╕я
% work_layer                          %%% робочий шар
% saveTomka                           %%% шлях до збереження
% name                                %%% ╕мя анал╕зу╓мого зображення  

cd (saveTomka); pause(1);
[M, N, C]=size(correlation_matrix);
RAD=floor(sqrt((M/2)^2+(N/2)^2));

for i=drange(1,RAD)
    for j=drange(1,360)
        [X, Y]=(pol2cart((j-1)*2*pi/360,i-1));
        X=X+M/2;
        Y=Y+N/2;
        if(X>=0 && X<=M && Y<=N && Y>=0)
        X=round(X);
        Y=round(Y);
        X=X+(X==0);
        Y=Y+(Y==0);
        
        if C>1
        POLAR_OUT(i,j,:)= correlation_matrix(X,Y,:);
        else
        POLAR_OUT(i,j)= correlation_matrix(X,Y);            
        end
        
        end
    end
end

[m,n] = size(POLAR_OUT);
POLAR_OUT_RAZMERU = zeros (1,n); 
for j=1:n
    for i=m:-1:1
        if POLAR_OUT (i,j) ~= 0
        POLAR_OUT_RAZMERU(1,j) = i;
        break
        end
    end
end



[mm,nn]         =   size(POLAR_OUT);
POLAR_OUT_VIZ   =   ones (mm,nn); 
for kk = 1 : nn
    
    for ii = mm : -1 : 1
        if POLAR_OUT(ii,kk) == 0
            continue             
        else
            stop = ii; 
            break
        end
    end
    
    for ii = 1:stop
        POLAR_OUT_VIZ(ii,kk) = POLAR_OUT(ii,kk);             
    end
end

        figure('name',['2D-AKF in polar coordinates'],'units','normalized','outerposition',[0 0 1 1],'Color','white')
        imshow(POLAR_OUT_VIZ, 'DisplayRange', [min(min(POLAR_OUT)) max(max(POLAR_OUT))]); colormap (jet); colorbar;
        xlabel ('Кут, град')
        ylabel ('Рад╕ус, п╕ксел╕')
        pause(0.0001);
        frame_h = get(handle(gcf),'JavaFrame');
        set(frame_h,'Maximized',1);
        pause(1);
        img = getframe(gcf); imwrite(img.cdata, [ name,' - 2D-AKF (jet) in polar coordinates', '.jpeg']); pause(1);
 
        figure('name',['2D-AKF in polar coordinates'],'units','normalized','outerposition',[0 0 1 1],'Color','white')
        imshow(POLAR_OUT_VIZ, 'DisplayRange', [min(min(POLAR_OUT)) max(max(POLAR_OUT))]); colormap (gray); colorbar;
        xlabel ('Кут, град')
        ylabel ('Рад╕ус, п╕ксел╕')
        pause(0.0001);
        frame_h = get(handle(gcf),'JavaFrame');
        set(frame_h,'Maximized',1);
        pause(1);
        img = getframe(gcf); imwrite(img.cdata, [ name,' - 2D-AKF (gray) in polar coordinates', '.jpeg']); pause(1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
assignin('base','POLAR_OUT',POLAR_OUT)
assignin('base','POLAR_OUT_RAZMERU',POLAR_OUT_RAZMERU)

    close all
    pause (2)
end
