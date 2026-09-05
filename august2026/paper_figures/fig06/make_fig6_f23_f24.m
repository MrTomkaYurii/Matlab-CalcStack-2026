function make_fig6_f23_f24(FIG)
% MAKE_FIG6_F23_F24  Рисунок 6 (мультифрактали), пара елементів f23/f24.
%   Те саме, що make_fig6_f33_f44, інші елементи. ОБСЯГ — FIG.fig06_f23f24.*.

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(root, fullfile(root,'common'), here);
if nargin < 1 || isempty(FIG); FIG = cfg_figures(); end

fprintf('=== Fig6, варіант f23/f24 (мультифрактали) ===\n');
n = make_grid_pair(FIG, 'fig06_f23f24', 'Fig6', 'mfr');
fprintf('=== Fig6 (f23,f24): %d рисунк(ів) -> %s ===\n', n, FIG.out.root);
end
