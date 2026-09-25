function rawDir = tp_sim_write_mat(CFG, sample, example, IMG, SIM)
% TP_SIM_WRITE_MAT  Записує модельні поля в ТОЙ САМИЙ формат, що й реальні
%   зразки, тож august2026_copy\tp_load_mat.m читає їх без жодних змін:
%       <simRoot>\<зразок>\<приклад>\mat\ex_<стан>.mat, ey_<стан>.mat
%       стан ∈ {0,45,90,135,liv,prav}; у кожному РІВНО ОДНА комплексна N x N
%       змінна (ex / ey).
%   Поруч (НЕ в теці mat) -- truth.mat: істина, за якою побудовано зразок
%       (theta, delta, спекл-носій, seed, множник нормування) для перевірки.
%
%   IMG, SIM : виходи tp_sim_speckle_BT(CFG, example)

rawDir = fullfile(CFG.paths.simRoot, sample, example, 'mat');
if ~exist(rawDir, 'dir'); mkdir(rawDir); end

states  = {'0','45','90','135','liv','prav'};
inNames = {'in0','in45','in90','in135','inliv','inprav'};
for s = 1:numel(states)
    ex = IMG.(inNames{s}).Ex; %#ok<NASGU>
    ey = IMG.(inNames{s}).Ey; %#ok<NASGU>
    save(fullfile(rawDir, sprintf('ex_%s.mat', states{s})), 'ex');
    save(fullfile(rawDir, sprintf('ey_%s.mat', states{s})), 'ey');
end

truth = SIM; %#ok<NASGU>
simParams = CFG.sim; %#ok<NASGU>
save(fullfile(CFG.paths.simRoot, sample, example, 'truth.mat'), 'truth', 'simParams');
end
