function winData = paper_prep(winData, elems, kind, FIG)
% PAPER_PREP  Готує КОЖНУ панель рисунка до відмальовування: із сирої карти
%   winData{w}.data.(elem).(comp) (comp = 'mod'|'arg') робить те, що реально
%   показується, залежно від kind:
%     'raw'  Fig1 — карта як є                       + гістограма значень
%     'acf'  Fig2 — 2D-АКФ (core\tp_acf_psd)         + 1D-переріз АКФ
%     'psd'  Fig3 — 2D-спектр потужності (log10)     + гістограма значень
%     'wav'  Fig5 — скалограма |W(a,b)| (CWT профілю)  + гістограма |W|
%     'skel' Fig4 — вейвлет-скелетон (лінії WTMM-макс.) + гістограма F(h) максимумів
%     'mfr'  Fig6 — крива D(q)/tau/h(q)                 + спектр f(h) з Delta h
%
%   Додає winData{w}.prep.(elem).(comp) зі структурою:
%     .img            2D double — що подати в imagesc/pcolor (нема для 'skel')
%     .x, .y          вектори осей (для 'acf'/'psd' — ЗІ ЗНАКОМ, центр у 0;
%                     для 'wav'/'skel' .y — масштаб a, вісь логарифмічна)
%     .axX, .axY      підписи осей карти (tex)
%     .yLog           true -> вісь y логарифмічна ('wav'/'skel')
%     .skB,.skA,.skH  точки скелетону (позиція, масштаб, |W| у максимумі) — лише 'skel'
%     .isMod          logical
%     .histSrc        значення для нижньої гістограми ([] якщо kind='acf')
%     .cutLag,.cutCurve,.cutXlab   1D-переріз ([] якщо не 'acf')
%     .Lcorr          довжина кореляції (FWHM перерізу; NaN якщо не 'acf')

comps = {'mod','arg'};
addpath(fileparts(fileparts(mfilename('fullpath'))));           % ...\paper_figures
addpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))),'core'));  % ...\august2026\core

for w = 1:numel(winData)
    for e = 1:numel(elems)
        for ci = 1:2
            comp = comps{ci};
            M = winData{w}.data.(elems{e}).(comp);
            P = struct('img',[], 'x',[], 'y',[], 'axX','', 'axY','', 'yLog',false, ...
                       'skB',[], 'skA',[], 'skH',[], 'mf',[], ...
                       'isMod',strcmp(comp,'mod'), 'histSrc',[], ...
                       'cutLag',[], 'cutCurve',[], 'cutXlab','', 'Lcorr',NaN, ...
                       'loLag',NaN, 'hiLag',NaN, ...
                       'wcutB',[], 'wcutLo',[], 'wcutHi',[], 'wcutALo',NaN, 'wcutAHi',NaN);

            switch kind
                case 'raw'
                    P.img = M;
                    P.x = 1:size(M,2);  P.y = 1:size(M,1);
                    P.axX = sprintf('x (%s)', FIG.axis.unit);
                    P.axY = sprintf('y (%s)', FIG.axis.unit);
                    P.histSrc = M(isfinite(M));

                case 'acf'
                    % ПОВНА 2D-АКФ + повний 1D-переріз + півширина; вікно лагів
                    % (спільне на весь FigN) ріже render_grid_4x4 / make_stats_table.
                    [acf, ~, lx, ly] = tp_acf_psd(M, FIG.acf.method);   % acf у [0,1], розмір (2M-1)
                    P.img = acf;   P.x = lx;   P.y = ly;
                    P.axX = sprintf('\\Deltax (%s)', FIG.axis.unit);
                    P.axY = sprintf('\\Deltay (%s)', FIG.axis.unit);
                    [P.cutLag, P.cutCurve, P.cutXlab] = acf_cut(acf, lx, ly, FIG.acf.cut, FIG.axis.unit);
                    [P.Lcorr, P.loLag, P.hiLag] = tp_acf_hwhm(P.cutLag, P.cutCurve);

                case 'psd'
                    [~, psd] = tp_acf_psd(M, FIG.acf.method);           % psd fftshift, розмір MxN
                    [My, Nx] = size(psd);
                    fx = ((0:Nx-1) - floor(Nx/2)) / Nx;                 % нормована частота, [-0.5, 0.5)
                    fy = ((0:My-1) - floor(My/2)) / My;
                    % DC (k=0) виключаємо: у tp_acf_psd.m сигнал центрують
                    % (віднімають середнє) ПЕРЕД FFT, тому psd у самій точці
                    % k=0 ~ машинний нуль -> log10 дає ~-300 і одним пікселем
                    % ламає колірну шкалу й гістограму для всього спектра
                    % (перевірено: без цього карта майже одноколірна).
                    [~, ixDC] = min(abs(fx));  [~, iyDC] = min(abs(fy));
                    psd(iyDC, ixDC) = NaN;
                    Z = psd;
                    if FIG.psd.log,  Z = log10(psd + realmin);  end
                    fr = FIG.psd.cropFrac;
                    kx = abs(fx) <= fr*0.5;   ky = abs(fy) <= fr*0.5;
                    P.img = Z(ky, kx);   P.x = fx(kx);   P.y = fy(ky);
                    P.axX = 'k_x (1/px)';   P.axY = 'k_y (1/px)';
                    P.histSrc = P.img(isfinite(P.img));

                case 'wav'
                    [A, b, a] = wav_cwt(M, FIG);         % A: nScale x nB, |W|
                    P.img = A;   P.x = b;   P.y = a;   P.yLog = strcmpi(FIG.wav.yscale,'log');
                    P.axX = sprintf('b (%s)', FIG.axis.unit);
                    P.axY = sprintf('scale a (%s)', FIG.axis.unit);
                    P.histSrc = A(isfinite(A));

                    % два перерізи |W(a_fix,b)| при ФІКСОВАНОМУ масштабі —
                    % низький (FIG.wav.cutScales(1)) і високий (2). 'a' —
                    % дискретна сітка CWT-філтербанку, беремо найближчий рядок.
                    if isfield(FIG.wav,'cutScales') && numel(FIG.wav.cutScales) == 2
                        [~, iLo] = min(abs(a - FIG.wav.cutScales(1)));
                        [~, iHi] = min(abs(a - FIG.wav.cutScales(2)));
                        P.wcutB    = b;
                        P.wcutLo   = A(iLo, :);
                        P.wcutHi   = A(iHi, :);
                        P.wcutALo  = a(iLo);
                        P.wcutAHi  = a(iHi);
                    end

                case 'skel'
                    [A, b, a] = wav_cwt(M, FIG);
                    [P.skB, P.skA, P.skH] = wtmm_skeleton(A, b, a);
                    P.x = [b(1) b(end)];   P.y = [a(1) a(end)];
                    P.yLog = strcmpi(FIG.wav.yscale,'log');
                    P.axX = sprintf('b (%s)', FIG.axis.unit);
                    P.axY = sprintf('scale a (%s)', FIG.axis.unit);
                    P.histSrc = P.skH(isfinite(P.skH));

                case 'mfr'
                    P.mf = mfr_spectrum(M, FIG);

                otherwise
                    error('paper_prep: невідомий kind "%s"', kind);
            end
            winData{w}.prep.(elems{e}).(comp) = P;
        end
    end
end
end

% ======================================================================
function [lag, curve, xlab] = acf_cut(acf, lx, ly, mode, unit)
% 1D-переріз 2D-АКФ через центр (лаг=0).
[~, iy0] = min(abs(ly));
[~, ix0] = min(abs(lx));
switch lower(mode)
    case 'y'
        lag = ly(:).';   curve = acf(:, ix0).';
        xlab = sprintf('\\Deltay (%s)', unit);
    case 'radial'
        [lag, curve] = radial_average(acf, lx, ly);
        xlab = sprintf('\\Delta (%s)', unit);
    otherwise   % 'x'
        lag = lx(:).';   curve = acf(iy0, :);
        xlab = sprintf('\\Deltax (%s)', unit);
end
curve = max(curve, 0);
end

% ======================================================================
function [A, b, a] = wav_cwt(M, FIG)
% 1D-профіль карти -> CWT (Wavelet Toolbox) -> |W(a,b)|, обмежений
% діапазоном масштабів; за конусом впливу -> NaN (не псує гістограму/шкалу).
switch lower(FIG.wav.profile)
    case 'center_col', sig = M(:, round(size(M,2)/2)).';
    case 'mean_row',   sig = mean(M, 1, 'omitnan');
    otherwise,         sig = M(round(size(M,1)/2), :);
end

% Якщо центральний профіль містить замало валідних точок (випав з фазової маски),
% шукаємо рядок з найбільшою кількістю валідних пікселів
if sum(isfinite(sig)) < 4
    valPerRow = sum(isfinite(M), 2);
    [maxN, bestRow] = max(valPerRow);
    if maxN >= 4
        sig = M(bestRow, :);
    end
end

fb = cwtfilterbank('SignalLength',numel(sig), 'Wavelet',FIG.wav.wavelet, ...
                   'VoicesPerOctave',FIG.wav.voices);
a0 = scales(fb);            % масштаби, той самий порядок, що й freq / рядки wtc
sr = FIG.wav.scaleRange;
keep = a0 >= sr(1) & a0 <= sr(2);
if ~any(keep); keep = true(size(a0)); end
a = a0(keep);
a = reshape(a, [], 1);
b = 1:numel(sig);

% Якщо у всій карті недостатньо точок (вироджена / повністю замаскована карта)
if sum(isfinite(sig)) < 4
    A = nan(numel(a), numel(b));
    return;
end

sig = fillmissing(fillmissing(sig(:).', 'linear'), 'nearest');
sig(~isfinite(sig)) = 0;   % 100% гарантія скінченності для wt()

[wtc, freq, coi] = wt(fb, sig);
A0 = abs(wtc);
coiA = interp1(freq, a0, coi, 'linear', 'extrap');
coiA = min(max(reshape(coiA, 1, []), min(a0)), max(a0));

A = A0(keep, :);

if FIG.wav.coiMask
    for r = 1:numel(a)
        A(r, a(r) > coiA) = NaN;
    end
end
end

% ======================================================================
function MF = mfr_spectrum(M, FIG)
% Обгортка над core\tp_multifractal.m: будує CFG-shim із FIG.wav.* + FIG.mfr.qRange.
cfgShim.wavelet = struct('name',FIG.wav.wavelet, 'voicesPerOctave',FIG.wav.voices, ...
                         'profile',FIG.wav.profile, 'scaleRange',FIG.wav.scaleRange);
cfgShim.multifractal = struct('qRange', FIG.mfr.qRange);
MF = tp_multifractal(M, [], cfgShim);
end

% ======================================================================
function [B, Ax, H] = wtmm_skeleton(A, b, a)
% Лінії локальних максимумів |W| уздовж b на кожному масштабі (WTMM).
B = []; Ax = []; H = [];
for r = 1:size(A,1)
    row = A(r, :);
    idx = find(islocalmax(row) & isfinite(row));
    B  = [B,  b(idx)];                          %#ok<AGROW>
    Ax = [Ax, repmat(a(r), 1, numel(idx))];     %#ok<AGROW>
    H  = [H,  row(idx)];                        %#ok<AGROW>
end
end

% ======================================================================
function [r, prof] = radial_average(A, lx, ly)
[LX, LY] = meshgrid(lx, ly);
R  = round(hypot(LX, LY));
rm = min(max(abs(lx)), max(abs(ly)));
r  = 0:rm;
prof = zeros(1, numel(r));
for i = 1:numel(r)
    m = R == r(i);
    if any(m(:)); prof(i) = mean(A(m), 'omitnan'); else; prof(i) = NaN; end
end
prof = fillmissing(prof, 'linear');
% дзеркалимо, щоб переріз був симетричний (пік у центрі)
r    = [-fliplr(r(2:end)), r];
prof = [ fliplr(prof(2:end)), prof];
end
