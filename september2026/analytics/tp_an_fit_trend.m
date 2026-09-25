function TT = tp_an_fit_trend(T, groupVars, xVar, metricVars)
% TP_ANALYTICS_FIT_TREND  Загальна функція: для кожної комбінації groupVars
%   підганяє ЛІНІЙНИЙ тренд metric ~ xVar (по кожній колонці metricVars
%   окремо), повертає ДОВГУ таблицю зі slope/r2/monotonic/n.
%
%   Використовується і для тренду по фазових вікнах (xVar='phase_deg',
%   groupVars без 'phase_deg'/'phase_index'), і для тренду по кроках
%   (xVar='step', groupVars без 'step') — та сама логіка, інша вісь.
%
%   TT = tp_an_fit_trend(T, groupVars, xVar, metricVars)
%       T.(metric).slope    — нахил лінійної апроксимації
%       T.(metric).r2       — коефіцієнт детермінації (наскільки лінійно)
%       T.(metric).monotonic— чи монотонна крива (за трендом, не лише R^2)
%       T.(metric).n        — скільки точок (після NaN-фільтра) увійшло

if isempty(T)
    TT = table(); return;
end

[G, keys] = findgroups(T(:, groupVars));
nG = max(G);
rowsCell = cell(nG * numel(metricVars), 1);
idx_out = 0;

for gi = 1:nG
    idx = (G == gi);
    sub = T(idx, :);
    x = sub.(xVar);
    [xs, order] = sort(x);

    for m = 1:numel(metricVars)
        yAll = sub.(metricVars{m});
        y = yAll(order);
        valid = isfinite(xs) & isfinite(y);
        n = nnz(valid);

        if n < 3
            slope = NaN; r2 = NaN; mono = false;
        else
            xv = xs(valid); yv = y(valid);
            c = polyfit(xv, yv, 1);
            yFit = polyval(c, xv);
            ssRes = sum((yv - yFit).^2);
            ssTot = sum((yv - mean(yv)).^2);
            r2 = 1 - ssRes / max(ssTot, eps);
            slope = c(1);
            dv = diff(yv);
            mono = all(dv >= -1e-9) || all(dv <= 1e-9);
        end

        row = keys(gi, :);
        row.metric    = string(metricVars{m});
        row.slope     = slope;
        row.r2        = r2;
        row.monotonic = mono;
        row.n         = n;

        idx_out = idx_out + 1;
        rowsCell{idx_out} = row;
    end
end

TT = vertcat(rowsCell{1:idx_out});
end
