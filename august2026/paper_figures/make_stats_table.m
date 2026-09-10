function T = make_stats_table(FIG)
% MAKE_STATS_TABLE  Статистичні моменти розподілів, ПОКАЗАНИХ на панелях
%   рисунків Fig1..Fig7 — окремо від самих рисунків. Набори:
%
%     stats.moments.txt/.docx   Fig1 — Z1..Z4 карт |f|/arg
%     stats.acf.txt/.docx       Fig2 — Z2, Z4 2D-АКФ + довжина кореляції (FWHM)
%     stats.psd.txt/.docx       Fig3 — Z1..Z4 значень log10(PSD)
%     stats.skeleton.txt/.docx  Fig4 — Z1..Z4 амплітуд WTMM-максимумів (F(h))
%     stats.wavelet.txt/.docx   Fig5 — Z1..Z4 амплітуд |W(a,b)|
%     stats.multifractal / stats.mueller  — Fig6 / Fig7
%
%   .txt — вирівняні колонки, блок на кожен рисунок (зручно читати);
%   .docx — ті самі числа у стилі журналу. ОКРЕМИЙ файл на КОЖЕН алгоритм
%   (варіант) — тег алгоритму в імені файлу; кладуться у теку СВОГО рисунка:
%   FIG.out.root\<FigN>\stats.<набір>.<variant>.txt/.docx
%   (variant = XY | generalized | OX | OY | PERP | polarOX | polarOY)
%   Так повторний прогін іншого алгоритму НЕ затирає таблиці попереднього.
%
%   ОБСЯГ = FIG.build (як у run_all_figures): рахуються таблиці ЛИШЕ для
%   обраних рисунків ('Fig1' -> обидві пари; 'Fig2:f33f44' -> лише ця пара).
%   Порожній / відсутній FIG.build -> усі набори.
%
%   Числа рахуються з ТИХ САМИХ величин, що на панелях (через paper_prep) —
%   нічого у f_ik не перераховується.
%
%       make_stats_table            % бере cfg_figures()
%       T = make_stats_table(FIG)   % + повертає останню зведену таблицю

here = fileparts(mfilename('fullpath'));   % ...\paper_figures
addpath(here, fullfile(here,'common'));
if nargin < 1 || isempty(FIG); FIG = cfg_figures(); end
if ~exist(FIG.out.root,'dir'); mkdir(FIG.out.root); end

specs = { ...
  struct('file','stats.moments','kind','raw','fig','Fig1', ...
         'keys',{{'fig01_f33f44','fig01_f23f24'}}, 'metrics',{{'Z1','Z2','Z3','Z4'}}), ...
  struct('file','stats.acf',    'kind','acf','fig','Fig2', ...
         'keys',{{'fig02_f33f44','fig02_f23f24'}}, 'metrics',{{'Z2','Z4','Lcorr'}}), ...
  struct('file','stats.psd',    'kind','psd','fig','Fig3', ...
         'keys',{{'fig03_f33f44','fig03_f23f24'}}, 'metrics',{{'Z1','Z2','Z3','Z4'}}), ...
  struct('file','stats.skeleton','kind','skel','fig','Fig4', ...
         'keys',{{'fig04_f33f44','fig04_f23f24'}}, 'metrics',{{'Z1','Z2','Z3','Z4'}}), ...
  struct('file','stats.wavelet','kind','wav','fig','Fig5', ...
         'keys',{{'fig05_f33f44','fig05_f23f24'}}, 'metrics',{{'Z1','Z2','Z3','Z4'}}), ...
  struct('file','stats.multifractal','kind','mfr','fig','Fig6', ...
         'keys',{{'fig06_f33f44','fig06_f23f24'}}, 'metrics',{{'dH','dHl','dHr','asym','D0','D1','D2'}}), ...
  struct('file','stats.mueller','kind','mueller','fig','Fig7', ...
         'keys',{{'fig07'}}, 'metrics',{{'Z1','Z2','Z3','Z4'}}) };

build = {};
if isfield(FIG,'build') && ~isempty(FIG.build); build = FIG.build; end
build = build(~strcmpi(build, 'stats'));   % 'stats' — службовий прапорець run_all_figures, не селектор рисунка
FIG.build = build;                         % те саме звуження бачить collect_spec (фільтр .keys)
% Порожній залишок (FIG.build = {'stats'} або {}) -> таблиці для УСІХ рисунків.

for s = 1:numel(specs)
    if ~spec_wanted(build, specs{s})
        continue;   % цей рисунок не обрано у FIG.build
    end
    if strcmp(specs{s}.kind,'mueller')
        T = collect_mueller(FIG, specs{s});
    else
        T = collect_spec(FIG, specs{s});
    end
    if isempty(T); fprintf(2,'  [%s] нема даних — пропуск\n', specs{s}.file); continue; end

    % ОКРЕМИЙ набір файлів на кожен алгоритм (варіант): stats.<набір>.<tag>.txt/.docx.
    % Так повторний прогін іншого алгоритму не затирає таблиці попереднього.
    vtags = unique(T.variant, 'stable');
    for vi = 1:numel(vtags)
        vt = vtags{vi};
        Tv = T(strcmp(T.variant, vt), :);
        txtPath = write_txt(Tv, FIG, specs{s}, vt);
        fprintf('  [ok] %s  (%d рядків)\n', txtPath, height(Tv));
        if FIG.stats.docx
            try
                fprintf('  [ok] %s\n', build_docx(Tv, FIG, specs{s}, vt));
            catch ME
                fprintf(2, '  [docx skip] %s [%s] : %s\n', specs{s}.file, vt, ME.message);
            end
        end
    end
end
end

% ======================================================================
function tf = spec_wanted(build, sp)
% Чи потрібні таблиці цього набору за FIG.build (порожній -> усі).
if isempty(build); tf = true; return; end
if strcmp(sp.kind, 'mueller'); tf = build_wants(build, sp.fig); return; end
tf = any(cellfun(@(k) build_wants(build, sp.fig, key_pair(k)), sp.keys));
end

function p = key_pair(key)
p = regexprep(key, '^fig\d+_', '');   % 'fig01_f33f44' -> 'f33f44'
end

% ======================================================================
function T = collect_spec(FIG0, sp)
rows = {};
keys = sp.keys;
if isfield(FIG0,'build') && ~isempty(FIG0.build)
    keys = keys(cellfun(@(k) build_wants(FIG0.build, sp.fig, key_pair(k)), keys));
end
for p = 1:numel(keys)
    FIG = apply_fig_params(FIG0, keys{p});   % ті самі пер-фігурні параметри, що й у рендері
    C = FIG.(keys{p});  elems = C.elems;
    for si = 1:numel(C.samples)
        sName = C.samples{si};  sTag = local_tag(FIG, sName);
        for xi = 1:numel(C.examples)
            ex = C.examples{xi};
            for vi = 1:numel(C.variants)
                v = C.variants{vi};
                base = sprintf('%s.%s-%s.%s.%s.%s%s', sp.fig, elems{1}, elems{2}, v.tag, sTag, ex_prefix(FIG), ex);

                winData = cell(1, numel(FIG.phase));  ok = true;
                for w = 1:numel(FIG.phase)
                    try
                        winData{w} = tp_paper_read(FIG, sName, ex, v, FIG.phase(w).glob);
                    catch ME
                        fprintf(2, '  [skip] %s / %s : %s\n', base, FIG.phase(w).label, ME.message);
                        ok = false; break;
                    end
                end
                if ~ok; continue; end
                winData = paper_prep(winData, elems, sp.kind, FIG);

                for w = 1:numel(FIG.phase)
                    for e = 1:numel(elems)
                        for comp = {'mod','arg'}
                            P = winData{w}.prep.(elems{e}).(comp{1});
                            if strcmp(sp.kind,'mfr')
                                z = nan(1,4);  N = NaN;  Lc = NaN;  mf = mfr_row(P.mf);
                            else
                                if strcmp(sp.kind,'acf'); src = P.img(isfinite(P.img)); else; src = P.histSrc; end
                                z = stats_moments(src, FIG.stats.excessKurt);
                                N = numel(src);  Lc = P.Lcorr;  mf = nan(1,7);
                            end
                            rows(end+1,:) = { base, sp.fig, [elems{1} '-' elems{2}], v.tag, sName, ex, ...
                                FIG.phase(w).label, elems{e}, tern(strcmp(comp{1},'mod'),'|f|','arg'), ...
                                N, z(1), z(2), z(3), z(4), Lc, mf(1),mf(2),mf(3),mf(4),mf(5),mf(6),mf(7) }; %#ok<AGROW>
                        end
                    end
                end
            end
        end
    end
end
if isempty(rows); T = table(); return; end
T = cell2table(rows, 'VariableNames', {'figure','fig','elem_pair','variant','sample', ...
    'example','phase_window','element','component','N', ...
    'Z1_mean','Z2_std','Z3_skewness','Z4_kurtosis','Lcorr_px', ...
    'deltaH','dH_left','dH_right','asymmetry','D0','D1','D2'});
end

% ======================================================================
function T = collect_mueller(FIG0, sp)
% Fig7: Z1..Z4 сирих карт УСІХ 16 елементів f_ik (mod і arg).
FIG = apply_fig_params(FIG0, sp.keys{1});
C = FIG.fig07;  rows = {};
for si = 1:numel(C.samples)
    sName = C.samples{si};  sTag = local_tag(FIG, sName);
    for xi = 1:numel(C.examples)
        ex = C.examples{xi};
        for vi = 1:numel(C.variants)
            v = C.variants{vi};
            for w = 1:numel(FIG.phase)
                try
                    D = tp_paper_read(FIG, sName, ex, v, FIG.phase(w).glob);
                catch;  continue;
                end
                base = sprintf('Fig7.mueller.%s.%s.%s%s', v.tag, sTag, ex_prefix(FIG), ex);
                for i = 1:4
                    for k = 1:4
                        for comp = {'mod','arg'}
                            M = D.data.(sprintf('f%d%d',i,k)).(comp{1});
                            src = M(isfinite(M));
                            z = stats_moments(src, FIG.stats.excessKurt);
                            rows(end+1,:) = { base, 'Fig7', 'mueller', v.tag, sName, ex, ...
                                FIG.phase(w).label, sprintf('f%d%d',i,k), ...
                                tern(strcmp(comp{1},'mod'),'|f|','arg'), numel(src), ...
                                z(1), z(2), z(3), z(4), NaN, NaN,NaN,NaN,NaN,NaN,NaN,NaN }; %#ok<AGROW>
                        end
                    end
                end
            end
        end
    end
end
if isempty(rows); T = table(); return; end
T = cell2table(rows, 'VariableNames', {'figure','fig','elem_pair','variant','sample', ...
    'example','phase_window','element','component','N', ...
    'Z1_mean','Z2_std','Z3_skewness','Z4_kurtosis','Lcorr_px', ...
    'deltaH','dH_left','dH_right','asymmetry','D0','D1','D2'});
end

% ======================================================================
function v = mfr_row(MF)
if isempty(MF) || MF.degenerate
    v = nan(1,7);
else
    v = [MF.deltaH, MF.leftWidth, MF.rightWidth, MF.asymmetry, MF.D0, MF.D1, MF.D2];
end
end

% ======================================================================
function tag = local_tag(FIG, sName)
i = find(strcmp(FIG.sampleTag(:,1), sName), 1);
if isempty(i); tag = regexprep(lower(sName), '\s+', '-'); else; tag = FIG.sampleTag{i,2}; end
end

% ======================================================================
function outPath = write_txt(T, FIG, sp, vtag)
% Гарно вирівняний .txt: шапка з поясненням -> блок на кожен рисунок
% (зразок x приклад), у блоці — таблиця з вирівняними колонками. ОКРЕМИЙ файл
% на алгоритм: FIG.out.root\<sp.fig>\<sp.file>.<vtag>.txt
outDir = fullfile(FIG.out.root, sp.fig);
if ~exist(outDir,'dir'); mkdir(outDir); end
outPath = fullfile(outDir, sprintf('%s.%s.txt', sp.file, vtag));
[head, cols, fmts] = table_columns(sp.metrics);

fid = fopen(outPath, 'w', 'n', 'UTF-8');
oc  = onCleanup(@() fclose(fid));

bar = repmat('=', 1, 78);
fprintf(fid, '%s\n', bar);
fprintf(fid, '  %s   (%s · алгоритм %s)\n', stats_title(sp.kind), sp.fig, vtag);
fprintf(fid, '%s\n', bar);
for L = stats_legend(sp, FIG); fprintf(fid, '  %s\n', L{1}); end
fprintf(fid, '  Один блок = один рисунок; рядок = один розподіл (фаз. вікно x елемент x |f|/arg).\n');
fprintf(fid, '%s\n\n', bar);

colHead = [{'Фазове вікно','Елемент','Комп.'}, cellfun(@detex, head, 'UniformOutput',false), {'N'}];
leftCol = [true true true, false(1, numel(head)+1)];   % текст ліворуч, числа праворуч

bases = unique(T.figure, 'stable');
for b = 1:numel(bases)
    sub  = T(strcmp(T.figure, bases{b}), :);
    rows = cell(height(sub), numel(colHead));
    for r = 1:height(sub)
        isArg = strcmp(sub.component{r}, 'arg');
        rows{r,1} = detex(sub.phase_window{r});
        rows{r,2} = sub.element{r};
        rows{r,3} = tern(isArg, 'arg', '|f|');
        for k = 1:numel(cols)
            rows{r,3+k} = fmt_val(sub.(cols{k})(r), fmts{k}, isArg, sp.kind);
        end
        if isfinite(sub.N(r)); rows{r,end} = sprintf('%d', sub.N(r)); else; rows{r,end} = '—'; end
    end
    fprintf(fid, '%s\n', bases{b});
    print_block(fid, colHead, rows, leftCol);
    fprintf(fid, '\n');
end
end

function s = detex(s)
s = strrep(s, '\Delta', 'Δ');
s = strrep(s, '\pi', 'π');
s = regexprep(s, '(?<=[A-Za-zΔ])_(?=[0-9])', '');   % Z_1 -> Z1, D_0 -> D0
end

% ----------------------------------------------------------------------
function lines = stats_legend(sp, FIG)
% Легенда позначень — лише за метриками ЦЬОГО набору (спільна для .txt і .docx).
kL = tern(FIG.stats.excessKurt, 'Z4 — надлишковий ексцес (норма 0)', 'Z4 — ексцес (норма 3)');
m = struct('Z1','Z1 — середнє', 'Z2','Z2 — СКВ', 'Z3','Z3 — асиметрія', 'Z4',kL, ...
    'Lcorr','L — довжина кореляції (px)', 'dH','Δh — ширина спектра сингулярностей', ...
    'dHl','Δh_L — ліве крило', 'dHr','Δh_R — праве крило', 'asym','asym. — асиметрія спектра', ...
    'D0','D0 — розмірність носія', 'D1','D1 — інформаційна', 'D2','D2 — кореляційна');
lines = { strjoin(cellfun(@(k) m.(k), sp.metrics, 'UniformOutput', false), ';   ') };
if any(ismember({'Z1','Z2','Z3','Z4'}, sp.metrics))
    if ~(isfield(FIG,'data') && isfield(FIG.data,'normalize') && ~FIG.data.normalize)
        lines{end+1} = 'Числа рахуються за m_ik = f_ik / медіана|f_11| (безрозмірні).';
    else
        lines{end+1} = 'Числа — сирі (умовні одиниці, ~1e-6).';
    end
end
end

% ----------------------------------------------------------------------
function s = pretty(s)
% TeX -> Unicode для .docx (індекси, грецькі, тире).
s = strrep(s, '\Deltah_L', 'Δh (лів.)');
s = strrep(s, '\Deltah_R', 'Δh (прав.)');
s = strrep(s, '\Deltah',   'Δh');
s = strrep(s, '\Delta',    'Δ');
s = strrep(s, '\pi',       'π');
s = regexprep(s, '(?<=\d)\s*-\s*(?=\d)', '–');
map = {'Z_1','Z₁';'Z_2','Z₂';'Z_3','Z₃';'Z_4','Z₄';'D_0','D₀';'D_1','D₁';'D_2','D₂'};
for i = 1:size(map,1); s = strrep(s, map{i,1}, map{i,2}); end
end

% ----------------------------------------------------------------------
function t = ex_prefix(FIG)
if isfield(FIG,'exampleTag') && ~isempty(FIG.exampleTag); t = FIG.exampleTag; else; t = 'ex'; end
end

% ----------------------------------------------------------------------
function s = human_base(base, FIG)
% 'Fig1.f33-f44.generalized.heart.zrazok2' -> 'Серце · зразок 2 · generalized · f33–f44'
p = strsplit(base, '.');
if numel(p) < 5; s = base; return; end
exN = regexprep(p{end}, '^[A-Za-z]+', '');
i = find(strcmp(FIG.sampleTag(:,2), p{end-1}), 1);
sName = tern(isempty(i), p{end-1}, FIG.sampleTag{i,1});
if strcmpi(p{2}, 'mueller')
    s = sprintf('%s · зразок %s · %s · уся матриця Мюллера', sName, exN, p{end-2});
else
    s = sprintf('%s · зразок %s · %s · %s', sName, exN, p{end-2}, strrep(p{2},'-','–'));
end
end

% ----------------------------------------------------------------------
function print_block(fid, head, rows, leftCol)
n = numel(head);
w = zeros(1, n);
for c = 1:n
    w(c) = numel(char(head{c}));
    for r = 1:size(rows,1)
        w(c) = max(w(c), numel(char(rows{r,c})));
    end
end
rule = ['  ' repmat('-', 1, sum(w) + 2*(n-1))];
fprintf(fid, '%s\n', rule);
fprintf(fid, '  %s\n', pad_row(head, w, leftCol));
fprintf(fid, '%s\n', rule);
for r = 1:size(rows,1)
    fprintf(fid, '  %s\n', pad_row(rows(r,:), w, leftCol));
end
end

function s = pad_row(cells, w, leftCol)
p = strings(1, numel(cells));
for c = 1:numel(cells)
    if leftCol(c); p(c) = pad(string(cells{c}), w(c));
    else;          p(c) = pad(string(cells{c}), w(c), 'left');
    end
end
s = char(strjoin(p, '  '));
end

% ----------------------------------------------------------------------
function s = stats_title(kind)
m = struct( ...
  'raw',    'Статистичні моменти Z1–Z4 карт |f_ik| / arg(f_ik)', ...
  'acf',    'Моменти 2D-АКФ (Z2, Z4) та довжина кореляції L', ...
  'psd',    'Моменти спектра потужності Z1–Z4 значень log10(PSD)', ...
  'skel',   'Моменти WTMM-скелетону Z1–Z4 амплітуд максимумів F(h)', ...
  'wav',    'Вейвлет-моменти Z1–Z4 амплітуд |W(a,b)|', ...
  'mfr',    'Мультифрактальні дескриптори: ширина спектра Δh (ліво/право), асиметрія, D0/D1/D2', ...
  'mueller','Статистичні моменти Z1–Z4 усіх 16 елементів матриці Мюллера f_ik (|f| / arg)');
if isfield(m, kind); s = m.(kind); else; s = ['Статистичні моменти (' kind ')']; end
end

% ======================================================================
function outPath = build_docx(T, FIG, sp, vtag)
import mlreportgen.dom.*
outDir = fullfile(FIG.out.root, sp.fig);   % у теку свого рисунка
if ~exist(outDir,'dir'); mkdir(outDir); end
stem = sprintf('%s.%s', sp.file, vtag);    % ОКРЕМИЙ файл на алгоритм
outPath = fullfile(outDir, [stem '.docx']);
d = Document(fullfile(outDir, stem), 'docx');  open(d);
AR = {FontFamily('Arial')};

h = append(d, Heading(1, sprintf('%s  (%s · алгоритм %s)', stats_title(sp.kind), sp.fig, vtag)));
h.Style = [AR, {FontSize('13pt')}];

for L = stats_legend(sp, FIG)
    pp = append(d, Paragraph(L{1}));
    pp.Style = [AR, {FontSize('9pt'), Color('#444444'), OuterMargin('0pt','0pt','0pt','2pt')}];
end
pn = append(d, Paragraph(['Одна таблиця — один рисунок; рядок — один розподіл ' ...
    '(фазове вікно × елемент × |f|/arg). N — к-сть пікселів.']));
pn.Style = [AR, {FontSize('9pt'), Color('#444444'), OuterMargin('0pt','0pt','0pt','10pt')}];

[head, cols, fmts] = table_columns(sp.metrics);
colHead = [{'Фазове вікно','Елемент','Комп.'}, cellfun(@pretty, head, 'UniformOutput',false), {'N'}];
nC = numel(colHead);

bases = unique(T.figure, 'stable');
for b = 1:numel(bases)
    sub = T(strcmp(T.figure, bases{b}), :);
    cap = append(d, Paragraph(sprintf('Таблиця %d.  %s', b, human_base(bases{b}, FIG))));
    cap.Style = [AR, {FontSize('9.5pt'), Bold(true), OuterMargin('0pt','0pt','10pt','3pt')}];

    body = cell(height(sub), nC);
    for r = 1:height(sub)
        isArg = strcmp(sub.component{r}, 'arg');
        body{r,1} = pretty(sub.phase_window{r});
        body{r,2} = sub.element{r};
        body{r,3} = tern(isArg, 'arg', '|f|');
        for k = 1:numel(cols)
            body{r,3+k} = fmt_val(sub.(cols{k})(r), fmts{k}, isArg, sp.kind);
        end
        if isfinite(sub.N(r)); body{r,nC} = sprintf('%d', sub.N(r)); else; body{r,nC} = '—'; end
    end

    tbl = Table([colHead; body]);
    tbl.Style = [AR, {FontSize('9pt'), Width('100%'), HAlign('center'), ...
                 Border('solid','black','0.75pt'), RowSep('solid','#c0c0c0','0.25pt')}];
    tbl.TableEntriesVAlign = 'middle';
    for r = 1:tbl.NRows
        for cc = 1:tbl.NCols
            al = tern(cc <= 3 && r > 1, 'left', 'center');
            tbl.entry(r,cc).Style = {InnerMargin('5pt','5pt','2.5pt','2.5pt'), HAlign(al)};
        end
    end
    hr = tbl.row(1);
    hr.Style = [hr.Style, {Bold(true), BackgroundColor('#eeeeee'), ...
                Border('solid','black','0.75pt')}];
    try
        hr.Style = [hr.Style, {RepeatAsHeaderRow(true)}];   % повторювати шапку на кожній сторінці
    catch
    end

    append(d, tbl);
    sepP = append(d, Paragraph(''));  sepP.Style = {FontSize('4pt')};
end
close(d);
end

% ======================================================================
function [head, cols, fmts] = table_columns(metrics)
head = {};  cols = {};  fmts = {};
for i = 1:numel(metrics)
    switch metrics{i}
        case 'Z1', head{end+1}='Z_1 (сер.)';  cols{end+1}='Z1_mean';     fmts{end+1}='moment'; %#ok<AGROW>
        case 'Z2', head{end+1}='Z_2 (СКВ)';   cols{end+1}='Z2_std';      fmts{end+1}='moment'; %#ok<AGROW>
        case 'Z3', head{end+1}='Z_3 (асим.)'; cols{end+1}='Z3_skewness'; fmts{end+1}='plain';  %#ok<AGROW>
        case 'Z4', head{end+1}='Z_4 (екс.)';  cols{end+1}='Z4_kurtosis'; fmts{end+1}='plain';  %#ok<AGROW>
        case 'Lcorr', head{end+1}='L (px)';   cols{end+1}='Lcorr_px';    fmts{end+1}='plain';  %#ok<AGROW>
        case 'dH',   head{end+1}='\Deltah';   cols{end+1}='deltaH';     fmts{end+1}='plain';  %#ok<AGROW>
        case 'dHl',  head{end+1}='\Deltah_L'; cols{end+1}='dH_left';    fmts{end+1}='plain';  %#ok<AGROW>
        case 'dHr',  head{end+1}='\Deltah_R'; cols{end+1}='dH_right';   fmts{end+1}='plain';  %#ok<AGROW>
        case 'asym', head{end+1}='asym.';     cols{end+1}='asymmetry';  fmts{end+1}='plain';  %#ok<AGROW>
        case 'D0',   head{end+1}='D_0';       cols{end+1}='D0';         fmts{end+1}='plain';  %#ok<AGROW>
        case 'D1',   head{end+1}='D_1';       cols{end+1}='D1';         fmts{end+1}='plain';  %#ok<AGROW>
        case 'D2',   head{end+1}='D_2';       cols{end+1}='D2';         fmts{end+1}='plain';  %#ok<AGROW>
    end
end
end

function s = fmt_val(x, kind, isArg, specKind) %#ok<INUSD>
if ~isfinite(x); s = '—'; return; end
if abs(x) < 1e-9; s = tern(strcmp(kind,'plain'), '0.000', '0'); return; end   % ~0 (напр. сер. arg)
if strcmp(kind,'plain')
    s = sprintf('%.3f', x);
    if strcmp(s, '-0.000'); s = '0.000'; end
    return;
end
% 'moment' — адаптивно до порядку величини (після нормування |f_ik| ~ O(1),
% але log10(PSD), сирі режими тощо можуть бути дуже малі/великі)
a = abs(x);
if a >= 1e-3 && a < 1e4;  s = sprintf('%.4f', x);
else;                     s = sprintf('%.3e', x);
end
end

function s = tern(c,a,b); if c; s = a; else; s = b; end; end
