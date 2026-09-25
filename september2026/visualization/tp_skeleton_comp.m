function comp = tp_skeleton_comp(Z, meta, CFG)
% TP_SKELETON_COMP  Профіль + CWT + вейвлет-скелетон (WTMM), лише в межах конуса впливу.
%   ВИНЕСЕНО БЕЗ ЗМІН з viz_skeleton.m (локальна computeSkeleton) -- спільне для
%   viz_skeleton і статистики tp_stats_element (цифри збігаються з рисунком).
% Профіль + CWT + вилучення скелетону (WTMM) — важка частина, рахується раз.
switch lower(CFG.wavelet.profile)
    case 'center_col', sig = Z(:, round(size(Z,2)/2)).';  b = meta.y;
    case 'mean_row',   sig = mean(Z,1,'omitnan');         b = meta.x;
    otherwise,         sig = Z(round(size(Z,1)/2), :);    b = meta.x;
end
sig = fillmissing(sig,'linear'); sig = fillmissing(sig,'nearest');

comp = struct('degenerate', true);
if all(~isfinite(sig)) || std(sig(isfinite(sig)))==0
    return;
end

fb = cwtfilterbank('SignalLength',numel(sig),'Wavelet',CFG.wavelet.name, ...
                   'VoicesPerOctave',CFG.wavelet.voicesPerOctave);
[wtc, freq, coi] = wt(fb, sig);  scal0 = scales(fb);  A0 = abs(wtc);

% конус впливу (COI), у одиницях масштабу: за межею (a > coiScale(b)) CWT
% на краю профілю спотворений відсутністю даних за межею сигналу — ці
% "максимуми" НЕ фізичні, і мусять бути виключені зі скелетону, бо інакше
% псують саме числа (гістограму екстремумів), а не лише картинку.
coiScale = interp1(freq, scal0, coi, 'linear', 'extrap');
coiScale = reshape(coiScale, 1, []);   % рядок, як і b/A(r,:) — інакше неявне
                                       % розширення в матрицю замість поелементного порівняння
coiScale = min(max(coiScale, min(scal0)), max(scal0));

sr = CFG.wavelet.scaleRange;
keep = scal0>=sr(1) & scal0<=sr(2);
scal = scal0; A = A0;
if any(keep), scal = scal0(keep); A = A0(keep,:); end

% скелетон: локальні максимуми вздовж b на кожному масштабі (WTMM),
% ЛИШЕ всередині конуса впливу (a(r) <= coiScale(b))
[ns, ~] = size(A);
Bpts = []; Apts = []; Hpts = [];
for r = 1:ns
    idx = find(islocalmax(A(r,:)) & (scal(r) <= coiScale));
    Bpts = [Bpts, b(idx)];                          %#ok<AGROW>
    Apts = [Apts, repmat(scal(r), 1, numel(idx))];  %#ok<AGROW>
    Hpts = [Hpts, A(r,idx)];                        %#ok<AGROW>
end

comp.degenerate = false;
comp.Bpts = Bpts; comp.Apts = Apts; comp.Hpts = Hpts;
end
