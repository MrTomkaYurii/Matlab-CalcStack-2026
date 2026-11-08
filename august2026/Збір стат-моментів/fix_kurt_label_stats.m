function fix_kurt_label_stats(srcBase, dstBase)
% FIX_KURT_LABEL_STATS  Копіює всі поелементні fXX_stats.txt з основної теки
%   результатів у C:\August 2026-Results-3 (та сама структура тек) і виправляє
%   ПІДПИС колонки: 'kurt' -> 'exkurt' + пояснювальний рядок.
%
%   Значення НЕ змінюються — вони вже правильні (core/tp_moments.m):
%     |f|  — ексцес = mean(z.^4) - 3 (норма 0);
%     Arg  — круговий ексцес Фішера (R2*cos(mu2-2mu) - R^4)/(1-R)^2, без "-3".
%   Помилковим був лише підпис 'kurt' (наче це куртозис без -3).
%
%   Після цього теку C:\August 2026-Results-3 можна скопіювати поверх основної
%   і на Google Диск: fXX_stats.txt замінюються один в один, нові
%   fXX_stats_arg_central_0-2pi.txt додаються поряд.

if nargin < 1, srcBase = 'C:\August 2026-Results'; end
if nargin < 2, dstBase = 'C:\August 2026-Results-3'; end
sub = 'Розрахунки - Двот. елем. ММ';
srcRoot = fullfile(srcBase, sub);
dstRoot = fullfile(dstBase, sub);

L = dir(fullfile(srcRoot, '**', 'f*_stats.txt'));
L = L(~cellfun(@isempty, regexp({L.name}, '^f\d\d_stats\.txt$', 'once')));
fprintf('fXX_stats.txt: %d  ->  %s\n', numel(L), dstRoot);
note = sprintf(['\nexkurt: |f| — надлишковий ексцес = куртозис - 3 (норма 0);\n' ...
                '        Arg — круговий ексцес Фішера (кругові моменти, tp_moments).\n']);
nFix = 0; nSame = 0;
for k = 1:numel(L)
    src = fullfile(L(k).folder, L(k).name);
    txt = fileread(src, 'Encoding', 'UTF-8');
    new = regexprep(txt, 'skew\s+kurt(\s*\n)', ['skew' sprintf('%10s', 'exkurt') '$1'], 'once');
    if ~contains(new, 'exkurt:')
        new = [strtrim(new) newline note];
    end
    if strcmp(new, txt); nSame = nSame + 1; else; nFix = nFix + 1; end
    outDir = strrep(L(k).folder, srcRoot, dstRoot);
    if ~exist(outDir, 'dir'); mkdir(outDir); end
    fid = fopen(fullfile(outDir, L(k).name), 'w', 'n', 'UTF-8');
    fprintf(fid, '%s', new);
    fclose(fid);
end
fprintf('Готово: %d виправлено, %d вже були правильні.\n', nFix, nSame);
end
