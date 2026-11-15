function row = tz_stats(meta, quantity, x, isPhase, extra)
% TZ_STATS  Один рядок таблиці стат-моментів: Z1..Z4 розподілу x (NaN відкинуті).
%   isPhase = true -> КРУГОВІ моменти аргументу (stats_moments -> tp_moments):
%       Z1 — середній напрям [0, 2π), Z2 — кругове СКВ √(−2 ln R), Z3/Z4 — кругові асиметрія/ексцес.
%   isPhase = false -> лінійні: середнє, СКВ, асиметрія, НАДЛИШКОВИЙ ексцес (норма 0).
%   meta  : struct з полями block, sub, fig, col, sample, example, algo, win, elem
%   extra : довільний підпис (напр. 'L = 7.2 px' для АКФ), '' якщо нема
if nargin < 5; extra = ''; end
x = x(:);  x = x(isfinite(x));
if numel(x) >= 2
    z = stats_moments(x, true, isPhase);
else
    z = [NaN NaN NaN NaN];
end
row = {meta.block, meta.sub, meta.fig, meta.col, meta.sample, meta.example, meta.algo, ...
       sprintf('0–%gπ', meta.win), meta.elem, quantity, numel(x), z(1), z(2), z(3), z(4), extra};
end
