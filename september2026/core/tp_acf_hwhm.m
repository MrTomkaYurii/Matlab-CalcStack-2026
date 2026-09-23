function [hw, loLag, hiLag] = tp_acf_hwhm(lag, curve)
% TP_ACF_HWHM  Повна ширина на половині максимуму (FWHM/HWHM) 1D-перерізу
%   ACF (пік у lag=0), лінійна інтерполяція між сусідніми відліками.
%   Спільна для viz/viz_acf_cuts.m (малювання) і analysis/ (числове
%   зведення) — щоб цифри завжди збігались з тим, що на графіку.
%
%   [hw, loLag, hiLag] = tp_acf_hwhm(lag, curve)
%       hw            : повна ширина (hiLag-loLag), NaN якщо не знайдено
%       loLag, hiLag  : межі зліва/справа від піка на рівні 0.5*peak

[~, i0] = min(abs(lag));
peak = curve(i0);
half = 0.5*peak;

hiLag = NaN;
for i = i0:numel(curve)-1
    if curve(i) >= half && curve(i+1) < half
        t = (half - curve(i)) / (curve(i+1) - curve(i));
        hiLag = lag(i) + t*(lag(i+1)-lag(i));
        break;
    end
end
loLag = NaN;
for i = i0:-1:2
    if curve(i) >= half && curve(i-1) < half
        t = (half - curve(i)) / (curve(i-1) - curve(i));
        loLag = lag(i) + t*(lag(i-1)-lag(i));
        break;
    end
end

if isnan(hiLag) && isnan(loLag)
    hw = NaN;
elseif isnan(hiLag)
    hw = 2*abs(loLag);
elseif isnan(loLag)
    hw = 2*abs(hiLag);
else
    hw = hiLag - loLag;
end
end
