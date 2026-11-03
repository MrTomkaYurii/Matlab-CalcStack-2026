function tf = fig_exists(outDir, baseName, FIG, sub)
% FIG_EXISTS  true, якщо рисунок уже збережено в УСІХ форматах FIG.out.formats
%   (ті самі шляхи, що й fig_export). Для продовження після краху / вимкнення
%   світла: готові рисунки пропускаються. Перемалювати все — FIG.out.redo = true.

if nargin < 4 || isempty(sub); sub = ''; end
tf = false;
if isfield(FIG.out,'redo') && FIG.out.redo; return; end
for k = 1:numel(FIG.out.formats)
    fmt = lower(FIG.out.formats{k});
    fmtDir = fullfile(outDir, fmt);
    if ~isempty(sub); fmtDir = fullfile(fmtDir, sub); end
    if ~isfile(fullfile(fmtDir, [baseName '.' fmt])); return; end
end
tf = true;
end
