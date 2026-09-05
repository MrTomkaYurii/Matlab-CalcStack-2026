function files = fig_export(figH, outDir, baseName, FIG)
% FIG_EXPORT  Зберігає ОДНУ фігуру в усіх форматах FIG.out.formats, КОЖЕН —
%   у своїй підтеці outDir\<fmt>\ (щоб svg/pdf/png не змішувались в одній
%   теці): outDir\svg\<baseName>.svg, outDir\pdf\<baseName>.pdf, ...
%   baseName — без розширення (крапки в імені дозволені: вони не
%   інтерпретуються як розширення, значуще лише останнє ".<fmt>").
%
%   svg  : print -dsvg -painters      (векторний, редагований в Inkscape:
%          текст лишається текстом, лінії — окремими path)
%   pdf  : exportgraphics ContentType=vector   (для журналу / Illustrator)
%   tiff : exportgraphics Resolution=FIG.out.tiffDPI   (растр, фінал)
%   png  : exportgraphics Resolution=FIG.out.pngDPI    (прев'ю)
%   fig  : savefig                                     (перевідкрити в MATLAB)

files = strings(0,1);

for k = 1:numel(FIG.out.formats)
    fmt   = lower(FIG.out.formats{k});
    fmtDir = fullfile(outDir, fmt);
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
