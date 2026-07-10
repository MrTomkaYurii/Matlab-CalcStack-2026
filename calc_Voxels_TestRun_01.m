clear; close all; clc;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Example: Introduction to using im2patch for voxel plotting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %parula(250) создаёт цветовую карту из 250 цветов. parula — это одна из предустановленных цветовых карт MATLAB, которая плавно меняется от синего к жёлтому.
        cMap=parula(250);       
        
        %faceAlpha1 и faceAlpha2 задают уровни прозрачности для вокселей. 
        %faceAlpha1 = 1 означает, что грани полностью непрозрачные, тогда как faceAlpha2 = 0.5 делает их полупрозрачными.
        faceAlpha1=1;
        faceAlpha2=0.5;

        %воксели, которые вы визуализируете, не будут иметь видимых границ. Если вы хотите видеть границы вокселей, можно изменить это значение на цвет, например:
        edgeColor1='none';
        edgeColor2='none';
        fontSize=15;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Simulating an image
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        M=rand(50,50,50);

x_start = 1;
y_start = 1;
z_start = 1;
x_end = x_start + 49;
y_end = y_start + 49;
z_end = z_start + 49;
M_cube = M(x_start:x_end, y_start:y_end, z_start:z_end);

        % Создание линейных индексов для всех элементов куба
        indPatch = 1:numel(M_cube);
        %Создаются линейные индексы для всех элементов массива M. numel(M) возвращает общее количество элементов в массиве M.
        [F,V,C]=im2patch(M_cube,indPatch,'v');
            cFigure;
            title('patch type: v');
            xlabel('J - columns'); ylabel('I - rows'); zlabel('K - slices'); hold on;
            gpatch(F,V,C,'k',faceAlpha2);
                    % gpatch используется для отображения полигонов. Здесь F — это индексы граней, V — координаты вершин, C — цвета граней. 
                    % Параметр 'k' задает черный цвет для ребер (границ) полигонов, а faceAlpha2 задает прозрачность граней.
            colormap(cMap); caxis([min(M_cube(:)) max(M_cube(:))]); colorbar;
            axisGeom(gca,fontSize); camlight headlight;
            drawnow;
                    % axisGeom настраивает геометрию осей и задает размер шрифта для подписей осей. camlight headlight добавляет освещение к 
                    % фигуре для лучшей визуализации трехмерных объектов. drawnow обновляет график.
% ---------------------------------------------------------------------------
%Creating patch data for voxel display with shared vertices and faces removed
        [F,V,C]=im2patch(M,indPatch,'vu');
            cFigure;
            title('patch type: vu');
                    % Функция im2patch преобразует трехмерный массив данных в набор полигонов (patches). Параметр 'vu' указывает, что будут созданы 
                    % полигоны для всех вокселей, указанных в indPatch, с уникальными вершинами. Это позволяет избежать дублирования вершин и создает 
                    % более оптимальную структуру данных для отображения.

                    %'vu': Параметр 'vu' в функции im2patch указывает на создание полигонов с уникальными вершинами. Это означает, что каждая вершина 
                    % в наборе данных будет уникальной и не будет дублироваться. Это полезно для оптимизации структуры данных и уменьшения объема памяти, 
                    % необходимого для хранения вершин и граней.
            xlabel('J - columns'); ylabel('I - rows'); zlabel('K - slices'); hold on;
            gpatch(F,V,C,'k',faceAlpha2);
            colormap(cMap); caxis([min(M(:)) max(M(:))]); colorbar;
            axisGeom(gca,fontSize); camlight headlight;
            drawnow;
% ---------------------------------------------------------------------------
%Creating patch data for voxel display with only non-shared faces and vertices
        [F,V,C]=im2patch(M,indPatch,'vb');
        cFigure;
        title('patch type: vb');
        xlabel('J - columns');ylabel('I - rows'); zlabel('K - slices'); hold on;
        gpatch(F,V,C,'k',faceAlpha2);
        colormap(cMap); caxis([min(M(:)) max(M(:))]); colorbar;
        axisGeom(gca,fontSize); camlight headlight;
        drawnow;
% ---------------------------------------------------------------------------
%im2patch for Slice Plotting
        cFigure;
        title('patch type: si, sj, sk');
        xlabel('J - columns');ylabel('I - rows'); zlabel('K - slices'); hold on;      
            %Setting up indices for I direction slices
            S=round(size(M,1)./2); %Selection of middle slice
            L_plot=false(size(M)); L_plot(S,:,:)=1;
            indPatch=find(L_plot);
            [F,V,C]=im2patch(M,indPatch,'si'); %Creating patch data for y mid-voxel slices
            gpatch(F,V,C);
            %Setting up indices for J direction slices
            S=round(size(M,2)./2); %Selection of middle slice
            L_plot=false(size(M)); L_plot(:,S,:)=1;
            indPatch=find(L_plot);
            [F,V,C]=im2patch(M,indPatch,'sj'); %Creating patch data for x mid-voxel slices
            gpatch(F,V,C);
            %Setting up indices for Z direction slices
            S=round(size(M,3)./2); %Selection of middle slice
            L_plot=false(size(M)); L_plot(:,:,S)=1;
            indPatch=find(L_plot);
            [F,V,C]=im2patch(M,indPatch,'sk'); %Creating patch data for z mid-voxel slices
            gpatch(F,V,C); 
        colormap(cMap); caxis([min(M(:)) max(M(:))]); colorbar;
        axisGeom(gca,fontSize); camlight headlight;
        drawnow;
% ---------------------------------------------------------------------------
%Comparison to standard MATLAB imagesc function and the patch type MATLAB functions slice and pcolor
        cFigure;
            subplot(2,2,1);
            title('MATLAB imagesc function');
            xlabel('J - columns');ylabel('I - rows'); zlabel('K - slices'); hold on;
            imagesc(M(:,:,S));
            colormap(cMap); caxis([min(M(:)) max(M(:))]);
            axisGeom(gca,fontSize); view(2);
            
            subplot(2,2,2);
            title('MATLAB slice function');
            xlabel('J - columns');ylabel('I - rows'); zlabel('K - slices'); hold on;
            slice(M,[],[],S);
            axisGeom(gca,fontSize);
            colormap(cMap); caxis([min(M(:)) max(M(:))]);
            axisGeom(gca,fontSize); view(2);
            
            subplot(2,2,3);
            title('im2patch function');
            xlabel('J - columns');ylabel('I - rows'); zlabel('K - slices'); hold on;
            gpatch(F,V,C);
            colormap(cMap); caxis([min(M(:)) max(M(:))]);
            axisGeom(gca,fontSize); view(2);
            
            subplot(2,2,4);
            title('MATLAB pcolor function');
            xlabel('J - columns');ylabel('I - rows'); zlabel('K - slices'); hold on;
            pcolor(M(:,:,S));
            colormap(cMap); caxis([min(M(:)) max(M(:))]);
            axisGeom(gca,fontSize); view(2);
        drawnow;
% ---------------------------------------------------------------------------
% Creating and plotting combined voxel and slice patch data

       %Simulating 3D image
        [X,Y,Z]=meshgrid(linspace(-4.77,4.77,25));
        phi=(1+sqrt(5))/2;
        M=1/6*(2 - (cos(X + phi*Y) + cos(X - phi*Y) + cos(Y + phi*Z) + cos(Y - phi*Z) + cos(Z - phi*X) + cos(Z + phi*X)));
        %Creating and plotting patch data. Last example illustrates the use of a specific logic description (i.e. a mask) for the voxels of interest
        
        cFigure;
        title('Combined voxel and slice plotting');
        xlabel('J - columns');ylabel('I - rows'); zlabel('K - slices'); hold on;
            % Setting up indices for I direction slices
            S=round(size(M,1)./2); %Selection of middle slice
            L_plot=false(size(M)); L_plot(S,:,:)=1;
            indPatch=find(L_plot);
            [F,V,C]=im2patch(M,indPatch,'si'); %Creating patch data for y mid-voxel slices
            gpatch(F,V,C,'none',faceAlpha2);
            % Setting up indices for J direction slices
            S=round(size(M,2)./2); %Selection of middle slice
            L_plot=false(size(M)); L_plot(:,S,:)=1;
            indPatch=find(L_plot);
            [F,V,C]=im2patch(M,indPatch,'sj'); %Creating patch data for x mid-voxel slices
            gpatch(F,V,C,'none',faceAlpha2);
            % Setting up indices for K direction slices
            S=round(size(M,3)./2); %Selection of middle slice
            L_plot=false(size(M)); L_plot(:,:,S)=1;
            indPatch=find(L_plot);
            [F,V,C]=im2patch(M,indPatch,'sk'); %Creating patch data for z mid-voxel slices
            gpatch(F,V,C,'none',faceAlpha2);
        % Setting up indices for voxels to plot
        L_mask = M>=0.75 & M<=1;
        [F,V,C]=im2patch(M,L_mask,'vb'); %Creating patch data for selection of high voxels
        gpatch(F,V,C);
        colormap(cMap); colorbar; caxis([min(M(:)) max(M(:))]);
        axisGeom(gca,fontSize); camlight headlight;
        drawnow;
% -----------------------------------------------------------------------
% Shrinking patch data through combination with scalePatch function

        % Using the function |scalePatch| patch data can be shrunk to aid
        % visualisation (can be a tool to avoid memory costly transparency for
        % instance).
        
        [Ev,Vv,Cv]=im2patch(M,L_mask,'h'); %This creates a hexahedral element for each voxel
        [Evs,Vvs]=scalePatch(Ev,Vv,0.25); %Apply voxel element scaling
        [Fvs,Cvs]=element2patch(Evs,Cv); %Convert to quad faces for plotting
        %Plotting the voxels
        
        cFigure;
        title('Scaled (shrunk) patch data');
        xlabel('J - columns');ylabel('I - rows'); zlabel('K - slices'); hold on;
        gpatch(Fvs,Vvs,Cvs);
        colormap(cMap); colorbar; caxis([min(Cvs(:)) max(Cvs(:))]);
        axisGeom(gca,fontSize); camlight headlight;
        drawnow;
% -----------------------------------------------------------------------
%Medical image data and coordinate manipulation due to voxel size
        
        % Get a 3D image
        load mri;
        M=squeeze(D); %example image data set
        v=2./[1,1,0.4]; %example voxel size
        %The voxels to display can be specified as a list (vector) of voxels numbers (linear indices) or using a mask (logic array).
        
            %Defining row, column and slice indicices for slice patching
            sliceIndexI=round(size(M,1)/2); %(close to) middle row
            sliceIndexJ=round(size(M,2)/2); %(close to) middle column
            sliceIndexK=round(size(M,3)/2); %(close to) middle slice
            
            %Defining "masks" i.e. logic arrays with ones for voxels of interest
            logicSliceI=false(size(M));
            logicSliceI(sliceIndexI,:,:)=1;
            logicSliceI=logicSliceI & M>0;
            
            logicSliceJ=false(size(M));
            logicSliceJ(:,sliceIndexJ,:)=1;
            logicSliceJ=logicSliceJ & M>0;
            
            logicSliceK=false(size(M));
            logicSliceK(:,:,sliceIndexK)=1;
            logicSliceK=logicSliceK & M>0;
        
        %Defining voxel indices for voxels of interest
        T_low=min(M(:))+((max(M(:))-min(M(:)))/10); %Threshold example
        logicVoxels=(M>T_low);
        logicVoxels(:,1:sliceIndexJ,:)=0;
       
        %Creating patch data The patch data consists of a matrix array defining the faces, a matrix array defining the vertices and a vector for the colour data. The vertices are based on the image coordinates however they are formatted as: [X(:) Y(:) Z(:)]. X relates to columns, Y to rows and Z to slices. Use a function like im2cart , or im2mrcart to convert image to cartesian coordinates.
        
        [Fv,Vv,Cv]=im2patch(M,logicVoxels,'vb');
        [Fx,Vx,Cx]=im2patch(M,logicSliceJ,'sj');
        [Fy,Vy,Cy]=im2patch(M,logicSliceI,'si');
        [Fz,Vz,Cz]=im2patch(M,logicSliceK,'sk');
        
        % Convert image coordinates to cartesian coordinates
        [Vv(:,1),Vv(:,2),Vv(:,3)]=im2cart(Vv(:,2),Vv(:,1),Vv(:,3),v);
        [Vx(:,1),Vx(:,2),Vx(:,3)]=im2cart(Vx(:,2),Vx(:,1),Vx(:,3),v);
        [Vy(:,1),Vy(:,2),Vy(:,3)]=im2cart(Vy(:,2),Vy(:,1),Vy(:,3),v);
        [Vz(:,1),Vz(:,2),Vz(:,3)]=im2cart(Vz(:,2),Vz(:,1),Vz(:,3),v);
       
        cFigure;
        title('MRI visualisation, slices and voxels in cartesian coordinates with aid of voxel size');
        xlabel('X (mm)');ylabel('Y (mm)'); zlabel('Z (mm)'); hold on;
        gpatch(Fv,Vv,Cv,edgeColor1,faceAlpha2);
        gpatch(Fx,Vx,Cx,edgeColor1,faceAlpha1);
        gpatch(Fy,Vy,Cy,edgeColor1,faceAlpha1);
        gpatch(Fz,Vz,Cz,edgeColor1,faceAlpha1);
        colormap(gray(250)); colorbar;
        axisGeom(gca,fontSize); camlight headlight;
        drawnow;
% -----------------------------------------------------------------------
%Combining colormap and RGB driven patch colours

        Cv=(Cv*ones(1,3))./max(Cv(:));
        %Plotting the voxels
        
        cFigure;
        title('MRI visualisation, slices and voxels, colormap and RGB driven respectively');
        xlabel('X (mm)');ylabel('Y (mm)'); zlabel('Z (mm)'); hold on;
        
        %RGB driven
        gpatch(Fv,Vv,Cv,edgeColor1,faceAlpha2);
        
        %Colormap driven
        gpatch(Fx,Vx,Cx,edgeColor1,faceAlpha1);
        gpatch(Fy,Vy,Cy,edgeColor1,faceAlpha1);
        gpatch(Fz,Vz,Cz,edgeColor1,faceAlpha1);
        
        colormap(cMap); colorbar;
        axisGeom(gca,fontSize); camlight headlight;
        drawnow;