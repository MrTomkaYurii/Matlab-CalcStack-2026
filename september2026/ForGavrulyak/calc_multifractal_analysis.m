function stats = calc_multifractal_analysis(Z1, Z2, outPrefix)
% CALC_MULTIFRACTAL_ANALYSIS Мультифрактальний аналіз 2D розподілів (WTMM)
%
% ВХІДНІ ПАРАМЕТРИ:
%   Z1        - обов'язковий, 2D матриця дійсних значень (наприклад, азимут, 
%               модуль двоточкового елемента ММ |f_ik|, інтенсивність тощо).
%   Z2        - опційний, 2D матриця дійсних значень (наприклад, еліптичність, 
%               фаза/аргумент arg(f_ik) тощо). Якщо не вказано, береться Z2 = Z1.
%   outPrefix - опційний, текстовий префікс для збереження файлів 
%               (за замовчуванням: 'multifractal').
%
% ВИХІДНІ ДАНІ:
%   stats     - структура з мультифрактальними параметрами: ширина спектра Delta_h,
%               вершина h0, ліве та праве крила Delta_h_L, Delta_h_R, узагальнені
%               розмірності Реньї D0, D1, D2 та статистичні моменти карт.
%
% ЗБЕРЕЖЕНІ ФАЙЛИ (у підпапці results/):
%   results/<outPrefix>_fig.png   - рисунок 4х2 (партиційні функції, tau(q), h(q), f(h))
%   results/<outPrefix>_stats.txt - текстовий файл зі статистичними параметрами
%
% ПРИКЛАД ВИКЛИКУ:
%   stats = calc_multifractal_analysis(azimuth, ellipticity, 'sample_01');

if nargin < 1 || isempty(Z1)
    error('calc_multifractal_analysis:Помилка', ...
        'Необхідно передати хоча б одну 2D матрицю Z1 (наприклад: calc_multifractal_analysis(Z1, Z2)).');
end
if nargin < 2 || isempty(Z2)
    Z2 = Z1;
end
if nargin < 3 || isempty(outPrefix)
    outPrefix = 'multifractal';
end

baseDir = fileparts(mfilename('fullpath'));
if isempty(baseDir), baseDir = pwd; end
saveDir = fullfile(baseDir, 'results');
if ~exist(saveDir, 'dir'), mkdir(saveDir); end

% Розрахунок мультифрактальних спектрів
res1 = compute_mf_core(Z1);
res2 = compute_mf_core(Z2);

% Побудова вертикального рисунка 4х2 (Z1 зліва, Z2 справа)
fig = figure('Name', 'Multifractal Analysis', 'Color', 'w', 'Position', [80, 20, 1100, 1300]);
try, theme(fig, 'light'); catch, end

ink = [0.10 0.10 0.10];
cTau = [0.20 0.40 0.80];
cH   = [0.15 0.55 0.35];
cF   = [0.80 0.20 0.20];

% Ряд 1: Партиційні функції log Z(q,a) vs log(a)
axA = subplot(4, 2, 1);
render_partition_function(axA, res1, ink);
apply_axes_style(axA, 'A', ink);

axB = subplot(4, 2, 2);
render_partition_function(axB, res2, ink);
apply_axes_style(axB, 'B', ink);

% Ряд 2: Масовий показник tau(q)
axC = subplot(4, 2, 3);
plot(axC, res1.q, res1.tau, 'o-', 'Color', cTau, 'MarkerFaceColor', cTau, 'MarkerSize', 4, 'LineWidth', 1.4);
if ~isnan(res1.meanR2)
    text(axC, 0.04, 0.08, sprintf('R^2 = %.3f', res1.meanR2), 'Units', 'normalized', ...
        'FontName', 'Helvetica', 'FontSize', 9.5, 'Color', ink, 'BackgroundColor', 'w', ...
        'EdgeColor', [0.6 0.6 0.6], 'Margin', 3);
end
apply_axes_style(axC, 'C', ink); grid(axC, 'on');

axD = subplot(4, 2, 4);
plot(axD, res2.q, res2.tau, 'o-', 'Color', cTau, 'MarkerFaceColor', cTau, 'MarkerSize', 4, 'LineWidth', 1.4);
if ~isnan(res2.meanR2)
    text(axD, 0.04, 0.08, sprintf('R^2 = %.3f', res2.meanR2), 'Units', 'normalized', ...
        'FontName', 'Helvetica', 'FontSize', 9.5, 'Color', ink, 'BackgroundColor', 'w', ...
        'EdgeColor', [0.6 0.6 0.6], 'Margin', 3);
end
apply_axes_style(axD, 'D', ink); grid(axD, 'on');

% Ряд 3: Показник Гельдера h(q) = d(tau)/dq
axE = subplot(4, 2, 5);
plot(axE, res1.q, res1.h, 'o-', 'Color', cH, 'MarkerFaceColor', cH, 'MarkerSize', 4, 'LineWidth', 1.4);
apply_axes_style(axE, 'E', ink); grid(axE, 'on');

axF = subplot(4, 2, 6);
plot(axF, res2.q, res2.h, 'o-', 'Color', cH, 'MarkerFaceColor', cH, 'MarkerSize', 4, 'LineWidth', 1.4);
apply_axes_style(axF, 'F', ink); grid(axF, 'on');

% Ряд 4: Мультифрактальний спектр сингулярності f(h)
axG = subplot(4, 2, 7);
val1 = isfinite(res1.h) & isfinite(res1.f);
plot(axG, res1.h(val1), res1.f(val1), 'o-', 'Color', cF, 'MarkerFaceColor', cF, 'MarkerSize', 4, 'LineWidth', 1.6);
text(axG, 0.04, 0.92, sprintf('\\Delta h = %.3f', res1.deltaH), 'Units', 'normalized', ...
    'FontName', 'Helvetica', 'FontSize', 10, 'FontWeight', 'bold', 'Color', ink, ...
    'BackgroundColor', 'w', 'EdgeColor', [0.6 0.6 0.6], 'Margin', 3);
apply_axes_style(axG, 'G', ink); grid(axG, 'on');

axH = subplot(4, 2, 8);
val2 = isfinite(res2.h) & isfinite(res2.f);
plot(axH, res2.h(val2), res2.f(val2), 'o-', 'Color', cF, 'MarkerFaceColor', cF, 'MarkerSize', 4, 'LineWidth', 1.6);
text(axH, 0.04, 0.92, sprintf('\\Delta h = %.3f', res2.deltaH), 'Units', 'normalized', ...
    'FontName', 'Helvetica', 'FontSize', 10, 'FontWeight', 'bold', 'Color', ink, ...
    'BackgroundColor', 'w', 'EdgeColor', [0.6 0.6 0.6], 'Margin', 3);
apply_axes_style(axH, 'H', ink); grid(axH, 'on');

% Збереження рисунка
figPath = fullfile(saveDir, [outPrefix '_fig.png']);
try
    exportgraphics(fig, figPath, 'Resolution', 200);
catch
    saveas(fig, figPath);
end

% Розрахунок та збереження статистики
stats = struct();
stats.Z1_map = calc_moments(Z1);
stats.Z1_mf  = res1;
stats.Z2_map = calc_moments(Z2);
stats.Z2_mf  = res2;

txtPath = fullfile(saveDir, [outPrefix '_stats.txt']);
write_stats_file(txtPath, stats);

fprintf('Мультифрактальний аналіз завершено.\n  Рисунок: %s\n  Статистика: %s\n', figPath, txtPath);
end

% =========================================================================
% Допоміжні функції розрахунку
% =========================================================================
function res = compute_mf_core(Z)
    if ~isreal(Z), Z = abs(Z); end
    sig = Z(round(size(Z, 1) / 2), :);
    sig = fillmissing(sig, 'linear');
    sig = fillmissing(sig, 'nearest');

    fb = cwtfilterbank('SignalLength', numel(sig), 'Wavelet', 'amor', 'VoicesPerOctave', 12);
    [wtc, freq, coi] = wt(fb, sig);
    scal0 = scales(fb);
    A0 = abs(wtc);

    coiScale = interp1(freq, scal0, coi, 'linear', 'extrap');
    coiScale = reshape(coiScale, 1, []);
    coiScale = min(max(coiScale, min(scal0)), max(scal0));

    sr = [1 50];
    keep = scal0 >= sr(1) & scal0 <= sr(2);
    scal = scal0(keep);
    A = A0(keep, :);

    nS = numel(scal);
    maxVals = cell(nS, 1);
    for r = 1:nS
        idx = find(islocalmax(A(r, :)) & (scal(r) <= coiScale));
        maxVals{r} = A(r, idx);
    end

    q = -5:0.5:5;
    nQ = numel(q);
    logA = log(scal(:)');
    logZ = nan(nQ, nS);

    for si = 1:nS
        v = maxVals{si};
        v = v(v > 0);
        if isempty(v), continue; end
        v = v / sum(v); % нормована міра на масштабі
        for qi = 1:nQ
            logZ(qi, si) = log(sum(v.^q(qi)));
        end
    end

    tau = nan(1, nQ);
    intercept = nan(1, nQ);
    R2 = nan(1, nQ);
    for qi = 1:nQ
        valid = isfinite(logZ(qi, :));
        if nnz(valid) >= 3
            c = polyfit(logA(valid), logZ(qi, valid), 1);
            yFit = polyval(c, logA(valid));
            ssRes = sum((logZ(qi, valid) - yFit).^2);
            ssTot = sum((logZ(qi, valid) - mean(logZ(qi, valid))).^2);
            R2(qi) = 1 - ssRes / max(ssTot, eps);
            tau(qi) = c(1);
            intercept(qi) = c(2);
        end
    end

    h = gradient(tau, q);
    f = q .* h - tau;

    % Узагальнені розмірності D(q) = tau(q)/(q-1)
    D = nan(size(q));
    for qi = 1:nQ
        if abs(q(qi) - 1) < 1e-6
            D(qi) = h(qi);
        elseif isfinite(tau(qi))
            D(qi) = tau(qi) / (q(qi) - 1);
        end
    end

    [~, i0] = min(abs(q));
    [~, i1] = min(abs(q - 1));
    [~, i2] = min(abs(q - 2));

    val_h = h(isfinite(h) & isfinite(f));
    if ~isempty(val_h)
        hMin = min(val_h);
        hMax = max(val_h);
        deltaH = hMax - hMin;
        h0 = h(i0);
        leftW = h0 - hMin;
        rightW = hMax - h0;
        asym = (rightW - leftW) / max(rightW + leftW, eps);
    else
        deltaH = NaN; h0 = NaN; leftW = NaN; rightW = NaN; asym = NaN;
    end

    r2Fin = R2(isfinite(R2));
    if ~isempty(r2Fin), meanR2 = mean(r2Fin); else, meanR2 = NaN; end

    res.q         = q;
    res.scal      = scal;
    res.logA      = logA;
    res.logZ      = logZ;
    res.tau       = tau;
    res.intercept = intercept;
    res.R2        = R2;
    res.meanR2    = meanR2;
    res.h         = h;
    res.f         = f;
    res.D         = D;
    res.deltaH    = deltaH;
    res.h0        = h0;
    res.D0        = D(i0);
    res.D1        = D(i1);
    res.D2        = D(i2);
    res.leftW     = leftW;
    res.rightW    = rightW;
    res.asym      = asym;
end

function render_partition_function(ax, res, ink)
    qShow = [-4, -2, 0, 2, 4];
    cols = lines(numel(qShow));
    hold(ax, 'on');
    for j = 1:numel(qShow)
        qi = find(abs(res.q - qShow(j)) < 1e-6, 1);
        if isempty(qi), continue; end
        valid = isfinite(res.logZ(qi, :));
        plot(ax, res.logA(valid), res.logZ(qi, valid), 'o', 'Color', cols(j, :), ...
             'MarkerSize', 4, 'DisplayName', sprintf('q = %g', qShow(j)));
        if isfinite(res.tau(qi))
            yFit = res.tau(qi) * res.logA(valid) + res.intercept(qi);
            plot(ax, res.logA(valid), yFit, ':', 'Color', cols(j, :), 'LineWidth', 1.3, 'HandleVisibility', 'off');
        end
    end
    hold(ax, 'off');
    legend(ax, 'Location', 'eastoutside', 'FontSize', 8, 'TextColor', ink, 'Box', 'on');
    grid(ax, 'on');
end

function apply_axes_style(ax, titleLetter, ink)
    set(ax, 'FontName', 'Helvetica', 'FontSize', 11, 'Box', 'on', 'Layer', 'top', ...
            'Color', 'w', 'XColor', ink, 'YColor', ink, 'ZColor', ink, ...
            'GridColor', [0.4 0.4 0.4], 'GridAlpha', 0.25);
    title(ax, titleLetter, 'FontSize', 14, 'FontWeight', 'bold', 'Color', ink);
end

function m = calc_moments(v)
    v = v(isfinite(v));
    mu = mean(v);
    sigma = std(v);
    if sigma > 0
        z = (v - mu) / sigma;
        sk = mean(z.^3);
        ku = mean(z.^4);
    else
        sk = 0; ku = 0;
    end
    m = [mu, sigma, sk, ku];
end

function write_stats_file(filePath, stats)
    fid = fopen(filePath, 'w', 'n', 'UTF-8');
    if fid == -1, return; end
    c = onCleanup(@() fclose(fid));

    fprintf(fid, 'Multifractal Statistics\n\n');
    fprintf(fid, '%-16s %14s %14s %14s %14s\n', 'Quantity', 'Mean_Z1', 'Std_Z2', 'Skew_Z3', 'Kurt_Z4');
    print_row(fid, 'Z1_Map', stats.Z1_map);
    print_row(fid, 'Z2_Map', stats.Z2_map);
    fprintf(fid, '\n');
    fprintf(fid, '%-12s %10s %10s %10s %10s %10s %10s %10s\n', 'Quantity', 'Delta_h', 'h0', 'D0', 'D1', 'D2', 'Delta_h_L', 'Delta_h_R');
    print_mf_row(fid, 'Z1', stats.Z1_mf);
    print_mf_row(fid, 'Z2', stats.Z2_mf);
end

function print_row(fid, name, m)
    fprintf(fid, '%-16s %14.5e %14.5e %14.5e %14.5e\n', name, m(1), m(2), m(3), m(4));
end

function print_mf_row(fid, name, mf)
    fprintf(fid, '%-12s %10.4f %10.4f %10.4f %10.4f %10.4f %10.4f %10.4f\n', ...
        name, mf.deltaH, mf.h0, mf.D0, mf.D1, mf.D2, mf.leftW, mf.rightW);
end
