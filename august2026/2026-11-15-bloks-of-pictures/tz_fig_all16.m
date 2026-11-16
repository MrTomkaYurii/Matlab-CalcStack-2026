function [rows, files] = tz_fig_all16(FIG, A, b, figNo, algo, win, outDir, T)
% TZ_FIG_ALL16  Рис.1–3 блоку: усі 16 елементів f11..f44 одного прикладу (b.main).
%   Два PNG — модулі (|f_ik|, нормовано 0..1, jet) і аргументи (Arg f_ik, 0..2π, CET-C6),
%   сітка 4×4, як Fig7 «формат статті». Межа модуля — спільна для всіх 16 елементів.
%   Порожні елементи (немає вхідних каналів) — біла панель з написом.
%   rows : рядки стат-моментів (|f| лінійні, Arg — кругові) для всіх 16 елементів.

api = make_fig_article('api');
rows = {};
base = fullfile(outDir, sprintf('Рис%d', figNo));
files = {[base '.mod.png'], [base '.arg.png']};
csvf  = fullfile(outDir, '_службові файли', sprintf('Рис%d.stats.csv', figNo));
if ~T.overwrite && all(cellfun(@isfile, [files {csvf}]))
    rows = readcell(csvf, 'Encoding','UTF-8');  rows = rows(2:end, :);
    fprintf('  [є] %s\n', base);  return;
end

D = tz_read(FIG, b.sample, b.main, algo, win);
pool = [];
for i = 1:4
    for k = 1:4
        m = D.data.(sprintf('f%d%d', i, k)).mod;  pool = [pool; m(isfinite(m))]; %#ok<AGROW>
    end
end
modLim = 1;  if ~isempty(pool); modLim = prctile(pool, 100 - A.modClipPct); end

meta = struct('block',b.id, 'sub','', 'fig',sprintf('Рис.%d', figNo), 'col','', ...
    'sample',b.sample, 'example',b.main, 'algo',algo, 'win',win, 'elem','');
R.W = A.W;  R.colGap = 0.8;
for comp = {'mod','arg'}
    R.rows = cell(1, 4);  L = 0;
    for i = 1:4
        R.rows{i} = cell(1, 4);
        for k = 1:4
            e = sprintf('f%d%d', i, k);
            M = D.data.(e).(comp{1});
            [ny, nx] = size(M);
            P = struct('type','map', 'title','', 'img',[], 'xr',[0 nx], 'yr',[0 ny], ...
                'xt',[], 'xtl',{{}}, 'yt',[], 'ytl',{{}}, 'cmap',jet(256), 'lim',[0 1], ...
                'ct',[], 'ctl',{{}}, 'cmult',0, 'xlab','\itx\rm, pix', 'ylab','\ity\rm, pix', ...
                'cross',true, 'inset','', 'contour',[], 'lines',api.cline([],[],[0 0 0],'-',0.5), ...
                'pts',[], 'letter','', 'note','');
            P.lines = P.lines([]);
            [P.xt, P.xtl] = api.ticks_lab([0 nx/2 nx]);  [P.yt, P.ytl] = api.ticks_lab([0 ny/2 ny]);
            m1 = meta;  m1.elem = e;  m1.col = sprintf('%d,%d', i, k);
            if strcmp(comp{1}, 'mod')
                P.title = sprintf('|f_{%d%d}|', i, k);
                P.img = M / modLim;  P.lim = [0 1];  P.cmap = jet(256);
                [P.ct, P.ctl] = api.ticks_lab(A.modTicks);
                rows(end+1, :) = tz_stats(m1, 'карта |f|', M, false); %#ok<AGROW>
            else
                P.title = sprintf('Arg f_{%d%d}', i, k);
                P.img = mod(M, 2*pi);  P.lim = [0 2*pi];  P.cmap = cet_c6(256);
                P.ct = A.argTicks * pi;  P.ctl = api.pi_labels(A.argTicks);
                rows(end+1, :) = tz_stats(m1, 'карта Arg (кругові)', mod(M, 2*pi), true); %#ok<AGROW>
            end
            P.inset = comp{1};                        % вставка ×4, як на картах Рис.4–8 / Fig1 статті
            if ~any(isfinite(M(:)))
                P.img = [];  P.inset = '';  P.note = 'порожній|канал';
            end
            L = L + 1;  P.letter = char('a' + L - 1);
            R.rows{i}{k} = P;
        end
    end
    f = sprintf('%s.%s.png', base, comp{1});
    if ~exist(outDir, 'dir'); mkdir(outDir); end
    h = render_article_fig(R, A);
    exportgraphics(h, f, 'Resolution', T.dpi, 'BackgroundColor','white', 'Padding','figure');
    close(h);
end
tz_write_csv(csvf, rows);
fprintf('  [ok] %s  (%s, %s, 0–%gπ)\n', base, b.sample, algo, win);
end
