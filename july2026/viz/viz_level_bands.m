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
levels = linspace(lo, hi, NL);
halfW  = 0.5 * pct * (hi - lo);   % половина ширини смуги (pct від діапазону)

half = ceil(NL/2);   % напр. NL=8 -> half=4 (2 групи по 4 рівні, по 2 рядки кожна)
fig = figure('Color','w','Visible','off','Position',[40 40 1500 1300]);
S.light(fig);

for j = 1:NL
    lvl  = levels(j);
    mask = abs(Z - lvl) <= halfW;
    nPx  = nnz(mask);

    if j <= half, maskRow = 1; histRow = 2; col = j;
    else,         maskRow = 3; histRow = 4; col = j - half;
    end

    % --- панель маски: де саме на зображенні лежать пікселі в смузі -----
    axM = subplot(4, half, (maskRow-1)*half + col);
    Zshow = nan(size(Z)); Zshow(mask) = Z(mask);
    im = imagesc(axM, meta.x, meta.y, Zshow); set(im,'AlphaData',mask);
    set(axM,'YDir','normal'); axis(axM,'image'); colormap(axM,cmap);
    if nPx > 0
        caxis(axM, [lvl-halfW, lvl+halfW]); colorbar(axM);
    end
    title(axM, sprintf('level = %.3g \\pm %.3g  (N=%d)', lvl, halfW, nPx), ...
          'FontSize',9,'FontWeight','bold','Interpreter','tex');
    xlabel(axM, meta.xlabel,'FontSize',8); ylabel(axM, meta.ylabel,'FontSize',8);
    S.apply(axM);

    % --- панель гістограми: наскільки щільно концентруються значення ----
    axH = subplot(4, half, (histRow-1)*half + col);
    if nPx > 0
        histogram(axH, Z(mask), 'FaceColor',[0.25 0.45 0.75], 'EdgeColor',[0.2 0.2 0.2]);
    end
    xlabel(axH, qlab,'FontSize',8); ylabel(axH,'Count','FontSize',8);
    title(axH, sprintf('values in band (N=%d)', nPx),'FontSize',9,'FontWeight','bold');
    S.apply(axH);
end

sgtitle(sprintf('%s  \\cdot  level-band concentration  (%s)  [%s]', ...
        meta.titlePrefix, qlab, cmap), ...
        'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
tp_save_figure(fig, CFG, ctx.parts, sprintf('%s_level_bands_%s_%s', ctx.name, qtag, cmap));
end
