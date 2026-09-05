function make_fig3_f33_f44(FIG)
% MAKE_FIG3_F33_F44  Рисунок 3 у статтю (спектри потужності),
%   пара елементів f33/f44.
%   16 панелей (4x4): ряди карт — 2D-спектр потужності (log10 PSD) карт
%   |f33|, arg(f33), |f44|, arg(f44) по 2 фазових вікнах; ряди під ними —
%   гістограми значень PSD (як у Рис. 1, тільки для PSD).
%   Генерується окремо для generalized / OX / OY x {тканини} x {приклади}.
%
%   Тека: august2026\paper_figures\fig03\ (разом із make_fig3_f23_f24.m).
%   ОБСЯГ — cfg_figures.m, секція FIG.fig03_f33f44.*.
%   PSD рахується на льоту з сирих result.mat (common\tp_acf_psd через
%   paper_prep); нічого у f_ik не перераховується.
%
%       make_fig3_f33_f44            % бере cfg_figures()
%       make_fig3_f33_f44(myFIG)

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(root, fullfile(root,'common'), here);
if nargin < 1 || isempty(FIG); FIG = cfg_figures(); end

fprintf('=== Fig3, варіант f33/f44 (PSD) ===\n');
n = make_grid_pair(FIG, 'fig03_f33f44', 'Fig3', 'psd');
fprintf('=== Fig3 (f33,f44): %d рисунк(ів) -> %s ===\n', n, FIG.out.root);
end
