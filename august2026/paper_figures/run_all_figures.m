 function run_all_figures(FIG)
% RUN_ALL_FIGURES  Пакетна обробка: усі рисунки у статтю + таблиці моментів.
%   Зовнішня точка входу пакета august2026\paper_figures.
%
%       run_all_figures            % бере cfg_figures()
%       run_all_figures(myFIG)     % власна конфігурація
%
%   Робить (кожен — обидві пари елементів f33-f44 і f23-f24,
%   generalized/OX/OY x зразки x приклади, color+gray, svg/pdf/png):
%     1) Fig1  сирі 2D-карти |f|/arg  + гістограми
%     2) Fig2  2D-АКФ тих карт         + 1D-перерізи АКФ
%     3) Fig3  2D-спектри потужності   + гістограми PSD
%     4) Fig4  вейвлет-скелетони (WTMM) + гістограми F(h) максимумів
%     5) Fig5  скалограми |W(a,b)|      + гістограми |W|
%     6) Fig6  крива D(q)               + спектр f(h) з Delta h
%     7) Fig7  повна матриця Мюллера на ОДНОМУ рисунку: |f_ik| + arg(f_ik),
%              обидва фазові вікна — 4 x (4x4) = 64 панелі
%     8) stats.moments / acf / psd / skeleton / wavelet / multifractal / mueller  (.txt + .docx)
%
%   Шлях: .../FigN/<color|gray>/<svg|pdf|png>/<generalized|OX|OY>/<файл>
%   Таблиці моментів — у теці свого рисунка, окремий файл на алгоритм:
%   .../FigN/stats.<набір>.<variant>.txt/.docx
%
%   Що САМЕ будувати — FIG.build (cfg_figures.m). Забери завдання зі списку —
%   воно пропускається. Поодинокі рисунки й далі: make_figN_xxx(cfg_figures()).
%
%   Структура пакета:
%     cfg_figures.m, fig_export.m, make_stats_table.m, run_all_figures.m  — спільне, тут
%     common\   — спільний рушій (tp_paper_read, paper_prep, render_grid_4x4, make_grid_pair)
%     figNN\    — по два скрипти-обгортки на рисунок (пари елементів)

here = fileparts(mfilename('fullpath'));   % ...\paper_figures
addpath(here, fullfile(here,'common'), fullfile(here,'fig01'), fullfile(here,'fig02'), ...
        fullfile(here,'fig03'), fullfile(here,'fig04'), fullfile(here,'fig05'), ...
        fullfile(here,'fig06'), fullfile(here,'fig07'));
if nargin < 1 || isempty(FIG); FIG = cfg_figures(); end
if ~exist(FIG.out.root,'dir'); mkdir(FIG.out.root); end
tp_paper_normalize('reset');   % свіжий кеш опорного масштабу f_11 на весь прогін
acf_win('reset');              % свіжий кеш спільного вікна лагів АКФ (FigN)

build = {'Fig1','Fig2','Fig3','Fig4','Fig5','Fig6','Fig7','stats'};   % за замовч. усе
if isfield(FIG,'build') && ~isempty(FIG.build); build = FIG.build; end

% таблиця завдань: {figTag, pairKey('' для Fig7), функція}
jobs = { ...
  'Fig1','f33f44', @() make_fig1_f33_f44(FIG);   'Fig1','f23f24', @() make_fig1_f23_f24(FIG); ...
  'Fig2','f33f44', @() make_fig2_f33_f44(FIG);   'Fig2','f23f24', @() make_fig2_f23_f24(FIG); ...
  'Fig3','f33f44', @() make_fig3_f33_f44(FIG);   'Fig3','f23f24', @() make_fig3_f23_f24(FIG); ...
  'Fig4','f33f44', @() make_fig4_f33_f44(FIG);   'Fig4','f23f24', @() make_fig4_f23_f24(FIG); ...
  'Fig5','f33f44', @() make_fig5_f33_f44(FIG);   'Fig5','f23f24', @() make_fig5_f23_f24(FIG); ...
  'Fig6','f33f44', @() make_fig6_f33_f44(FIG);   'Fig6','f23f24', @() make_fig6_f23_f24(FIG); ...
  'Fig7','',       @() make_fig7_mueller(FIG) };

t0 = tic;
fprintf('=== Скомпановані рисунки -> %s ===\n', FIG.out.root);
fprintf('формати: %s\nбудую: %s\n\n', strjoin(FIG.out.formats, ', '), strjoin(build, ', '));

for j = 1:size(jobs,1)
    if build_wants(build, jobs{j,1}, jobs{j,2})
        try
            jobs{j,3}();
        catch ME
            fprintf(2, '  [fail] %s%s : %s\n', jobs{j,1}, ...
                iff(isempty(jobs{j,2}),'',[':' jobs{j,2}]), ME.message);
        end
    end
end

if any(strcmpi(build, 'stats'))
    fprintf('\n=== Таблиці моментів ===\n');
    make_stats_table(FIG);
end

fprintf('\n=== Готово за %.0f с: %s ===\n', toc(t0), FIG.out.root);
end

% ----------------------------------------------------------------------
function s = iff(c,a,b); if c; s = a; else; s = b; end; end
