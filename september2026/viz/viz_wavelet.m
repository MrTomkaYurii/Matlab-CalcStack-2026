function viz_wavelet(D, meta, ctx, CFG)
% VIZ_WAVELET  Подання (3) за ескізом: 2x2 вейвлет W(a,b).
%   Панелі: [ скалограма |f| | профілі A(b) на кількох масштабах ;
%             скалограма Arg | профілі Arg ].
%   Будується у кожній colormap зі списку CFG.viz.colormaps (jet, gray).
%   Профіль беремо з карти за CFG.wavelet.profile; масштаби обмежені scaleRange.
%
%   - Конус впливу (COI): за межами COI (краї профілю, великі масштаби)
%     CWT-коефіцієнти спотворені відсутністю даних за межею сигналу —
%     ця зона тепер притлумлена (AlphaData) і обведена лінією.
%   - Вісь Scale a -- ЛІНІЙНА (не log).
%   - Позначені масштаби -- ЗАФІКСОВАНІ CFG.wavelet.highlightScales
%     (типово [3 25]): для кожного цільового значення береться найближчий
%     реально доступний бін CWT. Підписи БЕЗ округлення до цілого (%.3g) —
%     показують фактичне значення (напр. a=24.8), не ціль.
%   Потребує Wavelet Toolbox (cwtfilterbank / wt).

if isfield(CFG,'style'), S = viz_style(CFG.style); else, S = viz_style(); end

% CWT НЕ залежить від colormap (це лише спосіб малювання) — рахуємо
% ОДИН раз для модуля й аргументу, а не на кожен colormap.
compMod = computeWavelet(D.mod, meta, CFG, 'mod');
compArg = computeWavelet(D.arg, meta, CFG, 'arg');

for c = 1:numel(CFG.viz.colormaps)
    cmap = CFG.viz.colormaps{c};
    fig = figure('Color','w','Visible','off','Position',[80 80 1300 950]);
    S.light(fig);

    renderWaveletPair(subplot(2,2,1), subplot(2,2,2), compMod, meta.modLabel, S, cmap);
    renderWaveletPair(subplot(2,2,3), subplot(2,2,4), compArg, meta.argLabel, S, cmap);

    sgtitle(sprintf('%s  \\cdot  wavelet W(a,b)  [%s]', meta.titlePrefix, cmap), ...
            'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
    tp_save_figure(fig, CFG, ctx.parts, sprintf('%s_wavelet_%s', ctx.name, cmap));
end
end

% ------------------------------------------------------------------------
function comp = computeWavelet(Z, meta, CFG, quantity)
% Профіль із карти + CWT (важка частина) — рахується один раз.
switch lower(CFG.wavelet.profile)
    case 'center_col', sig = Z(:, round(size(Z,2)/2)).';  b = meta.y;  cutDir = 'OY';
    case 'mean_row',   sig = mean(Z,1,'omitnan');         b = meta.x;  cutDir = 'OX';
    otherwise,         sig = Z(round(size(Z,1)/2), :);    b = meta.x;  cutDir = 'OX';
end
sig = fillmissing(sig,'linear'); sig = fillmissing(sig,'nearest');

comp = struct('degenerate', true);
if all(~isfinite(sig)) || std(sig(isfinite(sig)))==0
    return;
end

fb = cwtfilterbank('SignalLength',numel(sig),'Wavelet',CFG.wavelet.name, ...
                   'VoicesPerOctave',CFG.wavelet.voicesPerOctave);
[wtc, freq, coi] = wt(fb, sig);   % coi: частотна межа конуса впливу, на кожен b
scal0 = scales(fb);               % повний (нефільтрований) набір масштабів, той самий порядок, що й freq
A0 = abs(wtc);

% межа COI у одиницях МАСШТАБУ (не частоти): a=1/f по тій самій кривій
% freq<->scal0, що дав сам CWT — інтерполяція, без припущень про сталу
% вейвлета. Скали БІЛЬШІ за coiScale(b) у позиції b — ненадійні (край).
coiScale = interp1(freq, scal0, coi, 'linear', 'extrap');
coiScale = reshape(coiScale, 1, []);   % рядок, як і b — інакше неявне
                                       % розширення в матрицю замість поелементного порівняння
coiScale = min(max(coiScale, min(scal0)), max(scal0));

sr = CFG.wavelet.scaleRange;             % обмеження масштабів (напр. [1 100])
keep = scal0>=sr(1) & scal0<=sr(2);
scal = scal0; A = A0;
if any(keep), scal = scal0(keep); A = A0(keep,:); end

hi = deriveHighlightScaleIdx(scal, CFG.wavelet.highlightScales);

comp.degenerate = false;
comp.b = b; comp.scal = scal; comp.A = A;
comp.coiScale = coiScale; comp.hi = hi;
end

% ------------------------------------------------------------------------
function hi = deriveHighlightScaleIdx(scal, targetScales)
% РІВНО 2 перерізи, ЗАФІКСОВАНІ цільові масштаби (CFG.wavelet.highlightScales,
% типово [3 25]) -- для кожного цільового значення береться НАЙБЛИЖЧИЙ
% реально доступний масштаб у scal (сітка CWT дискретна, точного 3.000 чи
% 25.000 там зазвичай нема); підпис показує це фактичне значення без
% округлення (%.3g), не цільове.
hi = nan(1, numel(targetScales));
for j = 1:numel(targetScales)
    [~, hi(j)] = min(abs(scal - targetScales(j)));
end
hi = unique(hi, 'stable');   % якщо обидві цілі впали в один і той самий бін
end

% ------------------------------------------------------------------------
function renderWaveletPair(axScalo, axProf, comp, qLabel, S, cmap)
if comp.degenerate
    title(axScalo,'(degenerate profile)'); return;
end
b = comp.b; scal = comp.scal; A = comp.A; hi = comp.hi; coiScale = comp.coiScale;
hiCols = {S.lineRed, S.lineBlue, [0.15 0.65 0.30], [0.60 0.35 0.75]};   % до 4 рівнів, різні кольори

% ліва панель — скалограма, поза конусом впливу (COI) -- НЕ прозоро (дані
% лишаються видимі), а трохи РОЗМИТО (Gaussian blur), щоб позначити
% "менш надійно", не ховаючи саму скалограму під білим полем.
reliable = bsxfun(@le, scal(:), coiScale(:)');    % [nScales x nB], 1 = надійно (в межах COI)
sigmaPx = 2;                                       % м'яке розмиття, у пікселях матриці A
ksz = 2*ceil(2*sigmaPx)+1; kx = -floor(ksz/2):floor(ksz/2);
g = exp(-(kx.^2)/(2*sigmaPx^2)); g = g/sum(g);
Ablur = conv2(conv2(A, g, 'same'), g', 'same');
Adisp = A; Adisp(~reliable) = Ablur(~reliable);
im = imagesc(axScalo, b, scal, Adisp); set(axScalo,'YDir','normal');   % лінійна шкала Scale a (не log)
colormap(axScalo, cmap); cb = colorbar(axScalo);
cb.Label.String = '|W(a,b)|  (blurred = outside cone of influence)'; cb.Color = S.ink;
hold(axScalo,'on');
plot(axScalo, b, coiScale, '--', 'Color',[0.95 0.95 0.95], 'LineWidth',1.5, 'HandleVisibility','off');
plot(axScalo, b, coiScale, ':',  'Color',[0.10 0.10 0.10], 'LineWidth',1.0, 'HandleVisibility','off');
for j = 1:numel(hi)
    if isnan(hi(j)), continue; end
    yline(axScalo, scal(hi(j)), '-', 'Color','w', 'LineWidth',1.3, ...
          'Label',sprintf('a=%.3g',scal(hi(j))), 'LabelHorizontalAlignment','left', 'LabelColor','w');
end
xlabel(axScalo,'Translation b (px)','FontSize',S.labelSize); ylabel(axScalo,'Scale a','FontSize',S.labelSize);
title(axScalo, sprintf('Scalogram W(a,b) of %s  (dashed = cone-of-influence edge)', qLabel), ...
      'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
S.apply(axScalo);

% права панель — профілі на позначених масштабах (0.5x/1x/2x виміряної HWHM)
hold(axProf,'on');
for j = 1:numel(hi)
    if isnan(hi(j)), continue; end
    col = hiCols{mod(j-1,numel(hiCols))+1};
    plot(axProf, b, A(hi(j),:), 'Color',col, 'LineWidth',1.6, 'DisplayName',sprintf('a = %.3g', scal(hi(j))));
end
xlabel(axProf,'Translation b (px)','FontSize',S.labelSize); ylabel(axProf,'|W(a,b)|','FontSize',S.labelSize);
title(axProf, sprintf('Coefficients A(b) — %s', qLabel),'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
legend(axProf,'Location','northeast'); S.apply(axProf);
end
