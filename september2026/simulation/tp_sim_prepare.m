function tp_sim_prepare(CFG)
% TP_SIM_PREPARE  СТВОРЕННЯ модельних зразків: для кожного імені з CFG.simSamples і кожного
%   прикладу з CFG.paths.examples -- сирі поля моделі:
%     tp_sim_speckle_BT -> .mat у CFG.paths.simRoot (той самий формат, що й реальні зразки;
%     august2026_copy\tp_load_mat.m читає їх без змін) + рисунки етапів Sim 01-05 (CFG.sim.stageFigures)
%     у <saveRoot>\<зразок>\<приклад>\SIM_ANALYSIS\.
%   Запускається ОКРЕМО -- run_sim_model.m -- і лише раз: основний прогін (run_LB_CB_rho_demo)
%   модель НЕ створює, а лише бере готові сирі поля й рахує з них Крок A -- так само, як для
%   реальних зразків (fik_calculation\tp_prepare_fik_calc.m).
%   Що вже створено -- не перестворюється, доки CFG.sim.regenerate = false.

for s = 1:numel(CFG.simSamples)
    smp = CFG.simSamples{s};
    for e = 1:numel(CFG.paths.examples)
        ex = CFG.paths.examples{e};
        fprintf('\n##### модельний зразок %s\\%s #####\n', smp, ex);

        rawDir = fullfile(CFG.paths.simRoot, smp, ex, 'mat');
        haveRaw = all(cellfun(@(f) isfile(fullfile(rawDir, f)), rawNames()));
        if CFG.sim.regenerate || ~haveRaw
            [IMG, SIM, DBG] = tp_sim_speckle_BT(CFG, ex);
            tp_sim_write_mat(CFG, smp, ex, IMG, SIM);
            fprintf('  [sim] створено (seed=%d) -> %s\n', SIM.seed, rawDir);
            if CFG.sim.stageFigures
                tp_sim_analysis(CFG, smp, ex, SIM, DBG);
            end
        else
            fprintf('  [sim] уже створено, пропущено (CFG.sim.regenerate = false): %s\n', rawDir);
        end
    end
end
end

% ------------------------------------------------------------------------
function names = rawNames()
st = {'0','45','90','135','liv','prav'};
names = [strcat('ex_', st, '.mat'), strcat('ey_', st, '.mat')];
end
