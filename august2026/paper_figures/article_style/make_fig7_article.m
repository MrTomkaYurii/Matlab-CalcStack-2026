function n = make_fig7_article(scope)
% MAKE_FIG7_ARTICLE  Fig7 (повна матриця Мюллера) "як у статті" — у стилі рисунків S1–S4:
%   сітка 4x4 карт f11..f44, ширина 175 мм, кожна карта з осями, шкалою кольору й хрестиком.
%   На кожне фазове вікно — ДВА рисунки: модуль (|f_ik|, нормовано 0..1, jet) і аргумент
%   (Arg f_ik, 0..2pi, CET-C6). Межа модуля спільна для всіх 16 елементів і всіх 8 вікон.
%
%   scope : .samples, .examples, .variants, .phases, .overwrite, .docx — як у make_fig_article
%   Вивід : <outRoot>\Fig7\png\<variant>\<Відсутні вхідні канали | Усі вхідні канали>\
%           Fig7.mueller.OX.heart.zrazok1.phase01.0-2pi.<mod|arg>.png

here = fileparts(mfilename('fullpath'));
addpath(here, fullfile(fileparts(here), 'common'), fileparts(here), ...
        fullfile(fileparts(fileparts(here)), 'core'));
if nargin < 1; scope = struct(); end
FIG = apply_fig_params(cfg_figures(), 'fig07');
C = FIG.fig07;
A = article_style();
outRoot = 'C:\August 2026-Results\Розрахунки - Скомпановані рисунки - Формат статті 09.11';
if isfield(FIG.out, 'rootArticle'); outRoot = FIG.out.rootArticle; end
if isfield(scope, 'outRoot'); outRoot = scope.outRoot; end

phases = 1:8;  if isfield(scope, 'phases'); phases = scope.phases; end
samples  = pick(scope, 'samples',  C.samples);
examples = pick(scope, 'examples', C.examples);
variants = C.variants;
if isfield(scope, 'variants')
    variants = variants(cellfun(@(v) any(strcmp(v.tag, scope.variants)), variants));
end
overwrite = isfield(scope, 'overwrite') && scope.overwrite;
R.W = 175;  R.colGap = 0.8;                 % як S1–S4
% підтеки: рисунки з порожніми елементами (немає вхідних каналів) — окремо від повних
SUB = {'Відсутні вхідні канали', 'Усі вхідні канали'};

n = 0;
for si = 1:numel(samples)
    sTag = FIG.sampleTag{strcmp(FIG.sampleTag(:,1), samples{si}), 2};
    for xi = 1:numel(examples)
        for vi = 1:numel(variants)
            v = variants{vi};
            vDir = fullfile(outRoot, 'Fig7', 'png', v.tag);
            base = arrayfun(@(k) sprintf('Fig7.mueller.%s.%s.zrazok%s.phase%02d.0-%gpi', ...
                v.tag, sTag, examples{xi}, k, 2 - 0.25*(k-1)), phases, 'uni', 0);
            if ~overwrite && any(cellfun(@(sub) all(cellfun(@(b) isfile(fullfile(vDir, sub, [b '.arg.png'])), base)), SUB))
                fprintf('  [є] %s\n', regexprep(base{1}, '\.phase.*', '')); continue;
            end
            W = cell(1, numel(phases));
            try
                for w = 1:numel(phases)
                    W{w} = tp_paper_read(FIG, samples{si}, examples{xi}, v, sprintf('phase_%02d_*', phases(w)));
                end
            catch ME
                fprintf(2, '  [skip] Fig7 / %s / %s / %s : %s\n', samples{si}, examples{xi}, v.tag, ME.message);
                continue;
            end
            pool = [];
            for w = 1:numel(W)
                for i = 1:4
                    for k = 1:4
                        m = W{w}.data.(sprintf('f%d%d', i, k)).mod;  pool = [pool; m(isfinite(m))]; %#ok<AGROW>
                    end
                end
            end
            modLim = 1;  if ~isempty(pool); modLim = prctile(pool, 100 - A.modClipPct); end
            % сортування: є елемент без жодного значення в усіх вікнах (порожні канали ex_90 / ey_0)
            missing = {};
            for i = 1:4
                for k = 1:4
                    e = sprintf('f%d%d', i, k);
                    if all(cellfun(@(D) ~any(isfinite(D.data.(e).mod(:))), W)); missing{end+1} = e; end %#ok<AGROW>
                end
            end
            outDir = fullfile(vDir, SUB{1 + isempty(missing)});
            if ~isempty(missing); fprintf('  відсутні канали: %s\n', strjoin(missing, ' ')); end
            if ~exist(outDir, 'dir'); mkdir(outDir); end
            readme(here, vDir, SUB);
            for w = 1:numel(W)
                for comp = {'mod','arg'}
                    try
                        R.rows = grid_rows(W{w}, comp{1}, modLim, A);
                        figH = render_article_fig(R, A);
                        f = fullfile(outDir, sprintf('%s.%s.png', base{w}, comp{1}));
                        exportgraphics(figH, f, 'Resolution', 600, 'BackgroundColor','white', 'Padding','figure');
                        close(figH);
                        n = n + 1;
                        fprintf('  [ok] %s.%s\n', base{w}, comp{1});
                    catch ME
                        fprintf(2, '  [fail] %s.%s : %s\n', base{w}, comp{1}, ME.message);
                        close all force;
                    end
                end
            end
        end
    end
end
if n > 0 && (~isfield(scope, 'docx') || scope.docx)
    st = system(sprintf('python "%s" "%s"', fullfile(here, 'make_figures_docx.py'), fullfile(outRoot, 'Fig7')));
    if st ~= 0; fprintf(2, '  [docx] помилка: make_figures_docx.py\n'); end
end
end

% =====================================================================
function rows = grid_rows(D, comp, modLim, A)
rows = cell(1, 4);  L = 0;
for i = 1:4
    rows{i} = cell(1, 4);
    for k = 1:4
        M = D.data.(sprintf('f%d%d', i, k)).(comp);
        [ny, nx] = size(M);
        T = struct('type','map', 'img',[], 'xr',[0 nx], 'yr',[0 ny], 'cmap',[], 'lim',[], ...
            'cmult',0, 'xlab','\itx\rm, pix', 'ylab','\ity\rm, pix', 'cross',true, 'inset','', ...
            'contour',[], 'pts',[], 'letter','');
        [T.xt, T.xtl] = tl([0 nx/2 nx]);  [T.yt, T.ytl] = tl([0 ny/2 ny]);
        if numel(D.ax.x) == nx && D.ax.x(1) < 0      % generalized: карта рознесень, осі Δx, Δy = -M..M
            T.xr = [D.ax.x(1)-0.5, D.ax.x(end)+0.5];  T.yr = [D.ax.y(1)-0.5, D.ax.y(end)+0.5];
            s = 10^floor(log10(max(D.ax.x)*0.7));  s = floor(max(D.ax.x)*0.7/s)*s;
            [T.xt, T.xtl] = tl([-s 0 s]);  T.yt = T.xt;  T.ytl = T.xtl;
            T.xlab = '\Delta\itx\rm, pix';  T.ylab = '\Delta\ity\rm, pix';
        end
        if strcmp(comp, 'mod')
            T.title = sprintf('|f_{%d%d}|', i, k);
            T.img = M / modLim;  T.lim = [0 1];  T.cmap = jet(256);
            [T.ct, T.ctl] = tl(A.modTicks);
        else
            T.title = sprintf('Arg f_{%d%d}', i, k);
            T.img = mod(M, 2*pi);  T.lim = [0 2*pi];  T.cmap = cet_c6(256);
            T.ct = A.argTicks * pi;  T.ctl = {'0', char(960), ['2' char(960)]};
        end
        L = L + 1;  T.letter = char('a' + L - 1);
        rows{i}{k} = T;
    end
end
end

function readme(here, vDir, SUB)
% «Прочитати обов'язково.docx» — однаковий в обох підтеках (пояснення порожніх каналів); раз на теку
persistent done
if isempty(done); done = {}; end
if any(strcmp(done, vDir)); return; end
dirs = cellfun(@(s) sprintf(' "%s"', fullfile(vDir, s)), SUB, 'uni', 0);
system(sprintf('python "%s"%s', fullfile(here, 'make_readme_docx.py'), [dirs{:}]));
done{end+1} = vDir;
end

function [t, l] = tl(t)
l = arrayfun(@(x) sprintf('%g', x), t, 'uni', 0);
end

function x = pick(s, f, d)
if isfield(s, f); x = s.(f); else; x = d; end
end
