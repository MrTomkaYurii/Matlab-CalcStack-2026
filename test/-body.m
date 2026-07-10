en='.bmp';  
[Z00,mapZ00]=imread(['C:\Users\Yurii\Documents\MATLAB\', '0-0', en]);
Z00=rgb2gray(Z00);

% 2D AKF - matrix calculation
CORR_MATRIX_2D = corr_func_2D(Z00(1:301,1:301), [], '', 'test');

% TO POLAR COORDINATES
to_polar_coordinates(CORR_MATRIX_2D, [], '', 'test');

%  AKF-PSD-STAT DIRECTIONS
akf_psd_stat_directions(CORR_MATRIX_2D, POLAR_OUT, 10, [], '', 'test');