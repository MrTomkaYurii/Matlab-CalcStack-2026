function stats = calc_acf_psd_analysis(Z1, Z2, outPrefix)
% CALC_ACF_PSD_ANALYSIS 2D АКФ та спектри потужності (PSD) для 2D розподілів
%
% ВХІДНІ ПАРАМЕТРИ:
%   Z1        - обов'язковий, 2D матриця дійсних значень (наприклад, азимут, 
%               модуль двоточкового елемента ММ |f_ik|, інтенсивність тощо).
%   Z2        - опційний, 2D матриця дійсних значень (наприклад, еліптичність, 
%               фаза/аргумент arg(f_ik) тощо). Якщо не вказано, береться Z2 = Z1.
%   outPrefix - опційний, текстовий префікс для збереження файлів 
%               (за замовчуванням: 'acf_psd').
%
% ВИХІДНІ ДАНІ:
%   stats     - структура зі статистичними моментами (середнє, дисперсія,
%               асиметрія, ексцес) для карт, околу піка АКФ, log10(PSD), а також
%               довжини кореляції Lx, Ly (HWHM на рівні 0.5) у пікселях.
%
% ЗБЕРЕЖЕНІ ФАЙЛИ (у підпапці results/):
%   results/<outPrefix>_2d_fig.png          - рисунок 2х2: 2D АКФ та 2D PSD (дБ)
%   results/<outPrefix>_cuts_loglog_fig.png - рисунок 2х2: 1D перерізи АКФ та 
%                                             1D спектри потужності у LOG-LOG
%   results/<outPrefix>_stats.txt           - текстовий файл зі статистичними моментами
%
% ПРИКЛАД ВИКЛИКУ:
%   stats = calc_acf_psd_analysis(azimuth, ellipticity, 'sample_01');

if nargin < 1 || isempty(Z1)
    error('calc_acf_psd_analysis:Помилка', ...
        'Необхідно передати хоча б одну 2D матрицю Z1 (наприклад: calc_acf_psd_analysis(Z1, Z2)).');
end
if nargin < 2 || isempty(Z2)
    Z2 = Z1;
end
if nargin < 3 || isempty(outPrefix)
    outPrefix = 'acf_psd';
end

baseDir = fileparts(mfilename('fullpath'));
if isempty(baseDir), baseDir = pwd; end
saveDir = fullfile(baseDir, 'results');
if ~exist(saveDir, 'dir'), mkdir(saveDir); end

% Розрахунок АКФ та PSD
res1 = compute_acf_psd_core(Z1);
res2 = compute_acf_psd_core(Z2);

ink = [0.10 0.10 0.10];
cRed = [0.85 0.10 0.10];
cBlue = [0.10 0.30 0.85];

% =========================================================================
% РИСУНОК 1: 2D АКФ + 2D PSD (2х2, два зверху, два знизу)
% =========================================================================
fig1 = figure('Name', '2D ACF and PSD', 'Color', 'w', 'Position', [80, 80, 1100, 850]);
try, theme(fig1, 'light'); catch, end

% Ряд 1: Z1
axA1 = subplot(2, 2, 1);
imagesc(axA1, res1.lagx, res1.lagy, res1.acf); axis(axA1, 'image');
colormap(axA1, 'jet'); caxis(axA1, [0 1]);
cbA1 = colorbar(axA1); cbA1.Label.String = 'ACF [0..1]'; cbA1.Color = ink;
apply_axes_style(axA1, 'A', ink);

axB1 = subplot(2, 2, 2);
imagesc(axB1, res1.dbMap); axis(axB1, 'image');
colormap(axB1, 'jet');
if isfinite(res1.loClip) && isfinite(res1.hiClip) && res1.loClip < res1.hiClip
    caxis(axB1, [res1.loClip res1.hiClip]);
end
cbB1 = colorbar(axB1); cbB1.Label.String = 'PSD (dB)'; cbB1.Color = ink;
apply_axes_style(axB1, 'B', ink);

% Ряд 2: Z2
axC1 = subplot(2, 2, 3);
imagesc(axC1, res2.lagx, res2.lagy, res2.acf); axis(axC1, 'image');
colormap(axC1, 'jet'); caxis(axC1, [0 1]);
cbC1 = colorbar(axC1); cbC1.Label.String = 'ACF [0..1]'; cbC1.Color = ink;
apply_axes_style(axC1, 'C', ink);

axD1 = subplot(2, 2, 4);
imagesc(axD1, res2.dbMap); axis(axD1, 'image');
colormap(axD1, 'jet');
if isfinite(res2.loClip) && isfinite(res2.hiClip) && res2.loClip < res2.hiClip
    caxis(axD1, [res2.loClip res2.hiClip]);
end
cbD1 = colorbar(axD1); cbD1.Label.String = 'PSD (dB)'; cbD1.Color = ink;
apply_axes_style(axD1, 'D', ink);

fig1Path = fullfile(saveDir, [outPrefix '_2d_fig.png']);
save_figure_png(fig1, fig1Path);

% =========================================================================
% РИСУНОК 2: 1D перерізи АКФ + 1D спектри в LOG-LOG (2х2)
% =========================================================================
fig2 = figure('Name', 'ACF Cuts and Log-Log PSD', 'Color', 'w', 'Position', [100, 100, 1100, 850]);
try, theme(fig2, 'light'); catch, end

% Ряд 1: Z1
axA2 = subplot(2, 2, 1);
plot(axA2, [-res1.zoomHalf res1.zoomHalf], [0.5 0.5], ':', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.2); hold(axA2, 'on');
plot(axA2, res1.lagx, res1.cx, 'Color', cRed, 'LineWidth', 1.6, 'DisplayName', 'OX');
plot(axA2, res1.lagy, res1.cy, 'Color', cBlue, 'LineWidth', 1.6, 'DisplayName', 'OY');
if isfinite(res1.hwX)
    xline(axA2, -res1.hwX, ':', 'Color', cRed, 'LineWidth', 1.2, 'HandleVisibility', 'off');
    xline(axA2, res1.hwX, ':', 'Color', cRed, 'LineWidth', 1.2, 'HandleVisibility', 'off');
end
if isfinite(res1.hwY)
    xline(axA2, -res1.hwY, ':', 'Color', cBlue, 'LineWidth', 1.2, 'HandleVisibility', 'off');
    xline(axA2, res1.hwY, ':', 'Color', cBlue, 'LineWidth', 1.2, 'HandleVisibility', 'off');
end
hold(axA2, 'off');
xlim(axA2, [-res1.zoomHalf res1.zoomHalf]); ylim(axA2, [0 1]);
legend(axA2, 'Location', 'northeast', 'TextColor', ink, 'Box', 'on');
text(axA2, 0.04, 0.08, sprintf('HWHM:\nOX = %.2f px\nOY = %.2f px', res1.hwX, res1.hwY), ...
    'Units', 'normalized', 'FontName', 'Helvetica', 'FontSize', 9.5, 'Color', ink, ...
    'BackgroundColor', 'w', 'EdgeColor', [0.6 0.6 0.6], 'Margin', 3);
apply_axes_style(axA2, 'A', ink); grid(axA2, 'on');

axB2 = subplot(2, 2, 2);
loglog(axB2, res1.fX, res1.pX, 'Color', cRed, 'LineWidth', 1.6, 'DisplayName', 'OX'); hold(axB2, 'on');
loglog(axB2, res1.fY, res1.pY, 'Color', cBlue, 'LineWidth', 1.6, 'DisplayName', 'OY'); hold(axB2, 'off');
legend(axB2, 'Location', 'northeast', 'TextColor', ink, 'Box', 'on');
apply_axes_style(axB2, 'B', ink); grid(axB2, 'on');

% Ряд 2: Z2
axC2 = subplot(2, 2, 3);
plot(axC2, [-res2.zoomHalf res2.zoomHalf], [0.5 0.5], ':', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.2); hold(axC2, 'on');
plot(axC2, res2.lagx, res2.cx, 'Color', cRed, 'LineWidth', 1.6, 'DisplayName', 'OX');
plot(axC2, res2.lagy, res2.cy, 'Color', cBlue, 'LineWidth', 1.6, 'DisplayName', 'OY');
if isfinite(res2.hwX)
    xline(axC2, -res2.hwX, ':', 'Color', cRed, 'LineWidth', 1.2, 'HandleVisibility', 'off');
    xline(axC2, res2.hwX, ':', 'Color', cRed, 'LineWidth', 1.2, 'HandleVisibility', 'off');
end
if isfinite(res2.hwY)
    xline(axC2, -res2.hwY, ':', 'Color', cBlue, 'LineWidth', 1.2, 'HandleVisibility', 'off');
    xline(axC2, res2.hwY, ':', 'Color', cBlue, 'LineWidth', 1.2, 'HandleVisibility', 'off');
end
hold(axC2, 'off');
xlim(axC2, [-res2.zoomHalf res2.zoomHalf]); ylim(axC2, [0 1]);
legend(axC2, 'Location', 'northeast', 'TextColor', ink, 'Box', 'on');
text(axC2, 0.04, 0.08, sprintf('HWHM:\nOX = %.2f px\nOY = %.2f px', res2.hwX, res2.hwY), ...
    'Units', 'normalized', 'FontName', 'Helvetica', 'FontSize', 9.5, 'Color', ink, ...
    'BackgroundColor', 'w', 'EdgeColor', [0.6 0.6 0.6], 'Margin', 3);
apply_axes_style(axC2, 'C', ink); grid(axC2, 'on');

axD2 = subplot(2, 2, 4);
loglog(axD2, res2.fX, res2.pX, 'Color', cRed, 'LineWidth', 1.6, 'DisplayName', 'OX'); hold(axD2, 'on');
loglog(axD2, res2.fY, res2.pY, 'Color', cBlue, 'LineWidth', 1.6, 'DisplayName', 'OY'); hold(axD2, 'off');
legend(axD2, 'Location', 'northeast', 'TextColor', ink, 'Box', 'on');
apply_axes_style(axD2, 'D', ink); grid(axD2, 'on');

fig2Path = fullfile(saveDir, [outPrefix '_cuts_loglog_fig.png']);
save_figure_png(fig2, fig2Path);

% Розрахунок та збереження статистики
stats = struct();
stats.Z1_map  = calc_moments(Z1);
stats.Z1_acf  = calc_moments(res1.acf_sub);
stats.Z1_psd  = calc_moments(res1.psd_log);
stats.Z1_Lx   = res1.hwX;
stats.Z1_Ly   = res1.hwY;

stats.Z2_map  = calc_moments(Z2);
stats.Z2_acf  = calc_moments(res2.acf_sub);
stats.Z2_psd  = calc_moments(res2.psd_log);
stats.Z2_Lx   = res2.hwX;
stats.Z2_Ly   = res2.hwY;

txtPath = fullfile(saveDir, [outPrefix '_stats.txt']);
write_stats_file(txtPath, stats);

fprintf('АКФ і PSD аналіз завершено.\n  Рисунки:\n    %s\n    %s\n  Статистика: %s\n', fig1Path, fig2Path, txtPath);
end

% =========================================================================
% Допоміжні функції розрахунку
% =========================================================================
function res = compute_acf_psd_core(Z)
    if ~isreal(Z), Z = abs(Z); end
    v = Z;
    fin = v(isfinite(v));
    if isempty(fin), mu = 0; else, mu = mean(fin); end
    v(~isfinite(v)) = mu;
    v = v - mu;
    [M, N] = size(v);

    % Лінійна 2D АКФ через FFT з нуль-доповненням
    Mp = 2*M - 1; Np = 2*N - 1;
    F = fft2(v, Mp, Np);
    acf = fftshift(real(ifft2(abs(F).^2)));
    acf = acf / max(abs(acf(:)) + eps);
    acf = max(acf, 0);

    % 2D PSD
    psd = fftshift(abs(fft2(v)).^2 / (M*N));

    [Ma, Na] = size(acf);
    lagx = (-(Na-1)/2 : (Na-1)/2);
    lagy = (-(Ma-1)/2 : (Ma-1)/2);

    % 1D центральні перерізи
    iy0 = round(Ma/2);
    ix0 = round(Na/2);
    cx = acf(iy0, :);
    cy = acf(:, ix0).';

    % Довжини кореляції (HWHM на рівні 0.5)
    hwX = calc_hwhm(lagx, cx);
    hwY = calc_hwhm(lagy, cy);

    % 1D PSD перерізів у log-log (за теоремою Вінера-Хінчина)
    Lx = numel(cx);
    pX = abs(fft(ifftshift(cx)));
    pos_x = 2:floor(Lx/2);
    fX = (pos_x - 1) / Lx; pX = pX(pos_x) + eps;

    Ly = numel(cy);
    pY = abs(fft(ifftshift(cy)));
    pos_y = 2:floor(Ly/2);
    fY = (pos_y - 1) / Ly; pY = pY(pos_y) + eps;

    % Окіл піка АКФ для статистики
    hw = max([hwX, hwY]);
    if isnan(hw) || isempty(hw) || hw <= 0, hw = 5; end
    half = min(round(hw*4), floor(min(Na, Ma)/4));
    sub = acf(abs(lagy) <= half, abs(lagx) <= half);

    % Шкала PSD у децибелах з обрізкою 1% і 99% перцентилів
    dbMap = 10*log10(psd + eps);
    loClip = prctile(dbMap(:), 1);
    hiClip = prctile(dbMap(:), 99);

    % log10 PSD без постійної складової (DC)
    psd_no_dc = psd;
    psd_no_dc(round(M/2), round(N/2)) = NaN;
    psd_log = log10(psd_no_dc(:) + eps);

    res.acf = acf;
    res.psd = psd;
    res.dbMap = dbMap;
    res.loClip = loClip;
    res.hiClip = hiClip;
    res.lagx = lagx;
    res.lagy = lagy;
    res.cx = cx;
    res.cy = cy;
    res.hwX = hwX;
    res.hwY = hwY;
    res.zoomHalf = max(round(hw*4), 10);
    res.fX = fX;
    res.pX = pX;
    res.fY = fY;
    res.pY = pY;
    res.acf_sub = sub(:);
    res.psd_log = psd_log;
end

function hw = calc_hwhm(lag, curve)
    [~, i0] = min(abs(lag));
    peak = curve(i0);
    half = 0.5 * peak;
    
    hiLag = NaN;
    for i = i0:numel(curve)-1
        if curve(i) >= half && curve(i+1) < half
            t = (half - curve(i)) / (curve(i+1) - curve(i));
            hiLag = lag(i) + t*(lag(i+1) - lag(i));
            break;
        end
    end
    
    loLag = NaN;
    for i = i0:-1:2
        if curve(i) >= half && curve(i-1) < half
            t = (half - curve(i)) / (curve(i-1) - curve(i));
            loLag = lag(i) + t*(lag(i-1) - lag(i));
            break;
        end
    end
    
    if isnan(hiLag) && isnan(loLag)
        hw = NaN;
    elseif isnan(hiLag)
        hw = abs(loLag);
    elseif isnan(loLag)
        hw = abs(hiLag);
    else
        hw = 0.5 * (hiLag - loLag);
    end
end

function apply_axes_style(ax, titleLetter, ink)
    set(ax, 'FontName', 'Helvetica', 'FontSize', 11, 'Box', 'on', 'Layer', 'top', ...
            'Color', 'w', 'XColor', ink, 'YColor', ink, 'ZColor', ink, ...
            'GridColor', [0.4 0.4 0.4], 'GridAlpha', 0.25);
    title(ax, titleLetter, 'FontSize', 14, 'FontWeight', 'bold', 'Color', ink);
end

function save_figure_png(fig, filePath)
    try
        exportgraphics(fig, filePath, 'Resolution', 200);
    catch
        saveas(fig, filePath);
    end
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

    fprintf(fid, 'ACF and PSD Statistics\n\n');
    fprintf(fid, '%-24s %14s %14s %14s %14s\n', 'Quantity', 'Mean_Z1', 'Std_Z2', 'Skew_Z3', 'Kurt_Z4');
    print_row(fid, 'Z1_Map', stats.Z1_map);
    print_row(fid, 'Z1_ACF_PeakArea', stats.Z1_acf);
    print_row(fid, 'Z1_log10_PSD', stats.Z1_psd);
    fprintf(fid, 'Correlation_Length_Z1: Lx = %.2f px, Ly = %.2f px\n\n', stats.Z1_Lx, stats.Z1_Ly);
    print_row(fid, 'Z2_Map', stats.Z2_map);
    print_row(fid, 'Z2_ACF_PeakArea', stats.Z2_acf);
    print_row(fid, 'Z2_log10_PSD', stats.Z2_psd);
    fprintf(fid, 'Correlation_Length_Z2: Lx = %.2f px, Ly = %.2f px\n', stats.Z2_Lx, stats.Z2_Ly);
end

function print_row(fid, name, m)
    fprintf(fid, '%-24s %14.5e %14.5e %14.5e %14.5e\n', name, m(1), m(2), m(3), m(4));
end
