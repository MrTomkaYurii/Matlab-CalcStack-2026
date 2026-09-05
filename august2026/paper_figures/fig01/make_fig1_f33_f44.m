function make_fig1_f33_f44(FIG)
% MAKE_FIG1_F33_F44  Рисунок 1 у статтю: елементи f33 і f44.
%   16 панелей (4 стовпці x 4 ряди): карти + гістограми, по 2 фазові вікна
%   (0-2pi, 0-0.75pi); стовпці — |f33|, arg(f33), |f44|, arg(f44).
%   Генерується окремо для XY / OX / OY x {Серце, Мяз живота, Мозг} x {1, 3}.
%
%   Тека: august2026\paper_figures\fig01\ — разом із make_fig1_f23_f24.m
%   (обидва — Fig1, різні пари елементів; спільний каркас — у ..\common\).
%   ОБСЯГ (елементи/тканини/приклади/варіанти) — у cfg_figures.m, секція
%   FIG.fig01_f33f44.*.
%
%   Запуск:
%       make_fig1_f33_f44            % бере cfg_figures()
%       make_fig1_f33_f44(myFIG)     % власна конфігурація
%
%   Правити оформлення саме цього рисунка можна тут або в спільному
%   ..\common\render_two_point_grid.m (каркас, спільний з make_fig1_f23_f24 —
%   та сама 16-панельна сітка, інші елементи).

here = fileparts(mfilename('fullpath'));   % ...\paper_figures\fig01
root = fileparts(here);                     % ...\paper_figures
addpath(root, fullfile(root,'common'), here);
if nargin < 1 || isempty(FIG); FIG = cfg_figures(); end

fprintf('=== Fig1, варіант f33/f44 ===\n');
n = make_grid_pair(FIG, 'fig01_f33f44', 'Fig1', 'raw');
fprintf('=== Fig1 (f33,f44): %d рисунк(ів) -> %s ===\n', n, FIG.out.root);
end
