
function [] = calc_Voxels(x_start, ...
    y_start, ...
    z_start, ...
    segmentSize, ...
    faceAlpha, ...
    edgeColor, ...
    min_Value, ...    
    max_Vaule, ...
    scale_Value)

% -------------------------------------------------------------------------
% x_start       - вершина для старта вырезки с Х координаты 
% y_start       - вершина для старта вырезки с Y координаты
% z_start       - вершина для старта вырезки с Z координаты
% segmentSize   - размер сегмента для вырезки куба => любое число
% faceAlpha     - задают уровни прозрачности для вокселей => задавать  0.5
% edgeColor     - границы вокселей, можно изменить это значение на цвет. Либо edgeColor='none';
% min_Value     - мінімальне значення для вибірки
% max_Value     - максимальне значенння для вибірки
% scale_Value   - размер отображемого вокселя для варинта визуализоции 2 => от 0 до 1
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
cMap        = parula(250); % parula(250) создаёт цветовую карту из 250 цветов. parula — это одна из предустановленных цветовых карт MATLAB, которая плавно меняется от синего к жёлтому.    
fontSize    = 15;          % размер шрифт
% -------------------------------------------------------------------------

    % -------------------------------------------------------------------------
    pathForRead  = 'D:\OneDrive\CALCULATIONS\Samples';                     % директива где хранятся образцы
    pathForSave  = 'D:\OneDrive\CALCULATIONS';                             % директива для сохранения
    pathForCode  = 'C:\Users\User\Documents\MATLAB'                        % директива c програмамми
    samples      = {'test-3d', 'Ликвар', 'Мозг', 'Миокард'};               % образцы биологических тканей
    examples     = {'em22', 'em23', 'em24','em33','em34','em44'};          % массивы
    % -------------------------------------------------------------------------
     global ThreeD_Image; 
     cd (pathForCode); 
     pause (0.5);

        % -----------------------------------------------------------------
        % -----------------------------------------------------------------
        for i = 1 : 1%numel(samples)                                         
        name = char(samples(i));
        cd (pathForSave); mkdir (name); 
        cd ([pathForSave, '\', name, '\']);
            for j = 1 : 1%numel(examples)                                         % прохождение по видам(подпапкам)
                example = char(examples (j));
                mkdir (example);
                savePath = [pathForSave, '\', name, '\', example, '\'];
                readPath = [pathForRead, '\', name, '\'];
                ThreeD_Image = load([readPath, '\', example, '.mat']);
                x_end = x_start + segmentSize;
                y_end = y_start + segmentSize;
                z_end = z_start + segmentSize;

                IM_cube = ThreeD_Image.tosave(x_start:x_end, y_start:y_end, z_start:z_end);

                % -----------
                % ВАРІАНТ #01
                figHandle = cFigure;
                title('Voxel and slice plotting');
                xlabel('J - columns'); ylabel('I - rows'); zlabel('K - slices'); hold on;
                       % Setting up indices for I direction slices
                   S=round(size(IM_cube,1)./2);                                  %S election of middle slice
                   L_plot=false(size(IM_cube)); L_plot(S,:,:)=1;
                   indPatch=find(L_plot);
                   [F,V,C]=im2patch(IM_cube,indPatch,'si');                      % Creating patch data for y mid-voxel slices
                   gpatch(F,V,C,'none',faceAlpha);
                       % Setting up indices for J direction slices
                   S=round(size(IM_cube,2)./2);                                  % Selection of middle slice
                   L_plot=false(size(IM_cube)); L_plot(:,S,:)=1;
                   indPatch=find(L_plot);
                   [F,V,C]=im2patch(IM_cube,indPatch,'sj');                      % Creating patch data for x mid-voxel slices
                   gpatch(F,V,C,'none',faceAlpha);
                       % Setting up indices for K direction slices
                   S=round(size(IM_cube,3)./2);                                  % Selection of middle slice
                   L_plot=false(size(IM_cube)); L_plot(:,:,S)=1;
                   indPatch=find(L_plot);
                   [F,V,C]=im2patch(IM_cube,indPatch,'sk');                      % Creating patch data for z mid-voxel slices
                   gpatch(F,V,C,'none',faceAlpha);
                
                % Setting up indices for voxels to plot
                L_mask = IM_cube >= min_Value & IM_cube <= max_Value;
                [F,V,C] = im2patch(IM_cube,L_mask,'vb');                          % Creating patch data for selection of high voxels
                gpatch(F,V,C);
                colormap(cMap); colorbar; clim([min(IM_cube(:)) max(IM_cube(:))]);
                axisGeom(gca,fontSize); 
                camlight headlight;
                drawnow;
                   for ang = 0 : 10 : 360
                       view(ang, 30);
                       pause(0.1);
                       outputFileName = [example, '-', num2str(ang), 'deg.png'];
                       outputFilePath = fullfile(savePath, outputFileName);
                       saveas(figHandle, outputFilePath);
                    end
                close(figHandle);
                pause(0.1);
                % -----------

                % -----------
                % ВАРІАНТ #02
                % Using the function |scalePatch| patch data can be shrunk to aid
                % visualisation (can be a tool to avoid memory costly transparency for instance).  
                L_mask = IM_cube >= min_Value & IM_cube <= max_Value;
                [Ev,Vv,Cv]  = im2patch(IM_cube,L_mask,'h');            % This creates a hexahedral element for each voxel
                [Evs,Vvs]   = scalePatch(Ev,Vv,scale_Value);           % Apply voxel element scaling
                [Fvs,Cvs]   = element2patch(Evs,Cv);                   % Convert to quad faces for plotting
                 
                figHandle = cFigure;
                title('Scaled (shrunk) patch data');
                xlabel('J - columns'); ylabel('I - rows'); zlabel('K - slices'); hold on;
                gpatch(Fvs,Vvs,Cvs);
                colormap(cMap); colorbar; clim([min(Cvs(:)) max(Cvs(:))]);
                axisGeom(gca,fontSize); 
                camlight headlight;
                drawnow;
                     for ang = 0 : 10 : 360
                         view(ang, 30);
                         pause(0.1);
                         outputFileName = [example, '-', num2str(ang), 'deg.png'];
                         outputFilePath = fullfile(savePath, outputFileName);
                         saveas(figHandle, outputFilePath);
                     end
                 close(figHandle);
                 pause(0.1);
                 % -----------

            end
        end
        %-----------------------------------------------------------------
        %-----------------------------------------------------------------


end
