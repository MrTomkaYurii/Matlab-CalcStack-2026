function stats = calc_wavelet_analysis(Z1, Z2, outPrefix)
% CALC_WAVELET_ANALYSIS Вейвлет-аналіз 2D розподілів (CWT, скалограма, перерізи)
%
% ВХІДНІ ПАРАМЕТРИ:
%   Z1        - обов'язковий, 2D матриця дійсних значень (наприклад, азимут, 
%               модуль двоточкового елемента ММ |f_ik|, інтенсивність тощо).
%   Z2        - опційний, 2D матриця дійсних значень (наприклад, еліптичність, 
%               фаза/аргумент arg(f_ik) тощо). Якщо не вказано, береться Z2 = Z1.
%   outPrefix - опційний, текстовий префікс для збереження файлів 
%               (за замовчуванням: 'wavelets').
%
% ВИХІДНІ ДАНІ:
%   stats     - структура зі статистичними моментами (середнє, дисперсія,
%               асиметрія, ексцес) для карт, скалограм і перерізів.
%
% ЗБЕРЕЖЕНІ ФАЙЛИ (у підпапці results/):
%   results/<outPrefix>_fig.png   - рисунок компоновки 2х2 (скалограми та перерізи)
%   results/<outPrefix>_stats.txt - текстовий файл зі статистичними моментами
%
% ПРИКЛАД ВИКЛИКУ:
%   stats = calc_wavelet_analysis(azimuth, ellipticity, 'sample_01');

if nargin < 1 || isempty(Z1)
    error('calc_wavelet_analysis:Помилка', ...
        'Необхідно передати хоча б одну 2D матрицю Z1 (наприклад: calc_wavelet_analysis(Z1, Z2)).');
end
if nargin < 2 || isempty(Z2)
    Z2 = Z1;
end
if nargin < 3 || isempty(outPrefix)
    outPrefix = 'wavelets';
end

baseDir = fileparts(mfilename('fullpath'));
if isempty(baseDir), baseDir = pwd; end
saveDir = fullfile(baseDir, 'results');
if ~exist(saveDir, 'dir'), mkdir(saveDir); end

% Розрахунок CWT для обох розподілів
res1 = compute_wavelet_core(Z1);
res2 = compute_wavelet_core(Z2);

% Побудова рисунка 2х2 (два зверху, два знизу)
fig = figure('Name', 'Wavelet Analysis', 'Color', 'w', 'Position', [80, 80, 1100, 850]);
try, theme(fig, 'light'); catch, end

ink = [0.10 0.10 0.10];
cRed = [0.85 0.10 0.10];
cBlue = [0.10 0.30 0.85];

% Ряд 1: Z1
axA = subplot(2, 2, 1);
imagesc(axA, 1:numel(res1.sig), res1.scal, res1.Adisp);
set(axA, 'YDir', 'normal'); colormap(axA, 'jet');
cbA = colorbar(axA); cbA.Label.String = '|W(a,b)|'; cbA.Color = ink;
hold(axA, 'on');
plot(axA, 1:numel(res1.sig), res1.coiScale, '--', 'Color', [0.95 0.95 0.95], 'LineWidth', 1.5);
plot(axA, 1:numel(res1.sig), res1.coiScale, ':', 'Color', ink, 'LineWidth', 1.0);
yline(axA, res1.scale_val1, '-', 'Color', 'w', 'LineWidth', 1.2);
yline(axA, res1.scale_val2, '-', 'Color', 'w', 'LineWidth', 1.2);
hold(axA, 'off');
apply_axes_style(axA, 'A', ink);

axB = subplot(2, 2, 2);
plot(axB, res1.cut1, 'Color', cRed, 'LineWidth', 1.6, 'DisplayName', sprintf('a = %.2f', res1.scale_val1)); hold(axB, 'on');
plot(axB, res1.cut2, 'Color', cBlue, 'LineWidth', 1.6, 'DisplayName', sprintf('a = %.2f', res1.scale_val2)); hold(axB, 'off');
legend(axB, 'Location', 'northeast', 'TextColor', ink, 'Box', 'on');
apply_axes_style(axB, 'B', ink); grid(axB, 'on');
xlim(axB, [1 numel(res1.sig)]);

% Ряд 2: Z2
axC = subplot(2, 2, 3);
imagesc(axC, 1:numel(res2.sig), res2.scal, res2.Adisp);
set(axC, 'YDir', 'normal'); colormap(axC, 'jet');
cbC = colorbar(axC); cbC.Label.String = '|W(a,b)|'; cbC.Color = ink;
hold(axC, 'on');
plot(axC, 1:numel(res2.sig), res2.coiScale, '--', 'Color', [0.95 0.95 0.95], 'LineWidth', 1.5);
plot(axC, 1:numel(res2.sig), res2.coiScale, ':', 'Color', ink, 'LineWidth', 1.0);
yline(axC, res2.scale_val1, '-', 'Color', 'w', 'LineWidth', 1.2);
yline(axC, res2.scale_val2, '-', 'Color', 'w', 'LineWidth', 1.2);
hold(axC, 'off');
apply_axes_style(axC, 'C', ink);

axD = subplot(2, 2, 4);
plot(axD, res2.cut1, 'Color', cRed, 'LineWidth', 1.6, 'DisplayName', sprintf('a = %.2f', res2.scale_val1)); hold(axD, 'on');
plot(axD, res2.cut2, 'Color', cBlue, 'LineWidth', 1.6, 'DisplayName', sprintf('a = %.2f', res2.scale_val2)); hold(axD, 'off');
legend(axD, 'Location', 'northeast', 'TextColor', ink, 'Box', 'on');
apply_axes_style(axD, 'D', ink); grid(axD, 'on');
xlim(axD, [1 numel(res2.sig)]);

% Збереження рисунка
figPath = fullfile(saveDir, [outPrefix '_fig.png']);
try
    exportgraphics(fig, figPath, 'Resolution', 200);
catch
    saveas(fig, figPath);
end

% Розрахунок та збереження статистики
stats = struct();
stats.Z1_map  = calc_moments(Z1);
stats.Z1_cwt  = calc_moments(res1.A);
stats.Z1_cut1 = calc_moments(res1.cut1);
stats.Z1_cut2 = calc_moments(res1.cut2);

stats.Z2_map  = calc_moments(Z2);
stats.Z2_cwt  = calc_moments(res2.A);
stats.Z2_cut1 = calc_moments(res2.cut1);
stats.Z2_cut2 = calc_moments(res2.cut2);

txtPath = fullfile(saveDir, [outPrefix '_stats.txt']);
write_stats_file(txtPath, stats, res1, res2);

fprintf('Вейвлет-аналіз завершено.\n  Рисунок: %s\n  Статистика: %s\n', figPath, txtPath);
end

% =========================================================================
% Допоміжні функції розрахунку
% =========================================================================
function res = compute_wavelet_core(Z)
    if ~isreal(Z), Z = abs(Z); end
    sig = Z(round(size(Z, 1) / 2), :);
    sig = fillmissing(sig, 'linear');
    sig = fillmissing(sig, 'nearest');

    fb = cwtfilterbank('SignalLength', numel(sig), 'Wavelet', 'amor', 'VoicesPerOctave', 12);
    [wtc, freq, coi] = wt(fb, sig);
    scal0 = scales(fb);
    A0 = abs(wtc);

    % Конус впливу (COI) в одиницях масштабу
    coiScale = interp1(freq, scal0, coi, 'linear', 'extrap');
    coiScale = reshape(coiScale, 1, []);
    coiScale = min(max(coiScale, min(scal0)), max(scal0));

    % Обмеження діапазону масштабів [1 50]
    sr = [1 50];
    keep = scal0 >= sr(1) & scal0 <= sr(2);
    scal = scal0(keep);
    A = A0(keep, :);

    % Розмиття області поза конусом впливу
    reliable = bsxfun(@le, scal(:), coiScale(:)');
    sigmaPx = 2;
    ksz = 2*ceil(2*sigmaPx) + 1; kx = -floor(ksz/2):floor(ksz/2);
    g = exp(-(kx.^2) / (2*sigmaPx^2)); g = g / sum(g);
    Ablur = conv2(conv2(A, g, 'same'), g', 'same');
    Adisp = A;
    Adisp(~reliable) = Ablur(~reliable);

    % Перерізи на фіксованих масштабах (a ≈ 3 та a ≈ 25)
    [~, i1] = min(abs(scal - 3));
    [~, i2] = min(abs(scal - 25));

    res.sig = sig;
    res.scal = scal;
    res.A = A;
    res.Adisp = Adisp;
    res.coiScale = coiScale;
    res.scale_val1 = scal(i1);
    res.scale_val2 = scal(i2);
    res.cut1 = A(i1, :);
    res.cut2 = A(i2, :);
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

function write_stats_file(filePath, stats, r1, r2)
    fid = fopen(filePath, 'w', 'n', 'UTF-8');
    if fid == -1, return; end
    c = onCleanup(@() fclose(fid));

    fprintf(fid, 'Wavelet Statistics\n\n');
    fprintf(fid, '%-24s %14s %14s %14s %14s\n', 'Quantity', 'Mean_Z1', 'Std_Z2', 'Skew_Z3', 'Kurt_Z4');
    print_row(fid, 'Z1_Map', stats.Z1_map);
    print_row(fid, 'Z1_Scalogram', stats.Z1_cwt);
    print_row(fid, sprintf('Z1_Cut_a=%.2f', r1.scale_val1), stats.Z1_cut1);
    print_row(fid, sprintf('Z1_Cut_a=%.2f', r1.scale_val2), stats.Z1_cut2);
    print_row(fid, 'Z2_Map', stats.Z2_map);
    print_row(fid, 'Z2_Scalogram', stats.Z2_cwt);
    print_row(fid, sprintf('Z2_Cut_a=%.2f', r2.scale_val1), stats.Z2_cut1);
    print_row(fid, sprintf('Z2_Cut_a=%.2f', r2.scale_val2), stats.Z2_cut2);
end

function print_row(fid, name, m)
    fprintf(fid, '%-24s %14.5e %14.5e %14.5e %14.5e\n', name, m(1), m(2), m(3), m(4));
end
