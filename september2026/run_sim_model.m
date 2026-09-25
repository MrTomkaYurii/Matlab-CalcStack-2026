% RUN_SIM_MODEL  СТВОРЕННЯ модельного (симульованого) зразка -- ОКРЕМИЙ запуск, раз.
%   Генерує сирі поля моделі (simulation\, той самий формат, що й реальні зразки) і малює
%   етапи Sim 01-05. Що вже створено -- пропускається (CFG.sim.regenerate = false); щоб
%   створити заново -- CFG.sim.regenerate = true.
%   Основний прогін run_LB_CB_rho_demo модель НЕ створює: він бере готові сирі поля, рахує з
%   них Крок A і Крок B так само, як для реальних зразків. Тому цей скрипт запускати треба
%   ДО основного прогону -- один раз (або після зміни CFG.sim.* / CFG.paths.examples).
%   Параметри моделі -- cfg_September.m, розділ 2б (CFG.simSamples, CFG.sim.*, приклад = CFG.paths.examples).

here = fileparts(mfilename('fullpath'));
addpath(here, fullfile(here,'LB_CB_rho'), genpath(fullfile(here,'august2026_copy')), ...
        fullfile(here,'visualization'), fullfile(here,'figure_export'), ...
        fullfile(here,'simulation'), fullfile(here,'fik_calculation'), ...
        fullfile(here,'stats'), fullfile(here,'analytics'));

CFG = cfg_September();
tp_sim_prepare(CFG);
fprintf('\nМодель створена. Далі: run_LB_CB_rho_demo\n');
