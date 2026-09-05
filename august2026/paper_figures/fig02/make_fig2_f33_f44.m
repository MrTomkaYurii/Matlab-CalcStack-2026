function make_fig2_f33_f44(FIG)
% MAKE_FIG2_F33_F44  Рисунок 2 у статтю (кореляційні характеристики),
%   пара елементів f33/f44.
%   16 панелей (4x4): ряди карт — 2D-АКФ карт |f33|, arg(f33), |f44|,
%   arg(f44) по 2 фазових вікнах (0-2pi, 0-0.75pi); ряди під ними —
%   1D-перерізи цих АКФ (пік у нульовому лагу).
%   Генерується окремо для generalized / OX / OY x {тканини} x {приклади}.
%
%   Тека: august2026\paper_figures\fig02\ (разом із make_fig2_f23_f24.m).
%   ОБСЯГ — cfg_figures.m, секція FIG.fig02_f33f44.*.
%   АКФ рахується на льоту з сирих result.mat (common\tp_acf_psd через
%   paper_prep); нічого у f_ik не перераховується.
%
%       make_fig2_f33_f44            % бере cfg_figures()
%       make_fig2_f33_f44(myFIG)

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(root, fullfile(root,'common'), here);
if nargin < 1 || isempty(FIG); FIG = cfg_figures(); end

fprintf('=== Fig2, варіант f33/f44 (АКФ) ===\n');
n = make_grid_pair(FIG, 'fig02_f33f44', 'Fig2', 'acf');
fprintf('=== Fig2 (f33,f44): %d рисунк(ів) -> %s ===\n', n, FIG.out.root);
end
