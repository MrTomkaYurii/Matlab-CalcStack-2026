function tp_prepare_fik_calc(CFG)
% TP_PREPARE_FIK_CALC  Крок A "з нуля" для зразків з CFG.samples: з сирих комплексних Ex,Ey рахує
%   f_ik -- алгоритми orthogonal і XY, фазові вікна CFG.fik.phases -- і пише result.mat у
%   CFG.paths.fikRoot (fik_calculation\tp_run_fik_calc.m). Що вже є на диску -- не перераховується,
%   доки CFG.fik.recompute = false.
%     реальні зразки  : сирі поля з CFG.paths.matRoot; лише при CFG.fik.source = 'compute'
%                       (при 'august' Крок B бере готові August-результати, тут нічого не робиться);
%     модельні зразки : сирі поля з CFG.paths.simRoot (їх створює run_sim_model.m); рахуються
%                       завжди. Якщо модель ще не створено -- [fik_calc skip] з підказкою.
%   Відомо биті приклади (CFG.dataHealth) пропускаються, як і в Кроці B.
%
%   Перевірено: результат збігається з August-результатами ТОЧНО (різниця 0) --
%   Серце/2 і Мяз живота/2, усі 16 елементів, XY / OX / OY.

for s = 1:numel(CFG.samples)
    smp = CFG.samples{s};
    isSim = any(strcmp(CFG.simSamples, smp));
    if ~isSim && ~strcmpi(CFG.fik.source, 'compute'), continue; end

    CFGa = CFG;
    CFGa.paths.saveRoot = CFG.paths.fikRoot;                     % куди tp_run_fik_calc пише result.mat
    if isSim, CFGa.paths.matRoot = CFG.paths.simRoot; end             % звідки читати сирі поля

    for e = 1:numel(CFG.paths.examples)
        ex = CFG.paths.examples{e};
        if any(strcmp(CFG.dataHealth.broken, [smp '\' ex])) && ~CFG.dataHealth.runBroken
            continue;                              % раннер Кроку B напише [skip] сам
        end
        if isSim && ~isfile(fullfile(CFGa.paths.matRoot, smp, ex, 'mat', 'ex_0.mat'))
            fprintf(2, '[fik_calc skip] %s\\%s: модель не створено (немає сирих полів) -- спершу run_sim_model.m\n', smp, ex);
            continue;
        end
        try
            tp_run_fik_calc(CFGa, smp, ex, CFG.fik.recompute);
        catch ME
            fprintf(2, '[fik_calc skip] %s\\%s: %s\n', smp, ex, ME.message);
        end
    end
end
end
