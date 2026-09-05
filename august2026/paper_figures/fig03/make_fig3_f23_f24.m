function make_fig3_f23_f24(FIG)
% MAKE_FIG3_F23_F24  Рисунок 3 у статтю (спектри потужності),
%   пара елементів f23/f24. Те саме, що make_fig3_f33_f44, інші елементи.
%   ОБСЯГ — cfg_figures.m, секція FIG.fig03_f23f24.*.

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(root, fullfile(root,'common'), here);
if nargin < 1 || isempty(FIG); FIG = cfg_figures(); end

fprintf('=== Fig3, варіант f23/f24 (PSD) ===\n');
n = make_grid_pair(FIG, 'fig03_f23f24', 'Fig3', 'psd');
fprintf('=== Fig3 (f23,f24): %d рисунк(ів) -> %s ===\n', n, FIG.out.root);
end
