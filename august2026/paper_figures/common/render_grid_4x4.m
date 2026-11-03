function figH = render_grid_4x4(elems, elemTex, winData, FIG, kind)
% RENDER_GRID_4X4  Один рисунок у статтю: 16 панелей = 4 стовпці x 4 ряди.
%   Спільний рушій для Fig1/Fig2/Fig3 — відрізняється лише `kind` і тим,
%   що заздалегідь поклав paper_prep у winData{w}.prep.(elem).(comp):
%     'raw'  Fig1 — ряд карт |f|/arg   + ряд гістограм значень
%     'acf'  Fig2 — ряд 2D-АКФ          + ряд 1D-перерізів АКФ
%     'psd'  Fig3 — ряд 2D-PSD (log10)  + ряд гістограм значень PSD
%
%   Рядки 1,3 — "карти" (фазові вікна 1 і 2), рядки 2,4 — "низ" під ними.
%   Над КОЖНОЮ картою — свій горизонтальний colorbar і заголовок стовпця.
%   Літери (a)..(p) — під панелями. Розмір фігури рахується з контенту.
%
%   elems {'f33','f44'}   elemTex {'f_{33}','f_{44}'}
%   winData 1x2 cell (з .data і .prep)   FIG cfg_figures() з .color.modMap/argMap
%   kind 'raw'|'acf'|'psd'

nCol = 4;
comp = {'mod','arg','mod','arg'};
eIdx = [1 1 2 2];
isCut = strcmp(kind,'acf');           % низ Fig2 = 1D-переріз АКФ (спад + півширина)
isWavCut = strcmp(kind,'wav');        % низ = 2 перерізи |W(a_fix,b)|, а не гістограма
acfW  = 100;                          % спільне піввікно лагів (px) для цієї групи; ставить make_grid_pair
if isCut && isfield(FIG,'acf') && isfield(FIG.acf,'win') && ~isempty(FIG.acf.win)
    acfW = FIG.acf.win;
end

g  = FIG.geom;  fs = FIG.font.size;
Wa = g.aspectW;
mS = (Wa - g.marginL - g.marginR - (nCol-1)*g.colGap) / nCol;
isMfr  = strcmp(kind,'mfr');          % обидва ряди блоку — лінійні графіки (D(q), f(h))
hdrH   = tern(isMfr, g.titleH + 3, g.cbarStripH + g.cbarTickH + g.titleH);
botH   = g.histH;
rowH    = [mS botH mS botH];
% зона підписів осі безпосередньо під панеллю (числа + назва осі); нижче неї —
% літера панелі з ОДНАКОВИМ відступом g.letterGap понад і під нею.
letterH = 0.30 * fs;                                    % ~візуальна висота літери, мм (10pt -> 3.0)
labZone = [g.axisLabelH g.axisLabelH g.axisLabelH g.axisLabelH];
mBelow  = labZone + 2*g.letterGap + letterH;            % повна смуга під рядом
rowKind = {'map','bot','map','bot'};
rowWin  = [1 1 2 2];

Ha = g.marginT + g.phaseHdrH + hdrH + rowH(1) + mBelow(1) + rowH(2) + mBelow(2) + g.blockGap + ...
     g.phaseHdrH + hdrH + rowH(3) + mBelow(3) + rowH(4) + mBelow(4) + g.marginB;

if isempty(g.figSize); figCm = [Wa Ha]/10; else; figCm = g.figSize; end
figH = figure('Units','centimeters', 'Position',[2 2 figCm], 'Color','w', ...
    'PaperUnits','centimeters', 'PaperSize',figCm, ...
    'PaperPositionMode','manual', 'PaperPosition',[0 0 figCm], 'InvertHardcopy','off');
set(figH, 'DefaultAxesFontName',FIG.font.name, 'DefaultTextFontName',FIG.font.name, ...
          'DefaultAxesFontSize',fs, 'DefaultTextFontSize',fs);

nrm  = @(x,y,w,h) [x/Wa, y/Ha, w/Wa, h/Ha];
colX = @(c) g.marginL + (c-1)*(mS + g.colGap);
blockRight = g.marginL + nCol*mS + (nCol-1)*g.colGap;

yb = zeros(1,4);  cur = Ha - g.marginT;
for r = 1:4
    if r == 1 || r == 3; cur = cur - g.phaseHdrH - hdrH; end
    cur = cur - rowH(r);  yb(r) = cur;  cur = cur - mBelow(r);
    if r == 2; cur = cur - g.blockGap; end
end

modRGB = cmap_rgb(FIG.color.modMap, 256);
argRGB = cmap_rgb(FIG.color.argMap, 256);

% ---- спільні межі кольору + межі гістограм ----
% Пул значень для шкали — ОКРЕМО |f| / arg (їх діапазони різняться на
% порядки). Беремо .histSrc (є для всіх kind, крім acf).
poolMod = [];  poolArg = [];
for w = 1:2
    for e = 1:2
        poolMod = [poolMod; finitecol(winData{w}.prep.(elems{e}).mod.histSrc)]; %#ok<AGROW>
        poolArg = [poolArg; finitecol(winData{w}.prep.(elems{e}).arg.histSrc)]; %#ok<AGROW>
    end
end
switch kind
    case 'raw'
        modClim = cliplim(poolMod, FIG.color.modClipPct);
        modClim(1) = 0;   % модуль фізично невід'ємний, починається з 0
        if isfield(FIG.color, 'modMax') && ~isempty(FIG.color.modMax) && isfinite(FIG.color.modMax)
            modClim(2) = min(modClim(2), FIG.color.modMax);
        end
        argClim = FIG.color.argClim;
    case 'acf'
        modClim = [0 1];  argClim = [0 1];
    case 'psd'
        modClim = cliplim(poolMod, FIG.psd.clipPct);
        argClim = cliplim(poolArg, FIG.psd.clipPct);
    otherwise                                   % 'wav' | 'skel'
        modClim = cliplim(poolMod, FIG.wav.clipPct);
        argClim = cliplim(poolArg, FIG.wav.clipPct);
end
modEdges = linspace(modClim(1), modClim(2), FIG.hist.nbins+1);
argEdges = linspace(argClim(1), argClim(2), FIG.hist.nbins+1);

% ---- Y-максимуми гістограм: ОКРЕМО для модулів і ОКРЕМО для аргументів ----
% Кожен тип має свій незалежний інтервал OY.
% Для аргументів інтервал однаковий для всіх arg у межах фігури (ymaxArg).
% Для модулів — свій спільний інтервал (ymaxMod) або per-window.
ymaxMod = 0;
ymaxArg = 0;
blockYmaxMod = zeros(1,2);
blockYmaxArg = zeros(1,2);

if any(strcmp(kind, {'raw','psd','skel'}))   % 'wav' тепер перерізи, не гістограма — власний ymax нижче
    for bl = 1:2
        D = winData{bl};
        for c = 1:nCol
            elem = elems{eIdx(c)};
            P = D.prep.(elem).(comp{c});
            edgc = tern(P.isMod, modEdges, argEdges);
            v = P.histSrc;  v = v(isfinite(v));
            cnt = histcounts(v, edgc, 'Normalization', FIG.hist.norm);
            pk = max([cnt eps]);
            if P.isMod
                ymaxMod = max(ymaxMod, pk);
                blockYmaxMod(bl) = max(blockYmaxMod(bl), pk);
            else
                ymaxArg = max(ymaxArg, pk);
                blockYmaxArg(bl) = max(blockYmaxArg(bl), pk);
            end
        end
    end
    ymaxMod = ymaxMod * 1.1;
    ymaxArg = ymaxArg * 1.1;
    blockYmaxMod = blockYmaxMod * 1.1;
    blockYmaxArg = blockYmaxArg * 1.1;
    % у вузькому вікні точок у рази менше (OX/OY/XY ~10%) — на спільній шкалі
    % гістограма "лежить". Шкала вікна стискається так, щоб пік займав не
    % менше FIG.hist.minFill висоти (1/3 — видно, що менше; 1 — окрема шкала).
    minFill = 1/3;
    if isfield(FIG.hist,'minFill') && ~isempty(FIG.hist.minFill); minFill = FIG.hist.minFill; end
    blockYmaxMod = min(ymaxMod, max(blockYmaxMod, blockYmaxMod / 1.1 / minFill));
    blockYmaxArg = min(ymaxArg, max(blockYmaxArg, blockYmaxArg / 1.1 / minFill));
end

% ---- overlay для підписів ----
axOv = axes('Parent',figH, 'Units','normalized', 'Position',[0 0 1 1], ...
            'XLim',[0 Wa], 'YLim',[0 Ha], 'Visible','off');
disableDefaultInteractivity(axOv);
lab = @(x,y,s,varargin) text(axOv, x, y, s, 'Clipping','off', 'Color','k', ...
        'HorizontalAlignment','center', 'FontSize',fs, varargin{:});

% ---- панелі ----
for r = 1:4
    D = winData{rowWin(r)};
    for c = 1:nCol
        elem  = elems{eIdx(c)};
        P     = D.prep.(elem).(comp{c});
        isMod = P.isMod;

        if isMod; cl = modClim; edg = modEdges; else; cl = argClim; edg = argEdges; end
        if strcmp(kind,'raw') && ~isMod; rgb = argRGB; else; rgb = modRGB; end
        if strcmp(kind,'acf'); edg = []; end

        ax = axes('Parent',figH, 'Units','normalized', 'Position',nrm(colX(c), yb(r), mS, rowH(r)));
        disableDefaultInteractivity(ax);
        set(ax, 'FontSize',fs, 'LineWidth',FIG.line.axis, 'TickDir','out', ...
                'XColor','k', 'YColor','k', 'Box','on', 'Layer','top', 'Color','w');

        if strcmp(rowKind{r},'map')
            switch kind
                case {'raw','acf','psd'}
                    px = P.x;  py = P.y;  pimg = P.img;
                    if strcmp(kind,'acf')      % спільне вікно лагів на весь FigN
                        kx = abs(P.x) <= acfW;   ky = abs(P.y) <= acfW;
                        px = P.x(kx);  py = P.y(ky);  pimg = P.img(ky, kx);
                    end
                    him = imagesc(ax, px, py, pimg);
                    set(him, 'AlphaData', isfinite(pimg));
                    set(ax, 'Color',FIG.color.nan, 'YDir',FIG.axis.yDir, ...
                            'TickLength',[0.02 0.02], 'XColor','k', 'YColor','k');
                    colormap(ax, rgb);  clim(ax, cl);  axis(ax, 'image');
                    if FIG.map.grid
                        set(ax, 'GridColor',FIG.map.gridColor, 'GridAlpha',FIG.map.gridAlpha, ...
                                'XGrid','on', 'YGrid','on');
                    end
                    if strcmp(kind,'acf') && any(pimg(:) >= FIG.acf.hwLevel) && any(pimg(:) <= FIG.acf.hwLevel)
                        hold(ax,'on');
                        contour(ax, px, py, pimg, [FIG.acf.hwLevel FIG.acf.hwLevel], ...
                                'LineColor',FIG.acf.hwColor, 'LineWidth',FIG.acf.hwW);
                        hold(ax,'off');
                    end

                case 'wav'                      % скалограма |W(a,b)|
                    pcolor(ax, P.x, P.y, P.img);  shading(ax,'flat');
                    colormap(ax, rgb);  clim(ax, cl);
                    set(ax, 'Color',FIG.color.nan, 'YDir','normal', 'Layer','top', ...
                            'TickLength',[0.02 0.02]);
                    if P.yLog; set(ax, 'YScale','log'); end
                    axis(ax, 'tight');
                    if isfinite(P.wcutALo) && isfinite(P.wcutAHi)   % позначити перерізи a=low/high (без легенди)
                        hold(ax,'on');
                        yline(ax, P.wcutALo, '--', 'Color',[0.20 0.60 0.25], 'LineWidth',1.1);
                        yline(ax, P.wcutAHi, '--', 'Color',[0.85 0.35 0.10], 'LineWidth',1.1);
                        hold(ax,'off');
                    end

                case 'skel'                     % scatter WTMM-скелетону
                    scatter(ax, P.skB, P.skA, FIG.skel.markerSize, P.skH, 'filled');
                    colormap(ax, rgb);  clim(ax, cl);
                    set(ax, 'Color','w', 'YDir','normal', 'Layer','top', 'TickLength',[0.02 0.02], ...
                            'XLim',[P.x(1) P.x(end)], 'YLim',[P.y(1) P.y(end)]);
                    if P.yLog; set(ax, 'YScale','log'); end

                case 'mfr'                      % ряд 1 — крива D(q) / tau(q) / h(q)
                    [xx, yy, yl] = mfr_row1(P.mf, FIG.mfr.row1);
                    plot(ax, xx, yy, 'o-', 'Color',FIG.mfr.line, 'MarkerFaceColor',FIG.mfr.line, ...
                         'MarkerSize',FIG.mfr.marker, 'LineWidth',FIG.mfr.lineW);
                    set(ax, 'Color','w', 'TickLength',[0.02 0.02]);
                    P.axX = 'q';  P.axY = yl;
            end
            set(ax, 'XColor','k', 'YColor','k');
            xlabel(ax, P.axX, 'Color','k');
            ylabel(ax, P.axY, 'Color','k');

            sfx = '';   % множник шкали (", ×10^{e}") для дрібних значень — у заголовок
            if ~isMfr
                % горизонтальний colorbar + заголовок НАД картою
                yMapTop = yb(r) + mS;
                cbY  = yMapTop + g.titleH + g.cbarTickH;
                cbAx = axes('Parent',figH, 'Units','normalized', ...
                            'Position',nrm(colX(c), cbY, mS, g.cbarStripH));
                disableDefaultInteractivity(cbAx);
                imagesc(cbAx, cl, [0 1], linspace(cl(1),cl(2),256));
                colormap(cbAx, rgb); clim(cbAx, cl);
                set(cbAx, 'YTick',[], 'XLim',cl, 'Box','on', 'LineWidth',FIG.line.axis, ...
                        'TickDir','out', 'FontSize',fs, 'XColor','k', 'YColor','k', 'XAxisLocation','bottom');
                if strcmp(kind,'raw') && ~isMod
                    set(cbAx, 'XTick',argTicks(cl), 'XTickLabel',argTickLbl(cl));
                else
                    [tl, sfx] = sclbl(cl(1), cl(2));
                    set(cbAx, 'XTick',cl, 'XTickLabel', tl, 'XTickLabelRotation',0);
                end
            end

            if isMod; ttl = sprintf('|%s|%s', elemTex{eIdx(c)}, sfx);
            else;     ttl = sprintf('arg(%s)', elemTex{eIdx(c)});
            end
            lab(colX(c) + mS/2, yb(r) + rowH(r) + g.titleH*0.5, ttl);

        elseif isCut
            % 1D-переріз 2D-АКФ через центр (лаг=0): спадання значень + півширина.
            % Те саме спільне вікно лагів, що й у 2D-карти над панеллю.
            kc = abs(P.cutLag) <= acfW;
            lagX = P.cutLag(kc);  lagX = lagX(:).';
            cv   = P.cutCurve(kc);  cv = cv(:).';
            plot(ax, lagX, cv, '-', 'Color',[0.20 0.35 0.75], 'LineWidth',1.3);
            hold(ax,'on');
            plot(ax, [lagX(1) lagX(end)], [FIG.acf.hwLevel FIG.acf.hwLevel], '--', ...
                 'Color',[0.55 0.55 0.55], 'LineWidth',0.7);          % рівень 0.5
            for xx = [P.loLag P.hiLag]
                if isfinite(xx) && xx > lagX(1) && xx < lagX(end)
                    plot(ax, [xx xx], [0 FIG.acf.hwLevel], ':', 'Color',[0.80 0.20 0.20], 'LineWidth',1.0);
                end
            end
            hold(ax,'off');
            set(ax, 'Color','w', 'XLim',[lagX(1) lagX(end)], 'YLim',[0 1.03], ...
                    'YTick',[0 0.5 1], 'TickLength',[0.02 0.02], 'Layer','top', ...
                    'XGrid','on', 'YGrid','on', 'GridColor',[0.35 0.35 0.35], ...
                    'GridAlpha',0.5, 'GridLineStyle','-', 'XColor','k', 'YColor','k');
            xlabel(ax, P.cutXlab, 'Color','k');
            ylabel(ax, 'ACF', 'Color','k');

        elseif isMfr
            % ряд 2 — спектр сингулярностей f(h), з підписаною Delta h
            MF = P.mf;
            if ~isempty(MF) && ~MF.degenerate
                vv = isfinite(MF.h) & isfinite(MF.f);
                [hs, si] = sort(MF.h(vv));  ff = MF.f(vv);  ff = ff(si);
                [hs, iu] = unique(hs, 'stable');  ff = ff(iu);
                % суцільна арка: інтерполяція по h (заповнює розрив на вершині
                % від спрощеного WTMM) + сирі точки як маркери
                if numel(hs) >= 4
                    hg = linspace(hs(1), hs(end), 60);
                    fg = smoothdata(interp1(hs, ff, hg, 'pchip'), 'movmean', 3);
                    plot(ax, hg, fg, '-', 'Color',FIG.mfr.line, 'LineWidth',FIG.mfr.lineW);
                    hold(ax,'on');
                end
                plot(ax, hs, ff, 'o', 'Color',FIG.mfr.line, 'MarkerFaceColor',FIG.mfr.line, ...
                     'MarkerSize',FIG.mfr.marker);
                hold(ax,'off');
                % Delta h — у порожньому НИЖНЬОМУ куті (вершина арки зверху)
                text(ax, 0.5, 0.06, sprintf('\\Deltah = %.2f', MF.deltaH), 'Units','normalized', ...
                     'HorizontalAlignment','center', 'VerticalAlignment','bottom', ...
                     'FontSize',fs, 'Color','k');
            end
            set(ax, 'Color','w', 'TickLength',[0.02 0.02], 'XColor','k', 'YColor','k');
            xlabel(ax, 'h', 'Color','k');
            ylabel(ax, 'f(h)', 'Color','k');

        elseif isWavCut
            % два перерізи |W(a_fix,b)| — низький (зелений) і високий (оранж.)
            % масштаб, ті самі кольори, що й пунктирні лінії на карті вище.
            plot(ax, P.wcutB, P.wcutLo, '-', 'Color',[0.20 0.60 0.25], 'LineWidth',1.1);
            hold(ax,'on');
            plot(ax, P.wcutB, P.wcutHi, '-', 'Color',[0.85 0.35 0.10], 'LineWidth',1.1);
            hold(ax,'off');
            yMaxCut = max([P.wcutLo(:); P.wcutHi(:); eps]) * 1.1;
            set(ax, 'Color','w', 'XLim',[P.wcutB(1) P.wcutB(end)], 'YLim',[0 yMaxCut], ...
                    'TickLength',[0.02 0.02], 'Layer','top', 'XColor','k', 'YColor','k');
            lgC = legend(ax, {sprintf('a=%.1f', P.wcutALo), sprintf('a=%.1f', P.wcutAHi)}, ...
                   'Location','northwest', 'Box','off', 'FontSize',fs-3, 'TextColor','k');
            lgC.ItemTokenSize = [10 18];   % коротші кольорові лінії-зразки в легенді (типово [30 18])
            xlabel(ax, P.axX, 'Color','k');
            ylabel(ax, '|W|', 'Color','k');

        else
            % гістограма значень (raw / psd)
            hw = mS * 0.84;
            ax.Position = nrm(colX(c) + (mS-hw)/2, yb(r), hw, rowH(r));
            v   = P.histSrc;
            ctr = edg(1:end-1) + diff(edg)/2;
            cnt = histcounts(v, edg, 'Normalization', FIG.hist.norm);
            bar(ax, ctr, cnt, 1, 'FaceColor',FIG.hist.fill, 'EdgeColor',FIG.hist.edge, ...
                'LineWidth',FIG.hist.edgeW);
            if isMod
                ymax = blockYmaxMod(rowWin(r));   % шкала свого фазового вікна (див. minFill)
            else
                ymax = blockYmaxArg(rowWin(r));
            end
            set(ax, 'Color','w', 'XLim',[edg(1) edg(end)], 'YLim',[0 ymax], ...
                    'TickLength',[0.02 0.02], 'YTick',[0 ymax/1.1], ...
                    'YTickLabel',{'0', explbl(ymax/1.1)}, 'TickLabelInterpreter','tex', ...
                    'YTickLabelRotation', 90, 'XColor','k', 'YColor','k');
            hsfx = '';
            if strcmp(kind,'raw') && ~isMod
                set(ax, 'XTick',argTicks(cl), 'XTickLabel',argTickLbl(cl));
            else
                [tl, hsfx] = sclbl(edg(1), edg(end));
                set(ax, 'XTick',[edg(1) edg(end)], 'XTickLabel', tl, 'XTickLabelRotation',0);
            end
            xlabel(ax, [botXlab(kind, isMod, elemTex{eIdx(c)}) hsfx], 'Color','k');
            ylabel(ax, ylabForNorm(FIG.hist.norm), 'Color','k');
        end

        % літера панелі — по центру між підписом осі (зверху) і наступною
        % панеллю (знизу): відступ g.letterGap ОДНАКОВИЙ з обох боків
        k = (r-1)*nCol + c;
        lab(colX(c) + mS/2, yb(r) - labZone(r) - g.letterGap - letterH/2, ...
            panel_letter(FIG.panel.letterStyle,k), ...
            'FontWeight', tern(FIG.panel.letterBold,'bold','normal'), 'VerticalAlignment','middle');
    end

    % підпис фазового вікна — над картовим рядом
    if strcmp(rowKind{r},'map')
        cbTop = yb(r) + rowH(r) + hdrH;
        ruleY = cbTop + 2.2;
        lab((g.marginL + blockRight)/2, ruleY + g.phaseHdrH*0.5, ...
            FIG.phase(rowWin(r)).label, 'VerticalAlignment','middle');
        line(axOv, [g.marginL blockRight], [ruleY ruleY], 'Color','k', 'LineWidth',0.5);
    end
end

uistack(axOv, 'top');
end

% ======================================================================
function v = finitecol(A);  v = A(isfinite(A));  v = v(:);  end

function [x, y, ylab] = mfr_row1(MF, which)
% Крива ряду 1 для Fig6.
if isempty(MF) || MF.degenerate
    x = []; y = []; ylab = 'D(q)'; return;
end
switch lower(which)
    case 'tau', x = MF.q;  y = MF.tau;  ylab = '\tau(q)';
    case 'hq',  x = MF.q;  y = MF.h;    ylab = 'h(q)';
    otherwise,  x = MF.q;  y = MF.D;    ylab = 'D(q)';
end
end

function cl = cliplim(v, pct)
v = v(isfinite(v));
if isempty(v); cl = [0 1]; return; end
if pct > 0; cl = [prctile(v, pct), prctile(v, 100-pct)];
else;       cl = [min(v), max(v)];
end
if ~(cl(2) > cl(1)); cl = cl(1) + [0 1]; end
end

function s = botXlab(kind, isMod, elemTex)
switch kind
    case 'psd',  s = 'log_{10} PSD';
    case 'wav',  s = '|W(a,b)|';
    case 'skel', s = '|W| at WTMM maxima';
    otherwise                                   % 'raw'
        if isMod; s = sprintf('|%s|', elemTex); else; s = sprintf('arg(%s) (rad)', elemTex); end
end
end

function M = cmap_rgb(spec, n)
if isnumeric(spec); M = spec; else; M = feval(spec, n); end
end

function s = explbl(v)
% Компактний науковий запис TeX "m x10^{e}" (замість "9.4e+04") для тіків
% гістограми, коли count сягає тисяч/десятків тисяч на 400x400-пиксельній карті.
if v == 0; s = '0'; return; end
e = floor(log10(abs(v)));
m = v / 10^e;
if abs(e) < 3; s = num2str(v, '%.2g');
else;          s = sprintf('%.2g{\\times}10^{%d}', m, e);
end
end

function s = numlbl(v)
if v == 0; s = '0';
elseif abs(v) >= 1e-3 && abs(v) < 1e4; s = num2str(v, '%.2g');
else; s = explbl(v);   % дрібний модуль (напр. без нормування f11) — "2.1x10^{-5}", не "0"
end
end

function [labs, sfx] = sclbl(lo, hi)
% Як endlbl, але дрібну шкалу (|кінець| < 1e-2, напр. модуль без нормування
% на f11 через порожній канал) підписує мантисою, а множник ", ×10^{e}"
% повертає окремо — для підпису осі (довгий тік "1.6×10^{-6}" повертався й
% наповзав на підпис).
sfx = '';
m = max(abs([lo hi]));
if m > 0 && m < 1e-2
    e = floor(log10(m));
    lo = lo / 10^e;  hi = hi / 10^e;
    sfx = sprintf(', {\\times}10^{%d}', e);
end
labs = endlbl(lo, hi);
end

function labs = endlbl(lo, hi)
% Підписи двох кінців осі (гістограма / colorbar): кінець, МІЗЕРНИЙ проти
% діапазону, показуємо як '0' — а не '1e-05' тощо.
thr = 0.01 * abs(hi - lo);   % лише відносно діапазону: абсолютний поріг 1e-4 обнуляв увесь дрібний модуль
f = @(v) tern(abs(v) < thr, '0', numlbl(v));
labs = {f(lo), f(hi)};
end

function s = ylabForNorm(nm)
switch nm
    case 'probability', s = 'p';
    case 'pdf',         s = 'PDF';
    otherwise,          s = 'count';
end
end

function s = panel_letter(style, k)
c = char('a' + k - 1);
switch style
    case '(a)', s = ['(' c ')'];
    case 'a)',  s = [c ')'];
    case 'a',   s = c;
    case '(A)', s = ['(' upper(c) ')'];
    otherwise,  s = ['(' c ')'];
end
end

function out = tern(cond, a, b)
if cond, out = a; else, out = b; end
end

% ------------------------------------------------------------------------
function t = argTicks(cl)
% мітки шкали аргументу: 0, pi, 2pi  або  -pi, 0, pi
t = [cl(1) mean(cl) cl(2)];
end

function l = argTickLbl(cl)
if cl(1) >= 0, l = {'0','\pi','2\pi'}; else, l = {'-\pi','0','\pi'}; end
end
