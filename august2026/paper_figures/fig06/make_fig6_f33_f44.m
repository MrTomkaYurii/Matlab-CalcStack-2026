function make_fig6_f33_f44(FIG)
% MAKE_FIG6_F33_F44  Рисунок 6 у статтю (мультифрактали), пара f33/f44.
%   16 панелей (4x4): ряд 1/3 — крива D(q) (спектр узагальнених розмірностей
%   1D-профілю карт |f33|, arg(f33), |f44|, arg(f44)); ряд 2/4 — спектр
%   сингулярностей f(h) з підписаною шириною Delta h (головний результат
%   мультифрактального аналізу). По 2 фазових вікнах. generalized/OX/OY x
%   {тканини} x {приклади}.
%
%   Тека: august2026\paper_figures\fig06\. ОБСЯГ — FIG.fig06_f33f44.*;
%   параметри — FIG.wav.* + FIG.mfr.*. core\tp_multifractal.m (спрощений
%   WTMM). Потребує Wavelet Toolbox.
%
%       make_fig6_f33_f44            % бере cfg_figures()
%       make_fig6_f33_f44(myFIG)

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(root, fullfile(root,'common'), here);
if nargin < 1 || isempty(FIG); FIG = cfg_figures(); end

fprintf('=== Fig6, варіант f33/f44 (мультифрактали) ===\n');
n = make_grid_pair(FIG, 'fig06_f33f44', 'Fig6', 'mfr');
fprintf('=== Fig6 (f33,f44): %d рисунк(ів) -> %s ===\n', n, FIG.out.root);
end
