function make_fig5_f23_f24(FIG)
% MAKE_FIG5_F23_F24  Рисунок 5 (вейвлети), пара елементів f23/f24.
%   Те саме, що make_fig5_f33_f44, інші елементи. ОБСЯГ — FIG.fig05_f23f24.*.

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(root, fullfile(root,'common'), here);
if nargin < 1 || isempty(FIG); FIG = cfg_figures(); end

fprintf('=== Fig5, варіант f23/f24 (вейвлет) ===\n');
n = make_grid_pair(FIG, 'fig05_f23f24', 'Fig5', 'wav');
fprintf('=== Fig5 (f23,f24): %d рисунк(ів) -> %s ===\n', n, FIG.out.root);
end
