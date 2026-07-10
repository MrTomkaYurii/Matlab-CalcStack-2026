function CORR_MATRIX_2D = calc_Corr_Func_2D(matrix_from_layer, work_layer, saveTomka, name)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2D автокореляц╕йна функц╕я
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd (saveTomka); pause(1);
CORR_MATRIX_2D = xcorr2(matrix_from_layer);
CORR_MATRIX_2D = CORR_MATRIX_2D + abs( min(min(CORR_MATRIX_2D)) );
CORR_MATRIX_2D = CORR_MATRIX_2D./(max(max(CORR_MATRIX_2D)));

assignin('base','CORR_MATRIX_2D',CORR_MATRIX_2D)

    figure('name','2D AUTOCORRELATION FUNCTION','units','normalized','outerposition',[0 0 1 1],'Color','white')
    imshow (CORR_MATRIX_2D); colorbar; colormap(jet);
    title ('2D AUTOCORRELATION FUNCTION','Color','r')
    pause(0.0001);
    frame_h = get(handle(gcf),'JavaFrame');
    set(frame_h,'Maximized',1);
    pause(1);
    img = getframe(gcf); imwrite(img.cdata, [ name,' - 2D-AKF (jet)', '.jpeg']); pause(1);

    figure('name','2D AUTOCORRELATION FUNCTION','units','normalized','outerposition',[0 0 1 1],'Color','white')
    imshow (CORR_MATRIX_2D); colorbar; colormap(gray);
    title ('2D AUTOCORRELATION FUNCTION','Color','r')
    pause(0.0001);
    frame_h = get(handle(gcf),'JavaFrame');
    set(frame_h,'Maximized',1);
    pause(1);
    img = getframe(gcf); imwrite(img.cdata, [ name,' - 2D-AKF (gray)', '.jpeg']); pause(1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% К╕нець
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end