function viz_an_metric_grid(S, label, unit, outFile, Sty)
% VIZ_AN_METRIC_GRID  Одна метрика -> одна фігура: по панелі на кожну величину Кроку B
%   (LB_{0,90}, LB_{45,135}, CB, rho, LB), вісь X = фазове вікно в градусах (360 = слабкий
%   фільтр -> 45 = найвужче, ЯВНО підписано), вісь Y = значення метрики, лінія на кожен
%   зразок, спільна легенда згори. Панелі з позначеною закономірністю ("тренд" /
%   "розрізняє") мають кольорову рамку й короткий підпис у кутку.
%   ПОРТ серпневого viz_analytics_metric_grid.m (там сітка 4x4 з 16 f_ik).
%   Sty : viz_style(CFG.style).

if isempty(S.elements)
    fprintf('  [viz_an_metric_grid] порожні дані для %s — пропущено.\n', label);
    return;
end

colors = [0.20 0.45 0.75; 0.85 0.35 0.10; 0.30 0.65 0.30; 0.60 0.30 0.70; 0.90 0.75 0.10; 0.30 0.30 0.30];
badgeColor = struct('trend',[0.20 0.60 0.20], 'discrim',[0.85 0.45 0.05], ...
                     'both',[0.75 0.60 0.05], 'none',[0.75 0.75 0.75]);
badgeText  = struct('trend','ТРЕНД', 'discrim','РІЗНИТЬСЯ', 'both','ТРЕНД+РІЗНИТЬСЯ', 'none','');

nE = numel(S.elements);
nC = min(nE, 3);  nR = ceil(nE / nC);
fig = figure('Color','w','Visible','off','Position',[40 40 1400 420*nR+120]);
Sty.light(fig);

for k = 1:nE
    axp = subplot(nR, nC, k);
    elem = S.elements{k};
    series = S.series.(elem);
    badge  = S.badge.(elem);
    bc = badgeColor.(badge);

    hold(axp, 'on');
    for si = 1:size(series,1)
        col = colors(mod(si-1, size(colors,1)) + 1, :);
        plot(axp, S.phaseDeg, series(si,:), 'o-', 'Color', col, ...
             'MarkerFaceColor', col, 'MarkerSize', 5, 'LineWidth', 1.5);
    end
    set(axp, 'XDir', 'reverse');
    if numel(S.phaseDeg) > 1
        xlim(axp, [min(S.phaseDeg)-10, max(S.phaseDeg)+10]);
    end
    set(axp, 'XTick', sort(S.phaseDeg), 'FontSize', 8);   % XTick зростаючий; напрям 360->45 дає XDir=reverse
    xlabel(axp, 'Фазове вікно, град', 'FontSize', 9);
    ylabel(axp, unit, 'FontSize', 9);
    title(axp, tp_an_elem_tex(elem), 'FontSize', 12, 'FontWeight','bold', 'Interpreter','tex');
    Sty.apply(axp);   % білий фон, читабельні підписи (ПОТІМ override рамки під позначку)
    box(axp, 'on');
    set(axp, 'XColor', bc, 'YColor', bc, 'LineWidth', 1.8);

    if ~strcmp(badge, 'none')
        text(axp, 0.97, 0.95, badgeText.(badge), 'Units','normalized', ...
             'HorizontalAlignment','right', 'VerticalAlignment','top', ...
             'FontSize', 7.5, 'FontWeight','bold', 'Color', bc, ...
             'BackgroundColor','w', 'Margin', 1);
    end
end

% спільна легенда (по зразках) окремою малою віссю ЗНИЗУ (згори вона накладалась
% на заголовок sgtitle)
legAx = axes('Position',[0 0.004 1 0.03], 'Visible','off');
hold(legAx, 'on');
for si = 1:numel(S.samples)
    col = colors(mod(si-1, size(colors,1)) + 1, :);
    plot(legAx, NaN, NaN, 'o-', 'Color', col, 'MarkerFaceColor', col, ...
         'LineWidth', 1.6, 'DisplayName', char(S.samples(si)));
end
legend(legAx, 'Orientation','horizontal', 'Location','south', 'Box','off', 'FontSize', 10);

sgtitle(sprintf('%s   [360\\circ = слабкий фільтр \\rightarrow 45\\circ = найвужче вікно]', label), ...
        'FontSize', 12, 'FontWeight','bold', 'Interpreter','tex');

outDir = fileparts(outFile);
if ~exist(outDir,'dir'); mkdir(outDir); end
try
    exportgraphics(fig, outFile, 'Resolution', 150, 'Padding', 'figure');
catch
    exportgraphics(fig, outFile, 'Resolution', 150);
end
close(fig);
end
