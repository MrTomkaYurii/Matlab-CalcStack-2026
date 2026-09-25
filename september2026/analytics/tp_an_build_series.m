function S = tp_an_build_series(T, metricName, elementOrder, trendR2, discrimRatio)
% TP_AN_BUILD_SERIES  Зводить довгу таблицю T в серії "зразок x фазове вікно" для
%   ОДНІЄЇ метрики по кожній величині Кроку B, усереднюючи по прикладах/кроках/
%   напрямах (OX і OY разом). ПОРТ серпневого tp_analytics_build_series.m; логіка
%   позначок та сама (пороги тепер у CFG.analytics):
%     - 'trend'   : медіанний R^2 лінійного тренду по вікну (по зразках) >= trendR2
%     - 'discrim' : розкид середніх між зразками > discrimRatio × типовий розкид
%                   усередині зразка (по вікнах)
%   badge = 'both' | 'trend' | 'discrim' | 'none'
%   Відмінності від серпня: 5 величин Кроку B у заданому порядку elementOrder
%   (а не 16 f_ik за абеткою); пороги -- параметри; довільна кількість зразків.
%
%   S.elements : cellstr (у порядку elementOrder, лише наявні в T)
%   S.samples  : string-вектор зразків
%   S.phaseDeg : кути вікон за спаданням (360 -> 45)
%   S.series.(elem)     : [зразок x вікно], середнє значення
%   S.trendR2.(elem), S.trendSlope.(elem) : 1 x nЗразків
%   S.badge.(elem)      : char

if nargin < 3 || isempty(elementOrder), elementOrder = cellstr(unique(T.element)); end
if nargin < 4, trendR2 = 0.7; end
if nargin < 5, discrimRatio = 1.5; end

if isempty(T)
    S = struct('elements',{{}}, 'samples',string.empty, 'phaseDeg',[], ...
                'series',struct(), 'trendR2',struct(), 'trendSlope',struct(), 'badge',struct());
    return;
end

present   = cellstr(unique(T.element));
elements  = elementOrder(ismember(elementOrder, present));
samples   = unique(T.sample);
phaseDeg  = sort(unique(T.phase_deg), 'descend');
phaseDeg  = phaseDeg(isfinite(phaseDeg));

S = struct();
S.elements = elements;
S.samples  = samples;
S.phaseDeg = phaseDeg;
S.series     = struct();
S.trendR2    = struct();
S.trendSlope = struct();
S.badge      = struct();

for ei = 1:numel(elements)
    elem = elements{ei};
    series = nan(numel(samples), numel(phaseDeg));
    r2s    = nan(1, numel(samples));
    slopes = nan(1, numel(samples));

    for si = 1:numel(samples)
        rowsMask = (T.element == elem) & (T.sample == samples(si));
        sub = T(rowsMask, :);
        vals = nan(1, numel(phaseDeg));
        for pi_ = 1:numel(phaseDeg)
            v = sub.(metricName)(sub.phase_deg == phaseDeg(pi_));
            v = v(isfinite(v));
            if ~isempty(v), vals(pi_) = mean(v); end
        end
        series(si,:) = vals;

        valid = isfinite(vals);
        if nnz(valid) >= 3
            % рядок/стовпець приводимо до одної орієнтації -- інакше y-yFit
            % мовчки броадкастилось би в NxN (як і в серпневому оригіналі)
            xv = phaseDeg(valid); yv = vals(valid);
            x = xv(:).'; y = yv(:).';
            c = polyfit(x, y, 1);
            yFit = polyval(c, x);
            ssRes = sum((y-yFit).^2); ssTot = sum((y-mean(y)).^2);
            r2s(si) = 1 - ssRes/max(ssTot, eps);
            slopes(si) = c(1);
        end
    end

    S.series.(elem)     = series;
    S.trendR2.(elem)    = r2s;
    S.trendSlope.(elem) = slopes;

    trendBadge = ~all(isnan(r2s)) && median(r2s,'omitnan') >= trendR2;

    sampleMeans = mean(series, 2, 'omitnan');
    sampleStds  = std(series, 0, 2, 'omitnan');
    withinStd   = mean(sampleStds, 'omitnan');
    rangeAcross = max(sampleMeans) - min(sampleMeans);
    discrimBadge = isfinite(rangeAcross) && isfinite(withinStd) && rangeAcross > discrimRatio*max(withinStd, eps);

    if trendBadge && discrimBadge
        S.badge.(elem) = 'both';
    elseif trendBadge
        S.badge.(elem) = 'trend';
    elseif discrimBadge
        S.badge.(elem) = 'discrim';
    else
        S.badge.(elem) = 'none';
    end
end
end
