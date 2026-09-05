function make_fig4_f23_f24(FIG)
% MAKE_FIG4_F23_F24  Рисунок 4 (вейвлет-скелетони), пара елементів f23/f24.
%   Те саме, що make_fig4_f33_f44, інші елементи. ОБСЯГ — FIG.fig04_f23f24.*.

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(root, fullfile(root,'common'), here);
if nargin < 1 || isempty(FIG); FIG = cfg_figures(); end

fprintf('=== Fig4, варіант f23/f24 (скелетон) ===\n');
n = make_grid_pair(FIG, 'fig04_f23f24', 'Fig4', 'skel');
fprintf('=== Fig4 (f23,f24): %d рисунк(ів) -> %s ===\n', n, FIG.out.root);
end
