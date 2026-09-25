function LBc = tp_level_bands_calc(Z, CFG)
% TP_LEVEL_BANDS_CALC  Рівні смугового аналізу й кількість пікселів у кожній смузі.
%   ВИНЕСЕНО БЕЗ ЗМІН з viz_level_bands.m (buildFigure) -- щоб той самий розрахунок
%   використовували і рисунок, і статистика tp_stats_element (цифри збігаються).
%
%   CFG.viz.bandLevels рівнів рівномірно між min і max, ПЛЮС 1 додатковий рівень =
%   МОДА розподілу (центр найбільш заповненого біна гістограми). Смуга кожного
%   рівня: |Z - рівень| <= halfW, halfW = 0.5*CFG.viz.bandWidthPct*(max-min).
%
%   LBc.valid = false, якщо розподіл вироджений (нічого рахувати/малювати);
%   інакше: lo, hi, levels (зростаючі, NL штук), peakIdx (індекс рівня-моди),
%   peakLevel, halfW, nTotal (скінченних пікселів), nPix (у кожній смузі),
%   pct (% від nTotal), NL.

NL0 = 8;    if isfield(CFG.viz,'bandLevels'),   NL0 = CFG.viz.bandLevels;   end
pct = 0.02; if isfield(CFG.viz,'bandWidthPct'), pct = CFG.viz.bandWidthPct; end

LBc = struct('valid', false);
lo = min(Z(:),[],'omitnan'); hi = max(Z(:),[],'omitnan');
if ~(isfinite(lo) && isfinite(hi)) || hi <= lo
    return;   % вироджений розподіл
end
levels0 = linspace(lo, hi, NL0);

% --- рівень-мода: центр найбільш заповненого біна гістограми --------------
v = Z(isfinite(Z));
[cnt, edges] = histcounts(v, max(20, CFG.viz.histBins));
[~, ipk] = max(cnt);
peakLevel = 0.5*(edges(ipk) + edges(ipk+1));

levels  = sort([levels0, peakLevel]);
peakIdx = find(levels == peakLevel, 1);
NL      = numel(levels);

halfW  = 0.5 * pct * (hi - lo);
nTotal = nnz(isfinite(Z));

nPix = zeros(1, NL);
for j = 1:NL
    nPix(j) = nnz(abs(Z - levels(j)) <= halfW);
end

LBc = struct('valid', true, 'lo', lo, 'hi', hi, 'levels', levels, ...
             'peakIdx', peakIdx, 'peakLevel', peakLevel, 'halfW', halfW, ...
             'nTotal', nTotal, 'nPix', nPix, 'pct', 100*nPix/max(nTotal,1), 'NL', NL);
end
