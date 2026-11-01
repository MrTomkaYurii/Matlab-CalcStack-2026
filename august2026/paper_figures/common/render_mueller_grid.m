function figH = render_mueller_grid(winData, FIG)
% RENDER_MUELLER_GRID  Fig7: УСЯ матриця Мюллера на ОДНОМУ рисунку.
%   Макет (за ескізом "Рис.7 / Повний набір |f_ik|"):
%
%     ┌───────────────── 0 - 2\pi ─────────────────┐
%     │   |f_ik|  4x4      │      arg(f_ik)  4x4     │
%     ├──────────────── 0 - 0.75\pi ───────────────┤
%     │   |f_ik|  4x4      │      arg(f_ik)  4x4     │
%     │  ▭ |f| colorbar    │     ▭ arg colorbar      │
%     └────────────────────────────────────────────┘
%
%   2 фазові вікна (блоки згори вниз) x [ |f| зліва | arg справа ].
%   Разом 4 x (4x4) = 64 панелі. Горизонтальні colorbar-и під нижнім блоком:
%   один спільний на всі 32 панелі |f|, один на arg (-pi..pi). Індекси рядка i
%   та стовпця k підписані з краю кожного блоку 4x4. Замість осей на кожній
%   (64) панелі — масштабна лінійка (px) у кутовій панелі кожного блоку:
%   усі панелі однакові за розміром і роздільністю.
%
%   winData : 1xW cell (W = numel(FIG.phase)) структур D зі tp_paper_read
%             (кожна має .data.f11..f44 з .mod/.arg та .ax.x/.y)
%   FIG     : cfg_figures() з підставленими FIG.color.modMap / FIG.color.argMap

W  = numel(winData);
fs = FIG.font.size;
modRGB = cmap_rgb(FIG.color.modMap, 256);
argRGB = cmap_rgb(FIG.color.argMap, 256);

% ---- спільні межі кольору (пул по УСІХ вікнах і елементах) ----
poolMod = [];  poolArg = [];
for w = 1:W
    for i = 1:4
        for k = 1:4
            Mm = winData{w}.data.(sprintf('f%d%d',i,k)).mod;
            Ma = winData{w}.data.(sprintf('f%d%d',i,k)).arg;
            poolMod = [poolMod; Mm(isfinite(Mm))]; %#ok<AGROW>
            poolArg = [poolArg; Ma(isfinite(Ma))]; %#ok<AGROW>
        end
    end
end
modClim = cliplim(poolMod, FIG.color.modClipPct);
modClim(1) = 0;   % модуль фізично невід'ємний
if isfield(FIG.color, 'modMax') && ~isempty(FIG.color.modMax) && isfinite(FIG.color.modMax)
    modClim(2) = min(modClim(2), FIG.color.modMax);
end
argClim = FIG.color.argClim;
if isempty(poolArg); argClim = FIG.color.argClim; end

% ---- геометрія (мм, абстрактна) ----
Wa      = FIG.geom.aspectW;
marL    = 10;      % i-індекси зліва
marR    = 6;
marT    = 14;      % заголовок рисунка
midGap  = 12;      % між групою |f| і групою arg
cellGap = 2;       % між сусідніми панелями у блоці 4x4
hdrH    = 12;      % смуга: підпис фаз. вікна + лінія + назва групи + k-індекси
gapU    = 9;       % під сіткою верхнього блоку -> заголовок нижнього
cbGap   = 7;       % під сіткою нижнього блоку -> colorbar
cbH     = 2.6;     % горизонтальний colorbar
cbTickH = 6;       % числа + підпис під colorbar-ом
marB    = 4;

grpW = (Wa - marL - marR - midGap) / 2;
sw   = (grpW - 3*cellGap) / 4;
gridH = 4*sw + 3*cellGap;

grpX.mod = marL;
grpX.arg = marL + grpW + midGap;

Ha = marT + W*(hdrH + gridH) + (W-1)*gapU + cbGap + cbH + cbTickH + marB;

% верх сітки кожного блоку (y верхнього краю рядка i=1)
gTop = zeros(1,W);  cur = Ha - marT;
for b = 1:W
    cur = cur - hdrH;
    gTop(b) = cur;
    if b < W; cur = cur - gridH - gapU; end
end

if isempty(FIG.geom.figSize); figCm = [Wa Ha]/10; else; figCm = FIG.geom.figSize; end
figH = figure('Units','centimeters', 'Position',[1 1 figCm], 'Color','w', ...
    'PaperUnits','centimeters', 'PaperSize',figCm, ...
    'PaperPositionMode','manual', 'PaperPosition',[0 0 figCm], 'InvertHardcopy','off');
set(figH, 'DefaultAxesFontName',FIG.font.name, 'DefaultTextFontName',FIG.font.name, ...
          'DefaultAxesFontSize',fs, 'DefaultTextFontSize',fs);
nrm = @(x,y,w,h) [x/Wa, y/Ha, w/Wa, h/Ha];

axOv = axes('Parent',figH, 'Units','normalized', 'Position',[0 0 1 1], ...
            'XLim',[0 Wa], 'YLim',[0 Ha], 'Visible','off');
disableDefaultInteractivity(axOv);
lab = @(x,y,s,varargin) text(axOv, x, y, s, 'Clipping','off', 'Color','k', ...
        'HorizontalAlignment','center', 'FontSize',fs, varargin{:});

comps = {'mod','arg'};
for b = 1:W
    D = winData{b};
    isLast = (b == W);
    for cc = 1:2
        comp = comps{cc};  isMod = strcmp(comp,'mod');
        gx = grpX.(comp);
        if isMod; rgb = modRGB; cl = modClim; else; rgb = argRGB; cl = argClim; end

        for i = 1:4
            for k = 1:4
                M  = D.data.(sprintf('f%d%d',i,k)).(comp);
                x0 = gx + (k-1)*(sw + cellGap);
                y0 = gTop(b) - i*sw - (i-1)*cellGap;
                ax = axes('Parent',figH, 'Units','normalized', 'Position',nrm(x0,y0,sw,sw));
                disableDefaultInteractivity(ax);
                him = imagesc(ax, D.ax.x, D.ax.y, M);
                set(him, 'AlphaData', isfinite(M));
                colormap(ax, rgb);  clim(ax, cl);  axis(ax, 'image');
                set(ax, 'Color',FIG.color.nan, 'YDir',FIG.axis.yDir, 'Box','on', 'Layer','top', ...
                        'LineWidth',FIG.line.axis, 'XColor','k', 'YColor','k', 'XTick',[], 'YTick',[]);
                if FIG.map.grid
                    set(ax, 'GridColor',FIG.map.gridColor, 'GridAlpha',FIG.map.gridAlpha, ...
                            'XGrid','on', 'YGrid','on');
                end
                if i == 4 && k == 1
                    add_scalebar(ax, D.ax.x, D.ax.y, FIG.axis.yDir, fs);
                end
            end
        end

        % назва групи + k-індекси над блоком
        lab(gx + grpW/2, gTop(b) + hdrH*0.34, tern(isMod,'|f_{ik}|','arg(f_{ik})'), ...
            'VerticalAlignment','middle');
        for k = 1:4
            lab(gx + (k-1)*(sw+cellGap) + sw/2, gTop(b) + 1.7, sprintf('k=%d',k), ...
                'VerticalAlignment','middle', 'FontSize',fs-1);
        end
        % i-індекси ліворуч від блоку
        for i = 1:4
            text(axOv, gx - 4.5, gTop(b) - i*sw - (i-1)*cellGap + sw/2, sprintf('i=%d',i), ...
                'Clipping','off', 'Color','k', 'FontSize',fs-1, 'Rotation',90, ...
                'HorizontalAlignment','center', 'VerticalAlignment','middle');
        end

        % горизонтальний colorbar під НИЖНІМ блоком (шкала спільна на всі блоки)
        if isLast
            cbY = marB + cbTickH;
            cbAx = axes('Parent',figH, 'Units','normalized', 'Position',nrm(gx, cbY, grpW, cbH));
            disableDefaultInteractivity(cbAx);
            imagesc(cbAx, cl, [0 1], linspace(cl(1),cl(2),256));
            colormap(cbAx, rgb);  clim(cbAx, cl);
            set(cbAx, 'YTick',[], 'XLim',cl, 'Box','on', 'LineWidth',FIG.line.axis, ...
                    'TickDir','out', 'FontSize',fs, 'XColor','k', 'YColor','k', 'XAxisLocation','bottom');
            if isMod
                set(cbAx, 'XTick',cl, 'XTickLabel', endlbl(cl(1), cl(2)));
                isNorm = ~(isfield(FIG,'data') && isfield(FIG.data,'normalize') && ~FIG.data.normalize);
                lab(gx + grpW/2, cbY + cbH + 2.2, tern(isNorm,'|f_{ik} / f_{11}|','|f_{ik}|  (a.u.)'), ...
                    'VerticalAlignment','middle', 'FontSize',fs-1);
            else
                set(cbAx, 'XTick',argTicks(cl), 'XTickLabel',argTickLbl(cl));
                lab(gx + grpW/2, cbY + cbH + 2.2, 'arg(f_{ik})  (rad)', 'VerticalAlignment','middle', 'FontSize',fs-1);
            end
        end
    end

    % підпис фазового вікна над блоком + лінія на всю ширину контенту
    ruleY = gTop(b) + hdrH - 1.5;
    xL = grpX.mod;  xR = grpX.arg + grpW;
    lab((xL+xR)/2, ruleY + 3.4, FIG.phase(b).label, 'VerticalAlignment','middle');
    line(axOv, [xL xR], [ruleY ruleY], 'Color','k', 'LineWidth',0.5);
end

% заголовок рисунка
lab(Wa/2, Ha - marT*0.42, 'Mueller matrix — modulus and argument of all f_{ik}', ...
    'FontWeight', tern(FIG.panel.letterBold,'bold','normal'), 'VerticalAlignment','middle');

uistack(axOv, 'top');
end

% ======================================================================
function add_scalebar(ax, xr, yr, yDir, fs)
% Масштабна лінійка (px) у нижньому-лівому куті панелі — замість осей.
spanx = max(xr(:)) - min(xr(:));
spany = max(yr(:)) - min(yr(:));
if ~(spanx > 0 && spany > 0); return; end
cand = [25 50 100 200 250 500 1000];
[~, j] = min(abs(cand - 0.32*spanx));
L = cand(j);
x1 = min(xr(:)) + 0.09*spanx;
if strcmpi(yDir,'reverse')
    yB = max(yr(:)) - 0.13*spany;  yT = yB - 0.075*spany;
else
    yB = min(yr(:)) + 0.13*spany;  yT = yB + 0.075*spany;
end
hold(ax,'on');
line(ax, [x1 x1+L], [yB yB], 'Color','w', 'LineWidth',2.2, 'Clipping','on');
text(ax, x1 + L/2, yT, sprintf('%g px', L), 'Color','w', 'FontSize',fs-2, ...
     'HorizontalAlignment','center', 'VerticalAlignment','middle', 'Clipping','on');
hold(ax,'off');
end

% ======================================================================
function M = cmap_rgb(spec, n)
if isnumeric(spec); M = spec; else; M = feval(spec, n); end
end

function cl = cliplim(v, pct)
v = v(isfinite(v));
if isempty(v); cl = [0 1]; return; end
if pct > 0
    cl = [prctile(v, pct), prctile(v, 100-pct)];
else
    cl = [min(v), max(v)];
end
if ~(cl(2) > cl(1)); cl = cl(1) + [0 1]; end
end

function s = numlbl(v)
if v == 0
    s = '0';
elseif abs(v) >= 1e-3 && abs(v) < 1e4
    s = num2str(v, '%.2g');
else
    s = num2str(v, '%.0e');
end
end

function labs = endlbl(lo, hi)
% Мізерний проти діапазону кінець осі -> '0' (а не '1e-05').
thr = max(1e-4, 0.01 * abs(hi - lo));
labs = { tern(abs(lo) < thr, '0', numlbl(lo)), tern(abs(hi) < thr, '0', numlbl(hi)) };
end

function out = tern(c,a,b); if c; out = a; else; out = b; end; end

% ------------------------------------------------------------------------
function t = argTicks(cl)
% мітки шкали аргументу: 0, pi, 2pi  або  -pi, 0, pi
t = [cl(1) mean(cl) cl(2)];
end

function l = argTickLbl(cl)
if cl(1) >= 0, l = {'0','\pi','2\pi'}; else, l = {'-\pi','0','\pi'}; end
end
