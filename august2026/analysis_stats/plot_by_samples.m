function plot_by_samples(T, CFG)
% PLOT_BY_SAMPLES  Зріз 1: порівняння статистичних моментів між зразками.
%   Для кожного (statsType × algo): один рисунок.
%   Кожен subplot = одна метрика. X-вісь = елементи (f33|f|, f33 arg, ...),
%   grouped bars = зразки (heart/muscle/brain), 2 бари на зразок (2 фаз. вікна).
%   Error bars = std по 3 прикладах (zrazok1/2/3).

outDir = fullfile(CFG.outRoot, 'by_samples');
combos = unique(T(:, {'statsType','algo'}), 'rows');

for ci = 1:height(combos)
    sType = char(combos.statsType(ci));
    algo  = char(combos.algo(ci));

    Tsub = T(T.statsType == string(sType) & T.algo == string(algo), :);
    if height(Tsub) == 0, continue; end

    metrics = get_metrics(sType);
    nM = numel(metrics);

    % ── Елемент×компонента (без нульових, напр. f31 у Mueller) ──────────
    [elemComps, xLabels] = build_elem_comp_list(Tsub, metrics);
    nEC = numel(xLabels);
    if nEC == 0, continue; end

    % ── Зразки та фазові вікна ─────────────────────────────────────────
    samples = string(CFG.samples);
    nS = numel(samples);
    pws = sort(unique(Tsub.phaseWidth), 'descend');   % широке першим
    nP = numel(pws);
    nGroups = nS * nP;   % стовпчиків на кожну x-категорію

    % ── Кольори: зразок → базовий колір, фаза → відтінок ──────────────
    baseColors = [0.20 0.40 0.80;    % heart  — синій
                  0.85 0.25 0.20;    % muscle — червоний
                  0.20 0.70 0.30];   % brain  — зелений
    if nS > size(baseColors,1)
        baseColors = [baseColors; lines(nS - size(baseColors,1))];
    end

    % ── Фігура ─────────────────────────────────────────────────────────
    nCols = min(nM, 4);
    nRows = ceil(nM / nCols);
    figW  = max(600, 140 * nEC);
    figH  = max(320, 260 * nRows);
    hf = figure('Visible','off', 'Color', 'w', 'Position', [50 50 figW figH]);

    for mi = 1:nM
        ax = subplot(nRows, nCols, mi); %#ok<NASGU>

        % Матриця means/stds: nEC × nGroups
        means = nan(nEC, nGroups);
        stds  = nan(nEC, nGroups);

        for k = 1:nEC
            gi = 0;
            for si = 1:nS
                for pi = 1:nP
                    gi = gi + 1;
                    idx = Tsub.element == elemComps{k,1} & ...
                          Tsub.component == elemComps{k,2} & ...
                          Tsub.sample == samples(si) & ...
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

        % Grouped bar
        b = bar(means, 'grouped');
        hold on;

        % Error bars
        groupWidth = min(0.8, nGroups / (nGroups + 1.5));
        for bi = 1:nGroups
            xb = (1:nEC) - groupWidth/2 + (2*bi - 1) * groupWidth / (2*nGroups);
            errorbar(xb, means(:,bi), stds(:,bi), 'k', 'LineStyle','none', ...
                     'LineWidth', 0.6, 'CapSize', 3);
        end
        hold off;

        % Кольори стовпчиків
        gi = 0;
        for si = 1:nS
            for pi = 1:nP
                gi = gi + 1;
                fade = 0.35 * (pi - 1);   % вужче вікно → блідіший
                b(gi).FaceColor = baseColors(si,:) * (1 - fade) + fade * [1 1 1];
            end
        end

        set(gca, 'XTick', 1:nEC, 'XTickLabel', xLabels, 'FontSize', 7);
        xtickangle(35);
        title(metrics{mi}, 'FontSize', 9);
        grid on; box on;

        if mi == 1
            legLabels = {};
            for si = 1:nS
                for pi = 1:nP
                    legLabels{end+1} = sprintf('%s (%.2g%s)', ...
                        CFG.sampleNames{si}, pws(pi), '\pi'); %#ok<AGROW>
                end
            end
            legend(b, legLabels, 'Location','best', 'FontSize', 6);
        end
    end

    fig_name = get_fig_for_type(Tsub);
    sgtitle(sprintf('%s (%s) · %s — по зразках', fig_name, sType, algo), ...
            'FontWeight','bold', 'FontSize', 11);

    fname = sprintf('samples_%s_%s_%s', fig_name, sType, algo);
    util_save_png(hf, outDir, fname, CFG.dpi);
end

end

% ========================================================================
%  Допоміжні локальні функції
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
% Повертає список унікальних (element, component) без цілком нульових.
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
