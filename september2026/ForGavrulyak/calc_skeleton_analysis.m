function stats = calc_skeleton_analysis(Z1, Z2, outPrefix)
% CALC_SKELETON_ANALYSIS Аналіз вейвлет-скелетонів 2D даних (WTMM максимуми)
%
% ВХІДНІ ПАРАМЕТРИ:
%   Z1        - обов'язковий, 2D матриця дійсних значень (наприклад, азимут, 
%               модуль двоточкового елемента ММ |f_ik|, інтенсивність тощо).
%   Z2        - опційний, 2D матриця дійсних значень (наприклад, еліптичність, 
%               фаза/аргумент arg(f_ik) тощо). Якщо не вказано, береться Z2 = Z1.
%   outPrefix - опційний, текстовий префікс для збереження файлів 
%               (за замовчуванням: 'skeletons').
%
% ВИХІДНІ ДАНІ:
%   stats     - структура зі статистичними моментами (середнє, дисперсія,
%               асиметрія, ексцес) для карт, скалограм та амплітуд максимумів.
%
% ЗБЕРЕЖЕНІ ФАЙЛИ (у підпапці results/):
%   results/<outPrefix>_fig.png   - рисунок компоновки 2х2 (скелетони та гістограми F(h))
%   results/<outPrefix>_stats.txt - текстовий файл зі статистичними моментами
%
% ПРИКЛАД ВИКЛИКУ:
%   stats = calc_skeleton_analysis(azimuth, ellipticity, 'sample_01');

if nargin < 1 || isempty(Z1)
    error('calc_skeleton_analysis:Помилка', ...
        'Необхідно передати хоча б одну 2D матрицю Z1 (наприклад: calc_skeleton_analysis(Z1, Z2)).');
end
if nargin < 2 || isempty(Z2)
    Z2 = Z1;
end
if nargin < 3 || isempty(outPrefix)
    outPrefix = 'skeletons';
end

baseDir = fileparts(mfilename('fullpath'));
if isempty(baseDir), baseDir = pwd; end
saveDir = fullfile(baseDir, 'results');
if ~exist(saveDir, 'dir'), mkdir(saveDir); end

% Розрахунок скелетонів
res1 = compute_skeleton_core(Z1);
res2 = compute_skeleton_core(Z2);

% Побудова рисунка 2х2 (два зверху, два знизу)
fig = figure('Name', 'Wavelet Skeletons', 'Color', 'w', 'Position', [80, 80, 1100, 850]);
try, theme(fig, 'light'); catch, end

ink = [0.10 0.10 0.10];

% Ряд 1: Z1
axA = subplot(2, 2, 1);
if ~isempty(res1.Hpts)
    scatter(axA, res1.Bpts, res1.Apts, 12, res1.Hpts, 'filled');
    set(axA, 'YScale', 'log'); colormap(axA, 'jet');
    cbA = colorbar(axA); cbA.Label.String = '|W| at maxima'; cbA.Color = ink;
end
apply_axes_style(axA, 'A', ink); grid(axA, 'on');
xlim(axA, [1 numel(res1.sig)]);

axB = subplot(2, 2, 2);
if ~isempty(res1.Hpts)
    histogram(axB, res1.Hpts, 30, 'FaceColor', [0.30 0.55 0.35], 'EdgeColor', [0.2 0.2 0.2]);
    text(axB, 0.96, 0.96, sprintf('N_{max} = %d\nmean = %.3g\nstd  = %.3g', numel(res1.Hpts), mean(res1.Hpts), std(res1.Hpts)), ...
        'Units', 'normalized', 'VerticalAlignment', 'top', 'HorizontalAlignment', 'right', ...
        'FontName', 'Helvetica', 'FontSize', 9.5, 'Color', ink, 'BackgroundColor', 'w', ...
        'EdgeColor', [0.6 0.6 0.6], 'Margin', 3);
end
apply_axes_style(axB, 'B', ink); grid(axB, 'on');

% Ряд 2: Z2
axC = subplot(2, 2, 3);
if ~isempty(res2.Hpts)
    scatter(axC, res2.Bpts, res2.Apts, 12, res2.Hpts, 'filled');
    set(axC, 'YScale', 'log'); colormap(axC, 'jet');
    cbC = colorbar(axC); cbC.Label.String = '|W| at maxima'; cbC.Color = ink;
end
apply_axes_style(axC, 'C', ink); grid(axC, 'on');
xlim(axC, [1 numel(res2.sig)]);

axD = subplot(2, 2, 4);
if ~isempty(res2.Hpts)
    histogram(axD, res2.Hpts, 30, 'FaceColor', [0.30 0.55 0.35], 'EdgeColor', [0.2 0.2 0.2]);
    text(axD, 0.96, 0.96, sprintf('N_{max} = %d\nmean = %.3g\nstd  = %.3g', numel(res2.Hpts), mean(res2.Hpts), std(res2.Hpts)), ...
        'Units', 'normalized', 'VerticalAlignment', 'top', 'HorizontalAlignment', 'right', ...
        'FontName', 'Helvetica', 'FontSize', 9.5, 'Color', ink, 'BackgroundColor', 'w', ...
        'EdgeColor', [0.6 0.6 0.6], 'Margin', 3);
end
apply_axes_style(axD, 'D', ink); grid(axD, 'on');

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
stats.Z1_skel = calc_moments(res1.Hpts);
stats.Z1_nMax = numel(res1.Hpts);

stats.Z2_map  = calc_moments(Z2);
stats.Z2_cwt  = calc_moments(res2.A);
stats.Z2_skel = calc_moments(res2.Hpts);
stats.Z2_nMax = numel(res2.Hpts);

txtPath = fullfile(saveDir, [outPrefix '_stats.txt']);
write_stats_file(txtPath, stats);

fprintf('Аналіз скелетонів завершено.\n  Рисунок: %s\n  Статистика: %s\n', figPath, txtPath);
end

% =========================================================================
% Допоміжні функції розрахунку
% =========================================================================
function res = compute_skeleton_core(Z)
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

    b = 1:numel(sig);
    Bpts = []; Apts = []; Hpts = [];
    for r = 1:size(A, 1)
        idx = find(islocalmax(A(r, :)) & (scal(r) <= coiScale));
        Bpts = [Bpts, b(idx)];
        Apts = [Apts, repmat(scal(r), 1, numel(idx))];
        Hpts = [Hpts, A(r, idx)];
    end

    res.sig  = sig;
    res.scal = scal;
    res.A    = A;
    res.coiScale = coiScale;
    res.Bpts = Bpts;
    res.Apts = Apts;
    res.Hpts = Hpts;
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

    fprintf(fid, 'Skeleton Statistics\n\n');
    fprintf(fid, '%-24s %14s %14s %14s %14s\n', 'Quantity', 'Mean_Z1', 'Std_Z2', 'Skew_Z3', 'Kurt_Z4');
    print_row(fid, 'Z1_Map', stats.Z1_map);
    print_row(fid, 'Z1_Scalogram', stats.Z1_cwt);
    print_row(fid, sprintf('Z1_Maxima_N=%d', stats.Z1_nMax), stats.Z1_skel);
    print_row(fid, 'Z2_Map', stats.Z2_map);
    print_row(fid, 'Z2_Scalogram', stats.Z2_cwt);
    print_row(fid, sprintf('Z2_Maxima_N=%d', stats.Z2_nMax), stats.Z2_skel);
end

function print_row(fid, name, m)
    fprintf(fid, '%-24s %14.5e %14.5e %14.5e %14.5e\n', name, m(1), m(2), m(3), m(4));
end
