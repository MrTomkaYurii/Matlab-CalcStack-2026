function viz_level_bands(D, meta, ctx, CFG)
% VIZ_LEVEL_BANDS  Смуговий аналіз концентрації значень навколо рівнів.
%   CFG.viz.bandLevels (типово 8) рівнів рівномірно між min і max, ПЛЮС
%   1 додатковий рівень = МОДА розподілу (центр найбільш заповненого біна
%   гістограми). Разом NL = bandLevels+1 (типово 9), відсортовані за
%   зростанням; рівень моди позначений "(peak)" і виділений кольором —
%   решта СІРІ (однаковий колір), щоб не було "райдужного" шуму.
%   Для кожного рівня показує:
%     - точки-маркери, де саме на зображенні лежать пікселі в смузі
%       рівень ± половина ширини (ширина = CFG.viz.bandWidthPct від
%       діапазону max-min); фіксований розмір маркера (не imagesc-піксель),
%       тому видно навіть 1 піксель;
%     - гістограму значень усередині цієї смуги.
%   Панель точок і панель гістограми НЕ 'axis image' -- обидві заповнюють
%   свою комірку сітки, тому однакового розміру (примусовий квадратний
%   аспект картинки робив її дрібнішою за сусідню гістограму).
%   ОКРЕМА фігура для модуля й окрема для аргументу. Компактна сітка:
%   cols = ceil(sqrt(NL)) колонок, groups = ceil(NL/cols) груп рівнів,
%   2*groups рядків (точки/гістограми чергуються).
%   Доповнює (2) viz_sections — там лінії контуру (згладжені), тут — де
%   саме й наскільки щільно значення концентруються біля обраних рівнів.

if isfield(CFG,'style'), S = viz_style(CFG.style); else, S = viz_style(); end
quants = { {D.mod, meta.modLabel, 'mod'}, {D.arg, meta.argLabel, 'arg'} };

% Сірий+peak-колір фіксовані, не залежать від CFG.viz.colormaps (jet/gray)
% -- тому ОДНА фігура на величину (mod/arg), без дублювання під кожен
% colormap (раніше давало 2 однакові файли з різними іменами).
for q = 1:numel(quants)
    Z = quants{q}{1}; qlab = quants{q}{2}; qtag = quants{q}{3};
    buildFigure(Z, qlab, qtag, meta, ctx, CFG, S);
end
end

% ------------------------------------------------------------------------
function buildFigure(Z, qlab, qtag, meta, ctx, CFG, S)
% Рівні, рівень-мода, ширина смуги і лічильники -- спільний розрахунок із
% статистикою (tp_level_bands_calc.m, перенесено сюди без змін логіки).
LBc = tp_level_bands_calc(Z, CFG);
if ~LBc.valid
    return;   % вироджений розподіл — нічого малювати
end
lo = LBc.lo; hi = LBc.hi; levels = LBc.levels; peakIdx = LBc.peakIdx;
NL = LBc.NL; halfW = LBc.halfW; nTotal = LBc.nTotal;

grayCol = [0.45 0.45 0.45];       % ОДИН сірий колір -- маркери й стовпці гістограми
peakCol = [0.80 0.15 0.15];       % лише рівень-мода виділений

cols   = ceil(sqrt(NL));
groups = ceil(NL/cols);

% Ручне позиціонування (не subplot-сітка з однаковою висотою на ВСІ рядки):
% панель точок -- КВАДРАТ зі стороною = ширина колонки (1:1, без
% спотворення кружечків); гістограма під нею -- компактніша смуга
% фіксованої висоти. Обидві однакової ШИРИНИ (colW) -- це і є "однакові
% по ОХ", а квадратна панель точок -- "однакові по ОХ і ОУ" для неї самої.
colW = 300; histH = 230; gapWithin = 95; gapBetween = 85;
marginL = 70; marginR = 15; marginT = 95; marginB = 60; gapX = 60;
% gapWithin/gapBetween мають вмістити: підпис+поділки під одною панеллю
% (~50px) ТА заголовок наступної (~25-30px) -- звідси такі великі числа,
% бо axes('Position',...) (на відміну від subplot) не резервує місце під
% підписи автоматично, вони виступають ЗА межі заданого прямокутника.
groupH = colW + gapWithin + histH;
Wfig = marginL + cols*colW + (cols-1)*gapX + marginR;
Hfig = marginT + groups*groupH + (groups-1)*gapBetween + marginB;
fig = figure('Color','w','Visible','off','Position',[40 40 Wfig Hfig]);
S.light(fig);
% УВАГА (причина "плаваючої" вёрстки): у звичайному вікні MATLAB (не -batch) висота
% фігури при створенні ОБМЕЖУЄТЬСЯ висотою екрана (тут задумано ~2200 px, а екран ~864),
% а при збереженні повертається до заданої. Панелі в ПІКСЕЛЯХ (Units='pixels') тоді
% розтягувались по вертикалі в Hfig/Hекрана разів: гістограми ставали в ~2.7 раза вищими,
% проміжки роздувались, верхні ряди йшли за край. Тому ВСЯ розкладка задається в
% НОРМАЛІЗОВАНИХ одиницях (частка фігури, розраховується з розмірів у пікселях) --
% вона не залежить від того, якого розміру вікно фігури в даний момент.
nrm = @(p) p ./ [Wfig Hfig Wfig Hfig];   % [x y w h] у пікселях задуму -> частки фігури

for j = 1:NL
    lvl  = levels(j);
    mask = abs(Z - lvl) <= halfW;
    nPx  = nnz(mask);
    pctOfTotal = 100 * nPx / max(nTotal,1);
    isPeak = (j == peakIdx);
    col_ = grayCol; if isPeak, col_ = peakCol; end

    grp = ceil(j/cols); col = j - (grp-1)*cols;   % 1-based, зверху-вниз/зліва-направо

    % лівий край колонки (px від лівого краю фігури)
    x0 = marginL + (col-1)*(colW+gapX);
    % верхній край групи (px ВІД ВЕРХУ фігури) -> нижче переводимо у Position
    % (bottom-left origin, тому "звідки знизу" = Hfig - yFromTop - height)
    yGroupTop = marginT + (grp-1)*(groupH+gapBetween);
    yMaskBottom = Hfig - yGroupTop - colW;
    yHistTop    = yGroupTop + colW + gapWithin;
    yHistBottom = Hfig - yHistTop - histH;

    % --- панель точок: де саме на зображенні лежать пікселі в смузі -----
    axM = axes('Parent',fig, 'Units','normalized', 'Position',nrm([x0 yMaskBottom colW colW]));
    xr = [min(meta.x) max(meta.x)]; yr = [min(meta.y) max(meta.y)];
    xlim(axM, xr); ylim(axM, yr); axis(axM,'image');   % 1:1, панель уже квадратна
    set(axM, 'YDir','normal', 'XTick',round(xr), 'YTick',round(yr), 'XTickLabelRotation',0);
    hold(axM,'on');
    if nPx > 0
        [rIdx, cIdx] = find(mask);
        mSize = max(2, min(10, 400/sqrt(max(nPx,1)))) / 3;   % в 3 рази менше (тонші точки)
        scatter(axM, meta.x(cIdx), meta.y(rIdx), mSize, 'filled', ...
                'MarkerFaceColor', col_, 'MarkerFaceAlpha', 0.85, 'MarkerEdgeColor','none');
    end
    hold(axM,'off');
    % scatter() з малою кількістю точок (N=1,7...) інколи повертає режим
    % меж осей у 'auto' і "зумить" під ці кілька точок, ігноруючи заданий
    % xlim/ylim -- фіксуємо межі ЗАНОВО й ЯВНО як 'manual' вже ПІСЛЯ
    % scatter, щоб усі панелі гарантовано мали однаковий масштаб 1-400.
    xlim(axM, xr); ylim(axM, yr);
    set(axM, 'XLimMode','manual', 'YLimMode','manual');
    ttl = sprintf('Level %d/%d', j, NL); if isPeak, ttl = [ttl ' (peak)']; end %#ok<AGROW>
    title(axM, ttl, 'FontSize',S.smallSize,'FontWeight','bold', 'Color', col_);
    text(axM, 0.03,0.03, sprintf('%s\nN=%d (%.1f%%)', tp_format_level(lvl), nPx, pctOfTotal), ...
         'Units','normalized','VerticalAlignment','bottom','FontName','Consolas','FontSize',S.smallSize-2, ...
         'Color','k','BackgroundColor','w','EdgeColor',[0.6 0.6 0.6],'Margin',1.5);
    xlabel(axM, meta.xlabel,'FontSize',S.smallSize); ylabel(axM, meta.ylabel,'FontSize',S.smallSize);
    S.apply(axM);

    % --- панель гістограми: наскільки щільно концентруються значення ----
    axH = axes('Parent',fig, 'Units','normalized', 'Position',nrm([x0 yHistBottom colW histH]));
    if nPx > 0
        vv = Z(mask);
        histogram(axH, vv, max(8,round(sqrt(nPx))), 'FaceColor',col_, ...
                  'EdgeColor',[0.25 0.25 0.25], 'FaceAlpha',0.85);
        hold(axH,'on');
        yl = ylim(axH);
        plot(axH, [lvl lvl], yl, '--', 'Color',[0.15 0.15 0.15], 'LineWidth',1.2);
        ylim(axH, yl);
        text(axH, 0.97,0.95, sprintf('mean=%.3g\nstd=%.2g', mean(vv), std(vv)), ...
             'Units','normalized','VerticalAlignment','top','HorizontalAlignment','right', ...
             'FontName','Consolas','FontSize',S.smallSize,'Color',S.ink,'BackgroundColor','w', ...
             'EdgeColor',[0.6 0.6 0.6],'Margin',2);
    else
        text(axH, 0.5,0.5,'(empty band)','Units','normalized','HorizontalAlignment','center', ...
             'Color',[0.5 0.5 0.5],'FontSize',S.smallSize);
    end
    xlabel(axH, qlab,'FontSize',S.smallSize); ylabel(axH,'Count','FontSize',S.smallSize);
    title(axH, sprintf('%.1f%% of pixels in band', pctOfTotal), 'FontSize',S.smallSize,'FontWeight','bold');
    S.apply(axH);
end

% sgtitle НЕ використовуємо -- воно кладе заголовок відносно normalized
% координат subplot-сітки, а тут ручні axes('Units','pixels',...), тому
% sgtitle рахує висоту неправильно й затирає перший ряд панелей. Замість
% цього -- окрема невидима вісь на всю фігуру з текстом у ФІКСОВАНІЙ,
% контрольованій позиції (у межах marginT).
axTitle = axes('Parent',fig, 'Units','normalized', 'Position',[0 0 1 1], 'Visible','off');
xlim(axTitle,[0 Wfig]); ylim(axTitle,[0 Hfig]);
text(axTitle, Wfig/2, Hfig - marginT*0.45, ...
     sprintf('%s  \\cdot  level-band concentration  (%s)  [range %.3g..%.3g, band=\\pm%.2g]', ...
             meta.titlePrefix, qlab, lo, hi, halfW), ...
     'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink, ...
     'HorizontalAlignment','center','VerticalAlignment','middle');
uistack(axTitle,'bottom');   % під панелями, щоб не перехоплювала клік/рендер-порядок
set(fig, 'Position', [40 40 Wfig Hfig]);   % на випадок, якщо вікно було урізане під екран
drawnow;
tp_save_figure(fig, CFG, ctx.parts, sprintf('%s_level_bands_%s', ctx.name, qtag));
end
