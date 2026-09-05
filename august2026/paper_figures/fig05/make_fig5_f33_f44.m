function make_fig5_f33_f44(FIG)
% MAKE_FIG5_F33_F44  Рисунок 5 у статтю (вейвлети), пара елементів f33/f44.
%   16 панелей (4x4): ряди карт — скалограма |W(a,b)| (CWT 1D-профілю карт
%   |f33|, arg(f33), |f44|, arg(f44)) по 2 фазових вікнах; ряди під ними —
%   гістограми амплітуд вейвлет-коефіцієнтів |W|.
%   Генерується окремо для generalized / OX / OY x {тканини} x {приклади}.
%
%   Тека: august2026\paper_figures\fig05\ (разом із make_fig5_f23_f24.m).
%   ОБСЯГ — cfg_figures.m, секція FIG.fig05_f33f44.*; параметри вейвлета —
%   FIG.wav.* (профіль, вейвлет, голоси/октава, діапазон масштабів).
%   Потребує Wavelet Toolbox (cwtfilterbank/wt).
%
%       make_fig5_f33_f44            % бере cfg_figures()
%       make_fig5_f33_f44(myFIG)

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(root, fullfile(root,'common'), here);
if nargin < 1 || isempty(FIG); FIG = cfg_figures(); end

fprintf('=== Fig5, варіант f33/f44 (вейвлет) ===\n');
n = make_grid_pair(FIG, 'fig05_f33f44', 'Fig5', 'wav');
fprintf('=== Fig5 (f33,f44): %d рисунк(ів) -> %s ===\n', n, FIG.out.root);
end
