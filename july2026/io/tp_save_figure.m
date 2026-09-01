function outFile = tp_save_figure(fig, CFG, parts, name)
% TP_SAVE_FIGURE  Маршрутизує фігуру в дерево результатів і експортує її.
%   Розкладка тек:
%       saveRoot / <зразок> / <алгоритм> / <DIR> / <подання> / name.<fmt>
%
%   parts : cellstr підтек, напр. {sample, algorithm, dir, representation}
%   name  : базове ім'я файлу (без розширення), напр. 'f11_module'
%
%   Повертає повний шлях. Використовує exportgraphics для якісного DPI.

outDir = fullfile(CFG.paths.saveRoot, parts{:});
if ~exist(outDir, 'dir'); mkdir(outDir); end

name    = matlab.lang.makeValidName(name);   % безпечне для файлової системи ім'я
outFile = fullfile(outDir, [name '.' CFG.out.format]);

try
    exportgraphics(fig, outFile, 'Resolution', CFG.out.dpi);
catch
    % Запасний варіант для старих версій без exportgraphics
    print(fig, outFile, ['-d' CFG.out.format], sprintf('-r%d', CFG.out.dpi));
end

if CFG.out.closeAfter && ishandle(fig)
    close(fig);
end
end
