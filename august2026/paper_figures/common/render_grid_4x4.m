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
isSurf = strcmp(kind,'acf');          % низ = 3D-поверхня АКФ, а не гістограма

g  = FIG.geom;  fs = FIG.font.size;
Wa = g.aspectW;
mS = (Wa - g.marginL - g.marginR - (nCol-1)*g.colGap) / nCol;
isMfr  = strcmp(kind,'mfr');          % обидва ряди блоку — лінійні графіки (D(q), f(h))
hdrH   = tern(isMfr, g.titleH + 3, g.cbarStripH + g.cbarTickH + g.titleH);
botH   = tern(isSurf, g.surf3dH, g.histH);
rowH    = [mS botH mS botH];
% зона підписів осі безпосередньо під панеллю (числа + назва осі); нижче неї —
% літера панелі з ОДНАКОВИМ відступом g.letterGap понад і під нею.
letterH = 0.30 * fs;                                    % ~візуальна висота літери, мм (10pt -> 3.0)
labZone = [g.axisLabelH g.axisLabelH g.axisLabelH g.axisLabelH];
if isSurf; labZone([2 4]) = g.surf3dLabelH; end
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
                    him = imagesc(ax, P.x, P.y, P.img);
                    set(him, 'AlphaData', isfinite(P.img));
                    set(ax, 'Color',FIG.color.nan, 'YDir',FIG.axis.yDir, ...
                            'TickLength',[0.02 0.02], 'XColor','k', 'YColor','k');
                    colormap(ax, rgb);  clim(ax, cl);  axis(ax, 'image');
                    if FIG.map.grid
                        set(ax, 'GridColor',FIG.map.gridColor, 'GridAlpha',FIG.map.gridAlpha, ...
                                'XGrid','on', 'YGrid','on');
                    end
                    if strcmp(kind,'acf')       % контур напівширини (0.5) поверх 2D-АКФ
                        hold(ax,'on');
                        contour(ax, P.x, P.y, P.img, [FIG.acf.hwLevel FIG.acf.hwLevel], ...
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
                    set(cbAx, 'XTick',[-pi 0 pi], 'XTickLabel',{'-\pi','0','\pi'});
                else
                    set(cbAx, 'XTick',cl, 'XTickLabel',{numlbl(cl(1)), numlbl(cl(2))});
                end
            end

            if isMod; ttl = sprintf('|%s|', elemTex{eIdx(c)});
            else;     ttl = sprintf('arg(%s)', elemTex{eIdx(c)});
            end
            lab(colX(c) + mS/2, yb(r) + rowH(r) + g.titleH*0.5, ttl);

        elseif isSurf
            % 3D-поверхня тієї ж 2D-АКФ (даунсемпл важкого масиву).
            N  = FIG.acf.surf3dN;
            xi = linspace(1, numel(P.x), min(N, numel(P.x)));
            yi = linspace(1, numel(P.y), min(N, numel(P.y)));
            Zd = interp2(P.img, xi, yi.', 'linear');
            [XX, YY] = meshgrid(interp1(1:numel(P.x), P.x, xi), interp1(1:numel(P.y), P.y, yi));
            if isempty(FIG.acf.surf3dEdge)
                surf(ax, XX, YY, Zd, 'EdgeColor','none', 'FaceColor','interp');
            else
                surf(ax, XX, YY, Zd, 'EdgeColor',FIG.acf.surf3dEdge, 'LineWidth',0.15, 'FaceColor','interp');
            end
            colormap(ax, rgb);  clim(ax, [0 1]);
            set(ax, 'Color','w', 'XColor','k', 'YColor','k', 'ZColor','k', ...
                    'XLim',[P.x(1) P.x(end)], 'YLim',[P.y(1) P.y(end)], 'ZLim',[0 1], ...
                    'ZTick',[0 0.5 1], 'XTick',[P.x(1) 0 P.x(end)], 'YTick',[P.y(1) 0 P.y(end)], ...
                    'TickLength',[0.02 0.02], 'Projection','orthographic');
            view(ax, FIG.acf.surf3dView);
            xlabel(ax, '\Deltax', 'Color','k');
            ylabel(ax, '\Deltay', 'Color','k');
            zlabel(ax, 'ACF', 'Color','k');
            % OuterPosition (а не Position) -> MATLAB вписує куб + підписи
            % осей у клітинку, нічого не вилазить на сусідів.
            ax.PositionConstraint = 'outerposition';
            ax.OuterPosition = nrm(colX(c) - g.colGap*0.30, yb(r) - labZone(r), ...
                                   mS + g.colGap*0.55, rowH(r) + labZone(r));

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

        else
            % гістограма значень (raw / psd)
            hw = mS * 0.84;
            ax.Position = nrm(colX(c) + (mS-hw)/2, yb(r), hw, rowH(r));
            v   = P.histSrc;
            ctr = edg(1:end-1) + diff(edg)/2;
            cnt = histcounts(v, edg, 'Normalization', FIG.hist.norm);
            bar(ax, ctr, cnt, 1, 'FaceColor',FIG.hist.fill, 'EdgeColor',FIG.hist.edge, ...
                'LineWidth',FIG.hist.edgeW);
            ymax = max([cnt eps]) * 1.1;
            set(ax, 'Color','w', 'XLim',[edg(1) edg(end)], 'YLim',[0 ymax], ...
                    'TickLength',[0.02 0.02], 'YTick',[0 ymax], ...
                    'YTickLabel',{'0', sprintf('%.2g', ymax/1.1)}, 'XColor','k', 'YColor','k');
            if strcmp(kind,'raw') && ~isMod
                set(ax, 'XTick',[-pi 0 pi], 'XTickLabel',{'-\pi','0','\pi'});
            else
                set(ax, 'XTick',[edg(1) edg(end)], 'XTickLabel',{numlbl(edg(1)), numlbl(edg(end))});
            end
            xlabel(ax, botXlab(kind, isMod, elemTex{eIdx(c)}), 'Color','k');
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
    case 'skel', s = 'h = |W| at maxima';
    otherwise                                   % 'raw'
        if isMod; s = sprintf('|%s|', elemTex); else; s = 'arg (rad)'; end
end
end

function M = cmap_rgb(spec, n)
if isnumeric(spec); M = spec; else; M = feval(spec, n); end
end

function s = numlbl(v)
if v == 0; s = '0';
elseif abs(v) >= 1e-3 && abs(v) < 1e4; s = num2str(v, '%.2g');
else; s = num2str(v, '%.0e');
end
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
