function MF = tp_multifractal(Z, meta, CFG)
% TP_MULTIFRACTAL  Мультифрактальний спектр f(h) з WTMM-максимумів 1D-
%   профілю карти Z (та сама CWT-схема, що й viz_wavelet/viz_skeleton:
%   профіль обирається за CFG.wavelet.profile, конус впливу враховано).
%
%   Спрощений WTMM: партиційна функція рахується по ВСІХ локальних
%   максимумах |W(a,b)| на кожному масштабі a (без ланцюжкового трекінгу
%   ліній максимумів через масштаби, як у "класичному" повному WTMM) —
%   прийнятне практичне наближення для оглядового спектру.
%
%   Формалізм (Muzy-Bacry-Arneodo):
%     Z(q,a) = sum_b |W(a,b)|^q            (партиційна функція)
%     tau(q) = нахил log(Z(q,a)) vs log(a) (масовий показник)
%     h(q)   = d tau(q) / dq               (показник Гельдера)
%     f(q)   = q*h(q) - tau(q)             (перетворення Лежандра)
%   Крива (h(q), f(q)), параметризована q, — і є спектр f(h).
%
%   MF.q, MF.a, MF.logZ (nQ x nA), MF.tau, MF.h, MF.f, MF.deltaH,
%   MF.degenerate

MF = struct('degenerate', true);

switch lower(CFG.wavelet.profile)
    case 'center_col', sig = Z(:, round(size(Z,2)/2)).';
    case 'mean_row',   sig = mean(Z,1,'omitnan');
    otherwise,         sig = Z(round(size(Z,1)/2), :);
end
sig = fillmissing(sig,'linear'); sig = fillmissing(sig,'nearest');
if sum(isfinite(sig)) < 4 || std(sig(isfinite(sig))) == 0
    return;
end
sig(~isfinite(sig)) = 0;

fb = cwtfilterbank('SignalLength',numel(sig),'Wavelet',CFG.wavelet.name, ...
                   'VoicesPerOctave',CFG.wavelet.voicesPerOctave);
[wtc, freq, coi] = wt(fb, sig);  scal0 = scales(fb);  A0 = abs(wtc);

coiScale = interp1(freq, scal0, coi, 'linear', 'extrap');
coiScale = reshape(coiScale, 1, []);
coiScale = min(max(coiScale, min(scal0)), max(scal0));

sr = CFG.wavelet.scaleRange;
keep = scal0>=sr(1) & scal0<=sr(2);
scal = scal0; A = A0;
if any(keep), scal = scal0(keep); A = A0(keep,:); end
nS = numel(scal);
if nS < 4
    return;   % замало масштабів для стійкої регресії
end

% максимуми на кожному масштабі, лише в межах конуса впливу
maxVals = cell(nS,1);
for r = 1:nS
    idx = find(islocalmax(A(r,:)) & (scal(r) <= coiScale));
    maxVals{r} = A(r,idx);
end

q  = CFG.multifractal.qRange;
nQ = numel(q);
logA = log(scal(:)');
logZ = nan(nQ, nS);
for si = 1:nS
    v = maxVals{si}; v = v(v > 0);
    if isempty(v), continue; end
    v = v / sum(v);   % НОРМОВАНА міра на цьому масштабі (сума=1) — інакше
                      % Z(1,a) не дорівнює тотожно 1, tau(1)~=0, і D(q)=
                      % tau(q)/(q-1) дає хибний розрив біля q=1 (перевірено:
                      % саме це і давало "зубець" на графіку D(q))
    for qi = 1:nQ
        logZ(qi,si) = log(sum(v.^q(qi)));
    end
end

% для кожного q: нахил (=tau(q)), перетин (для малювання лінії) і R^2
% (наскільки log Z(q,a) дійсно лінійна від log(a) — без цього неможливо
% перевірити, чи взагалі партиційна функція степенева, а не випадкова)
tau = nan(1,nQ); intercept = nan(1,nQ); R2 = nan(1,nQ);
for qi = 1:nQ
    valid = isfinite(logZ(qi,:));
    if nnz(valid) < 3, continue; end
    x = logA(valid); y = logZ(qi,valid);
    c = polyfit(x, y, 1);
    yFit = polyval(c, x);
    ssRes = sum((y - yFit).^2); ssTot = sum((y - mean(y)).^2);
    R2(qi) = 1 - ssRes / max(ssTot, eps);
    tau(qi) = c(1); intercept(qi) = c(2);
end

if nnz(isfinite(tau)) < 3
    return;
end

h = gradient(tau, q);      % d(tau)/dq, числова похідна
f = q.*h - tau;             % перетворення Лежандра

valid = isfinite(h) & isfinite(f);
if nnz(valid) < 3
    return;
end

% узагальнені розмірності D(q) = tau(q)/(q-1); q=1 через сусідні точки
% (границя за Лопіталем = h(1), уникаючи ділення на нуль)
D = nan(size(q));
for qi = 1:nQ
    if abs(q(qi) - 1) < 1e-9
        D(qi) = h(qi);              % lim_{q->1} tau(q)/(q-1) = tau'(1) = h(1)
    elseif isfinite(tau(qi))
        D(qi) = tau(qi) / (q(qi) - 1);
    end
end
[~, i0] = min(abs(q));              % q=0 -> вершина спектру f(h)
[~, i1] = min(abs(q-1));
[~, i2] = min(abs(q-2));
D0 = D(i0); D1 = D(i1); D2 = D(i2);
h0 = h(i0);                         % h у вершині (q=0) — ділить спектр на ліву/праву частини

hMin = min(h(valid)); hMax = max(h(valid));
leftWidth  = h0 - hMin;              % відповідає q>0 (сильні особливості)
rightWidth = hMax - h0;              % відповідає q<0 (слабкі особливості)
asym = (rightWidth - leftWidth) / max(rightWidth + leftWidth, eps);

MF.degenerate = false;
MF.q = q; MF.a = scal; MF.logZ = logZ; MF.tau = tau; MF.h = h; MF.f = f;
MF.tauIntercept = intercept; MF.R2 = R2;   % для оверлею ліній апроксимації й перевірки якості
MF.deltaH = hMax - hMin;   % ширина спектру — головний діагностичний показник
MF.D = D; MF.D0 = D0; MF.D1 = D1; MF.D2 = D2; MF.h0 = h0;
MF.leftWidth = leftWidth; MF.rightWidth = rightWidth; MF.asymmetry = asym;
end
