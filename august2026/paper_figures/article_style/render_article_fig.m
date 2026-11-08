function figH = render_article_fig(R, A)
% RENDER_ARTICLE_FIG  Рисунок "як у статті" з довільної сітки панелей.
%   Усе малюється на ОДНИХ осях у міліметрах (y вниз), кеглі/лінії — з article_style.
%
%   R.rows  : {рядок1, рядок2, ...}, рядок = {панель, панель, ...} (у рядку — один тип)
%   R.W     : ширина рисунка, мм (типово A.W = 85)
%   R.colGap: проміжок між колонками, мм (типово A.colGap)
%
%   Панель — struct з полем .type:
%   'map'   : .img (рядок 1 = низ, NaN -> білий) або [], .xr/.yr (межі осей у даних),
%             .xt/.xtl, .yt/.ytl (поділки й підписи), .cmap, .lim, .ct/.ctl (шкала кольору),
%             .cmult (показник множника x10^n над шкалою, 0 — нема), .title, .xlab, .ylab,
%             .cross, .inset ('' | 'mod' | 'arg' — вставка x4 з цих самих даних),
%             .contour (рівень або []), .lines (struct x,y,color,style,width), .pts (x,y,v)
%   'hist'  : .v (значення), .xl, .xt/.xtl, .xm (дрібні поділки), .color, .name (підпис осі x),
%             .nbins; верх осі sigma = справжній максимум стовпчика
%   'curve' : .lines (struct x,y,color,style,width,marker,msize), .xl/.yl, .xt/.xtl, .yt/.ytl,
%             .ylab (над віссю), .ymult, .name (підпис осі x), .title, .legend ({текст, колір; ...}),
%             .annot (текст унизу поля), .grid
%   Літера панелі — .letter.

if ~isfield(R, 'W');      R.W = A.W;           end
if ~isfield(R, 'colGap'); R.colGap = A.colGap; end
fs = A.fs;

% ---------- макет ----------
nr = numel(R.rows);
G = struct('h', cell(1, nr));
for r = 1:nr
    row = R.rows{r};  nc = numel(row);
    colW = (R.W - 2*A.margin - (nc-1)*R.colGap) / nc;
    G(r).colW = colW;  G(r).colX = A.margin + (0:nc-1) * (colW + R.colGap);
    G(r).type = row{1}.type;
    if strcmp(G(r).type, 'map')
        yl = 1;  cl = 1;
        for c = 1:nc
            yl = max([yl, cellfun(@vis_len, row{c}.ytl)]);
            cl = max([cl, cellfun(@vis_len, row{c}.ctl)]);
        end
        G(r).mapL = A.tick + A.pad + yl*A.DIGIT*fs + 1.7 + 1.0*fs;
        mapR = A.cbGap + A.cbW + A.tick + A.pad + cl*A.DIGIT*fs;
        G(r).S = colW - G(r).mapL - mapR;
        G(r).h = A.mapT + G(r).S + A.mapB + A.letterH;
    else
        hasT = any(cellfun(@(p) isfield(p,'title') && ~isempty(p.title), row));
        hasL = any(cellfun(@(p) isfield(p,'legend') && ~isempty(p.legend), row));
        G(r).top = A.histT;  if hasT; G(r).top = A.mapT; end
        if hasL; G(r).top = G(r).top + 1.0*fs; end      % легенда — окремим рядком над підписом осі
        G(r).hasL = hasL;
        G(r).h = G(r).top + A.histH + A.histB + A.letterH;
    end
end
H = 2*A.margin + sum([G.h]) + (nr-1)*A.rowGap;

figH = figure('Theme','light', 'Units','centimeters', 'Position',[2 2 R.W/10 H/10], 'Color','w', ...
    'PaperUnits','centimeters', 'PaperSize',[R.W H]/10, 'PaperPositionMode','manual', ...
    'PaperPosition',[0 0 R.W H]/10, 'InvertHardcopy','off', 'Visible','off');
ax = axes('Parent',figH, 'Units','normalized', 'Position',[0 0 1 1], ...
    'XLim',[0 R.W], 'YLim',[0 H], 'YDir','reverse', 'DataAspectRatio',[1 1 1], ...
    'Visible','off', 'Clipping','off');
hold(ax, 'on');

y = A.margin;
for r = 1:nr
    for c = 1:numel(R.rows{r})
        p = R.rows{r}{c};  x0 = G(r).colX(c);
        switch p.type
            case 'map',   draw_map(ax, A, x0, y, G(r), p);
            case 'hist',  draw_hist(ax, A, x0, y, G(r), p);
            case 'curve', draw_curve(ax, A, x0, y, G(r), p);
        end
    end
    y = y + G(r).h + A.rowGap;
end
end

% =====================================================================
function draw_map(ax, A, x0, y0, G, p)
fs = A.fs;  S = G.S;
mx = x0 + G.mapL;  my = y0 + A.mapT;
X = @(v) mx + (v - p.xr(1)) / (p.xr(2) - p.xr(1)) * S;
Y = @(v) my + S - (v - p.yr(1)) / (p.yr(2) - p.yr(1)) * S;

txt(ax, A, mx + S/2, my - 0.35*A.ft, p.title, A.titlePt, 'center', 'FontWeight','bold');
if ~isempty(p.img)
    img(ax, mx, my, S, S, to_rgb(flipud(p.img), p.lim, p.cmap, A.nanColor));
end
if isfield(p,'contour') && ~isempty(p.contour) && ~isempty(p.img)
    [ny, nx] = size(p.img);
    xv = linspace(p.xr(1), p.xr(2), nx+1);  xv = (xv(1:end-1) + xv(2:end)) / 2;
    yv = linspace(p.yr(1), p.yr(2), ny+1);  yv = (yv(1:end-1) + yv(2:end)) / 2;
    Cm = contourc(xv, yv, p.img, [p.contour p.contour]);
    k = 1;
    while k < size(Cm, 2)
        nP = Cm(2, k);  seg = Cm(:, k+1:k+nP);
        ln(ax, X(seg(1,:)), Y(seg(2,:)), [0 0 0], A.lineMM);
        k = k + nP + 1;
    end
end
if isfield(p,'pts') && ~isempty(p.pts) && ~isempty(p.pts.x)
    rgb = squeeze(to_rgb(p.pts.v(:), p.lim, p.cmap, A.nanColor));
    if isvector(rgb); rgb = reshape(rgb, 1, 3); end
    scatter(ax, X(p.pts.x(:)), Y(p.pts.y(:)), A.ptSize, rgb, 'filled', 'MarkerEdgeColor','none');
end
if isfield(p,'lines')
    for L = p.lines(:).'
        line(ax, X(L.x), Y(L.y), 'Color', L.color, 'LineStyle', L.style, ...
            'LineWidth', L.width, 'Clipping','off');
    end
end
if isfield(p,'cross') && p.cross
    c = [mx + S/2, my + S/2];  r = A.crossR;
    ln(ax, [c(1)-r c(1)+r], [c(2) c(2)], [1 1 1], A.crossMM);
    ln(ax, [c(1) c(1)], [c(2)-r c(2)+r], [1 1 1], A.crossMM);
end
if isfield(p,'inset') && ~isempty(p.inset)
    % вставка x4: фрагмент цих самих даних навколо A.insetCenter, без згладжування
    [ny, nx] = size(p.img);
    k = A.insetSize * S;
    nSrc = round(A.insetSize * nx / A.insetZoom);
    cxp = round(A.insetCenter(1) * nx);  cyp = round(A.insetCenter(2) * ny);
    ix = max(1, cxp - floor(nSrc/2)) + (0:nSrc-1);  iy = max(1, cyp - floor(nSrc/2)) + (0:nSrc-1);
    ix = ix(ix <= nx);  iy = iy(iy <= ny);
    img(ax, mx + S - k, my, k, k, to_rgb(flipud(p.img(iy, ix)), p.lim, p.cmap, A.nanColor));
    frame(ax, mx + S - k, my, k, k, [0 0 0], A.lineMM);
    Xp = @(v) mx + v / nx * S;  Yp = @(v) my + S - v / ny * S;      % квадратик — звідки взято фрагмент
    frame(ax, Xp(ix(1)-1), Yp(iy(end)), Xp(ix(end)) - Xp(ix(1)-1), Yp(iy(1)-1) - Yp(iy(end)), ...
        A.insetSrcColor, A.lineMM);
    txt(ax, A, mx + S - k + 0.4, my + k - 0.4, sprintf('\\times%d', A.insetZoom), A.insetLabelPt, 'left', ...
        'FontWeight','bold', 'Color', A.insetLabelColor.(p.inset));
end
frame(ax, mx, my, S, S, [0 0 0], A.lineMM);
note(ax, A, mx + S/2, my + S/2, p);

for i = 1:numel(p.xt)
    ln(ax, [X(p.xt(i)) X(p.xt(i))], [my+S my+S+A.tick], [0 0 0], A.lineMM);
    txt(ax, A, X(p.xt(i)), my + S + A.tick + A.pad + 0.72*fs, p.xtl{i}, A.fontPt, 'center');
end
for i = 1:numel(p.yt)
    ln(ax, [mx-A.tick mx], [Y(p.yt(i)) Y(p.yt(i))], [0 0 0], A.lineMM);
    txt(ax, A, mx - A.tick - A.pad, Y(p.yt(i)) + 0.36*fs, p.ytl{i}, A.fontPt, 'right');
end
ya = my + S + A.tick + A.pad + fs + 0.9;
arrow(ax, A, mx + 0.3*S, ya, mx + 0.75*S, ya);
txt(ax, A, mx + 0.525*S, ya + 0.7 + 0.75*fs, p.xlab, A.fontPt, 'center');   % 0.7: «k», «/», «Δ» вищі за «x»
xa = mx - G.mapL + 1.0*fs + 0.8;            % = mx - поділки - підписи - 0.9 (як у Fig1)
arrow(ax, A, xa, my + 0.75*S, xa, my + 0.25*S);
txt(ax, A, xa - 0.5 - 0.25*fs, my + S/2, p.ylab, A.fontPt, 'center', 'Rotation', 90);

% шкала кольору
cx = mx + S + A.cbGap;
grad = repmat(permute(flipud(p.cmap), [1 3 2]), 1, 2);   % 2 стовпці: при одному MATLAB звужує зображення
img(ax, cx, my, A.cbW, S, grad);
frame(ax, cx, my, A.cbW, S, [0 0 0], A.lineMM);
for i = 1:numel(p.ct)
    yy = my + S - (p.ct(i) - p.lim(1)) / (p.lim(2) - p.lim(1)) * S;
    ln(ax, [cx+A.cbW cx+A.cbW+A.tick*0.7], [yy yy], [0 0 0], A.lineMM);
    txt(ax, A, cx + A.cbW + A.tick + A.pad, yy + 0.36*fs, p.ctl{i}, A.fontPt, 'left');
end
if isfield(p,'cmult') && p.cmult ~= 0
    txt(ax, A, cx, my - 0.25*A.ft, sprintf('\\times10^{%d}', p.cmult), A.fontPt, 'left');
end
txt(ax, A, mx + S/2, y0 + G.h - 0.25*A.fl, ['(' p.letter ')'], A.letterPt, 'center');
end

% =====================================================================
function draw_hist(ax, A, x0, y0, G, p)
fs = A.fs;
if isfield(p,'note') && ~isempty(p.note)          % «мало даних»: порожнє поле з написом, без шкали sigma
    px = x0 + A.tick + A.pad + 2*A.DIGIT*fs;  pw = x0 + G.colW - px - 0.6*fs;
    py = y0 + G.top;  ph = A.histH;
    frame(ax, px, py, pw, ph, [0 0 0], A.lineMM);
    note(ax, A, px + pw/2, py + ph/2, p);
    txt(ax, A, px + pw/2, py + ph + A.tick + A.pad + fs + 0.6 + 0.8*fs, p.name, A.fontPt, 'center');
    txt(ax, A, px + pw/2, y0 + G.h - 0.25*A.fl, ['(' p.letter ')'], A.letterPt, 'center');
    return;
end
v = p.v(isfinite(p.v));
nb = A.nbins;  if isfield(p,'nbins') && ~isempty(p.nbins); nb = p.nbins; end
edges = linspace(p.xl(1), p.xl(2), nb + 1);
cnt = histcounts(v, edges);
% верх осі sigma = справжній максимум (кількість точок у найвищому стовпчику), без округлення вгору
top = max(max(cnt), 1);
if top >= 1e4; ex = floor(log10(top)); else; ex = 0; end
nd = A.yDiv;
ylab = containers.Map('KeyType','double','ValueType','char');
ylab(0) = '0';  ylab(nd/2) = sig2(top/2 / 10^ex);  ylab(nd) = sig2(top / 10^ex);
labw = max(cellfun(@numel, values(ylab))) * A.DIGIT * fs;

px = x0 + A.tick + A.pad + labw;
pw = x0 + G.colW - px - 0.6*fs;
py = y0 + G.top;  ph = A.histH;
X = @(u) px + (u - p.xl(1)) / (p.xl(2) - p.xl(1)) * pw;
Y = @(u) py + ph - u / top * ph;

for u = [p.xt(:).' p.xm(:).'];  ln(ax, [X(u) X(u)], [py py+ph], A.gridColor, A.gridMM);  end
for i = 0:nd;  ln(ax, [px px+pw], [Y(i*top/nd) Y(i*top/nd)], A.gridColor, A.gridMM);  end
for b = 1:numel(cnt)
    if cnt(b) <= 0; continue; end
    xa = X(edges(b));  xb = X(edges(b+1));  yt = Y(min(cnt(b), top));
    patch(ax, [xa xb xb xa], [py+ph py+ph yt yt], p.color, 'EdgeColor', A.edgeColor, ...
        'LineWidth', A.edgeMM / A.PT);
end
ln(ax, [px px+pw], [py+ph py+ph], [0 0 0], A.lineMM);
ln(ax, [px px], [py py+ph], [0 0 0], A.lineMM);
for i = 1:numel(p.xt)
    ln(ax, [X(p.xt(i)) X(p.xt(i))], [py+ph py+ph+A.tick], [0 0 0], A.lineMM);
    txt(ax, A, X(p.xt(i)), py + ph + A.tick + A.pad + 0.72*fs, p.xtl{i}, A.fontPt, 'center');
end
for u = p.xm(:).';  ln(ax, [X(u) X(u)], [py+ph py+ph+0.6*A.tick], [0 0 0], A.lineMM);  end
for i = 0:nd
    isLab = isKey(ylab, i);
    ln(ax, [px - A.tick*(1 - 0.4*~isLab) px], [Y(i*top/nd) Y(i*top/nd)], [0 0 0], A.lineMM);
    if isLab
        txt(ax, A, px - A.tick - A.pad, Y(i*top/nd) + 0.36*fs, ylab(i), A.fontPt, 'right');
    end
end
txt(ax, A, px, py - 0.45*fs, char(963), A.fontPt, 'center');
if ex ~= 0
    txt(ax, A, px + 0.9*fs, py - 0.45*fs, sprintf('\\times10^{%d}', ex), A.fontPt, 'left');
end
txt(ax, A, px + pw/2, py + ph + A.tick + A.pad + fs + 0.6 + 0.8*fs, p.name, A.fontPt, 'center');
txt(ax, A, px + pw/2, y0 + G.h - 0.25*A.fl, ['(' p.letter ')'], A.letterPt, 'center');
end

% =====================================================================
function draw_curve(ax, A, x0, y0, G, p)
fs = A.fs;
labw = max([1, cellfun(@vis_len, p.ytl)]) * A.DIGIT * fs;
px = x0 + A.tick + A.pad + labw;
pw = x0 + G.colW - px - 0.6*fs;
py = y0 + G.top;  ph = A.histH;
X = @(u) px + (u - p.xl(1)) / (p.xl(2) - p.xl(1)) * pw;
Y = @(u) py + ph - (u - p.yl(1)) / (p.yl(2) - p.yl(1)) * ph;

if isfield(p,'title') && ~isempty(p.title)
    txt(ax, A, px + pw/2, py - 0.35*A.ft, p.title, A.titlePt, 'center', 'FontWeight','bold');
end
if ~isfield(p,'grid') || p.grid
    for u = p.xt(:).';  ln(ax, [X(u) X(u)], [py py+ph], A.gridColor, A.gridMM);  end
    for u = p.yt(:).';  ln(ax, [px px+pw], [Y(u) Y(u)], A.gridColor, A.gridMM);  end
end
for L = p.lines(:).'
    xx = L.x(:).';  yy = L.y(:).';
    ok = isfinite(xx) & isfinite(yy) & xx >= p.xl(1) & xx <= p.xl(2);
    xx = xx(ok);  yy = min(max(yy(ok), p.yl(1)), p.yl(2));
    if isempty(xx); continue; end
    mk = 'none';  ms = 3;
    if isfield(L,'marker') && ~isempty(L.marker); mk = L.marker; end
    if isfield(L,'msize') && ~isempty(L.msize); ms = L.msize; end
    line(ax, X(xx), Y(yy), 'Color', L.color, 'LineStyle', L.style, 'LineWidth', L.width, ...
        'Marker', mk, 'MarkerSize', ms, 'MarkerFaceColor', L.color, 'MarkerEdgeColor', 'none', ...
        'Clipping','off');
end
frame(ax, px, py, pw, ph, [0 0 0], A.lineMM);
note(ax, A, px + pw/2, py + ph/2, p);
for i = 1:numel(p.xt)
    ln(ax, [X(p.xt(i)) X(p.xt(i))], [py+ph py+ph+A.tick], [0 0 0], A.lineMM);
    txt(ax, A, X(p.xt(i)), py + ph + A.tick + A.pad + 0.72*fs, p.xtl{i}, A.fontPt, 'center');
end
for i = 1:numel(p.yt)
    ln(ax, [px - A.tick px], [Y(p.yt(i)) Y(p.yt(i))], [0 0 0], A.lineMM);
    txt(ax, A, px - A.tick - A.pad, Y(p.yt(i)) + 0.36*fs, p.ytl{i}, A.fontPt, 'right');
end
txt(ax, A, px, py - 0.45*fs, p.ylab, A.fontPt, 'center');
if isfield(p,'ymult') && p.ymult ~= 0
    txt(ax, A, px + 0.5*fs + vis_len(p.ylab)*0.3*fs, py - 0.45*fs, sprintf('\\times10^{%d}', p.ymult), A.fontPt, 'left');
end
% легенда й примітка — над полем, справа (не перекривають криві)
xr = px + pw;  yb = py - 0.45*fs;  f8 = (A.fontPt - 1) * A.PT;
if isfield(p,'annot') && ~isempty(p.annot)
    txt(ax, A, xr, yb, p.annot, A.fontPt, 'right');
end
yb = yb - 1.0*fs;                                  % легенда — рядком вище (місце дає макет)
if isfield(p,'legend') && ~isempty(p.legend)
    for i = size(p.legend, 1):-1:1
        txt(ax, A, xr, yb, p.legend{i,1}, A.fontPt - 1, 'right');
        xr = xr - vis_len(p.legend{i,1}) * 0.55 * f8 - 0.5;
        ln(ax, [xr - 2.2, xr], [yb yb] - 0.3*f8, p.legend{i,2}, 1.0 * A.PT);
        xr = xr - 2.2 - 1.2;
    end
    if isfield(p,'legendTitle') && ~isempty(p.legendTitle)
        txt(ax, A, xr + 0.4, yb, p.legendTitle, A.fontPt - 1, 'right');
    end
end
txt(ax, A, px + pw/2, py + ph + A.tick + A.pad + fs + 0.6 + 0.8*fs, p.name, A.fontPt, 'center');
txt(ax, A, px + pw/2, y0 + G.h - 0.25*A.fl, ['(' p.letter ')'], A.letterPt, 'center');
end

% =====================================================================
function note(ax, A, xc, yc, p)
% напис «мало даних» (рядки розділені '|') по центру поля панелі
if ~isfield(p,'note') || isempty(p.note); return; end
L = strsplit(p.note, '|');  dy = 1.15 * (A.fontPt - 1) * A.PT;
for i = 1:numel(L)
    txt(ax, A, xc, yc + (i - (numel(L)+1)/2) * dy + 0.35*(A.fontPt-1)*A.PT, L{i}, A.fontPt - 1, 'center', ...
        'Color', [0.45 0.45 0.45]);
end
end

function n = vis_len(s)
% видима довжина підпису (без TeX-команд і дужок)
n = numel(regexprep(s, '\\[a-zA-Z]+|[{}^_]', ''));
end

function txt(ax, A, x, y, s, pt, halign, varargin)
% MATLAB ставить TeX-рядки (\it, індекси, ^) на низ виносних елементів, а не на базову лінію:
% зсуваємо їх униз на виносний елемент Arial (0.212 кегля). Пробіли в TeX-рядках MATLAB
% розширює — замінюємо на тонкий пробіл (U+2009), ширина тоді як у звичайного тексту.
if any(s == '\') || any(s == '_') || any(s == '^')
    d = 0.212 * pt * A.PT;
    rot = 0;  k = find(strcmpi(varargin(1:2:end), 'Rotation'));
    if ~isempty(k); rot = varargin{2*k}; end
    x = x + d * sind(rot);  y = y + d * cosd(rot);
    s = strrep(s, ' ', char(8201));
end
text(ax, x, y, s, 'FontName', A.font, 'FontUnits','points', 'FontSize', pt, ...
    'HorizontalAlignment', halign, 'VerticalAlignment', 'baseline', ...
    'Interpreter','tex', 'Clipping','off', 'Color',[0 0 0], varargin{:});   % чорний явно (тема MATLAB дає сірий)
end

function ln(ax, xs, ys, col, mm)
line(ax, xs, ys, 'Color', col, 'LineWidth', mm / (25.4/72), 'Clipping','off');
end

function frame(ax, x, y, w, h, col, mm)
ln(ax, [x x+w x+w x x], [y y y+h y+h y], col, mm);
end

function img(ax, x, y, w, h, rgb)
[nr, nc, ~] = size(rgb);
image(ax, 'XData', [x + w/(2*nc), x + w - w/(2*nc)], 'YData', [y + h/(2*nr), y + h - h/(2*nr)], 'CData', rgb);
end

function arrow(ax, A, x1, y1, x2, y2)
ln(ax, [x1 x2], [y1 y2], [0 0 0], A.lineMM);
d = [x2-x1, y2-y1];  d = d / norm(d);  n = [-d(2) d(1)];
Lh = 0.9;  Wh = 0.35;
p1 = [x2 y2];  b = p1 - Lh*d;
patch(ax, [p1(1) b(1)+Wh*n(1) b(1)-Wh*n(1)], [p1(2) b(2)+Wh*n(2) b(2)-Wh*n(2)], [0 0 0], 'EdgeColor','none');
end

function rgb = to_rgb(M, lim, cmap, nanc)
t = (M - lim(1)) / (lim(2) - lim(1));
idx = min(size(cmap,1), max(1, floor(t * size(cmap,1)) + 1));
idx(~isfinite(M)) = 1;
rgb = zeros([size(M) 3]);
for c = 1:3
    ch = reshape(cmap(idx, c), size(M));
    ch(~isfinite(M)) = nanc(c);
    rgb(:,:,c) = ch;
end
end

function s = sig2(v)
% підпис значення: 2 значущі цифри (як у вихідних рисунках: 2.1 x 10^4, 1.6)
if v == 0; s = '0'; return; end
s = sprintf('%g', round(v, 2 - ceil(log10(abs(v)))));
end
