function outFile = tp_stats_write(ST, meta, ctx, CFG)
% TP_STATS_WRITE  Пише статистику ОДНОГО елемента у текстовий файл у теці цього елемента:
%       <saveRoot>\<зразок>\<приклад>\<фаза>\<алгоритм>\<напрям>\<елемент>\<елемент>_stats.txt
%   Компактно, як в августі (paper_figures\make_stats_table.m): для кожного представлення --
%   ЧОТИРИ моменти mean / std / skew / kurt розподілу, показаного на рисунку, окремо для |X| і
%   arg[X]:  карта, 2D-АКФ (std, kurt + довжина кореляції L), спектр log10(PSD), скалограма
%   |W(a,b)|, перерізи вейвлета при фіксованих масштабах, вейвлет-скелетон; мультифрактал --
%   Δh, Δh_L, Δh_R, asym, D0, D1, D2. Числа рахує tp_stats_element.
%   kurt -- НЕ надлишковий (норма 3), skew = 0 для симетричного розподілу.

outDir = fullfile(CFG.paths.saveRoot, ctx.parts{:});
if ~exist(outDir,'dir'); mkdir(outDir); end
outFile = fullfile(outDir, [matlab.lang.makeValidName(ctx.name) '_stats.txt']);

plain   = plainName(meta.elemTeX);          % 'LB_0,90', 'CB', 'rho' ...
modName = ['|' plain '|'];
argName = plainName(regexprep(meta.argLabel, '\s*\[rad\]$', ''));   % 'arg[CB]'

% ---- умови розрахунку з шляху результату (parts = {зразок\приклад\фаза, алгоритм+LB_CB_rho, напрям, елемент})
sp    = strsplit(ctx.parts{1}, {'\','/'});
smp   = sp{1};
ex    = ''; if numel(sp) >= 2, ex = sp{2}; end
phase = ''; if numel(sp) >= 3, phase = phaseText(sp{3}); end
algo  = strtok(ctx.parts{2}, '+');
dirTxt = dirText(ctx.parts{3});
rows2 = {modName; argName};                 % рядки таблиць: |X| і arg[X]

w = 78;                                     % ширина рамки
fid = fopen(outFile, 'w', 'n', 'UTF-8');
c = onCleanup(@() fclose(fid));

fprintf(fid, '%s\n', repmat('═', 1, w));
fprintf(fid, ' СТАТИСТИКА  ·  %s\n', plain);
fprintf(fid, '%s\n', repmat('═', 1, w));
fprintf(fid, ' Зразок       : %s / %s\n', smp, ex);
fprintf(fid, ' Алгоритм     : %s   ·   %s\n', algo, dirTxt);
if ~isempty(phase)
    fprintf(fid, ' Фазове вікно : %s\n', phase);
end
fprintf(fid, '\n');

M = ST.mod.maps;  A = ST.arg.maps;
mom = {'mean','std','skew','kurt'};

% ---- 1. карта
table_(fid, w, '1. КАРТА  (2D-розподіл значень)', mom, rows2, ...
       [M.mean M.std M.skew M.kurt; A.mean A.std A.skew A.kurt], [M.nFinite; A.nFinite]);
if ~ST.qc.ok
    fprintf(fid, ' QC не пройдено: %s. Моменти = NaN, решта розділів не рахувалась.\n\n', ST.qc.reason);
    return;
end

% ---- 2. АКФ
a = ST.mod.acf;  b = ST.arg.acf;
table_(fid, w, sprintf('2. АКФ  (2D, вікно лагів ±%.1f px для |X|, ±%.1f px для arg;  L = FWHM АКФ)', a.half, b.half), ...
       {'std','kurt','L_x, px','L_y, px'}, rows2, ...
       [a.z2 a.z4 a.hwhmX a.hwhmY; b.z2 b.z4 b.hwhmX b.hwhmY], [a.n; b.n]);

% ---- 3. спектр потужності
table_(fid, w, '3. СПЕКТР ПОТУЖНОСТІ  (значення log10 PSD, 2D, без DC)', mom, rows2, ...
       [ST.mod.psd.z; ST.arg.psd.z], [ST.mod.psd.n; ST.arg.psd.n]);

% ---- 4. вейвлет: уся скалограма
Wm = ST.mod.wav;  Wa = ST.arg.wav;
table_(fid, w, '4. ВЕЙВЛЕТ  (амплітуди |W(a,b)| усієї скалограми)', mom, rows2, ...
       [zOr(Wm); zOr(Wa)], [nOr(Wm); nOr(Wa)]);

% ---- 5. вейвлет: перерізи при фіксованих масштабах
nCut = 0;
if Wm.valid && Wa.valid, nCut = min(numel(Wm.cuts), numel(Wa.cuts)); end
if nCut > 0
    lbl = cell(2*nCut, 1);  X = nan(2*nCut, 4);  N = nan(2*nCut, 1);
    for j = 1:nCut
        lbl{2*j-1} = sprintf('%s  a=%.3g', modName, Wm.cuts(j).a);
        lbl{2*j}   = sprintf('%s  a=%.3g', argName, Wa.cuts(j).a);
        X(2*j-1, :) = Wm.cuts(j).z;  N(2*j-1) = Wm.cuts(j).n;
        X(2*j,   :) = Wa.cuts(j).z;  N(2*j)   = Wa.cuts(j).n;
    end
    table_(fid, w, '5. ПЕРЕРІЗИ ВЕЙВЛЕТА  (|W(a,b)| при фіксованих масштабах a)', mom, lbl, X, N);
else
    table_(fid, w, '5. ПЕРЕРІЗИ ВЕЙВЛЕТА  (|W(a,b)| при фіксованих масштабах a)', mom, rows2, nan(2,4), nan(2,1));
end

% ---- 6. вейвлет-скелетон
Km = ST.mod.skel;  Ka = ST.arg.skel;
table_(fid, w, '6. ВЕЙВЛЕТ-СКЕЛЕТОН  (амплітуди максимумів |W|)', mom, rows2, ...
       [zOr(Km); zOr(Ka)], [nOr(Km); nOr(Ka)]);

% ---- 7. мультифрактал
table_(fid, w, '7. МУЛЬТИФРАКТАЛ  (Δh, крила спектра, асиметрія, розмірності)', ...
       {'Δh','Δh_L','Δh_R','asym','D0','D1','D2'}, rows2, ...
       [mfRow(ST.mod.mf); mfRow(ST.arg.mf)], []);

fprintf(fid, ' arg: mean кругове (циклічне), skew і kurt за центрованими кутами. kurt -- не надлишковий (норма 3).\n');
end

% ------------------------------------------------------------------------
function table_(fid, w, title, cols, rowLabels, X, N)
% Один блок: заголовок, шапка, рядки |X| / arg[X] з вирівняними колонками. N -- к-сть значень (або []).
fprintf(fid, ' %s\n', title);
fprintf(fid, ' %s\n', repmat('─', 1, w-2));
lw = max([18, cellfun(@numel, rowLabels(:)') + 2]);
cw = 10;
fprintf(fid, ' %s', padr(' ', lw));
for k = 1:numel(cols), fprintf(fid, '%s', padl(cols{k}, cw)); end
if ~isempty(N), fprintf(fid, '%s', padl('N', 9)); end
fprintf(fid, '\n');
for r = 1:numel(rowLabels)
    fprintf(fid, ' %s', padr(rowLabels{r}, lw));
    for k = 1:numel(cols), fprintf(fid, '%s', padl(fv(X(r,k)), cw)); end
    if ~isempty(N), fprintf(fid, '%s', padl(nv(N(r)), 9)); end
    fprintf(fid, '\n');
end
fprintf(fid, ' %s\n\n', repmat('─', 1, w-2));
end

function s = padr(t, n)
t = char(t);  s = [t repmat(' ', 1, max(0, n - numel(t)))];
end

function s = padl(t, n)
t = char(t);  s = [repmat(' ', 1, max(0, n - numel(t))) t];
end

function s = fv(v)
% число в фіксованому форматі; NaN/Inf -> тире
if isempty(v) || ~isfinite(v), s = '—'; else, s = sprintf('%.4f', v); end
end

function s = nv(n)
if isempty(n) || ~isfinite(n), s = '—'; else, s = sprintf('%d', n); end
end

function z = zOr(S)
% [mean std skew kurt] секції або NaN, якщо секція вироджена
if isstruct(S) && S.valid && isfield(S, 'z'), z = S.z; else, z = nan(1,4); end
end

function n = nOr(S)
if isstruct(S) && S.valid && isfield(S, 'n'), n = S.n; else, n = NaN; end
end

function v = mfRow(F)
% [Δh Δh_L Δh_R asym D0 D1 D2] мультифрактала або NaN
if F.valid
    v = [F.deltaH F.leftWidth F.rightWidth F.asymmetry F.D0 F.D1 F.D2];
else
    v = nan(1,7);
end
end

function p = plainName(tex)
% TeX-позначення -> звичайний текст: 'arg[LB_{0,90}]' -> 'arg[LB_0,90]'
p = regexprep(strrep(tex, '\rho', 'rho'), '[{}]', '');
end

function s = phaseText(folder)
% 'phase_03_[0-1.50pi]' -> '3   [0–1.50π]   (270°)'
tok = regexp(folder, '^phase_(\d+)_\[0-([0-9.]+)pi\]$', 'tokens', 'once');
if isempty(tok)
    s = folder;
else
    s = sprintf('%d   [0–%sπ]   (%d°)', str2double(tok{1}), tok{2}, round(str2double(tok{2})*180));
end
end

function s = dirText(dName)
% 'step_1' -> 'OX+OY, крок 1' (зведена карта XY);  'OX_step_1' -> 'OX, крок 1'
tok = regexp(dName, 'step_(\d+)$', 'tokens', 'once');
if isempty(tok), s = dName; return; end
d = regexprep(dName, '_?step_\d+$', '');
if isempty(d), d = 'OX+OY'; end
s = sprintf('%s, крок %s', d, tok{1});
end
