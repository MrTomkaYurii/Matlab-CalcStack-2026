function A = article_style()
% ARTICLE_STYLE  Параметри оформлення "як у статті" (половинка рисунка 85 мм).
%   Значення перенесено 1:1 з проєкту рисунків статті PCMM
%   (C:\November 2026 - Paper\Проект рисунков.toml + scripts\build_figure.py),
%   щоб MATLAB будував ті самі рисунки без Inkscape.
%   Усі розміри — мм, кеглі — pt.

A.PT    = 25.4 / 72;      % 1 pt у мм
A.DIGIT = 0.556;          % ширина цифри Arial у частках кегля

% --- шрифт / лінії ---
A.font      = 'Arial';
A.fontPt    = 9;          % цифри осей і шкал, підписи
A.titlePt   = 10;         % заголовки карт |f| / Arg f — жирні
A.letterPt  = 10;         % літери панелей (a), (b) ...
A.lineMM    = 0.5 * A.PT; % рамки, осі (0.5 pt)
A.gridMM    = 0.25 * A.PT;
A.gridColor = [200 200 200] / 255;

% --- макет половинки ---
A.W       = 85;           % ширина рисунка
A.margin  = 0.5;
A.colGap  = 3;
A.rowGap  = 1.5;
A.histH   = 16;           % висота поля гістограми
A.tick    = 0.7;
A.pad     = 0.4;
A.cbGap   = 1.0;
A.cbW     = 1.8;          % ширина шкали кольору

% --- карти ---
A.cross       = true;     % білий хрестик у центрі
A.crossR      = 0.8;
A.crossMM     = 0.25;
A.insetZoom   = 4;        % вставка ×4
A.insetSize   = 0.36;     % сторона вставки як частка сторони карти
A.insetCenter = [0.30 0.30];   % центр збільшеного фрагмента (частки x, y від лівого нижнього кута)
A.insetLabelPt = 9;
A.insetSrcColor = [0 0 0];     % рамка ділянки-джерела вставки на карті — чорна
A.insetLabelColor = struct('mod', [1 1 1], 'arg', [0 0 0]);   % «×4» біла на модулі, чорна на аргументі
A.nanColor    = [1 1 1];
A.ptSize      = 1.5;      % площа точки скелетону WTMM (pt^2)

% --- криві (Fig2 переріз АКФ, Fig5 перерізи |W|, Fig6 D(q), f(h)) ---
A.curveColor = [0.20 0.35 0.75];
A.curveMM    = 0.9 * (25.4/72);          % 0.9 pt
A.hwColor    = [0.80 0.20 0.20];         % півширина АКФ — червоні пунктири
A.cutLoColor = [0.20 0.60 0.25];         % переріз |W| на малому масштабі — зелений
A.cutHiColor = [0.85 0.35 0.10];         % на великому — помаранчевий
A.acfK   = 6;      % Fig2: піввікно лагів = acfK x найбільша півширина АКФ (окремо |f| і Arg f)
A.acfMin = 8;      % px — не вужче

% --- достатність даних (без артефактів заповнення пропусків) ---
A.minProfileFrac = 0.5;   % Fig4–Fig6: частка СПРАВЖНІХ точок у профілі (інакше — «мало даних», без кривих)
A.minPairs       = 1000;  % Fig2–Fig3: пар справжніх точок на лагу 1 px (інакше — «мало даних»)
A.minPairsLag    = 30;    % Fig2: лаги, де пар менше, на карті АКФ — білі (оцінка ненадійна)

% --- кольори / шкали ---
A.modMap    = 'jet';      % модуль 0..1
A.argMap    = 'cet_c6';   % аргумент 0..2pi (циклічна)
A.modTicks  = [0 0.5 1];
A.modClipPct = 2.5;       % верхня межа модуля = перцентиль (100 - modClipPct) пулу обох вікон і обох елементів
A.argTicks  = [0 1 2];    % у частках pi

% --- гістограми ---
A.nbins     = 100;        % правило проєкту: 100 бінів
A.yDiv      = 6;          % 6 поділок осі sigma, підписи 0 / середина / верх
A.absColor  = hex2rgb('85a2da');
A.argColor  = hex2rgb('dca286');
A.edgeColor = hex2rgb('333333');
A.edgeMM    = 0.25 * A.PT;
A.modXTicks = [0 0.5 1];   A.modXMinor = [0.25 0.75];
A.argXTicks = [0 1 2];     A.argXMinor = [0.5 1.5];       % у частках pi

% --- похідні розміри (як Layout у build_figure.py) ---
fs = A.fontPt * A.PT;  fl = A.letterPt * A.PT;  ft = A.titlePt * A.PT;
A.fs = fs;  A.fl = fl;  A.ft = ft;
A.colW = (A.W - 2*A.margin - A.colGap) / 2;
A.colX = [A.margin, A.margin + A.colW + A.colGap];
A.mapL = A.tick + A.pad + 3*A.DIGIT*fs + 1.7 + 1.0*fs;          % зліва: поділки, стрілка, повернуте «y, pix»
clab   = 3;                                                     % найдовша мітка шкали: '0.5'
mapR   = A.cbGap + A.cbW + A.tick + A.pad + clab*A.DIGIT*fs;
A.S    = A.colW - A.mapL - mapR;                                % сторона карти
A.mapT = 1.35 * ft;
A.mapB = A.tick + A.pad + fs + 1.6 + 0.9*fs;      % +0.3 мм: підпис осі не торкається стрілки
A.letterH = 0.6 + fl;
A.mapH  = A.mapT + A.S + A.mapB + A.letterH;
A.histT = 1.3 * fs;
A.histB = A.tick + A.pad + fs + 0.6 + 1.2*fs;
A.histHH = A.histT + A.histH + A.histB + A.letterH;
A.H = 2*A.margin + 2*A.mapH + 2*A.histHH + 3*A.rowGap;
end

function c = hex2rgb(h)
c = [hex2dec(h(1:2)) hex2dec(h(3:4)) hex2dec(h(5:6))] / 255;
end
