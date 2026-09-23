function viz_block3_contours(D, meta, ctx, CFG)
% VIZ_BLOCK3_CONTOURS  Блок 3 за ТЗ ("2Д Контури, 3Д контури"), ОДНІЄЮ
%   фігурою (2x2): [ 2D контур модуля | 2D контур аргументу ;
%                     3D контур модуля | 3D контур аргументу ].
%   Та сама логіка ліній/підписів/згладжування, що й viz_sections.m (2D) і
%   viz_contour3d.m (3D) — спільні функції з core/ (tp_contour_levels,
%   tp_format_level), щоб виправлення діяли скрізь одразу.

if isfield(CFG,'style'), S = viz_style(CFG.style); else, S = viz_style(); end
nL = CFG.viz.contourLevels;
smoothPx = 0; if isfield(CFG.viz,'contourSmoothPx'), smoothPx = CFG.viz.contourSmoothPx; end

for c = 1:numel(CFG.viz.colormaps)
    cmap = CFG.viz.colormaps{c};
    fig = figure('Color','w','Visible','off','Position',[80 80 1300 1150]);
    S.light(fig);

    contour2DPanel(subplot(2,2,1), meta.x, meta.y, D.mod, cmap, nL, meta, meta.modLabel, ...
                   sprintf('2D contour — module  %s', meta.modLabel), S, smoothPx);
    contour2DPanel(subplot(2,2,2), meta.x, meta.y, D.arg, cmap, nL, meta, meta.argLabel, ...
                   sprintf('2D contour — argument  %s', meta.argLabel), S, smoothPx);
    contour3DPanel(subplot(2,2,3), meta.x, meta.y, D.mod, cmap, nL, meta, meta.modLabel, ...
                   sprintf('3D contour — module  %s', meta.modLabel), S, smoothPx);
    contour3DPanel(subplot(2,2,4), meta.x, meta.y, D.arg, cmap, nL, meta, meta.argLabel, ...
                   sprintf('3D contour — argument  %s', meta.argLabel), S, smoothPx);

    sgtitle(sprintf('%s  \\cdot  Block 3: 2D + 3D contours  [%s]', meta.titlePrefix, cmap), ...
            'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
    tp_save_figure(fig, CFG, ctx.parts, sprintf('_block3_%s_%s', ctx.name, cmap));
end
end

% ------------------------------------------------------------------------
function contour2DPanel(ax, x, y, Z, cmap, nL, meta, cbLabel, ttl, S, smoothPx)
Zc = tp_smooth2(Z, smoothPx);
[lo, hi, levels] = tp_contour_levels(Zc, nL);
[C,~] = contour(ax, x, y, Zc, levels, 'LineWidth',1.2);
colormap(ax, cmap); caxis(ax,[lo hi]); axis(ax,'image'); set(ax,'YDir','normal');
cb = colorbar(ax); cb.Label.String = cbLabel; cb.Color = S.ink;
cb.Ticks = levels; cb.TickLabels = arrayfun(@tp_format_level, levels, 'UniformOutput', false);
labelContours2D(ax, C, min(x), max(x), min(y), max(y));
if smoothPx > 0, ttl = sprintf('%s  (smoothed \\sigma=%.0fpx)', ttl, smoothPx); end
xlabel(ax, meta.xlabel,'FontSize',S.labelSize); ylabel(ax, meta.ylabel,'FontSize',S.labelSize);
title(ax, ttl,'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
S.apply(ax);
end

% ------------------------------------------------------------------------
function contour3DPanel(ax, x, y, Z, cmap, nL, meta, cbLabel, ttl, S, smoothPx)
Zc = tp_smooth2(Z, smoothPx);
[lo, hi, levels] = tp_contour_levels(Zc, nL);
[C,~] = contour3(ax, x, y, Zc, levels, 'LineWidth',1.2);
colormap(ax, cmap); caxis(ax,[lo hi]); view(ax, 45, 30); grid(ax,'on');
hold(ax,'on');
labelContours3D(ax, C, min(x), min(y), max(y));
hold(ax,'off');
cb = colorbar(ax); cb.Label.String = cbLabel; cb.Color = S.ink;
cb.Ticks = levels; cb.TickLabels = arrayfun(@tp_format_level, levels, 'UniformOutput', false);
xlabel(ax, meta.xlabel,'FontSize',S.labelSize); ylabel(ax, meta.ylabel,'FontSize',S.labelSize);
zlabel(ax, cbLabel,'FontSize',S.labelSize);
if smoothPx > 0, ttl = sprintf('%s  (smoothed \\sigma=%.0fpx)', ttl, smoothPx); end
title(ax, ttl,'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
S.apply(ax);
end

% ------------------------------------------------------------------------
function [lv, VX, VY] = collectContourVertices(C)
i = 1; lv = []; VX = {}; VY = {};
while i < size(C,2)
    lvl = C(1,i); n = C(2,i); seg = C(:, i+1:i+n);
    j = find(abs(lv - lvl) < 1e-9, 1);
    if isempty(j)
        lv(end+1) = lvl;  VX{end+1} = seg(1,:);  VY{end+1} = seg(2,:); %#ok<AGROW>
    else
        VX{j} = [VX{j}, seg(1,:)];  VY{j} = [VY{j}, seg(2,:)];
    end
    i = i + n + 1;
end
[lv, order] = sort(lv);  VX = VX(order);  VY = VY(order);
end

% ------------------------------------------------------------------------
function labelContours2D(ax, C, xlo, xhi, ylo, yhi)
% Колонка чорних підписів біля лівого краю + тонка лінія-вказівник до
% фактичної точки на лінії (однозначніше за колір-у-колір).
[lv, VX, VY] = collectContourVertices(C);
L = numel(lv);
labelX = xlo + 0.08*(xhi - xlo);
hold(ax,'on');
for j = 1:L
    ty = ylo + (j - 0.5)/L * (yhi - ylo);
    [~, mi] = min(abs(VY{j} - ty));
    tx = VX{j}(mi); tyPt = VY{j}(mi);
    plot(ax, [labelX tx], [ty tyPt], '-', 'Color',[0.25 0.25 0.25], 'LineWidth',0.7, 'HandleVisibility','off');
    plot(ax, tx, tyPt, 'o', 'MarkerSize',4, 'MarkerFaceColor','k', 'MarkerEdgeColor','k', 'HandleVisibility','off');
    text(ax, labelX, ty, tp_format_level(lv(j)), 'FontSize',10, ...
         'FontWeight','bold', 'Color','k', 'BackgroundColor','w', ...
         'EdgeColor',[0.3 0.3 0.3], 'Margin',2, 'HorizontalAlignment','center', 'Clipping','on');
end
end

% ------------------------------------------------------------------------
function labelContours3D(ax, C, labelX, ylo, yhi)
% Те саме в 3D: колонка при x=labelX на висоті z=рівень, plot3-вказівник.
[lv, VX, VY] = collectContourVertices(C);
L = numel(lv);
for j = 1:L
    ty = ylo + (j - 0.5)/L * (yhi - ylo);
    [~, mi] = min(abs(VY{j} - ty));
    tx = VX{j}(mi); tyPt = VY{j}(mi); z = lv(j);
    plot3(ax, [labelX tx], [ty tyPt], [z z], '-', 'Color',[0.25 0.25 0.25], 'LineWidth',0.7, 'HandleVisibility','off');
    plot3(ax, tx, tyPt, z, 'o', 'MarkerSize',4, 'MarkerFaceColor','k', 'MarkerEdgeColor','k', 'HandleVisibility','off');
    text(ax, labelX, ty, z, tp_format_level(lv(j)), 'FontSize',9, ...
         'FontWeight','bold', 'Color','k', 'BackgroundColor','w', ...
         'EdgeColor',[0.3 0.3 0.3], 'Margin',1.5, 'HorizontalAlignment','center', 'Clipping','on');
end
end
