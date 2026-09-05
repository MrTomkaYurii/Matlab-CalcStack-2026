function U = fs_util()
% FS_UTIL  Спільні хелпери діагностики f_ik (набір функцій-хендлів).
%   U.loadFields    — 6 станів ex_*/ey_*.mat -> IMG.(inPol).Ex/.Ey (+ inRC)
%   U.pair          — двоточковий зріз IMG -> A1,A2 (напрям, відстань)
%   U.rng           — рядок діапазону "min … max (mean)" у зручному записі
%   U.panel         — imagesc-панель у subplot зі спільним стилем
%   U.hist          — гістограма значень у subplot
%   U.save          — зберегти фігуру як <outDir>\<NN>.<name>.png
%   U.orderOf       — порядок величини (округлений показник 10^k)

U.loadFields = @loadFields;
U.pair       = @pairSlice;
U.rng        = @rngStr;
U.panel      = @panelMap;
U.hist       = @histPanel;
U.save       = @saveFig;
U.orderOf    = @orderOf;
U.eng        = @eng;
end

% ======================================================================
function [IMG, meta] = loadFields(matRoot, sample, example, crop, rcSource)
% Читає 6 станів (0,45,90,135,liv,prav), робить вирізку crop, будує inRC.
states  = {'0','45','90','135','liv','prav'};
inNames = {'in0','in45','in90','in135','inliv','inprav'};
d = fullfile(matRoot, sample, example, 'mat');
if ~isfolder(d); d = fullfile(matRoot, sample, 'mat'); end
if ~isfolder(d); d = fullfile(matRoot, sample); end

N = crop.size;  x0 = crop.x0;  y0 = crop.y0;
IMG = struct();  meta = struct('dir',d, 'zero',{{}}, 'varName','');
for s = 1:numel(states)
    ex = loadOne(fullfile(d, sprintf('ex_%s.mat', states{s})));
    ey = loadOne(fullfile(d, sprintf('ey_%s.mat', states{s})));
    if isempty(meta.varName); meta.varName = ex.name; end
    Ex = ex.X;  Ey = ey.X;
    if all(Ex(:)==0); meta.zero{end+1} = sprintf('ex_%s', states{s}); end
    if all(Ey(:)==0); meta.zero{end+1} = sprintf('ey_%s', states{s}); end
    IMG.(inNames{s}) = struct('Ex', crp(Ex,y0,x0,N), 'Ey', crp(Ey,y0,x0,N));
end
IMG.inRC = IMG.(['in' rcSource]);
end

function o = loadOne(f)
S = load(f);  vn = fieldnames(S);
X = S.(vn{1});
if isreal(X); X = complex(X); end
o = struct('X', X, 'name', vn{1});
end

function Y = crp(X, y0, x0, N)
if size(X,1) < y0+N-1 || size(X,2) < x0+N-1
    N = min([N, size(X,1)-y0+1, size(X,2)-x0+1]);
end
Y = X(y0:y0+N-1, x0:x0+N-1);
end

% ======================================================================
function [A1, A2] = pairSlice(IMG, direction, d)
% Двоточковий зріз: точка 1 -> точка 2 на відстані d уздовж напряму.
pols = {'in0','in45','in90','in135','inliv','inprav','inRC'};
N = size(IMG.in0.Ex, 1);
A1 = struct();  A2 = struct();
for p = 1:numel(pols)
    P = pols{p};
    if strcmpi(direction,'OY')
        r1 = 1:N-d;  c1 = 1:N;   r2 = 1+d:N;  c2 = 1:N;
    else
        r1 = 1:N;    c1 = 1:N-d; r2 = 1:N;    c2 = 1+d:N;
    end
    A1.(P) = struct('Ex', IMG.(P).Ex(r1,c1), 'Ey', IMG.(P).Ey(r1,c1));
    A2.(P) = struct('Ex', IMG.(P).Ex(r2,c2), 'Ey', IMG.(P).Ey(r2,c2));
end
end

% ======================================================================
function s = rngStr(X)
v = X(isfinite(X));
if isempty(v); s = '(порожньо)'; return; end
s = sprintf('%s … %s  (сер. %s)', eng(min(v)), eng(max(v)), eng(mean(abs(v))));
end

function s = eng(x)
if x == 0; s = '0'; return; end
if ~isfinite(x); s = num2str(x); return; end
a = abs(x);
if a >= 1e-3 && a < 1e4; s = sprintf('%.3g', x);
else; s = sprintf('%.2e', x); end
end

function k = orderOf(x)
x = abs(x(:));  x = x(x>0 & isfinite(x));
if isempty(x); k = NaN; else; k = round(log10(median(x))); end
end

% ======================================================================
function panelMap(ax, Z, ttl, cmapName, C)
imagesc(ax, Z);  axis(ax,'image');
set(ax, 'YDir','normal', 'FontName',C.fig.font, 'FontSize',C.fig.fontSize, ...
        'XColor','k', 'YColor','k', 'Box','on');
colormap(ax, cmapName);
cb = colorbar(ax);  set(cb, 'FontName',C.fig.font, 'FontSize',C.fig.fontSize-1, 'Color','k');
v = Z(isfinite(Z));
if ~isempty(v) && max(v) > min(v); clim(ax, [min(v) max(v)]); end
title(ax, ttl, 'FontName',C.fig.font, 'FontSize',C.fig.fontSize, 'FontWeight','normal', ...
      'Interpreter','tex', 'Color','k');
end

function histPanel(ax, X, ttl, C)
v = X(isfinite(X));
histogram(ax, v, 50, 'FaceColor',[0.55 0.55 0.55], 'EdgeColor',[0 0 0], 'LineWidth',0.3);
set(ax, 'Color','w', 'FontName',C.fig.font, 'FontSize',C.fig.fontSize, ...
        'XColor','k', 'YColor','k', 'Box','on');
grid(ax, 'on');
xlabel(ax, 'значення', 'Color','k');  ylabel(ax, 'к-сть пікселів', 'Color','k');
title(ax, ttl, 'FontName',C.fig.font, 'FontSize',C.fig.fontSize, 'FontWeight','normal', ...
      'Interpreter','tex', 'Color','k');
end

% ======================================================================
function outPath = saveFig(figH, outDir, idx, name, C)
if ~isfolder(outDir); mkdir(outDir); end
outPath = fullfile(outDir, sprintf('%02d.%s.png', idx, name));
try
    exportgraphics(figH, outPath, 'Resolution', C.fig.dpi, 'BackgroundColor','white');
catch
    print(figH, outPath, '-dpng', sprintf('-r%d', C.fig.dpi));
end
close(figH);
end
