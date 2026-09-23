function compare_f34_f43()
% COMPARE_F34_F43  Пряме порівняння двох 2D-карт f34 і f43 (Крок A,
%   реальні дані Серце/2) -- чи вони однакові, чи різні.

resultFile = 'C:\August 2026-Results\Розрахунки - Двот. елем. ММ\Серце\2\phase_01_[0-2.00pi]\XY\step_1\result.mat';
S = load(resultFile);
R = S.R;
dir = R.dirs{1};

f34 = R.data.(dir).f34.cplx;
f43 = R.data.(dir).f43.cplx;

fprintf('Розмір карт: %dx%d\n', size(f34,1), size(f34,2));
fprintf('\n--- перші 3x3 пікселі ---\n');
fprintf('f34(1:3,1:3):\n'); disp(f34(1:3,1:3));
fprintf('f43(1:3,1:3):\n'); disp(f43(1:3,1:3));

diffMap = f34 - f43;
finiteMask = isfinite(diffMap);
absDiff = abs(diffMap(finiteMask));
relDiff = absDiff ./ max(abs(f34(finiteMask)), abs(f43(finiteMask)));

fprintf('\n--- f34 - f43 (різниця по всій карті) ---\n');
fprintf('max |f34-f43|       = %g\n', max(absDiff));
fprintf('mean |f34-f43|      = %g\n', mean(absDiff));
fprintf('частка пікселів, де f34==f43 РІВНО (abs diff < 1e-12): %.2f%%\n', ...
    100*mean(absDiff < 1e-12));
fprintf('mean відносної різниці |f34-f43|/max(|f34|,|f43|): %.4f (%.1f%%)\n', ...
    mean(relDiff), 100*mean(relDiff));

c = corrcoef(real(f34(finiteMask)), real(f43(finiteMask)));
fprintf('\nкореляція Re(f34) vs Re(f43): %.4f\n', c(1,2));
c2 = corrcoef(imag(f34(finiteMask)), imag(f43(finiteMask)));
fprintf('кореляція Im(f34) vs Im(f43): %.4f\n', c2(1,2));

fprintf('\n|f34| mean=%.4g std=%.4g\n', mean(abs(f34(finiteMask))), std(abs(f34(finiteMask))));
fprintf('|f43| mean=%.4g std=%.4g\n', mean(abs(f43(finiteMask))), std(abs(f43(finiteMask))));
end
