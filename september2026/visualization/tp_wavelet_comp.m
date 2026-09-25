function comp = tp_wavelet_comp(Z, meta, CFG)
% TP_WAVELET_COMP  Профіль із карти Z + CWT + масштаби/конус впливу/позначені масштаби.
%   ВИНЕСЕНО БЕЗ ЗМІН з viz_wavelet.m (локальна computeWavelet) -- щоб той самий
%   розрахунок використовували і подання viz_wavelet, і статистика tp_stats_element
%   (тоді цифри у текстовому файлі гарантовано ті самі, що на рисунку).
% Профіль із карти + CWT (важка частина) — рахується один раз.
switch lower(CFG.wavelet.profile)
    case 'center_col', sig = Z(:, round(size(Z,2)/2)).';  b = meta.y;  cutDir = 'OY';
    case 'mean_row',   sig = mean(Z,1,'omitnan');         b = meta.x;  cutDir = 'OX';
    otherwise,         sig = Z(round(size(Z,1)/2), :);    b = meta.x;  cutDir = 'OX';
end
sig = fillmissing(sig,'linear'); sig = fillmissing(sig,'nearest');

comp = struct('degenerate', true);
if all(~isfinite(sig)) || std(sig(isfinite(sig)))==0
    return;
end

fb = cwtfilterbank('SignalLength',numel(sig),'Wavelet',CFG.wavelet.name, ...
                   'VoicesPerOctave',CFG.wavelet.voicesPerOctave);
[wtc, freq, coi] = wt(fb, sig);   % coi: частотна межа конуса впливу, на кожен b
scal0 = scales(fb);               % повний (нефільтрований) набір масштабів, той самий порядок, що й freq
A0 = abs(wtc);

% межа COI у одиницях МАСШТАБУ (не частоти): a=1/f по тій самій кривій
% freq<->scal0, що дав сам CWT — інтерполяція, без припущень про сталу
% вейвлета. Скали БІЛЬШІ за coiScale(b) у позиції b — ненадійні (край).
coiScale = interp1(freq, scal0, coi, 'linear', 'extrap');
coiScale = reshape(coiScale, 1, []);   % рядок, як і b — інакше неявне
                                       % розширення в матрицю замість поелементного порівняння
coiScale = min(max(coiScale, min(scal0)), max(scal0));

sr = CFG.wavelet.scaleRange;             % обмеження масштабів (напр. [1 100])
keep = scal0>=sr(1) & scal0<=sr(2);
scal = scal0; A = A0;
if any(keep), scal = scal0(keep); A = A0(keep,:); end

hi = deriveHighlightScaleIdx(scal, CFG.wavelet.highlightScales);

comp.degenerate = false;
comp.b = b; comp.scal = scal; comp.A = A;
comp.coiScale = coiScale; comp.hi = hi;
end

% ------------------------------------------------------------------------
function hi = deriveHighlightScaleIdx(scal, targetScales)
% РІВНО 2 перерізи, ЗАФІКСОВАНІ цільові масштаби (CFG.wavelet.highlightScales,
% типово [3 25]) -- для кожного цільового значення береться НАЙБЛИЖЧИЙ
% реально доступний масштаб у scal (сітка CWT дискретна, точного 3.000 чи
% 25.000 там зазвичай нема); підпис показує це фактичне значення без
% округлення (%.3g), не цільове.
hi = nan(1, numel(targetScales));
for j = 1:numel(targetScales)
    [~, hi(j)] = min(abs(scal - targetScales(j)));
end
hi = unique(hi, 'stable');   % якщо обидві цілі впали в один і той самий бін
end
