function [lo, hi, levels] = tp_contour_levels(Z, nL)
% TP_CONTOUR_LEVELS  Спільний розрахунок рівнів контуру (строго зростаючі),
%   для 2D (viz_sections), 3D (viz_contour3d) і Блоку 3 (viz_block3_contours) —
%   щоб рівні завжди узгоджувались, якщо колись зміниться логіка.

lo = min(Z(:),[],'omitnan'); hi = max(Z(:),[],'omitnan');
if ~(isfinite(lo) && isfinite(hi)), lo=0; hi=1; end
if hi <= lo, hi = lo + 1e-9; end
levels = linspace(lo, hi, nL);
end
