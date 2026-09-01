function viz_contour3d(D, meta, ctx, CFG)
% VIZ_CONTOUR3D  Подання: контурні лінії у 3D (contour3) для модуля й аргументу.
%   Ті самі рівні, що й у 2D-контурах, підняті на свою висоту (z = значення).
%   Лінії рахуються по ЗГЛАДЖЕНОМУ полю (як і 2D-контур, viz_sections.m) —
%   БЕЗ згладжування на реальних (шумних) даних contour3 розсипається на
%   хмару дрібних несумісних фрагментів замість читабельних ліній.
%   Кожен рівень підписаний ПРЯМО НА ЛІНІЇ (на її фактичній висоті z),
%   кольором ЦІЄЇ лінії — щоб число однозначно зіставлялось з кривою,
%   навіть коли кілька рівнів візуально накладаються під цим ракурсом.
%   По одній фігурі на кожну colormap зі списку CFG.viz.colormaps.

S  = viz_style();
nL = CFG.viz.contourLevels;
smoothPx = 0; if isfield(CFG.viz,'contourSmoothPx'), smoothPx = CFG.viz.contourSmoothPx; end

for c = 1:numel(CFG.viz.colormaps)
    cmap = CFG.viz.colormaps{c};
    fig = figure('Color','w','Visible','off','Position',[80 80 1300 560]); S.light(fig);

    contour3Panel(subplot(1,2,1), meta.x, meta.y, D.mod, cmap, nL, meta, meta.modLabel, ...
                  sprintf('Module contour3  %s', meta.modLabel), S, smoothPx);
    contour3Panel(subplot(1,2,2), meta.x, meta.y, D.arg, cmap, nL, meta, meta.argLabel, ...
                  sprintf('Argument contour3  %s', meta.argLabel), S, smoothPx);

    sgtitle(sprintf('%s  \\cdot  3D contours  [%s]', meta.titlePrefix, cmap), ...
            'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
    tp_save_figure(fig, CFG, ctx.parts, sprintf('%s_contour3d_%s', ctx.name, cmap));
end
end

% ------------------------------------------------------------------------
function contour3Panel(ax, x, y, Z, cmap, nL, meta, cbLabel, ttl, S, smoothPx)
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
if smoothPx > 0
    ttl = sprintf('%s  (smoothed \\sigma=%.0fpx)', ttl, smoothPx);
end
title(ax, ttl,'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
S.apply(ax);
end

% ------------------------------------------------------------------------
function labelContours3D(ax, C, labelX, ylo, yhi)
% Один підпис на кожен рівень, У КОЛОНЦІ біля лівого краю (x=labelX, на
% висоті z=рівень), з тонкою лінією-вказівником (plot3) до фактичної точки
% на лінії — простий чорний текст, однозначний навіть коли кілька рівнів
% візуально накладаються під цим ракурсом (замість кольору-в-колір).
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
L = numel(lv);
for j = 1:L
    ty = ylo + (j - 0.5)/L * (yhi - ylo);
    [~, mi] = min(abs(VY{j} - ty));
    tx = VX{j}(mi); tyPt = VY{j}(mi); z = lv(j);
    plot3(ax, [labelX tx], [ty tyPt], [z z], '-', 'Color',[0.25 0.25 0.25], ...
          'LineWidth',0.7, 'HandleVisibility','off');
    plot3(ax, tx, tyPt, z, 'o', 'MarkerSize',4, 'MarkerFaceColor','k', ...
          'MarkerEdgeColor','k', 'HandleVisibility','off');
    text(ax, labelX, ty, z, tp_format_level(lv(j)), 'FontSize',9, ...
         'FontWeight','bold', 'Color','k', 'BackgroundColor','w', ...
         'EdgeColor',[0.3 0.3 0.3], 'Margin',1.5, ...
         'HorizontalAlignment','center', 'Clipping','on');
end
end
