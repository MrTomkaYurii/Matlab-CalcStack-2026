function S = tp_analytics_build_series(T, metricName)
% TP_ANALYTICS_BUILD_SERIES  Зводить сиру довгу таблицю T в серії
%   "зразок x фазове вікно" для ОДНІЄЇ метрики, по кожному з 16 елементів
%   f_ik — усереднюючи по прикладах/кроках/напрямах (OX+OY разом; коли
%   з'явиться generalized чи більше кроків, увійде в те саме усереднення).
%   Рахує лінійний тренд по фазовому вікну ОКРЕМО на кожен зразок і
%   присвоює позначку ("badge") за двома критеріями:
%     - 'trend'   : медіанний R^2 (по 3 зразках) >= 0.7 (стабільна,
%                   реальна залежність від звуження вікна)
%     - 'discrim' : розкид середніх між зразками помітно більший за
%                   типовий розкид ВСЕРЕДИНІ зразка (реально розрізняє
%                   тканини, а не шум)
%   badge = 'both' | 'trend' | 'discrim' | 'none'
%
%   S.elements   : 1x16 cellstr (f11..f44, природний порядок)
%   S.samples    : 1x3 string
%   S.phaseDeg   : 1x8 double, за спаданням (360 -> 45)
%   S.series.(elem)     : 3x8 double [зразок x фазове вікно], середнє значення
%   S.trendR2.(elem)    : 1x3 double
%   S.trendSlope.(elem) : 1x3 double
%   S.badge.(elem)      : char

if isempty(T)
    S = struct('elements',{{}}, 'samples',string.empty, 'phaseDeg',[], ...
                'series',struct(), 'trendR2',struct(), 'trendSlope',struct(), 'badge',struct());
    return;
end

elements  = cellstr(unique(T.element));
elements  = sort(elements);
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
            % phaseDeg (з unique() на стовпець таблиці) - стовпець; vals -
            % рядок. Без приведення до однієї орієнтації y-yFit нижче
            % мовчки БРОДКАСТИТЬСЯ в NxN матрицю (неявне розширення)
            % замість поелементного віднімання -> хибний вихід.
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

    trendBadge = ~all(isnan(r2s)) && median(r2s,'omitnan') >= 0.7;

    sampleMeans = mean(series, 2, 'omitnan');
    sampleStds  = std(series, 0, 2, 'omitnan');
    withinStd   = mean(sampleStds, 'omitnan');
    rangeAcross = max(sampleMeans) - min(sampleMeans);
    discrimBadge = isfinite(rangeAcross) && isfinite(withinStd) && rangeAcross > 1.5*max(withinStd, eps);

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
