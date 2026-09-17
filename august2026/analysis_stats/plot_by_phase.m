function plot_by_phase(T, CFG)
% PLOT_BY_PHASE  Зріз 3: вплив звуження фазового вікна.
%   Для кожного (statsType × algo): один scatter-рисунок.
%   Кожен subplot = одна метрика.
%   X = значення при ШИРОКОМУ вікні (2π), Y = при ВУЗЬКОМУ (0.75π).
%   Діагональ = немає змін. Точки вище/нижче = збільшення/зменшення.
%   Колір точок = зразок (heart/muscle/brain).
%   Кожна точка = один (зразок × приклад × елемент × компонента).

outDir = fullfile(CFG.outRoot, 'by_phase');
combos = unique(T(:, {'statsType','algo'}), 'rows');

sampleColors = [0.20 0.40 0.80;    % heart
                0.85 0.25 0.20;    % muscle
                0.20 0.70 0.30];   % brain
samples = string(CFG.samples);

for ci = 1:height(combos)
    sType = char(combos.statsType(ci));
    algo  = char(combos.algo(ci));

    Tsub = T(T.statsType == string(sType) & T.algo == string(algo), :);
    if height(Tsub) == 0, continue; end

    metrics = get_metrics(sType);
    nM = numel(metrics);
    pws = sort(unique(Tsub.phaseWidth), 'descend');
    if numel(pws) < 2, continue; end
    pw_wide   = pws(1);
    pw_narrow = pws(end);

    nCols = min(nM, 4);
    nRows = ceil(nM / nCols);
    hf = figure('Visible','off', 'Color', 'w', 'Position', [50 50 300*nCols 280*nRows]);

    for mi = 1:nM
        ax = subplot(nRows, nCols, mi);
        hold(ax, 'on');

        allXY = [];   % для визначення лімітів

        for si = 1:numel(samples)
            Tw = Tsub(Tsub.sample == samples(si) & Tsub.phaseWidth == pw_wide, :);
            Tn = Tsub(Tsub.sample == samples(si) & Tsub.phaseWidth == pw_narrow, :);

            xvals = []; yvals = [];
            for ri = 1:height(Tw)
                % Знайти відповідний рядок у вузькому вікні
                mask = Tn.element   == Tw.element(ri) & ...
                       Tn.component == Tw.component(ri) & ...
                       Tn.example   == Tw.example(ri);
                if ~any(mask), continue; end

                vw = Tw.(metrics{mi})(ri);
                vn = Tn.(metrics{mi})(find(mask, 1));

                if isnan(vw) || isnan(vn), continue; end
                if vw == 0 && vn == 0, continue; end   % нульові елементи

                xvals(end+1) = vw; %#ok<AGROW>
                yvals(end+1) = vn; %#ok<AGROW>
            end

            if ~isempty(xvals)
                sc = min(si, size(sampleColors,1));
                scatter(ax, xvals, yvals, 22, sampleColors(sc,:), ...
                        'filled', 'MarkerFaceAlpha', 0.55);
                allXY = [allXY, xvals, yvals]; %#ok<AGROW>
            end
        end

        % Діагональ (лінія "без змін")
        if ~isempty(allXY)
            mn = min(allXY); mx = max(allXY);
            margin = 0.08 * max(mx - mn, abs(mn)*0.1 + 1e-6);
            lims = [mn - margin, mx + margin];
            plot(ax, lims, lims, 'k--', 'LineWidth', 0.6);
            xlim(ax, lims); ylim(ax, lims);
        end

        hold(ax, 'off');
        xlabel(sprintf('%.2g\\pi (широке)', pw_wide), 'FontSize', 8);
        ylabel(sprintf('%.2g\\pi (вузьке)', pw_narrow), 'FontSize', 8);
        title(metrics{mi}, 'FontSize', 9);
        axis(ax, 'equal');
        grid(ax, 'on'); box(ax, 'on');

        if mi == 1
            legend(ax, CFG.sampleNames, 'Location','best', 'FontSize', 7);
        end
    end

    fig_name = get_fig_for_type(Tsub);
    sgtitle(sprintf('%s (%s) · %s — фазовий ефект', fig_name, sType, algo), ...
            'FontWeight','bold', 'FontSize', 11);

    fname = sprintf('phase_%s_%s_%s', fig_name, sType, algo);
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

function fn = get_fig_for_type(Tsub)
    figs = unique(Tsub.fig);
    fn = char(figs(1));
end
