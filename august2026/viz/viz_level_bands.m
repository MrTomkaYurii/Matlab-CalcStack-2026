function viz_level_bands(D, meta, ctx, CFG)
% VIZ_LEVEL_BANDS  Смуговий аналіз концентрації значень навколо рівнів.
%   Для CFG.viz.bandLevels рівнів (рівномірно між min і max) показує:
%     - маску пікселів, чиє значення потрапляє в смугу рівень ± половина
%       ширини (ширина = CFG.viz.bandWidthPct від діапазону max-min);
%     - гістограму значень усередині цієї смуги (форма реальної концентрації).
%   ОКРЕМА фігура для модуля й окрема для аргументу (за NL=8 рівнів -> 4
%   рядки x 4 стовпці: рядок1=маски 1-4, рядок2=гістограми 1-4,
%   рядок3=маски 5-8, рядок4=гістограми 5-8).
%   Доповнює (2) viz_sections — там лінії контуру (згладжені), тут — де
%   саме й наскільки щільно значення концентруються біля обраних рівнів.

S  = viz_style();
NL  = 8;    if isfield(CFG.viz,'bandLevels'),   NL  = CFG.viz.bandLevels;   end
pct = 0.02; if isfield(CFG.viz,'bandWidthPct'), pct = CFG.viz.bandWidthPct; end

quants = { {D.mod, meta.modLabel, 'mod'}, {D.arg, meta.argLabel, 'arg'} };

for q = 1:numel(quants)
    Z = quants{q}{1}; qlab = quants{q}{2}; qtag = quants{q}{3};
    for c = 1:numel(CFG.viz.colormaps)
        cmap = CFG.viz.colormaps{c};
        buildFigure(Z, qlab, qtag, meta, ctx, CFG, S, cmap, NL, pct);
    end
end
end

% ------------------------------------------------------------------------
function buildFigure(Z, qlab, qtag, meta, ctx, CFG, S, cmap, NL, pct)
lo = min(Z(:),[],'omitnan'); hi = max(Z(:),[],'omitnan');
if ~(isfinite(lo) && isfinite(hi)) || hi <= lo
    return;   % вироджений розподіл — нічого малювати
end
levels  = linspace(lo, hi, NL);
halfW   = 0.5 * pct * (hi - lo);   % половина ширини смуги (pct від діапазону)
nTotal  = nnz(isfinite(Z));        % для % від загальної кількості валідних пікселів
histCol = [0.25 0.45 0.75];        % ОДИН колір для всіх гістограм (не по рівню — інакше
                                   % "райдужний" ефект і візуальний шум на 8 маленьких панелях)

half = ceil(NL/2);   % напр. NL=8 -> half=4 (2 групи по 4 рівні, по 2 рядки кожна)
fig = figure('Color','w','Visible','off','Position',[40 40 1600 1350]);
S.light(fig);

for j = 1:NL
    lvl  = levels(j);
    mask = abs(Z - lvl) <= halfW;
    nPx  = nnz(mask);
    pctOfTotal = 100 * nPx / max(nTotal,1);

    if j <= half, maskRow = 1; histRow = 2; col = j;
    else,         maskRow = 3; histRow = 4; col = j - half;
    end

    % --- панель маски: де саме на зображенні лежать пікселі в смузі -----
    % Короткий заголовок ("Level j/N") — довгий текст (значення/N/%) на
    % 4 вузьких колонках наповзав на сусідню панель; ці деталі тепер у
    % компактній підписаній рамці всередині панелі (як mean/std на гістограмі).
    axM = subplot(4, half, (maskRow-1)*half + col);
    Zshow = nan(size(Z)); Zshow(mask) = Z(mask);
    im = imagesc(axM, meta.x, meta.y, Zshow); set(im,'AlphaData',mask);
    set(axM,'YDir','normal'); axis(axM,'image');
    if strcmp(qtag,'arg'), colormap(axM, viz_arg_cmap(cmap)); else, colormap(axM, cmap); end
    if nPx > 0
        caxis(axM, [lvl-halfW, lvl+halfW]); cb = colorbar(axM); cb.Color = S.ink;
    end
    title(axM, sprintf('Level %d/%d', j, NL), 'FontSize',9,'FontWeight','bold');
    text(axM, 0.03,0.03, sprintf('%s\nN=%d (%.1f%%)', tp_format_level(lvl), nPx, pctOfTotal), ...
         'Units','normalized','VerticalAlignment','bottom','FontName','Consolas','FontSize',7, ...
         'Color','k','BackgroundColor','w','EdgeColor',[0.6 0.6 0.6],'Margin',1.5);
    xlabel(axM, meta.xlabel,'FontSize',8); ylabel(axM, meta.ylabel,'FontSize',8);
    S.apply(axM);

    % --- панель гістограми: наскільки щільно концентруються значення ----
    axH = subplot(4, half, (histRow-1)*half + col);
    if nPx > 0
        v = Z(mask);
        histogram(axH, v, max(8,round(sqrt(nPx))), 'FaceColor',histCol, ...
                  'EdgeColor',[0.25 0.25 0.25], 'FaceAlpha',0.85);
        hold(axH,'on');
        yl = ylim(axH);
        plot(axH, [lvl lvl], yl, '--', 'Color',[0.15 0.15 0.15], 'LineWidth',1.2);
        ylim(axH, yl);
        text(axH, 0.97,0.95, sprintf('mean=%.3g\nstd=%.2g', mean(v), std(v)), ...
             'Units','normalized','VerticalAlignment','top','HorizontalAlignment','right', ...
             'FontName','Consolas','FontSize',8,'Color',S.ink,'BackgroundColor','w', ...
             'EdgeColor',[0.6 0.6 0.6],'Margin',2);
    else
        text(axH, 0.5,0.5,'(empty band)','Units','normalized','HorizontalAlignment','center', ...
             'Color',[0.5 0.5 0.5],'FontSize',9);
    end
    xlabel(axH, qlab,'FontSize',8); ylabel(axH,'Count','FontSize',8);
    title(axH, sprintf('%.1f%% of pixels in band', pctOfTotal), 'FontSize',9,'FontWeight','bold');
    S.apply(axH);
end

sgtitle(sprintf('%s  \\cdot  level-band concentration  (%s)  [range %.3g..%.3g, band=\\pm%.2g, %s]', ...
        meta.titlePrefix, qlab, lo, hi, halfW, cmap), ...
        'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
tp_save_figure(fig, CFG, ctx.parts, sprintf('%s_level_bands_%s_%s', ctx.name, qtag, cmap));
end
