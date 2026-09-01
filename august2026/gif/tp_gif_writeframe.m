function tp_gif_writeframe(fig, gifPath, delay, isFirst)
% TP_GIF_WRITEFRAME  Дописує поточний стан фігури як кадр у GIF-файл.
%   Рендерить через exportgraphics (працює і для невидимих фігур, на
%   відміну від getframe) у тимчасовий PNG, конвертує в індексоване
%   зображення і додає в gifPath. Перший кадр (isFirst=true) створює файл.

tmpPng = [tempname '.png'];
exportgraphics(fig, tmpPng, 'Resolution', 110);
im = imread(tmpPng);
delete(tmpPng);
[imind, cm] = rgb2ind(im, 256);

if isFirst
    imwrite(imind, cm, gifPath, 'gif', 'LoopCount', Inf, 'DelayTime', delay);
else
    imwrite(imind, cm, gifPath, 'gif', 'WriteMode', 'append', 'DelayTime', delay);
end
end
