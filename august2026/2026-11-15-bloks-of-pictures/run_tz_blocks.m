function run_tz_blocks(ids, opts)
% RUN_TZ_BLOCKS  Усі рисунки ТЗ «Нові рисунки» (15.11.2026) з УЖЕ порахованих result.mat.
%   f_ik не перераховуються: читаються готові карти (tp_paper_read), а АКФ, спектри,
%   вейвлети й скелетони будуються з них тим самим кодом, що й рисунки «формат статті».
%
%       run_tz_blocks                      % усі увімкнені блоки (cfg_tz_blocks: .enabled)
%       run_tz_blocks({'1','3'})           % лише ці блоки (у т.ч. вимкнені — явно названі)
%       run_tz_blocks({'1'}, struct('overwrite',true))
%       run_tz_blocks({}, struct('saveRoot','D:\...\Розрахунки - Двот. елем. ММ', 'out','D:\...'))
%
%   Вивід (T.out):
%     Блок N - <тканина> (eA-eB)\
%       Блок N.1 - АКФ\                       Рис1.mod/.arg … Рис3.mod/.arg, Рис4 … Рис8  (+ .stats.csv)
%       Блок N.2 - Спектри потужності\        Рис4 … Рис8
%       Блок N.3 - Вейвлети (a = 10, a = 55)\ Рис4 … Рис8
%       Блок N.4 - Скелетони\                 Рис4 … Рис8
%       Рисунки_Блок N.docx           усі рисунки блоку з підписами за ТЗ
%       Стат-моменти_Блок N.docx/.csv модулі, аргументи (КРУГОВІ), ортогональні АКФ,
%                                     спектри, вейвлет-коефіцієнти на двох масштабах, скелетони
%   Журнал: T.out\run_tz_blocks.log. Готові PNG пропускаються — прогін можна перезапускати.

here = fileparts(mfilename('fullpath'));
root = fileparts(here);                                    % ...\august2026
pf   = fullfile(root, 'paper_figures');
addpath(here, pf, fullfile(pf, 'common'), fullfile(pf, 'article_style'), fullfile(root, 'core'));
if nargin < 1; ids = {}; end
if nargin < 2; opts = struct(); end
ids = cellstr(ids);

T = cfg_tz_blocks();
for f = fieldnames(opts).'; T.(f{1}) = opts.(f{1}); end
FIG = cfg_figures();
if ~isempty(T.saveRoot); FIG.data.saveRoot = T.saveRoot; end
FIG.wav.cutScales  = T.wav.cutScales;
FIG.wav.scaleRange = T.wav.scaleRange;
A = tz_style();
warning('off', 'MATLAB:print:ContentTypeImageSuggested');

assert(isfolder(FIG.data.saveRoot), 'Немає даних: %s (скачати / перерахувати result.mat)', FIG.data.saveRoot);
if ~exist(T.out, 'dir'); mkdir(T.out); end
diary(fullfile(T.out, 'run_tz_blocks.log'));  diary on;
cleanup = onCleanup(@() diary('off'));
tz_read('reset');
t0 = tic;
fprintf('=== %s  дані: %s ===\n', datestr(now, 'dd.mm.yyyy HH:MM'), FIG.data.saveRoot);

for bi = 1:numel(T.blocks)
    b = T.blocks(bi);
    if isempty(ids)
        if ~b.enabled; fprintf('\n--- Блок %s вимкнено: %s\n', b.id, b.note); continue; end
    elseif ~any(strcmp(ids, b.id))
        continue;
    end
    t1 = tic;
    [e1, e2] = b.elems{:};
    bdir = fullfile(T.out, sprintf('Блок %s - %s (%s-%s)', b.id, b.name, e1, e2));
    fprintf('\n=== Блок %s: %s %s, %s / %s, вікно 0–%gπ ===\n', b.id, b.sample, ...
        strjoin([{b.main} b.others], ','), e1, e2, b.win);
    if ~isempty(b.note); fprintf('  ! %s\n', b.note); end
    rows = {};  cap = {};

    % ---------------- Рис.1–3: усі 16 елементів
    d16 = fullfile(bdir, sprintf('Блок %s.1 - %s', b.id, T.kinds(1).name));   % як у ТЗ: Рис.1–3 входять у Блок N.1
    spec16 = {1, 'XY', b.win; 2, 'OY', 2; 3, 'OY', b.win};
    for i = 1:3
        [no, algo, w] = spec16{i, :};
        try
            [r, files] = tz_fig_all16(FIG, A, b, no, algo, w, d16, T);
            rows = [rows; r]; %#ok<AGROW>
            for c = {'mod','arg'}
                cap(end+1, :) = {rel(bdir, files{strcmp({'mod','arg'}, c{1})}), ...
                    caption16(b, no, algo, w, c{1})}; %#ok<AGROW>
            end
        catch ME
            fprintf(2, '  [fail] Рис.%d : %s (%s:%d)\n', no, ME.message, ME.stack(1).name, ME.stack(1).line);
        end
    end

    % ---------------- Рис.4–8: за підблоками N.1–N.4
    for k = 1:numel(T.kinds)
        K = T.kinds(k);
        sub = sprintf('%s.%d', b.id, k);
        sdir = fullfile(bdir, sprintf('Блок %s - %s', sub, K.name));
        for no = 4:8
            cols = grid_cols(b, no);
            try
                [r, f] = tz_fig_grid(FIG, A, b, no, sub, K.key, cols, sdir, T);
                rows = [rows; r]; %#ok<AGROW>
                cap(end+1, :) = {rel(bdir, f), caption_grid(b, no, cols, K.key, sub, FIG)}; %#ok<AGROW>
            catch ME
                fprintf(2, '  [fail] %s Рис.%d : %s (%s:%d)\n', sub, no, ME.message, ME.stack(1).name, ME.stack(1).line);
            end
        end
    end

    tz_write_csv(fullfile(bdir, sprintf('Стат-моменти_Блок %s.csv', b.id)), rows);
    writecell([{'file','caption'}; cap], fullfile(bdir, 'captions.csv'), 'Encoding','UTF-8');
    if T.docx
        st = system(sprintf('python "%s" "%s" "%s"', fullfile(here, 'make_tz_docx.py'), bdir, b.note));
        if st ~= 0; fprintf(2, '  [docx] помилка make_tz_docx.py\n'); end
    end
    fprintf('=== Блок %s: %.0f хв ===\n', b.id, toc(t1)/60);
end
fprintf('\n=== Готово за %.1f хв ===\n', toc(t0)/60);
end

% =====================================================================
function cols = grid_cols(b, no)
[e1, e2] = b.elems{:};  m = b.main;  [o1, o2] = b.others{:};
c = @(ex, algo, w, el, comp, tag) struct('example',ex, 'algo',algo, 'win',w, 'elem',el, 'comp',comp, 'tag',tag);
switch no
    case {4, 5, 6}
        algo = 'OY';  w = b.win;
        if no == 4; w = 2; end
        if no == 6; algo = 'XY'; end
        cols = [c(m,algo,w,e1,'mod',''), c(m,algo,w,e1,'arg',''), c(m,algo,w,e2,'mod',''), c(m,algo,w,e2,'arg','')];
    case {7, 8}
        el = e1;  if no == 8; el = e2; end
        t1 = sprintf(' (%s)', o1);  t2 = sprintf(' (%s)', o2);
        cols = [c(o1,'XY',b.win,el,'mod',t1), c(o2,'XY',b.win,el,'mod',t2), ...
                c(o1,'XY',b.win,el,'arg',t1), c(o2,'XY',b.win,el,'arg',t2)];
end
end

function s = caption16(b, no, algo, w, comp)
what = 'модулі |f_ik|';  if strcmp(comp, 'arg'); what = 'аргументи Arg f_ik (0–2π)'; end
s = sprintf('Рис. %d (%s %s) — сканування %s, діапазон %s — усі 16 елементів: %s.', ...
    no, b.name, b.main, algo, wtxt(w), what);
end

function s = caption_grid(b, no, cols, kind, sub, FIG)
nm = @(c) sprintf('%s %s%s', ifelse(strcmp(c.comp,'mod'), 'модуль', 'аргумент'), c.elem(2:3), c.tag);
first = strjoin(arrayfun(nm, cols, 'uni', 0), ', ');
switch kind
    case 'acf',  r34 = 'третій рядок — двовимірні АКФ; четвертий — ортогональні лінійні перерізи АКФ (Δx, Δy)';
    case 'psd',  r34 = 'третій рядок — двовимірні спектри потужності log10; четвертий — їх гістограми';
    case 'wav',  r34 = sprintf('третій рядок — вейвлет-скалограми |W(a,b)|; четвертий — перерізи при a = %g і a = %g', FIG.wav.cutScales);
    case 'skel', r34 = 'третій рядок — вейвлет-скелетони (WTMM); четвертий — гістограми |W| у максимумах';
end
who = sprintf('%s %s', b.name, b.main);
if no >= 7; who = sprintf('%s %s і %s %s', b.name, b.others{1}, b.name, b.others{2}); end
s = sprintf('[%s] Рис. %d (%s) — сканування %s, діапазон %s (перший рядок зліва направо: %s; другий рядок — гістограми; %s).', ...
    sub, no, who, cols(1).algo, wtxt(cols(1).win), first, r34);
end

function s = wtxt(w)
if w == 2; s = '0–2π'; else; s = sprintf('0–%gπ', w); end
end

function v = ifelse(c, a, b)
if c; v = a; else; v = b; end
end

function r = rel(base, f)
r = f(numel(base)+2:end);
end
