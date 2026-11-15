function [rows, file] = tz_fig_grid(FIG, A, b, figNo, sub, kind, cols, outDir, T)
% TZ_FIG_GRID  Рис.4–8 блоку: 4 колонки × 4 рядки.
%   Рядок 1 — карти, рядок 2 — гістограми (як Fig1 статті),
%   рядки 3–4 — за kind (як Fig2–Fig5 статті, з тим самим кодом панелей):
%     'acf'  2D-АКФ + ОРТОГОНАЛЬНІ перерізи АКФ (Δx — синій, Δy — помаранчевий) з півшириною
%     'psd'  2D-спектр потужності log10 + гістограма
%     'wav'  скалограма |W(a,b)| + перерізи при a = FIG.wav.cutScales (10 і 55)
%     'skel' скелетон WTMM + гістограма |W| у максимумах
%   cols : struct-масив з 4 колонок: .example .algo .win .elem .comp ('mod'|'arg') .tag (дописка до заголовка)
%   Межі кольору / осей — спільні для колонок з однаковою компонентою (|f| або Arg).
%   rows : стат-моменти показаних розподілів (див. tz_stats).

api = make_fig_article('api');
file = fullfile(outDir, sprintf('Рис%d.png', figNo));
csvf = fullfile(outDir, sprintf('Рис%d.stats.csv', figNo));
rows = {};
if ~T.overwrite && isfile(file) && isfile(csvf)
    rows = readcell(csvf, 'Encoding','UTF-8');  rows = rows(2:end, :);
    fprintf('  [є] %s\n', file);  return;
end

nc = numel(cols);
[WR, WK, DD] = deal(cell(1, nc));
for c = 1:nc
    s = cols(c);  e = s.elem;
    D = tz_read(FIG, b.sample, s.example, s.algo, s.win);
    DD{c} = D;
    Wr = paper_prep({D}, {e}, 'raw', FIG);
    WR{c} = one(api.attach_quality(Wr, {e}, []), e);
    Wk = {D};  Q = [];
    if any(strcmp(kind, {'wav','skel'})); [Wk, Q] = api.pick_profiles(Wk, {e}, A); end
    Wk = paper_prep(Wk, {e}, kind, FIG);
    if any(strcmp(kind, {'acf','psd'})); [Wk, Q] = api.masked_acf_psd(Wk, {e}, kind, A, FIG); end
    Wk = api.attach_quality(Wk, {e}, Q);
    if strcmp(kind, 'acf'); Wk{1} = add_ycut(Wk{1}, e); end
    WK{c} = one(Wk, e);
end
Lr = api.pooled_limits(WR, {'el'}, 'raw', A, FIG);
Lk = api.pooled_limits(WK, {'el'}, kind, A, FIG);

R.W = A.W;  R.colGap = 1.2;
R.rows = repmat({cell(1, nc)}, 1, 4);
meta0 = struct('block',b.id, 'sub',sub, 'fig',sprintf('Рис.%d', figNo), 'col','', ...
    'sample',b.sample, 'example','', 'algo','', 'win',NaN, 'elem','');
for c = 1:nc
    s = cols(c);  comp = s.comp;  M = WR{c}.data.el.(comp);
    tex = sprintf('f_{%s}', s.elem(2:3));
    Pr = WR{c}.prep.el.(comp);  Pk = WK{c}.prep.el.(comp);
    [T1, B1] = api.panels(Pr, M, comp, tex, 'raw', Lr.(comp), A, FIG, DD{c}.ax);
    [T2, B2] = api.panels(Pk, M, comp, tex, kind, Lk.(comp), A, FIG, DD{c}.ax);
    if strcmp(kind, 'acf')
        Wl = Lk.(comp);
        s = tick_step(0.85 * Wl);                 % у 4 колонках поле вужче — поділки ближче до країв,
        [T2.xt, T2.xtl] = api.ticks_lab([-s 0 s]);  % щоб «-10», «0», «10» не злипались
        [T2.yt, T2.ytl] = deal(T2.xt, T2.xtl);  [B2.xt, B2.xtl] = deal(T2.xt, T2.xtl);
        if Pk.quality.ok
            kc = abs(Pk.cutLagY) <= Wl;
            B2.lines(end+1) = api.cline(Pk.cutLagY(kc), Pk.cutCurveY(kc), A.acfYColor, '-', A.curveMM / A.PT);
            B2.legend = {[char(916) 'x'], A.curveColor; [char(916) 'y'], A.acfYColor};
        end
        B2.name = '\Delta\itx\rm, \Delta\ity\rm, pix';
    end
    if ~any(isfinite(M(:)))
        msg = 'порожній|канал';
        [T1, B1, T2, B2] = deal(api.blank(T1, msg), api.blank(B1, msg), api.blank(T2, msg), api.blank(B2, msg));
    elseif ~Pk.quality.ok
        [T2, B2] = deal(api.blank(T2, Pk.quality.msg), api.blank(B2, Pk.quality.msg));
    end
    T1.title = [T1.title s.tag];
    if isfield(T2, 'title') && ~isempty(T2.title); T2.title = [T2.title s.tag]; end
    P4 = {T1, B1, T2, B2};
    for r = 1:4
        P4{r}.letter = char('a' + (r-1)*nc + c - 1);
        R.rows{r}{c} = P4{r};
    end

    % ---- стат-моменти показаних розподілів
    m = meta0;  m.col = sprintf('%d', c);  m.example = s.example;  m.algo = s.algo;
    m.win = s.win;  m.elem = s.elem;
    isArg = strcmp(comp, 'arg');
    if isArg
        rows(end+1, :) = tz_stats(m, 'карта Arg (кругові)', mod(M, 2*pi), true); %#ok<AGROW>
    else
        rows(end+1, :) = tz_stats(m, 'карта |f|', M, false); %#ok<AGROW>
    end
    ok = Pk.quality.ok && any(isfinite(M(:)));
    cq = @(x) x(:) .* (ok ./ ok);      % NaN, якщо «мало даних»
    nm = {'|f|', 'Arg'};  nm = nm{1 + isArg};
    switch kind
        case 'acf'
            Wl = Lk.(comp);
            kx = abs(Pk.cutLag) <= Wl;  ky = abs(Pk.cutLagY) <= Wl;
            rows(end+1, :) = tz_stats(m, sprintf('АКФ %s, переріз Δx', nm), cq(Pk.cutCurve(kx)), false, ...
                sprintf('L(Δx) = %.2f px', Pk.Lcorr)); %#ok<AGROW>
            rows(end+1, :) = tz_stats(m, sprintf('АКФ %s, переріз Δy', nm), cq(Pk.cutCurveY(ky)), false, ...
                sprintf('L(Δy) = %.2f px', Pk.LcorrY)); %#ok<AGROW>
        case 'psd'
            rows(end+1, :) = tz_stats(m, sprintf('log10 PSD %s', nm), cq(Pk.histSrc), false); %#ok<AGROW>
        case 'wav'
            rows(end+1, :) = tz_stats(m, sprintf('|W| %s, a = %g', nm, FIG.wav.cutScales(1)), cq(Pk.wcutLo), false, ...
                sprintf('a(факт.) = %.2f px', Pk.wcutALo)); %#ok<AGROW>
            rows(end+1, :) = tz_stats(m, sprintf('|W| %s, a = %g', nm, FIG.wav.cutScales(2)), cq(Pk.wcutHi), false, ...
                sprintf('a(факт.) = %.2f px', Pk.wcutAHi)); %#ok<AGROW>
        case 'skel'
            rows(end+1, :) = tz_stats(m, sprintf('скелетон %s: |W| у WTMM', nm), cq(Pk.skH), false); %#ok<AGROW>
    end
end

if ~exist(outDir, 'dir'); mkdir(outDir); end
h = render_article_fig(R, A);
exportgraphics(h, file, 'Resolution', T.dpi, 'BackgroundColor','white', 'Padding','figure');
close(h);
tz_write_csv(csvf, rows);
fprintf('  [ok] %s\n', file);
end

% =====================================================================
function C = one(W, e)
% {D з .data.(e) / .prep.(e)} -> struct з полем 'el' (щоб pooled_limits бачив усі колонки разом)
C.data.el = W{1}.data.(e);
C.prep.el = W{1}.prep.(e);
end

function s = tick_step(x)
% найбільший «круглий» крок 1 / 2 / 2.5 / 5 x 10^k, що не перевищує x
e = floor(log10(x));  c = [1 2 2.5 5 10] * 10^e;
s = c(find(c <= x * (1 + 1e-9), 1, 'last'));
end

function D = add_ycut(D, e)
% ортогональний переріз 2D-АКФ по Δy (по Δx його вже дає masked_acf_psd) + півширина
for comp = {'mod','arg'}
    P = D.prep.(e).(comp{1});
    [~, ix0] = min(abs(P.x));
    cv = P.img(:, ix0).';
    P.cutLagY = P.y;  P.cutCurveY = cv;
    cv(~isfinite(cv)) = 0;
    P.LcorrY = tp_acf_hwhm(P.y, cv);
    D.prep.(e).(comp{1}) = P;
end
end
