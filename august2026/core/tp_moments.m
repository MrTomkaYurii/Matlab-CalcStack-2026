function [mu, sd, sk, ku, n] = tp_moments(v, isPhase)
% TP_MOMENTS  Чотири статистичні моменти (mean/std/skew/kurt) вибірки v.
%   v має бути вже без NaN (isfinite) — фільтрує викликаюча сторона.
%   isPhase=true -> кругові моменти (циклічне середнє, центровані кути);
%   inакше -> звичайні лінійні моменти. Єдине джерело формул для
%   viz_maps_hist (текст на гістограмі) і viz_stats_table (текстовий файл),
%   щоб цифри в них завжди збігались.

n = numel(v);
if n < 2
    mu = NaN; sd = NaN; sk = NaN; ku = NaN;
    return;
end

if isPhase
    mu = angle(mean(exp(1i*v)));
    cc = atan2(sin(v-mu), cos(v-mu));   % центровані кути
    sd = std(v);
    zc = cc / max(std(cc), eps);
    sk = mean(zc.^3); ku = mean(zc.^4);
else
    mu = mean(v); sd = std(v);
    z  = (v-mu) / max(sd, eps);
    sk = mean(z.^3); ku = mean(z.^4);
end
end
