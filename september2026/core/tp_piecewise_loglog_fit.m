function fit = tp_piecewise_loglog_fit(f, p)
% TP_PIECEWISE_LOGLOG_FIT  Двосегментна (кусково-лінійна) апроксимація
%   log-log залежності p(f) — замість однієї прямої на весь діапазон
%   (яка на реальних даних із "коліном" між двома режимами тільки нав'язує
%   хибну монофрактальну картину, див. обговорення viz_acf_cuts.m).
%   Точку зламу шукаємо перебором (мінімум сумарного SSE обох сегментів).
%   Другий (високочастотний) сегмент, якщо майже плаский (|нахил|<0.3),
%   позначається як "шумовий поріг" — далі цієї межі спектр вже не сигнал.
%
%   fit.valid, fit.breakF, fit.seg1/.seg2 = struct('lf',[a b],'coef',[m c],'beta',-m),
%   fit.isNoiseFloor2

valid = isfinite(f) & isfinite(p) & f > 0 & p > 0;
lf = log10(f(valid)); lp = log10(p(valid));
n = numel(lf);

fit = struct('valid', false);
if n < 10
    return;   % замало точок для двох стійких сегментів
end

bestSSE = Inf; bestK = NaN;
for k = 4:(n-4)
    c1 = polyfit(lf(1:k), lp(1:k), 1);
    c2 = polyfit(lf(k+1:end), lp(k+1:end), 1);
    sse = sum((lp(1:k)   - polyval(c1,lf(1:k))).^2) + ...
          sum((lp(k+1:end) - polyval(c2,lf(k+1:end))).^2);
    if sse < bestSSE
        bestSSE = sse; bestK = k;
    end
end
k = bestK;
c1 = polyfit(lf(1:k), lp(1:k), 1);
c2 = polyfit(lf(k+1:end), lp(k+1:end), 1);

fit.valid  = true;
fit.breakF = 10^lf(k);
fit.seg1 = struct('lf',[lf(1) lf(k)],     'coef',c1, 'beta',-c1(1));
fit.seg2 = struct('lf',[lf(k+1) lf(end)], 'coef',c2, 'beta',-c2(1));
fit.isNoiseFloor2 = abs(fit.seg2.beta) < 0.3;
end
