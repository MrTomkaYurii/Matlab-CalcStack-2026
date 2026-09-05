function make_fig4_f33_f44(FIG)
% MAKE_FIG4_F33_F44  Рисунок 4 у статтю (вейвлет-скелетони), пара f33/f44.
%   16 панелей (4x4): ряди карт — вейвлет-скелетон (лінії локальних
%   максимумів |W(a,b)|, WTMM) у площині (позиція b, масштаб a), точки
%   пофарбовані амплітудою максимуму; ряди під ними — гістограми F(h)
%   розподілу цих амплітуд. По 2 фазових вікнах, для |f33|/arg(f33)/
%   |f44|/arg(f44). generalized / OX / OY x {тканини} x {приклади}.
%
%   Тека: august2026\paper_figures\fig04\. ОБСЯГ — FIG.fig04_f33f44.*;
%   параметри вейвлета — FIG.wav.*. Потребує Wavelet Toolbox.
%
%       make_fig4_f33_f44            % бере cfg_figures()
%       make_fig4_f33_f44(myFIG)

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(root, fullfile(root,'common'), here);
if nargin < 1 || isempty(FIG); FIG = cfg_figures(); end

fprintf('=== Fig4, варіант f33/f44 (скелетон) ===\n');
n = make_grid_pair(FIG, 'fig04_f33f44', 'Fig4', 'skel');
fprintf('=== Fig4 (f33,f44): %d рисунк(ів) -> %s ===\n', n, FIG.out.root);
end
