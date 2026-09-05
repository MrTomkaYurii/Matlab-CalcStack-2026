function files = fig_export(figH, outDir, baseName, FIG, sub)
% FIG_EXPORT  Зберігає ОДНУ фігуру в усіх форматах FIG.out.formats, КОЖЕН —
%   у своїй підтеці outDir\<fmt>\[\<sub>\] (щоб svg/pdf/png не змішувались):
%   outDir\svg\<sub>\<baseName>.svg, outDir\pdf\<sub>\<baseName>.pdf, ...
%   sub (необов'язково) — ще один рівень усередині <fmt>\ (напр. тег алгоритму
%   'generalized'/'OX'/'OY': в одну теку картинок збирається багато й важко
%   шукати). Порожній/відсутній -> без цього рівня.
%   baseName — без розширення (крапки в імені дозволені: вони не
%   інтерпретуються як розширення, значуще лише останнє ".<fmt>").
%
%   svg  : print -dsvg -painters      (векторний, редагований в Inkscape:
%          текст лишається текстом, лінії — окремими path)
%   pdf  : exportgraphics ContentType=vector   (для журналу / Illustrator)
%   tiff : exportgraphics Resolution=FIG.out.tiffDPI   (растр, фінал)
%   png  : exportgraphics Resolution=FIG.out.pngDPI    (прев'ю)
%   fig  : savefig                                     (перевідкрити в MATLAB)

if nargin < 5 || isempty(sub); sub = ''; end
files = strings(0,1);

for k = 1:numel(FIG.out.formats)
    fmt   = lower(FIG.out.formats{k});
    fmtDir = fullfile(outDir, fmt);
    if ~isempty(sub); fmtDir = fullfile(fmtDir, sub); end
    if ~exist(fmtDir,'dir'); mkdir(fmtDir); end
    f = fullfile(fmtDir, [baseName '.' fmt]);
    switch fmt
        case 'svg'
            print(figH, f, '-dsvg', '-vector');   % -vector = сучасна назва -painters
        case 'pdf'
            exportgraphics(figH, f, 'ContentType','vector', 'BackgroundColor','white');
        case 'tiff'
            exportgraphics(figH, f, 'Resolution', FIG.out.tiffDPI, 'BackgroundColor','white');
        case 'png'
            exportgraphics(figH, f, 'Resolution', FIG.out.pngDPI, 'BackgroundColor','white');
        case 'fig'
            savefig(figH, f);
        otherwise
            warning('fig_export:fmt', 'невідомий формат "%s" — пропущено', fmt);
            continue;
    end
    files(end+1,1) = string(f); %#ok<AGROW>
end
end
