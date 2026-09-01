function c = tp_level_color(cmap, lo, hi, v)
% TP_LEVEL_COLOR  Колір з colormap, що відповідає значенню v у діапазоні
%   [lo,hi] — ТОЙ САМИЙ колір, яким намальована лінія цього рівня контуру.
%   Підпис цим кольором (замість однакового чорного на всіх) дозволяє
%   однозначно зіставити число з конкретною лінією серед багатьох.

try
    table = feval(cmap, 256);
catch
    table = jet(256);
end
if hi > lo
    idx = round((v - lo)/(hi - lo) * 255) + 1;
else
    idx = 128;
end
idx = min(max(idx,1),256);
c = table(idx,:);
end
