% RUN_LB_CB_rho_DEMO  Запуск Кроку B (LB_0_90, LB_45_135, CB, rho, LB).
%   ВСІ налаштування -- у cfg_September.m (зразки, приклади, алгоритми,
%   фазові вікна, шляхи, що малювати, стиль). Тут нічого не міняється:
%   відредагуй cfg_September.m і запусти цей файл.
%
%   Що робить (LB_CB_rho\tp_run_LB_CB_rho.m): для кожного зразок × приклад ×
%   фаза × алгоритм бере ГОТОВИЙ result.mat Кроку A (для реальних зразків --
%   August-результати, не перераховується), рахує 5 величин, зберігає числа і
%   будує рисунки під CFG.paths.saveRoot. Крок A рахується тут з нуля з сирих полів
%   (реальні зразки -- CFG.fik.source; модель -- завжди). Сирі поля МОДЕЛІ ('Модель',
%   симуляція) тут НЕ створюються -- їх раз створює run_sim_model.m.

here = fileparts(mfilename('fullpath'));
addpath(here, fullfile(here,'LB_CB_rho'), genpath(fullfile(here,'august2026_copy')), ...
        fullfile(here,'visualization'), fullfile(here,'figure_export'), ...
        fullfile(here,'simulation'), fullfile(here,'fik_calculation'), ...
        fullfile(here,'stats'), fullfile(here,'analytics'));

CFG = cfg_September();
tp_run_LB_CB_rho(CFG);
