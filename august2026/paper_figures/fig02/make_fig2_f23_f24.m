function make_fig2_f23_f24(FIG)
% MAKE_FIG2_F23_F24  Рисунок 2 у статтю (кореляційні характеристики),
%   пара елементів f23/f24. Те саме, що make_fig2_f33_f44, інші елементи.
%   ОБСЯГ — cfg_figures.m, секція FIG.fig02_f23f24.*.

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(root, fullfile(root,'common'), here);
if nargin < 1 || isempty(FIG); FIG = cfg_figures(); end

fprintf('=== Fig2, варіант f23/f24 (АКФ) ===\n');
n = make_grid_pair(FIG, 'fig02_f23f24', 'Fig2', 'acf');
fprintf('=== Fig2 (f23,f24): %d рисунк(ів) -> %s ===\n', n, FIG.out.root);
end
