function outFile = tp_save_LB_CB_rho_result(R2, dir, CFG)
% TP_SAVE_LB_CB_RHO_RESULT  Зберігає ЧИСЛОВІ результати Кроку B (не лише
%   картинки) в ту саму теку, куди tp_save_figure.m кладе рисунки кожного
%   елемента (елементи на рівень нижче, у своїх підтеках LB_0_90/,
%   LB_45_135/, CB/, rho/, LB/), щоб result.mat завжди лежав поряд з
%   рисунками, які з нього побудовані — так само, як у Кроці A
%   (saveRoot\<зразок>\<алгоритм>\<dir>\result.mat):
%       saveRoot\<зразок>\<алгоритм+LB_CB_rho>\<dir>\result.mat   (variable R2)
%
%   R2  : вихід tp_LB_CB_rho_from_result.m (R2.elements = 5 зелених імен)
%   dir : той самий напрям/крок
%   CFG : потрібне лише CFG.paths.saveRoot

outDir = fullfile(CFG.paths.saveRoot, R2.sample, R2.algorithm, dir);
if ~exist(outDir, 'dir'); mkdir(outDir); end
outFile = fullfile(outDir, 'result.mat');
save(outFile, 'R2', '-v7.3');
end
