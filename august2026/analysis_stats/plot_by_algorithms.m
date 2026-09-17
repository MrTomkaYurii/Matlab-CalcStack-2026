function plot_by_algorithms(T, CFG)
% PLOT_BY_ALGORITHMS  Зріз 2: порівняння алгоритмів (XY/generalized/OX/OY).
%   Для кожного statsType: один рисунок (усі 4 алгоритми разом).
%   Кожен subplot = одна метрика. X-вісь = елементи,
%   grouped bars = алгоритми × фазові вікна.
%   Бари = mean по ВСІХ зразках × прикладах, error bars = std.

outDir = fullfile(CFG.outRoot, 'by_algorithms');
statsTypes = unique(T.statsType, 'stable');

for si = 1:numel(statsTypes)
    sType = char(statsTypes(si));
    Tsub = T(T.statsType == string(sType), :);
    if height(Tsub) == 0, continue; end

    metrics = get_metrics(sType);
    nM = numel(metrics);

    [elemComps, xLabels] = build_elem_comp_list(Tsub, metrics);
    nEC = numel(xLabels);
    if nEC == 0, continue; end

    algos = unique(Tsub.algo, 'stable');
    nA = numel(algos);
    pws = sort(unique(Tsub.phaseWidth), 'descend');
    nP = numel(pws);
    nGroups = nA * nP;

    % Кольори: алгоритм → базовий колір (lines colormap)
    algoColors = [0.00 0.45 0.74;   % XY          — синій
                  0.85 0.33 0.10;   % generalized — оранжевий
                  0.49 0.18 0.56;   % OX          — фіолетовий
                  0.47 0.67 0.19];  % OY          — зелений
    if nA > size(algoColors, 1)
        algoColors = [algoColors; lines(nA - size(algoColors,1))];
    end

    nCols = min(nM, 4);
    nRows = ceil(nM / nCols);
    figW  = max(600, 140 * nEC);
    figH  = max(320, 260 * nRows);
    hf = figure('Visible','off', 'Color', 'w', 'Position', [50 50 figW figH]);

    for mi = 1:nM
        subplot(nRows, nCols, mi);

        means = nan(nEC, nGroups);
        stds  = nan(nEC, nGroups);

        for k = 1:nEC
            gi = 0;
            for ai = 1:nA
                for pi = 1:nP
                    gi = gi + 1;
                    idx = Tsub.element == string(elemComps{k,1}) & ...
                          Tsub.component == string(elemComps{k,2}) & ...
                          Tsub.algo == algos(ai) & ...
                          Tsub.phaseWidth == pws(pi);
                    vals = Tsub.(metrics{mi})(idx);
                    vals = vals(~isnan(vals));
                    if ~isempty(vals)
                        means(k, gi) = mean(vals);
                        stds(k, gi)  = std(vals);
                    end
                end
            end
        end

        if all(isnan(means(:))), continue; end

        b = bar(means, 'grouped');
        hold on;
        groupWidth = min(0.8, nGroups / (nGroups + 1.5));
        for bi = 1:nGroups
            xb = (1:nEC) - groupWidth/2 + (2*bi-1) * groupWidth / (2*nGroups);
            errorbar(xb, means(:,bi), stds(:,bi), 'k', 'LineStyle','none', ...
                     'LineWidth', 0.6, 'CapSize', 2);
        end
        hold off;

        gi = 0;
        for ai = 1:nA
            for pi = 1:nP
                gi = gi + 1;
                fade = 0.35 * (pi - 1);
                b(gi).FaceColor = algoColors(ai,:) * (1 - fade) + fade * [1 1 1];
            end
        end

        set(gca, 'XTick', 1:nEC, 'XTickLabel', xLabels, 'FontSize', 7);
        xtickangle(35);
        title(metrics{mi}, 'FontSize', 9);
        grid on; box on;

        if mi == 1
            legLabels = {};
            for ai = 1:nA
                for pi = 1:nP
                    legLabels{end+1} = sprintf('%s (%.2g%s)', ...
                        algos(ai), pws(pi), '\pi'); %#ok<AGROW>
                end
            end
            legend(b, legLabels, 'Location','best', 'FontSize', 6);
        end
    end

    fig_name = get_fig_for_type(Tsub);
    sgtitle(sprintf('%s (%s) — по алгоритмах', fig_name, sType), ...
            'FontWeight','bold', 'FontSize', 11);

    fname = sprintf('algos_%s_%s', fig_name, sType);
    util_save_png(hf, outDir, fname, CFG.dpi);
end

end

% ========================================================================
function m = get_metrics(statsType)
    switch char(statsType)
        case {'moments','psd','skeleton','wavelet','wavelet_cuts','mueller'}
            m = {'Z1','Z2','Z3','Z4'};
        case 'acf'
            m = {'Z2','Z4','Lcorr'};
        case 'multifractal'
            m = {'dH','dH_L','dH_R','asym','D0','D1','D2'};
        otherwise
            m = {'Z1','Z2','Z3','Z4'};
    end
end

function [ec, labels] = build_elem_comp_list(Tsub, metrics)
    pairs = unique(Tsub(:, {'element','component'}), 'rows');
    keep = true(height(pairs), 1);
    nM = numel(metrics);
    for k = 1:height(pairs)
        mask = Tsub.element == pairs.element(k) & Tsub.component == pairs.component(k);
        allZ = true;
        for m = 1:nM
            v = Tsub.(metrics{m})(mask);
            if any(v ~= 0 & ~isnan(v)), allZ = false; break; end
        end
        if allZ, keep(k) = false; end
    end
    pairs = pairs(keep, :);
    ec = [cellstr(pairs.element), cellstr(pairs.component)];
    labels = cell(height(pairs), 1);
    for k = 1:height(pairs)
        c = char(pairs.component(k));
        if strcmp(c, '|f|'), c = 'mod'; end
        labels{k} = sprintf('%s %s', pairs.element(k), c);
    end
end

function fn = get_fig_for_type(Tsub)
    figs = unique(Tsub.fig);
    fn = char(figs(1));
end
