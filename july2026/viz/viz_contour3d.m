function viz_contour3d(D, meta, ctx, CFG)
% VIZ_CONTOUR3D  Подання: контурні лінії у 3D (contour3) для модуля й аргументу.
%   Ті самі рівні, що й у 2D-контурах, але підняті на свою висоту (z = значення).
%   Значення читається по осі z та по колорбару (позначки на рівнях);
%   підписів на лініях немає (у 3D вони б заважали).
%   По одній фігурі на кожну colormap зі списку CFG.viz.colormaps.

S  = viz_style();
nL = CFG.viz.contourLevels;

for c = 1:numel(CFG.viz.colormaps)
    cmap = CFG.viz.colormaps{c};
    fig = figure('Color','w','Visible','off','Position',[80 80 1300 560]); S.light(fig);

    contour3Panel(subplot(1,2,1), meta.x, meta.y, D.mod, cmap, nL, meta, meta.modLabel, ...
                  sprintf('Module contour3  %s', meta.modLabel), S);
    contour3Panel(subplot(1,2,2), meta.x, meta.y, D.arg, cmap, nL, meta, meta.argLabel, ...
                  sprintf('Argument contour3  %s', meta.argLabel), S);

    sgtitle(sprintf('%s  \\cdot  3D contours  [%s]', meta.titlePrefix, cmap), ...
            'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
    tp_save_figure(fig, CFG, ctx.parts, sprintf('%s_contour3d_%s', ctx.name, cmap));
end
end

% ------------------------------------------------------------------------
function contour3Panel(ax, x, y, Z, cmap, nL, meta, cbLabel, ttl, S)
lo = min(Z(:),[],'omitnan'); hi = max(Z(:),[],'omitnan');
if ~(isfinite(lo) && isfinite(hi)), lo=0; hi=1; end
if hi <= lo, hi = lo + 1e-9; end
levels = linspace(lo, hi, nL);
contour3(ax, x, y, Z, levels, 'LineWidth',1.2);
colormap(ax, cmap); caxis(ax,[lo hi]); view(ax, 45, 30); grid(ax,'on');
cb = colorbar(ax); cb.Label.String = cbLabel; cb.Color = S.ink;
cb.Ticks = levels; cb.TickLabels = compose('%.2f', levels(:));
xlabel(ax, meta.xlabel,'FontSize',S.labelSize); ylabel(ax, meta.ylabel,'FontSize',S.labelSize);
zlabel(ax, cbLabel,'FontSize',S.labelSize);
title(ax, ttl,'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
S.apply(ax);
end
