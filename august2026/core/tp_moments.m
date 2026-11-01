function [mu, sd, sk, ku, n] = tp_moments(v, isPhase)
% TP_MOMENTS  Чотири статистичні моменти Z1..Z4 вибірки v.
%   v має бути вже без NaN (isfinite) — фільтрує викликаюча сторона.
%   Єдине джерело формул для viz_maps_hist (текст на гістограмі),
%   viz_stats_table (текстовий файл) і аналітики, щоб цифри збігались.
%
%   isPhase=false -> центральні моменти:
%       Z1 = середнє, Z2 = СКВ (N-1), Z3 = асиметрія, Z4 = ексцес - 3
%   isPhase=true  -> кругові моменти (не залежать від запису фази
%       в (-pi,pi] чи [0,2pi)):
%       M1 = mean(exp(i*v)) = R*exp(i*mu),  M2 = mean(exp(2i*v)) = R2*exp(i*mu2)
%       Z1 = mu (у [0,2pi)),  Z2 = sqrt(-2 ln R),
%       Z3 = R2*sin(mu2-2mu)/(1-R)^(3/2),  Z4 = (R2*cos(mu2-2mu) - R^4)/(1-R)^2

n = numel(v);
if n < 2
    mu = NaN; sd = NaN; sk = NaN; ku = NaN;
    return;
end

if isPhase
    M1 = mean(exp(1i*v));   R  = abs(M1);   m1 = angle(M1);
    M2 = mean(exp(2i*v));   R2 = abs(M2);   m2 = angle(M2);
    mu = mod(m1, 2*pi);
    sd = sqrt(-2*log(max(R, realmin)));
    q  = max(1 - R, eps);
    sk = R2*sin(m2 - 2*m1) / q^1.5;
    ku = (R2*cos(m2 - 2*m1) - R^4) / q^2;
else
    mu = mean(v); sd = std(v);
    z  = (v-mu) / max(sd, eps);
    sk = mean(z.^3); ku = mean(z.^4) - 3;
end
end
