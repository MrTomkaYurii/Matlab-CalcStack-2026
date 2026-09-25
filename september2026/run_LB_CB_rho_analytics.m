% RUN_LB_CB_rho_ANALYTICS  Аналітика статистики Кроку B БЕЗ повторного розрахунку.
%   Перебудовує таблицю метрик із уже збережених result.mat Кроку B (статистика
%   перераховується, LB/CB/rho -- ні) і будує тренди по фазових вікнах, порівняння
%   зразків/прикладів, рисунки й highlights.csv у CFG.paths.analyticsRoot.
%   Обираються зразки/приклади/вікна/алгоритми, задані в cfg_September.m.
%   (Під час звичайного прогону run_LB_CB_rho_demo аналітика вже будується сама --
%   CFG.stepB.analytics = true; цей файл -- щоб перегнати її окремо.)

here = fileparts(mfilename('fullpath'));
addpath(here, fullfile(here,'LB_CB_rho'), genpath(fullfile(here,'august2026_copy')), ...
        fullfile(here,'visualization'), fullfile(here,'figure_export'), ...
        fullfile(here,'simulation'), fullfile(here,'fik_calculation'), ...
        fullfile(here,'stats'), fullfile(here,'analytics'));

CFG = cfg_September();
tp_run_analytics(CFG, 'rebuild');
