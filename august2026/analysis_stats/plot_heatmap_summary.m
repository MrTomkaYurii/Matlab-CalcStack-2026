function plot_heatmap_summary(T, CFG)
% PLOT_HEATMAP_SUMMARY  Зведений числовий Heatmap-Dashboard.
%   Для кожного (statsType × algo) будує окремий багатопанельний рисунок:
%   Кожен subplot = одна метрика (Z1, Z2, Z3, Z4 або dH..D2).
%   Рядки = Елементи (напр. f33 |f|, f33 arg, ...).
%   Стовпці = 6 станів (Heart 2π, Heart 0.75π | Muscle 2π, Muscle 0.75π | Brain 2π, Brain 0.75π).
%   Всередині кожної клітинки надруковано точне число (усереднене по 3 зразках).
%   Чіткий білий фон, контрастний colormap.

outDir = fullfile(CFG.outRoot, 'heatmaps');
combos = unique(T(:, {'statsType','algo'}), 'rows');

sampleTags = {'heart', 'muscle', 'brain'};
sampleNames = {'Heart', 'Muscle', 'Brain'};
pws = [2.0, 0.75];   % широке і звужене

% 6 колонок
colLabels = {};
for s = 1:numel(sampleNames)
    for p = 1:numel(pws)
        colLabels{end+1} = sprintf('%s (%.2g\\pi)', sampleNames{s}, pws(p)); %#ok<AGROW>
    end
end
nColsState = numel(colLabels);

for ci = 1:height(combos)
    sType = char(combos.statsType(ci));
    algo  = char(combos.algo(ci));

    Tsub = T(T.statsType == string(sType) & T.algo == string(algo), :);
    if height(Tsub) == 0, continue; end

    metrics = get_metrics(sType);
    nM = numel(metrics);

    [elemComps, rowLabels] = build_elem_comp_list(Tsub, metrics);
    nR = numel(rowLabels);
    if nR == 0, continue; end

    % Розміщення сабплотів (наприклад 2x2 для Z1..Z4 або 2x4 для multifractal)
    subCols = min(nM, 2);
    if nM > 4, subCols = 3; end
    subRows = ceil(nM / subCols);

    cellW = 65; cellH = 26;
    figW = max(700, subCols * (cellW * nColsState + 160));
    figH = max(450, subRows * (cellH * nR + 110));
    hf = figure('Visible','off', 'Color','w', 'Position', [40 40 figW figH]);

    for mi = 1:nM
        % Збираємо матрицю: nR × nColsState
        mat = nan(nR, nColsState);
        for r = 1:nR
            colIdx = 0;
            for s = 1:numel(sampleTags)
                for p = 1:numel(pws)
                    colIdx = colIdx + 1;
                    mask = Tsub.element == string(elemComps{r,1}) & ...
                           Tsub.component == string(elemComps{r,2}) & ...
                           Tsub.sample == string(sampleTags{s}) & ...
                           abs(Tsub.phaseWidth - pws(p)) < 0.05;
                    vals = Tsub.(metrics{mi})(mask);
                    vals = vals(~isnan(vals));
                    if ~isempty(vals)
                        mat(r, colIdx) = mean(vals);
                    end
                end
            end
        end

        ax = subplot(subRows, subCols, mi);
        set(ax, 'Color', 'w');

        % Якщо є валідні дані
        if all(isnan(mat(:)))
            continue;
        end

        % Малюємо heatmap через imagesc
        im = imagesc(ax, mat);
        set(ax, 'Color', 'w');
        colormap(ax, parula);
        cb = colorbar(ax);
        cb.FontSize = 7;

        % Підписи осей
        set(ax, 'XTick', 1:nColsState, 'XTickLabel', colLabels, 'FontSize', 7.5);
        xtickangle(ax, 30);
        set(ax, 'YTick', 1:nR, 'YTickLabel', rowLabels, 'FontSize', 7.5);

        title(ax, sprintf('%s', metrics{mi}), 'FontSize', 10, 'FontWeight', 'bold');

        % Виводимо числові значення прямо в клітинках
        clims = [min(mat(~isnan(mat))), max(mat(~isnan(mat)))];
        midVal = mean(clims);
        for r = 1:nR
            for c = 1:nColsState
                val = mat(r, c);
                if ~isnan(val)
                    % Форматування тексту
                    if abs(val) >= 100
                        txt = sprintf('%.0f', val);
                    elseif abs(val) >= 10
                        txt = sprintf('%.1f', val);
                    elseif abs(val) >= 1
                        txt = sprintf('%.2f', val);
                    elseif abs(val) > 0.001
                        txt = sprintf('%.3f', val);
                    elseif val == 0
                        txt = '0';
                    else
                        txt = sprintf('%.1e', val);
                    end

                    % Колір тексту для контрасту з клітинкою
                    if val > midVal
                        tColor = 'k';
                        if clims(2) - clims(1) > 0 && (val - clims(1))/(clims(2)-clims(1)) > 0.85
                            tColor = [0.1 0.1 0.1];
                        end
                    else
                        tColor = 'w';
                    end

                    text(ax, c, r, txt, 'HorizontalAlignment', 'center', ...
                         'VerticalAlignment', 'middle', 'FontSize', 6.5, ...
                         'FontWeight', 'bold', 'Color', tColor);
                end
            end
        end
        grid(ax, 'off');
    end

    fig_name = get_fig_for_type(Tsub);
    sgtitle(sprintf('%s (%s) · %s — Теплова карта моментів (середні по 3 зразках)', ...
            fig_name, sType, algo), 'FontWeight', 'bold', 'FontSize', 11);

    fname = sprintf('heatmap_%s_%s_%s', fig_name, sType, algo);
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
