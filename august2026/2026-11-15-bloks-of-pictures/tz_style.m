function A = tz_style()
% TZ_STYLE  Оформлення рисунків ТЗ: як article_style, але кегль 10–11 pt
%   (ТЗ: «усі символи і цифри на рівні 10-11 кегля»). Похідні розміри перераховано
%   за тими самими формулами, що в article_style.m.
A = article_style();
A.fontPt   = 10;     % цифри осей і шкал, підписи
A.titlePt  = 11;     % заголовки панелей
A.letterPt = 11;     % літери (a), (b) ...
A.insetLabelPt = 10;
A.W = 175;           % 4 колонки — на всю ширину сторінки (як S1–S4 / Fig7)

fs = A.fontPt * A.PT;  fl = A.letterPt * A.PT;  ft = A.titlePt * A.PT;
A.fs = fs;  A.fl = fl;  A.ft = ft;
A.mapT    = 1.35 * ft;
A.mapB    = A.tick + A.pad + fs + 1.6 + 0.9*fs;
A.letterH = 0.6 + fl;
A.histT   = 1.3 * fs;
A.histB   = A.tick + A.pad + fs + 0.6 + 1.2*fs;
A.histH   = 18;      % трохи вище, ніж у статті (16), під більший кегль
A.acfYColor = [0.85 0.35 0.10];   % переріз АКФ по Δy (по Δx — A.curveColor)
end
