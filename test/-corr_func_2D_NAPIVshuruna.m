function  NAPIVSH_AKF  = corr_func_2D_NAPIVshuruna(INPUT)

% programspath = evalin('base',  'programspath');
            

        CORR_MATRIX_2D = xcorr2(INPUT);
        CORR_MATRIX_2D = CORR_MATRIX_2D + abs( min(min(CORR_MATRIX_2D)) );
        CORR_MATRIX_2D = CORR_MATRIX_2D./(max(max(CORR_MATRIX_2D)));
                    
%         cd(programspath); pause(1); %-------------------------------------
        POLAR_OUT_2D = to_polar_coordinates_NAPIVshuruna(CORR_MATRIX_2D);

                    [m,n] = size(POLAR_OUT_2D);
                    POLAR_WORK = zeros (2*m,180);

                    k=0;
                    for i = 1 : 1 : n/2
                        k = k+1;
                        line1 = POLAR_OUT_2D (:,i);
                        line1 = line1(length(line1):-1:1);
                        line2 = POLAR_OUT_2D (:,i+180);
                        POLAR_WORK (:,k) = [line1;line2];
                    end

                    [Xdim,Ydim] = size(POLAR_WORK);
                    for j = 1 : Ydim
                    X_first(j) = find (POLAR_WORK (:,j)>0.5 , 1, 'first');
                    X_last(j)  = find (POLAR_WORK (:,j)>0.5 , 1, 'last');
                    end

                    napiv_AKF = X_last - X_first;
                    NAPIVSH_AKF = mean(napiv_AKF);
                    
                    plot(NAPIVSH_AKF);

end


