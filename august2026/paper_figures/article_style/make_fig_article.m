function n = make_fig_article(figTag, scope)
% MAKE_FIG_ARTICLE  Рисунки Fig1–Fig6 "як у статті" (половинка 85 мм, render_article_fig).
%   Кожне фазове вікно — окремий рисунок: елемент 1 (верхній рядок + нижній рядок),
%   під ним елемент 2. Колонки: |f| і Arg f.
%     Fig1 'raw'  карта |f| (0..1) / Arg f (0..2pi, CET-C6) + гістограми
%     Fig2 'acf'  2D-АКФ + 1D-переріз з півшириною
%     Fig3 'psd'  2D-спектр потужності log10 + гістограма
%     Fig4 'skel' вейвлет-скелетон (WTMM) + гістограма |W| у максимумах
%     Fig5 'wav'  скалограма |W(a,b)| + два перерізи при фіксованому a
%     Fig6 'mfr'  D(q) + спектр сингулярностей f(h), Delta h
%   Дані й обчислення — ті самі, що в paper_figures (tp_paper_read, paper_prep).
%   Межі кольору — спільні для всіх 8 вікон і обох елементів (окремо |f| і Arg f),
%   тож рисунки вікон порівнянні. Гістограми — справжні кількості точок.
%
%   figTag : 'Fig1' ... 'Fig6'
%   scope  : необов'язково — .pair ('fig02_f33f44'), .samples, .examples, .variants (теги),
%            .phases ([1 6]), .overwrite (типово false: готові PNG пропускаються —
%            нічний прогін можна перезапустити), .docx (типово true)
%   Вивід  : <outRoot>\FigN\png\<variant>\FigN.f33-f44.OX.heart.zrazok1.phase01.0-2pi.png
%            + Word-файли в <outRoot>\FigN\ (make_figures_docx.py; для Fig1 ще стат-моменти)

here = fileparts(mfilename('fullpath'));
addpath(here, fullfile(fileparts(here), 'common'), fileparts(here), ...
        fullfile(fileparts(fileparts(here)), 'core'));
if nargin < 2; scope = struct(); end
FIG0 = cfg_figures();
A = article_style();
outRoot = 'C:\August 2026-Results\Розрахунки - Скомпановані рисунки - Формат статті 09.11';
if isfield(FIG0.out, 'rootArticle'); outRoot = FIG0.out.rootArticle; end
if isfield(scope, 'outRoot'); outRoot = scope.outRoot; end      % напр. пробний прогін в іншу теку

KIND = struct('Fig1','raw', 'Fig2','acf', 'Fig3','psd', 'Fig4','skel', 'Fig5','wav', 'Fig6','mfr');
kind = KIND.(figTag);
num  = sscanf(figTag, 'Fig%d');
PH = phase_list(scope);

pairs = {sprintf('fig%02d_f33f44', num), sprintf('fig%02d_f23f24', num)};
if isfield(scope, 'pair'); pairs = cellstr(scope.pair); end
overwrite = isfield(scope, 'overwrite') && scope.overwrite;
n = 0;
for pi_ = 1:numel(pairs)
    FIG = apply_fig_params(FIG0, pairs{pi_});
    C = FIG.(pairs{pi_});
    samples  = pick(scope, 'samples',  C.samples);
    examples = pick(scope, 'examples', C.examples);
    variants = C.variants;
    if isfield(scope, 'variants')
        variants = variants(cellfun(@(v) any(strcmp(v.tag, scope.variants)), variants));
    end
    for si = 1:numel(samples)
        sTag = FIG.sampleTag{strcmp(FIG.sampleTag(:,1), samples{si}), 2};
        for xi = 1:numel(examples)
            for vi = 1:numel(variants)
                v = variants{vi};
                outDir = fullfile(outRoot, figTag, 'png', v.tag);
                base = arrayfun(@(p) sprintf('%s.%s-%s.%s.%s.zrazok%s.%s', figTag, C.elems{1}, C.elems{2}, ...
                    v.tag, sTag, examples{xi}, p.tag), PH, 'uni', 0);
                if ~overwrite && all(cellfun(@(b) isfile(fullfile(outDir, [b '.png'])), base))
                    fprintf('  [є] %s\n', regexprep(base{1}, '\.phase.*', '')); continue;
                end
                W = cell(1, numel(PH));
                try
                    for w = 1:numel(PH)
                        W{w} = tp_paper_read(FIG, samples{si}, examples{xi}, v, PH(w).glob);
                    end
                    Q = [];
                    if any(strcmp(kind, {'wav','skel','mfr'})); [W, Q] = pick_profiles(W, C.elems, A); end
                    W = paper_prep(W, C.elems, kind, FIG);
                    if any(strcmp(kind, {'acf','psd'})); [W, Q] = masked_acf_psd(W, C.elems, kind, A, FIG); end
                    W = attach_quality(W, C.elems, Q);
                catch ME
                    fprintf(2, '  [skip] %s / %s / %s / %s : %s\n', figTag, samples{si}, examples{xi}, v.tag, ME.message);
                    continue;
                end
                L = pooled_limits(W, C.elems, kind, A, FIG);
                for w = 1:numel(PH)
                    try
                        R.rows = build_rows(W{w}, C, kind, L, A, FIG);
                        figH = render_article_fig(R, A);
                        if ~exist(outDir, 'dir'); mkdir(outDir); end
                        exportgraphics(figH, fullfile(outDir, [base{w} '.png']), 'Resolution', 600, ...
                            'BackgroundColor','white', 'Padding','figure');
                        close(figH);
                        n = n + 1;
                        fprintf('  [ok] %s\n', base{w});
                    catch ME
                        fprintf(2, '  [fail] %s : %s\n', base{w}, ME.message);
                        close all force;
                    end
                end
            end
        end
    end
end
if n > 0 && (~isfield(scope, 'docx') || scope.docx)
    make_docx(here, fullfile(outRoot, figTag), strcmp(figTag, 'Fig1'));
end
end

% =====================================================================
function rows = build_rows(D, C, kind, L, A, FIG)
% 4 рядки: (верх, низ) для елемента 1, потім для елемента 2; колонки |f| | Arg f
rows = {};  k = 0;
for e = 1:2
    top = cell(1, 2);  bot = cell(1, 2);
    for ci = 1:2
        comp = {'mod','arg'};  comp = comp{ci};
        P = D.prep.(C.elems{e}).(comp);
        [top{ci}, bot{ci}] = panels(P, D.data.(C.elems{e}).(comp), comp, C.elemTex{e}, kind, L.(comp), A, FIG, D.ax);
        if isfield(P, 'quality') && ~P.quality.ok        % замало справжніх даних -> без кривих/карт, лише напис
            [top{ci}, bot{ci}] = deal(blank(top{ci}, P.quality.msg), blank(bot{ci}, P.quality.msg));
        end
    end
    for ci = 1:2;  k = k + 1;  top{ci}.letter = char('a' + k - 1);  end
    for ci = 1:2;  k = k + 1;  bot{ci}.letter = char('a' + k - 1);  end
    rows(end+1:end+2) = {top, bot}; %#ok<AGROW>
end
end

% =====================================================================
function [T, B] = panels(P, M, comp, elemTex, kind, lim, A, FIG, ax)
isMod = strcmp(comp, 'mod');
if isMod
    ttl = ['|' elemTex '|'];   col = A.absColor;
else
    ttl = ['Arg ' elemTex];    col = A.argColor;
end
pixX = '\itx\rm, pix';   pixY = '\ity\rm, pix';
T = map_base(ttl);
switch kind
    case 'raw'
        [ny, nx] = size(M);
        T.xr = [0 nx];  T.yr = [0 ny];
        [T.xt, T.xtl] = ticks_lab([0 nx/2 nx]);  [T.yt, T.ytl] = ticks_lab([0 ny/2 ny]);
        T.xlab = pixX;  T.ylab = pixY;  T.cross = true;  T.inset = comp;
        if numel(ax.x) == nx && ax.x(1) < 0          % generalized: карта рознесень, осі Δx, Δy = -M..M
            T.xr = [ax.x(1)-0.5, ax.x(end)+0.5];  T.yr = [ax.y(1)-0.5, ax.y(end)+0.5];
            s = nice_step(max(ax.x) * 0.7, true);
            [T.xt, T.xtl] = ticks_lab([-s 0 s]);  T.yt = T.xt;  T.ytl = T.xtl;
            T.xlab = '\Delta\itx\rm, pix';  T.ylab = '\Delta\ity\rm, pix';
        end
        if isMod
            T.img = M / lim;  T.lim = [0 1];  T.cmap = jet(256);
            [T.ct, T.ctl] = ticks_lab(A.modTicks);
            B = hist_spec(T.img, [0 1], A.modXTicks, A.modXMinor, col, ttl);
        else
            T.img = mod(M, 2*pi);  T.lim = [0 2*pi];  T.cmap = cet_c6(256);
            T.ct = A.argTicks*pi;  T.ctl = pi_labels(A.argTicks);
            B = hist_spec(T.img, [0 2*pi], A.argXTicks*pi, A.argXMinor*pi, col, ttl);
            B.xtl = pi_labels(A.argXTicks);
        end

    case 'acf'
        Wl = lim;                                   % піввікно лагів під ширину АКФ (pooled_limits)
        kx = abs(P.x) <= Wl;  ky = abs(P.y) <= Wl;
        T.img = P.img(ky, kx);  T.lim = [0 1];  T.cmap = jet(256);
        T.xr = [-Wl-0.5, Wl+0.5];  T.yr = T.xr;
        s = nice_step(Wl * 0.7, true);
        [T.xt, T.xtl] = ticks_lab([-s 0 s]);  T.yt = T.xt;  T.ytl = T.xtl;
        [T.ct, T.ctl] = ticks_lab([0 0.5 1]);
        T.xlab = '\Delta\itx\rm, pix';  T.ylab = '\Delta\ity\rm, pix';
        T.contour = FIG.acf.hwLevel;
        kc = abs(P.cutLag) <= Wl;
        B = curve_base('ACF', '\Delta\itx\rm, pix');
        B.lines = cline(P.cutLag(kc), P.cutCurve(kc), A.curveColor, '-', A.curveMM / A.PT);
        B.lines(2) = cline([-Wl Wl], [1 1]*FIG.acf.hwLevel, [0.45 0.45 0.45], '--', 0.6);
        for xx = [P.loLag P.hiLag]
            if isfinite(xx) && abs(xx) < Wl
                B.lines(end+1) = cline([xx xx], [0 FIG.acf.hwLevel], A.hwColor, ':', 0.9);
            end
        end
        B.xl = [-Wl Wl];  B.yl = [0 1];  B.xt = T.xt;  B.xtl = T.xtl;
        [B.yt, B.ytl] = ticks_lab([0 0.5 1]);

    case 'psd'
        T.img = P.img;  T.lim = lim;  T.cmap = jet(256);
        d = P.x(2) - P.x(1);
        T.xr = [P.x(1)-d/2, P.x(end)+d/2];  d = P.y(2) - P.y(1);  T.yr = [P.y(1)-d/2, P.y(end)+d/2];
        s = nice_step(max(abs(T.xr)) * 0.7, true);
        [T.xt, T.xtl] = ticks_lab([-s 0 s]);  T.yt = T.xt;  T.ytl = T.xtl;
        [T.ct, T.ctl] = ticks_lab(nice_ticks(lim, 3));
        T.xlab = '\itk_x\rm, 1/pix';  T.ylab = '\itk_y\rm, 1/pix';
        xt = nice_ticks(lim, 3);
        B = hist_spec(P.histSrc, lim, xt, mids(xt), col, 'log_{10} PSD');

    case 'skel'
        T.img = [];  T.lim = lim;  T.cmap = jet(256);
        T.pts = struct('x', P.skB, 'y', P.skA, 'v', P.skH);
        N = P.x(2);
        T.xr = [0 N];  T.yr = [P.y(1) P.y(2)];
        [T.xt, T.xtl] = ticks_lab([0 N/2 N]);  [T.yt, T.ytl] = ticks_lab(nice_ticks(T.yr, 3));
        T.xlab = '\itb\rm, pix';  T.ylab = '\ita\rm, pix';
        [T.ct, T.ctl, T.cmult] = scaled_ticks(lim);
        xt = nice_ticks(lim, 3);
        [~, xtl, mx] = scaled_ticks(lim);
        nm = '|\itW\rm| in WTMM';  if mx ~= 0; nm = sprintf('%s, \\times10^{%d}', nm, mx); end
        B = hist_spec(P.histSrc, lim, xt, mids(xt), col, nm);  B.xtl = xtl;

    case 'wav'
        [a, o] = sort(P.y(:));  Aw = P.img(o, :);
        aU = linspace(a(1), a(end), 240).';
        T.img = interp1(a, Aw, aU, 'linear');  T.lim = lim;  T.cmap = jet(256);
        N = numel(P.x);
        T.xr = [0 N];  T.yr = [a(1) a(end)];
        [T.xt, T.xtl] = ticks_lab([0 N/2 N]);  [T.yt, T.ytl] = ticks_lab(nice_ticks(T.yr, 3));
        T.xlab = '\itb\rm, pix';  T.ylab = '\ita\rm, pix';
        [T.ct, T.ctl, T.cmult] = scaled_ticks(lim);
        T.lines = cline([0 N], [1 1]*P.wcutALo, A.cutLoColor, '--', 0.75);
        T.lines(2) = cline([0 N], [1 1]*P.wcutAHi, A.cutHiColor, '--', 0.75);
        top = max([P.wcutLo(:); P.wcutHi(:); eps]);
        yl = [0 top * 1.08];
        [yt, ytl, ym] = scaled_ticks(yl);
        B = curve_base('|\itW\rm|', '\itb\rm, pix');
        B.lines = cline(P.wcutB, P.wcutLo, A.cutLoColor, '-', A.curveMM / A.PT);
        B.lines(2) = cline(P.wcutB, P.wcutHi, A.cutHiColor, '-', A.curveMM / A.PT);
        B.xl = [0 N];  B.yl = yl;  B.xt = T.xt;  B.xtl = T.xtl;  B.yt = yt;  B.ytl = ytl;  B.ymult = ym;
        B.legend = {sprintf('%.1f', P.wcutALo), A.cutLoColor; ...
                    sprintf('%.1f', P.wcutAHi), A.cutHiColor};
        B.legendTitle = '\ita\rm:';

    case 'mfr'
        MF = P.mf;
        T = curve_base('\itD\rm(\itq\rm)', '\itq');  T.title = ttl;
        B = curve_base('\itf\rm(\ith\rm)', '\ith');
        if isempty(MF) || MF.degenerate
            [T.xl, T.yl, T.xt, T.xtl, T.yt, T.ytl] = deal([0 1], [0 1], [], {}, [], {});
            [B.xl, B.yl, B.xt, B.xtl, B.yt, B.ytl] = deal([0 1], [0 1], [], {}, [], {});
            B.annot = 'нема даних';
        else
            ln = A.curveMM / A.PT;
            T.lines = cline(MF.q, MF.D, A.curveColor, '-', ln, 'o', 2.2);
            T.xl = [min(MF.q) max(MF.q)];  [T.xt, T.xtl] = ticks_lab(nice_ticks(T.xl, 3));
            [T.yl, T.yt, T.ytl] = auto_axis(MF.D);
            vv = isfinite(MF.h) & isfinite(MF.f);
            [hs, si] = sort(MF.h(vv));  ff = MF.f(vv);  ff = ff(si);
            [hs, iu] = unique(hs, 'stable');  ff = ff(iu);
            B.lines = cline(hs, ff, A.curveColor, 'none', ln, 'o', 2.2);
            if numel(hs) >= 4
                hg = linspace(hs(1), hs(end), 60);
                fg = smoothdata(interp1(hs, ff, hg, 'pchip'), 'movmean', 3);
                B.lines(2) = cline(hg, fg, A.curveColor, '-', ln);
            end
            [B.xl, B.xt, B.xtl] = auto_axis(hs);
            [B.yl, B.yt, B.ytl] = auto_axis(ff);
            B.annot = sprintf('\\Delta\\ith\\rm = %.2f', MF.deltaH);
        end
end
end

function p = blank(p, msg)
p.note = msg;
switch p.type
    case 'map',   p.img = [];  p.pts = [];  p.lines = p.lines([]);  p.contour = [];  p.inset = '';
    case 'hist',  p.v = [];
    case 'curve'                                   % шкали, зняті з даних, яких немає, — прибрати
        p.lines = p.lines([]);  p.legend = {};  p.legendTitle = '';  p.annot = '';
        p.yt = [];  p.ytl = {};  p.ymult = 0;
        if strcmp(p.name, '\ith'); p.xt = [];  p.xtl = {}; end
end
end

% =====================================================================
function [W, Q] = pick_profiles(W, elems, A)
% Fig4–Fig6 рахуються по ОДНОМУ рядку карти (центральному, FIG.wav.profile = 'center_row'),
% пропуски в ньому paper_prep заповнює прямими лініями -> «трикутники»-артефакти.
% Якщо в центральному рядку замало справжніх точок, беремо рядок, де їх найбільше
% (підставляємо його на місце центрального); якщо й там < A.minProfileFrac — панель «мало даних».
Q = cell(size(W));
for w = 1:numel(W)
    for e = 1:numel(elems)
        for comp = {'mod','arg'}
            M = W{w}.data.(elems{e}).(comp{1});
            cr = round(size(M,1)/2);  N = size(M,2);
            n = nnz(isfinite(M(cr,:)));
            if n / N < A.minProfileFrac
                [nb, rb] = max(sum(isfinite(M), 2));
                if nb > n; M(cr,:) = M(rb,:); n = nb; end
                W{w}.data.(elems{e}).(comp{1}) = M;
            end
            ok = n / N >= A.minProfileFrac;
            Q{w}.(elems{e}).(comp{1}) = struct('ok', ok, ...
                'msg', sprintf('мало даних|%d точок', n));
        end
    end
end
end

function [W, Q] = masked_acf_psd(W, elems, kind, A, FIG)
% Fig2–Fig3: АКФ лише по парах СПРАВЖНІХ точок (пропуски не заповнюються середнім).
% Сума добутків на лагу ділиться на кількість таких пар і множиться на кількість пар повної карти,
% тому на повній карті результат тотожний tp_acf_psd ('fast'); спектр — з цієї АКФ (Вінер–Хінчин).
Q = cell(size(W));
for w = 1:numel(W)
    for e = 1:numel(elems)
        for comp = {'mod','arg'}
            M = W{w}.data.(elems{e}).(comp{1});
            m = isfinite(M);  [Mr, Nc] = size(M);  Mp = 2*Mr - 1;  Np = 2*Nc - 1;
            v = zeros(Mr, Nc);
            if any(m(:)); v(m) = M(m) - mean(M(m)); end
            num  = fftshift(real(ifft2(abs(fft2(v, Mp, Np)).^2)));
            cnt  = fftshift(round(real(ifft2(abs(fft2(double(m), Mp, Np)).^2))));
            full = fftshift(round(real(ifft2(abs(fft2(ones(Mr, Nc), Mp, Np)).^2))));
            acfU = num .* full ./ max(cnt, 1);
            pairs1 = cnt(Mr, Nc + 1);
            P = W{w}.prep.(elems{e}).(comp{1});
            lagx = -(Nc-1):(Nc-1);  lagy = -(Mr-1):(Mr-1);
            if strcmp(kind, 'acf')
                a = acfU;  a(cnt < A.minPairsLag) = NaN;
                a = max(a / acfU(Mr, Nc), 0);
                P.img = a;  P.x = lagx;  P.y = lagy;
                P.cutLag = lagx;  cv = a(Mr, :);  P.cutCurve = cv;
                cv(~isfinite(cv)) = 0;
                [P.Lcorr, P.loLag, P.hiLag] = tp_acf_hwhm(lagx, cv);
            else
                a0 = acfU;  a0(cnt < 1) = 0;
                psd = fftshift(abs(fft2(ifftshift(a0)))) / (Mr * Nc);
                fx = ((0:Np-1) - floor(Np/2)) / Np;  fy = ((0:Mp-1) - floor(Mp/2)) / Mp;
                [~, ix0] = min(abs(fx));  [~, iy0] = min(abs(fy));
                psd(iy0, ix0) = NaN;                                   % DC (сигнал центровано)
                Z = psd;  if FIG.psd.log; Z = log10(psd + realmin); end
                fr = FIG.psd.cropFrac;  kx = abs(fx) <= fr*0.5;  ky = abs(fy) <= fr*0.5;
                P.img = Z(ky, kx);  P.x = fx(kx);  P.y = fy(ky);
                P.histSrc = P.img(isfinite(P.img));
            end
            W{w}.prep.(elems{e}).(comp{1}) = P;
            Q{w}.(elems{e}).(comp{1}) = struct('ok', pairs1 >= A.minPairs, ...
                'msg', sprintf('мало даних|%.1f%% точок', 100 * mean(m(:))));
        end
    end
end
end

function W = attach_quality(W, elems, Q)
for w = 1:numel(W)
    for e = 1:numel(elems)
        for comp = {'mod','arg'}
            q = struct('ok', true, 'msg', '');
            if ~isempty(Q); q = Q{w}.(elems{e}).(comp{1}); end
            W{w}.prep.(elems{e}).(comp{1}).quality = q;
        end
    end
end
end

% =====================================================================
function L = pooled_limits(W, elems, kind, A, FIG)
% спільні межі на всі вікна й обидва елементи — окремо |f| і Arg f
for comp = {'mod','arg'}
    if strcmp(kind, 'acf')
        % піввікно лагів = acfK півширин (найбільша серед 8 вікон і 2 елементів; вироджені — ні)
        Ls = [];  maxLag = inf;
        for w = 1:numel(W)
            for e = 1:numel(elems)
                P = W{w}.prep.(elems{e}).(comp{1});
                maxLag = min(maxLag, max(abs(P.x)));
                if ~P.quality.ok; continue; end
                if isfinite(P.Lcorr) && P.Lcorr > 0; Ls(end+1) = P.Lcorr; end %#ok<AGROW>
            end
        end
        ok = Ls < 0.25 * maxLag;                     % майже сталі карти (АКФ не спадає) не роздувають вікно,
        if any(ok); Ls = Ls(ok); end                 % якщо є нормальні; інакше (generalized — широка АКФ) беремо всі
        Wl = A.acfMin;  if ~isempty(Ls); Wl = max(A.acfMin, ceil(A.acfK * max(Ls))); end
        L.(comp{1}) = min(Wl, maxLag);
        continue;
    end
    pool = [];
    for w = 1:numel(W)
        for e = 1:numel(elems)
            P = W{w}.prep.(elems{e}).(comp{1});
            if ~P.quality.ok; continue; end              % «мало даних» не впливає на шкали
            switch kind
                case 'raw',  x = W{w}.data.(elems{e}).(comp{1});
                case 'skel', x = P.skH;
                otherwise,   x = P.histSrc;
            end
            x = x(:);  pool = [pool; x(isfinite(x))]; %#ok<AGROW>
        end
    end
    if isempty(pool); pool = [0; 1]; end
    switch kind
        case 'raw',  lim = prctile(pool, 100 - A.modClipPct);           % |f| ділиться на це -> 0..1
        case 'psd',  lim = prctile(pool, [FIG.psd.clipPct, 100 - FIG.psd.clipPct]);
        case {'wav','skel'}, lim = [0, prctile(pool, 100 - FIG.wav.clipPct)];
        otherwise,   lim = [0 1];
    end
    if numel(lim) == 2 && ~(lim(2) > lim(1)); lim = lim(1) + [0 1]; end
    L.(comp{1}) = lim;
end
end

% =====================================================================
function T = map_base(ttl)
T = struct('type','map', 'title',ttl, 'img',[], 'xr',[0 1], 'yr',[0 1], 'xt',[], 'xtl',{{}}, ...
    'yt',[], 'ytl',{{}}, 'cmap',jet(256), 'lim',[0 1], 'ct',[], 'ctl',{{}}, 'cmult',0, ...
    'xlab','', 'ylab','', 'cross',false, 'inset','', 'contour',[], ...
    'lines',cline([],[],[0 0 0],'-',0.5), 'pts',[], 'letter','');
T.lines = T.lines([]);
end

function B = curve_base(ylab, name)
B = struct('type','curve', 'title','', 'lines',cline([],[],[0 0 0],'-',0.5), 'xl',[0 1], 'yl',[0 1], ...
    'xt',[], 'xtl',{{}}, 'yt',[], 'ytl',{{}}, 'ylab',ylab, 'ymult',0, 'name',name, ...
    'legend',{{}}, 'legendTitle','', 'annot','', 'grid',true, 'letter','');
B.lines = B.lines([]);
end

function L = cline(x, y, color, style, width, marker, msize)
if nargin < 6; marker = ''; end
if nargin < 7; msize = []; end
L = struct('x',x, 'y',y, 'color',color, 'style',style, 'width',width, 'marker',marker, 'msize',msize);
end

function B = hist_spec(v, xl, xt, xm, color, name)
[~, xtl] = ticks_lab(xt);
B = struct('type','hist', 'v',v, 'xl',xl, 'xt',xt, 'xtl',{xtl}, 'xm',xm, 'color',color, ...
    'name',name, 'nbins',[], 'letter','');
end

function [t, l] = ticks_lab(t)
l = arrayfun(@(x) sprintf('%g', round(x, 6)), t, 'uni', 0);
end

function [t, l, ex] = scaled_ticks(lim)
% поділки в межах lim; дрібні/великі значення -> підписи в одиницях 10^ex
t = nice_ticks(lim, 3);
m = max(abs(lim));
ex = 0;  if m > 0 && (m < 1e-2 || m >= 1e4); ex = floor(log10(m)); end
l = arrayfun(@(x) sprintf('%g', round(x / 10^ex, 6)), t, 'uni', 0);
end

function t = nice_ticks(lim, n)
% «круглий» крок 1/2/2.5/5 x 10^k: найменший, при якому в межах lim не більше 4 поділок
s = nice_step((lim(2) - lim(1)) / n, true);
t = (ceil(lim(1)/s - 1e-9) : floor(lim(2)/s + 1e-9)) * s;
while numel(t) > 4
    s = nice_step(s * 1.01, false);
    t = (ceil(lim(1)/s - 1e-9) : floor(lim(2)/s + 1e-9)) * s;
end
t(abs(t) < s*1e-9) = 0;
end

function s = nice_step(x, down)
% «кругле» 1/2/2.5/5 x 10^k: найближче не більше x (down) або >= x
e = floor(log10(x));  m = x / 10^e;
c = [1 2 2.5 5 10];
if down; s = c(find(c <= m + 1e-9, 1, 'last')) * 10^e;
else;    s = c(find(c >= m - 1e-9, 1, 'first')) * 10^e;
end
end

function [lim, t, l] = auto_axis(v)
v = v(isfinite(v));
if isempty(v); lim = [0 1]; [t, l] = ticks_lab([0 0.5 1]); return; end
lo = min(v);  hi = max(v);
if hi <= lo; hi = lo + 1; end
lim = [lo hi] + [-1 1] * 0.06 * (hi - lo);        % дані + 6% поля, без «круглого» розширення
[t, l] = ticks_lab(nice_ticks(lim, 3));
end

function m = mids(t)
m = (t(1:end-1) + t(2:end)) / 2;
end

function labs = pi_labels(k)
labs = cell(size(k));
for i = 1:numel(k)
    if k(i) == 0, labs{i} = '0';
    elseif k(i) == 1, labs{i} = char(960);                  % π з Arial (прямий)
    else, labs{i} = sprintf('%g%s', k(i), char(960));
    end
end
end

function PH = phase_list(scope)
% усі 8 фазових вікон (phase_01 = 0–2pi ... phase_08 = 0–0.25pi), або scope.phases
phases = 1:8;
if isfield(scope, 'phases'); phases = scope.phases; end
PH = struct('glob', {}, 'tag', {});
for k = phases
    PH(end+1) = struct('glob', sprintf('phase_%02d_*', k), ...
                       'tag',  sprintf('phase%02d.0-%gpi', k, 2 - 0.25*(k-1))); %#ok<AGROW>
end
end

function x = pick(s, f, d)
if isfield(s, f); x = s.(f); else; x = d; end
end

function make_docx(here, figDir, withStats)
% Word-файли в теці FigN: тканина x алгоритм (рисунки; для Fig1 — ще стат-моменти поруч)
scripts = {'make_figures_docx.py'};
if withStats; scripts{end+1} = 'make_fig1_stats_docx.py'; end
for py = scripts
    st = system(sprintf('python "%s" "%s"', fullfile(here, py{1}), figDir));
    if st ~= 0; fprintf(2, '  [docx] помилка: %s\n', py{1}); end
end
end
