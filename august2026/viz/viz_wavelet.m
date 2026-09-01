function viz_wavelet(D, meta, ctx, CFG)
% VIZ_WAVELET  Подання (3) за ескізом: 2x2 вейвлет W(a,b).
%   Панелі: [ скалограма |f| | профілі A(b) на кількох масштабах ;
%             скалограма Arg | профілі Arg ].
%   Будується у кожній colormap зі списку CFG.viz.colormaps (jet, gray).
%   Профіль беремо з карти за CFG.wavelet.profile; масштаби обмежені scaleRange.
%
%   Дві фізичні поправки (раніше були відсутні):
%   - Конус впливу (COI): за межами COI (краї профілю, великі масштаби)
%     CWT-коефіцієнти спотворені відсутністю даних за межею сигналу —
%     ця зона тепер притлумлена (AlphaData) і обведена лінією.
%   - Позначені масштаби (highlightScales) більше НЕ фіксовані [10,50]
%     (це були параметри старого СИНТЕТИЧНОГО симулятора, не реальних
%     даних) — рахуються з РЕАЛЬНО виміряної півширини АКФ (HWHM, та сама
%     величина, що на поданні 4B) цього самого профілю: 0.5x/1x/2x HWHM,
%     кілька рівнів. Якщо АКФ недоступна (4A/4B/Блок1 вимкнені) —
%     запасний варіант: CFG.wavelet.highlightScales.
%   Потребує Wavelet Toolbox (cwtfilterbank / wt).

S = viz_style();

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

hs = deriveHighlightScales(meta, CFG, quantity, cutDir, scal);
hi = nan(1,numel(hs));
for j = 1:numel(hs)
    [~,hi(j)] = min(abs(scal - hs(j)));
end

comp.degenerate = false;
comp.b = b; comp.scal = scal; comp.A = A;
comp.coiScale = coiScale; comp.hi = hi;
end

% ------------------------------------------------------------------------
function hs = deriveHighlightScales(meta, CFG, quantity, cutDir, scal)
% 0.5x / 1x / 2x виміряної HWHM АКФ цього самого профілю (той напрям, що
% CFG.wavelet.profile: OX або OY), тієї самої величини (mod/arg). Запасний
% варіант — CFG.wavelet.highlightScales, якщо АКФ не порахована.
hs = CFG.wavelet.highlightScales;
if isempty(meta.acfData) || ~isfield(meta.acfData, quantity)
    return;
end
entry = meta.acfData.(quantity);
if strcmpi(cutDir, 'OY')
    lag = entry.lagy;  cut = entry.acf(:, round(size(entry.acf,2)/2)).';
else
    lag = entry.lagx;  cut = entry.acf(round(size(entry.acf,1)/2), :);
end
hw = halfWidthEstimate(lag, cut);
if ~isfinite(hw) || hw <= 0
    return;
end
lo = min(scal); hi = max(scal);
hs = [0.5*hw, hw, 2*hw];
hs = hs(hs >= lo & hs <= hi);
if isempty(hs), hs = CFG.wavelet.highlightScales; end
end

function hw = halfWidthEstimate(lag, curve)
% Та сама логіка HWHM, що й viz_acf_cuts.m / viz_block1_summary.m.
[~, i0] = min(abs(lag));
peak = curve(i0); half = 0.5*peak;
hiLag = NaN;
for i = i0:numel(curve)-1
    if curve(i) >= half && curve(i+1) < half
        t = (half - curve(i)) / (curve(i+1) - curve(i));
        hiLag = lag(i) + t*(lag(i+1)-lag(i)); break;
    end
end
loLag = NaN;
for i = i0:-1:2
    if curve(i) >= half && curve(i-1) < half
        t = (half - curve(i)) / (curve(i-1) - curve(i));
        loLag = lag(i) + t*(lag(i-1)-lag(i)); break;
    end
end
if isnan(hiLag) && isnan(loLag), hw = NaN;
elseif isnan(hiLag), hw = 2*abs(loLag);
elseif isnan(loLag), hw = 2*abs(hiLag);
else, hw = hiLag - loLag;
end
end

% ------------------------------------------------------------------------
function renderWaveletPair(axScalo, axProf, comp, qLabel, S, cmap)
if comp.degenerate
    title(axScalo,'(degenerate profile)'); return;
end
b = comp.b; scal = comp.scal; A = comp.A; hi = comp.hi; coiScale = comp.coiScale;
hiCols = {S.lineRed, S.lineBlue, [0.15 0.65 0.30], [0.60 0.35 0.75]};   % до 4 рівнів, різні кольори

% ліва панель — скалограма, з притлумленою зоною поза конусом впливу (COI)
im = imagesc(axScalo, b, scal, A); set(axScalo,'YDir','normal'); set(axScalo,'YScale','log');
reliable = bsxfun(@le, scal(:), coiScale(:)');    % [nScales x nB], 1 = надійно (в межах COI)
alphaData = 0.30 + 0.70*double(reliable);          % поза COI — притлумлено, не приховано зовсім
set(im, 'AlphaData', alphaData);
colormap(axScalo, cmap); cb = colorbar(axScalo);
cb.Label.String = '|W(a,b)|  (dim = outside cone of influence)'; cb.Color = S.ink;
hold(axScalo,'on');
plot(axScalo, b, coiScale, '--', 'Color',[0.95 0.95 0.95], 'LineWidth',1.5, 'HandleVisibility','off');
plot(axScalo, b, coiScale, ':',  'Color',[0.10 0.10 0.10], 'LineWidth',1.0, 'HandleVisibility','off');
for j = 1:numel(hi)
    if isnan(hi(j)), continue; end
    col = hiCols{mod(j-1,numel(hiCols))+1};
    yline(axScalo, scal(hi(j)), '-', 'Color',col, 'LineWidth',1.3, ...
          'Label',sprintf('a=%.0f',scal(hi(j))), 'LabelHorizontalAlignment','left');
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
    plot(axProf, b, A(hi(j),:), 'Color',col, 'LineWidth',1.6, 'DisplayName',sprintf('a = %.0f', scal(hi(j))));
end
xlabel(axProf,'Translation b (px)','FontSize',S.labelSize); ylabel(axProf,'|W(a,b)|','FontSize',S.labelSize);
title(axProf, sprintf('Coefficients A(b) — %s', qLabel),'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
legend(axProf,'Location','northeast'); S.apply(axProf);
end
