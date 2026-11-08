function draw_algo_schemes(outDir)
% DRAW_ALGO_SCHEMES  Схеми чотирьох алгоритмів двоточкового сканування для
%   шапок Word-файлів статмоментів: schemes\scheme_<OX|OY|XY|generalized>.png
%   r1 — перша точка, r2 — друга; d — крок (у розрахунку d = 1 px).

if nargin < 1, outDir = fullfile(fileparts(mfilename('fullpath')), 'schemes'); end
if ~exist(outDir, 'dir'); mkdir(outDir); end
set(groot, 'DefaultFigureVisible', 'off');
set(groot, 'DefaultTextColor','k', 'DefaultAxesColor','w', 'DefaultAxesXColor','k', 'DefaultAxesYColor','k');

C1 = [0.85 0.20 0.15];  C2 = [0.15 0.35 0.80];  CG = [0.80 0.80 0.80];
ARR = [0.10 0.10 0.10];

% ---- OX, OY, XY: сітка пікселів, r1 у центрі, стрілки до r2 ----
cases = {'OX', [1 0];  'OY', [0 1];  'XY', [1 0; 0 1]};
for c = 1:size(cases, 1)
    fig = figure('Color','w', 'Position',[0 0 1000 420]);  lightTheme(fig);
    % ліва панель: пара точок на кадрі
    ax = axes(fig, 'Position',[0.02 0.04 0.36 0.80]); hold(ax,'on'); axis(ax,'equal','off');
    gridPx(ax, 7, CG);
    r1 = [4 4];
    plot(ax, r1(1), r1(2), 'o', 'MarkerSize',16, 'MarkerFaceColor',C1, 'MarkerEdgeColor','k');
    text(ax, r1(1)-0.35, r1(2)-0.55, 'r_1', 'FontSize',16, 'FontWeight','bold');
    D = cases{c,2};
    for k = 1:size(D,1)
        r2 = r1 + 2*D(k,:);                        % намальовано d = 2 клітинки для наочності
        quiver(ax, r1(1), r1(2), 0.8*(r2(1)-r1(1)), 0.8*(r2(2)-r1(2)), 0, 'Color',ARR, 'LineWidth',2, 'MaxHeadSize',0.8);
        plot(ax, r2(1), r2(2), 'o', 'MarkerSize',16, 'MarkerFaceColor',C2, 'MarkerEdgeColor','k');
        text(ax, r2(1)+0.25, r2(2)+0.35, 'r_2', 'FontSize',16, 'FontWeight','bold');
        if D(k,1); text(ax, mean([r1(1) r2(1)])-0.3, r1(2)-0.5, 'd', 'FontSize',15, 'FontAngle','italic'); end
        if D(k,2); text(ax, r1(1)-0.6, mean([r1(2) r2(2)]), 'd', 'FontSize',15, 'FontAngle','italic'); end
    end
    title(ax, 'кадр: пара точок', 'FontSize',14);
    % права панель: формула
    ax2 = axes(fig, 'Position',[0.42 0.08 0.57 0.84]); axis(ax2,'off');
    switch cases{c,1}
        case 'OX', s = {'f_{ik}(r_1) = f_{ik}(r_1, r_1 + (d, 0))', '', 'карта в координатах r_1 = (x, y)', 'кожен піксель — своя пара'};
        case 'OY', s = {'f_{ik}(r_1) = f_{ik}(r_1, r_1 + (0, d))', '', 'карта в координатах r_1 = (x, y)', 'кожен піксель — своя пара'};
        case 'XY', s = {'f_{ik}(r_1) = f_{ik}(r_1, r_1+(d,0))', '            + f_{ik}(r_1, r_1+(0,d))', '', 'комплексна сума OX + OY (без ділення),', 'потім \div медіана |f_{11}|', 'карта в координатах r_1 = (x, y)'};
    end
    text(ax2, 0, 0.5, s, 'FontSize',14, 'VerticalAlignment','middle');
    exportgraphics(fig, fullfile(outDir, ['scheme_' cases{c,1} '.png']), 'Resolution',150);
    close(fig);
end

% ---- generalized: одне рознесення Δ від УСІХ перших точок -> один піксель Δ-карти ----
fig = figure('Color','w', 'Position',[0 0 1250 460]);  lightTheme(fig);
ax = axes(fig, 'Position',[0.01 0.04 0.32 0.76]); hold(ax,'on'); axis(ax,'equal','off');
gridPx(ax, 7, CG);
dlt = [2 1];
for x = 1:2:5
    for y = 1:2:5
        quiver(ax, x, y, dlt(1), dlt(2), 0, 'Color',ARR, 'LineWidth',1.4, 'MaxHeadSize',0.5);
        plot(ax, x, y, 'o', 'MarkerSize',9, 'MarkerFaceColor',C1, 'MarkerEdgeColor','k');
        plot(ax, x+dlt(1), y+dlt(2), 'o', 'MarkerSize',9, 'MarkerFaceColor',C2, 'MarkerEdgeColor','k');
    end
end
text(ax, 0.3, 7.6, 'усі перші точки r_1, той самий \Delta', 'FontSize',13);
title(ax, 'кадр', 'FontSize',14);
% стрілка між панелями
annotation(fig, 'arrow', [0.35 0.43], [0.5 0.5], 'LineWidth',1.8);
annotation(fig, 'textbox', [0.33 0.53 0.12 0.1], 'String',{'усереднення','по r_1'}, 'FontSize',12, 'EdgeColor','none', 'HorizontalAlignment','center');
% Δ-карта
ax2 = axes(fig, 'Position',[0.48 0.14 0.20 0.72]); hold(ax2,'on'); axis(ax2,'equal');
set(ax2, 'XLim',[-4 4], 'YLim',[-4 4], 'XTick',[-4 0 4], 'YTick',[-4 0 4], 'Box','on', 'FontSize',11);
xline(ax2, 0, ':', 'Color',[0.5 0.5 0.5]); yline(ax2, 0, ':', 'Color',[0.5 0.5 0.5]);
plot(ax2, dlt(1), dlt(2), 's', 'MarkerSize',14, 'MarkerFaceColor',[0.95 0.65 0.10], 'MarkerEdgeColor','k');
plot(ax2, -dlt(1), -dlt(2), 's', 'MarkerSize',14, 'MarkerFaceColor',[1 0.85 0.55], 'MarkerEdgeColor','k');
text(ax2, dlt(1)+0.4, dlt(2)+0.3, '\Delta', 'FontSize',14);
text(ax2, -dlt(1)-1.6, -dlt(2)-0.5, '-\Delta', 'FontSize',14);
xlabel(ax2, '\Deltax (px)'); ylabel(ax2, '\Deltay (px)');
title(ax2, '\Delta-карта', 'FontSize',14);
ax3 = axes(fig, 'Position',[0.70 0.08 0.30 0.84]); axis(ax3,'off');
text(ax3, 0, 0.5, {'|f(\Delta)| = <|f_{ik}(r_1, r_1+\Delta)|>_{r_1}', ...
                   'arg f(\Delta) = кругове середнє:', 'atan2(\Sigma sin, \Sigma cos)', '', ...
                   '\Delta — усі рознесення', '|\Deltax|, |\Deltay| < N  (\Delta \neq 0)', ...
                   '\Delta і -\Delta — дзеркальні'}, 'FontSize',12, 'VerticalAlignment','middle');
exportgraphics(fig, fullfile(outDir, 'scheme_generalized.png'), 'Resolution',150);
close(fig);
fprintf('Схеми: %s\n', outDir);
end

function lightTheme(fig)
try, theme(fig, 'light'); catch, end   % -batch може стартувати в темній темі
end

function gridPx(ax, n, col)
for k = 0.5:1:n+0.5
    plot(ax, [0.5 n+0.5], [k k], '-', 'Color',col);
    plot(ax, [k k], [0.5 n+0.5], '-', 'Color',col);
end
xlim(ax, [0 n+1]); ylim(ax, [0 n+1]);
end
