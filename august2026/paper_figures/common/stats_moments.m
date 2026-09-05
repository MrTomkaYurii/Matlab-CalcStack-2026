function z = stats_moments(x, excessKurt)
% STATS_MOMENTS  Чотири статистичні моменти розподілу (Z1..Z4), NaN відкинуті.
%   z = [Z1 Z2 Z3 Z4]:
%     Z1 = середнє
%     Z2 = СКВ (std, нормування на N-1)
%     Z3 = асиметрія (skewness)
%     Z4 = ексцес (kurtosis); excessKurt=true -> надлишковий (kurtosis-3)
%
%   Рахує напряму (без Statistics Toolbox), щоб пакет рисунків не залежав
%   від тулбоксу.

if nargin < 2, excessKurt = false; end
x = x(:);
x = x(isfinite(x));
n = numel(x);
if n < 2
    z = [NaN NaN NaN NaN];
    return;
end
m  = mean(x);
s  = std(x, 0);                 % 0 -> нормування на N-1
if s <= 0
    z = [m 0 NaN NaN];
    return;
end
xc = (x - m) / s;
Z3 = mean(xc.^3);
Z4 = mean(xc.^4);
if excessKurt, Z4 = Z4 - 3; end
z = [m s Z3 Z4];
end
