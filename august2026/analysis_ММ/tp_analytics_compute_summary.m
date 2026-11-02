function S = tp_analytics_compute_summary(D, CFG)
% TP_ANALYTICS_COMPUTE_SUMMARY  Плаский struct числових метрик ОДНОГО
%   елемента f_ik за конкретних умов (зразок/приклад/вікно/алгоритм/
%   напрям/крок вже визначені викликаючою стороною — тут лише самі D.mod,
%   D.arg карти). Рахує ТЕ САМЕ, що вже рахують в'юери (tp_moments у
%   viz_stats_table.m, tp_acf_psd+HWHM у viz_acf_cuts.m, tp_multifractal у
%   viz_multifractal_dimensions.m) — але лише повертає числа, без картинок,
%   для агрегації в analytics_summary_table (tp_analytics_collect_summaries.m).
%
%   Колонки узгоджені з tp_analytics_metric_names.m — якщо тут щось
%   додаєш/перейменовуєш, онови і той список.

vMod = D.mod(isfinite(D.mod));
vArg = D.arg(isfinite(D.arg) & D.mod > 0);   % |f| = 0 -> аргумент не визначений
[muM,sdM,skM,kuM,nM] = tp_moments(vMod, false);
[muA,sdA,skA,kuA,nA] = tp_moments(vArg, true);

% QC-поріг на самі МОМЕНТИ (не лише на діагностичну картинку tp_visualize):
% замалі/задірявлені вибірки дають статистично ненадійний 3-й/4-й момент
% (асиметрію/ексцес) — на вузьких фазових вікнах (phase_07/08) може лишитись
% лічені пікселі. Той самий maxNaNfrac, що й у tp_validate.m (частка NaN
% від ПОВНОГО кадру), + жорсткий абсолютний мінімум CFG.qc.minValidPixels
% (типово 1000) — блокує обчислення, а не лише показ. N (nM/nA) лишається
% справжнім, щоб було видно ЧОМУ рядок NaN. Fallback-значення нижче —
% ЛИШЕ якщо CFG.qc не задано (не мало б траплятись) — синхронізовані з
% "бойовими" значеннями cfg_TwoPoint.m, щоб не розійтись мовчки.
maxNaNfrac = 0.95;
if isfield(CFG,'qc') && isfield(CFG.qc,'maxNaNfrac'); maxNaNfrac = CFG.qc.maxNaNfrac; end
minValidPixels = 1000;
if isfield(CFG,'qc') && isfield(CFG.qc,'minValidPixels'); minValidPixels = CFG.qc.minValidPixels; end

nanFracMod = 1 - numel(vMod)/numel(D.mod);
if nM < minValidPixels || nanFracMod > maxNaNfrac
    muM = NaN; sdM = NaN; skM = NaN; kuM = NaN;
end
nanFracArg = 1 - numel(vArg)/numel(D.arg);
if nA < minValidPixels || nanFracArg > maxNaNfrac
    muA = NaN; sdA = NaN; skA = NaN; kuA = NaN;
end

[acfMod, ~, lagxM, lagyM] = tp_acf_psd(D.mod, CFG.acf.method);
[acfArg, ~, lagxA, lagyA] = tp_acf_psd(D.arg, CFG.acf.method);
hwxM = tp_acf_hwhm(lagxM, acfMod(round(size(acfMod,1)/2), :));
hwyM = tp_acf_hwhm(lagyM, acfMod(:, round(size(acfMod,2)/2)).');
hwxA = tp_acf_hwhm(lagxA, acfArg(round(size(acfArg,1)/2), :));
hwyA = tp_acf_hwhm(lagyA, acfArg(:, round(size(acfArg,2)/2)).');

MFmod = tp_multifractal(D.mod, struct(), CFG);
MFarg = tp_multifractal(D.arg, struct(), CFG);

S = struct();
S.n_mod = nM; S.mean_mod = muM; S.std_mod = sdM; S.skew_mod = skM; S.kurt_mod = kuM;
S.n_arg = nA; S.mean_arg = muA; S.std_arg = sdA; S.skew_arg = skA; S.kurt_arg = kuA;
S.acf_hwhm_x_mod = hwxM; S.acf_hwhm_y_mod = hwyM;
S.acf_hwhm_x_arg = hwxA; S.acf_hwhm_y_arg = hwyA;
S.mf_D0_mod = mfField(MFmod,'D0'); S.mf_D1_mod = mfField(MFmod,'D1'); S.mf_D2_mod = mfField(MFmod,'D2');
S.mf_deltaH_mod = mfField(MFmod,'deltaH'); S.mf_asym_mod = mfField(MFmod,'asymmetry');
S.mf_D0_arg = mfField(MFarg,'D0'); S.mf_D1_arg = mfField(MFarg,'D1'); S.mf_D2_arg = mfField(MFarg,'D2');
S.mf_deltaH_arg = mfField(MFarg,'deltaH'); S.mf_asym_arg = mfField(MFarg,'asymmetry');
end

% ------------------------------------------------------------------------
function v = mfField(MF, name)
if ~MF.degenerate && isfield(MF, name)
    v = MF.(name);
else
    v = NaN;
end
end
