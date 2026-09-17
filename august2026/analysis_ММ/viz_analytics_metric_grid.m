function viz_analytics_metric_grid(S, label, unit, outFile)
% VIZ_ANALYTICS_METRIC_GRID  Одна метрика -> одна фігура: 4x4 сітка (16
%   f_ik), вісь X = фазове вікно в градусах (360=слабкий фільтр -> 45=
%   найвужче, ЯВНО підписано напрям), вісь Y = значення метрики (з
%   одиницею), 3 лінії (по зразку), спільна легенда згори. Панелі з
%   позначеною закономірністю ("тренд"/"розрізняє") мають кольорову рамку
%   й короткий підпис у кутку — щоб було видно ОДРАЗУ, без окремої таблиці.

if isempty(S.elements)
    fprintf('  [viz_analytics_metric_grid] порожні дані для %s — пропущено.\n', label);
    return;
end

colors = [0.20 0.45 0.75; 0.85 0.35 0.10; 0.30 0.65 0.30];  % 3 зразки: синій/оранж/зелений
badgeColor = struct('trend',[0.20 0.60 0.20], 'discrim',[0.85 0.45 0.05], ...
                     'both',[0.75 0.60 0.05], 'none',[0.75 0.75 0.75]);
badgeText  = struct('trend','ТРЕНД', 'discrim','РІЗНИТЬСЯ', 'both','ТРЕНД+РІЗНИТЬСЯ', 'none','');

Sty = viz_style();   % примусово світла тема — інакше в темній темі MATLAB
                      % фон і осі виходять чорними, нечитабельно
fig = figure('Color','w','Visible','off','Position',[40 40 1500 1150]);
Sty.light(fig);

for k = 1:16
    axp = subplot(4,4,k);
    elemGuess = sprintf('f%d%d', ceil(k/4), mod(k-1,4)+1);
    idx = find(strcmp(S.elements, elemGuess), 1);
    if isempty(idx)
        axis(axp, 'off');
        continue;
    end
    elem = S.elements{idx};
    series = S.series.(elem);
    badge  = S.badge.(elem);
    bc = badgeColor.(badge);

    hold(axp, 'on');
    for si = 1:size(series,1)
        plot(axp, S.phaseDeg, series(si,:), 'o-', 'Color', colors(si,:), ...
             'MarkerFaceColor', colors(si,:), 'MarkerSize', 4, 'LineWidth', 1.4);
    end
    set(axp, 'XDir', 'reverse');
    if numel(S.phaseDeg) > 1
        xlim(axp, [min(S.phaseDeg)-10, max(S.phaseDeg)+10]);
    end
    set(axp, 'XTick', sort(S.phaseDeg), 'FontSize', 7);   % XTick має бути зростаючим;
                                                            % візуальний напрям (360->45) дає XDir=reverse вище
    xlabel(axp, 'Фазове вікно, град', 'FontSize', 7.5);
    ylabel(axp, unit, 'FontSize', 7.5);
    title(axp, sprintf('f_{%s}', elem(2:3)), 'FontSize', 10, 'FontWeight','bold', 'Interpreter','tex');
    Sty.apply(axp);   % білий фон, читабельні підписи (ПОТІМ override рамки під позначку)
    box(axp, 'on');
    set(axp, 'XColor', bc, 'YColor', bc, 'LineWidth', 1.8);

    if ~strcmp(badge, 'none')
        text(axp, 0.97, 0.95, badgeText.(badge), 'Units','normalized', ...
             'HorizontalAlignment','right', 'VerticalAlignment','top', ...
             'FontSize', 6.5, 'FontWeight','bold', 'Color', bc, ...
             'BackgroundColor','w', 'Margin', 1);
    end
end

% спільна легенда (по зразках) окремою малою віссю згори
legAx = axes('Position',[0 0.965 1 0.03], 'Visible','off');
hold(legAx, 'on');
for si = 1:numel(S.samples)
    plot(legAx, NaN, NaN, 'o-', 'Color', colors(si,:), 'MarkerFaceColor', colors(si,:), ...
         'LineWidth', 1.6, 'DisplayName', char(S.samples(si)));
end
legend(legAx, 'Orientation','horizontal', 'Location','north', 'Box','off', 'FontSize', 9);

sgtitle(sprintf('%s   [360\\circ = слабкий фільтр \\rightarrow 45\\circ = найвужче вікно]', label), ...
        'FontSize', 12, 'FontWeight','bold', 'Interpreter','tex');

outDir = fileparts(outFile);
if ~exist(outDir,'dir'); mkdir(outDir); end
exportgraphics(fig, outFile, 'Resolution', 150);
close(fig);
end
