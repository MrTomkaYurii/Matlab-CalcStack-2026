function ST = tp_stats_element(D, meta, CFG)
% TP_STATS_ELEMENT  Статистика ОДНОГО елемента Кроку B (LB_0_90, LB_45_135, CB, rho, LB),
%   окремо для модуля (ST.mod) й аргументу (ST.arg). Набір і визначення -- ТІ САМІ, що в
%   серпневому paper_figures\make_stats_table.m: для кожного ПРЕДСТАВЛЕННЯ -- чотири моменти
%   розподілу, показаного на рисунку (Z1 = mean, Z2 = std, Z3 = skew, Z4 = kurt):
%
%     .maps   карта |X| / arg[X]: N, mean/std/skew/kurt (tp_moments; для arg кругові)
%     .acf    2D-АКФ у вікні лагів (як вставка на рисунку acf_psd: 4×HWHM, мін. 5 px):
%             z2 = std, z4 = kurt; hwhmX/hwhmY = L (FWHM АКФ по X / по Y, px)
%     .psd    значення log10(PSD) 2D-спектра, DC виключено: z = [mean std skew kurt]
%     .wav    амплітуди |W(a,b)| усієї скалограми (tp_wavelet_comp): z; .cuts(j) = переріз
%             |W(a_j,b)| при j-му позначеному масштабі a_j (CFG.wavelet.highlightScales): a, z
%     .skel   амплітуди максимумів вейвлет-скелетону (tp_skeleton_comp): z
%     .mf     мультифрактал (tp_multifractal): D0, D1, D2, deltaH, leftWidth, rightWidth, asymmetry
%
%   Розрахунки спільні з рисунками (tp_wavelet_comp, tp_skeleton_comp, tp_acf_psd, tp_acf_hwhm).
%   Споживачі: текстовий файл елемента (tp_stats_write.m) і таблиця аналітики
%   (tp_an_row_from_stats.m: .maps, .acf.hwhmX/hwhmY, .mf).
%
%   D    : struct('mod','arg','cplx')  -- R2.data.(dir).(elem)
%   meta : з tp_element_meta.m (x, y, acfData, підписи)
%   CFG  : cfg_September()
%
%   QC (як у серпневій аналітиці): якщо скінченних пікселів < CFG.qc.minValidPixels або частка
%   NaN > CFG.qc.maxNaNfrac -- ST.qc.ok = false; тоді рахується лише .maps (моменти = NaN), решта
%   не рахується (на майже порожній карті вона була б шумом).

minValid = 1000;   if isfield(CFG,'qc') && isfield(CFG.qc,'minValidPixels'), minValid = CFG.qc.minValidPixels; end
maxNaN   = 0.95;   if isfield(CFG,'qc') && isfield(CFG.qc,'maxNaNfrac'),     maxNaN   = CFG.qc.maxNaNfrac;     end

nTot  = numel(D.mod);
nFin  = nnz(isfinite(D.mod));
nanFr = 1 - nFin/nTot;
reason = '';
if nFin < minValid
    reason = sprintf('скінченних пікселів %d < minValidPixels %d', nFin, minValid);
elseif nanFr > maxNaN
    reason = sprintf('частка NaN %.3f > maxNaNfrac %.2f', nanFr, maxNaN);
end
ok = isempty(reason);

ST = struct();
ST.qc = struct('ok', ok, 'reason', reason, 'minValidPixels', minValid, 'maxNaNfrac', maxNaN);
ST.mod = oneQuantity(D.mod, false, meta.acfData.mod, meta, CFG, ok, minValid, maxNaN);
ST.arg = oneQuantity(D.arg, true,  meta.acfData.arg, meta, CFG, ok, minValid, maxNaN);
end

% ------------------------------------------------------------------------
function Q = oneQuantity(Z, isPhase, acfq, meta, CFG, ok, minValid, maxNaN)
Q = struct();
Q.maps = mapStats(Z, isPhase, minValid, maxNaN);
if ~ok, return; end
Q.acf  = acfStats(acfq);
Q.psd  = psdStats(acfq);
[Q.wav, Q.skel] = waveletStats(Z, meta, CFG);
Q.mf   = mfStats(Z, CFG);
end

% ------------------------------------------------------------------------
function z = mom4(v)
% [mean std skew kurt] скінченних значень v (tp_moments, лінійні); n<2 -> NaN
v = v(:);  v = v(isfinite(v));
[mu, sd, sk, ku] = tp_moments(v, false);
z = [mu sd sk ku];
end

% ------------------------------------------------------------------------
function M = mapStats(Z, isPhase, minValid, maxNaN)
v = Z(isfinite(Z));
M = struct('nTotal', numel(Z), 'nFinite', numel(v));
M.nanFrac = 1 - numel(v)/numel(Z);
[mu, sd, sk, ku] = tp_moments(v, isPhase);
% моменти -- за серпневим правилом QC (NaN на замалих/задірявлених вибірках)
if numel(v) < minValid || M.nanFrac > maxNaN
    mu = NaN; sd = NaN; sk = NaN; ku = NaN;
end
M.mean = mu; M.std = sd; M.skew = sk; M.kurt = ku;
end

% ------------------------------------------------------------------------
function A = acfStats(acfq)
% 2D-АКФ у вікні лагів -- те саме, що показує вставка на рисунку acf_psd (viz_acf_psd.m):
% півширина вікна = 4 × max(HWHM_x, HWHM_y), мінімум 5 px.
acf = acfq.acf;  lagx = acfq.lagx;  lagy = acfq.lagy;
[~, ix0] = min(abs(lagx));  [~, iy0] = min(abs(lagy));
hwx = tp_acf_hwhm(lagx, acf(iy0, :));            % L по X (FWHM), px
hwy = tp_acf_hwhm(lagy, acf(:, ix0).');          % L по Y (FWHM), px
hw = max([hwx, hwy], [], 'omitnan');
if isempty(hw) || isnan(hw), hw = 2.5; end
half = max(hw*4, 5);
if isinf(half), half = 10; end
half = min(half, min(max(lagx), max(lagy)));
sub = acf(lagy >= -half & lagy <= half, lagx >= -half & lagx <= half);
z = mom4(sub);
A = struct('hwhmX', hwx, 'hwhmY', hwy, 'half', half, 'z2', z(2), 'z4', z(4), 'n', nnz(isfinite(sub)));
end

% ------------------------------------------------------------------------
function P = psdStats(acfq)
% log10 значень 2D-спектра потужності. DC (k = 0) виключено: сигнал центрують перед FFT
% (tp_acf_psd), тому PSD у точці k=0 ~ машинний нуль і log10 дав би ~-300 в одному пікселі.
psd = acfq.psd;                                   % 2D PSD, fftshift, розмір My x Nx
[My, Nx] = size(psd);
fx = ((0:Nx-1) - floor(Nx/2)) / Nx;
fy = ((0:My-1) - floor(My/2)) / My;
[~, ixDC] = min(abs(fx));  [~, iyDC] = min(abs(fy));
psd(iyDC, ixDC) = NaN;
L = log10(psd + realmin);
P = struct('z', mom4(L), 'n', nnz(isfinite(L)));
end

% ------------------------------------------------------------------------
function [W, K] = waveletStats(Z, meta, CFG)
% Скалограма |W(a,b)|, її перерізи при позначених масштабах і скелетон -- ті самі CWT-розрахунки,
% що на рисунках wavelet / skeleton (tp_wavelet_comp, tp_skeleton_comp).
comp = tp_wavelet_comp(Z, meta, CFG);
W = struct('valid', ~comp.degenerate);
if W.valid
    A = comp.A;  scal = comp.scal;
    W.z = mom4(A);
    W.n = nnz(isfinite(A));
    cuts = struct('a', {}, 'z', {}, 'n', {});
    for j = 1:numel(comp.hi)
        idx = comp.hi(j);
        cuts(j).a = scal(idx);
        cuts(j).z = mom4(A(idx, :));
        cuts(j).n = nnz(isfinite(A(idx, :)));
    end
    W.cuts = cuts;
end

sk = tp_skeleton_comp(Z, meta, CFG);
K = struct('valid', ~sk.degenerate);
if K.valid
    K.z = mom4(sk.Hpts);
    K.n = nnz(isfinite(sk.Hpts));
end
end

% ------------------------------------------------------------------------
function F = mfStats(Z, CFG)
MF = tp_multifractal(Z, struct(), CFG);           % так само, як у tp_analytics_compute_summary
F = struct('valid', ~MF.degenerate);
if ~F.valid, return; end
for n = {'D0','D1','D2','deltaH','asymmetry','leftWidth','rightWidth'}
    F.(n{1}) = MF.(n{1});
end
end
