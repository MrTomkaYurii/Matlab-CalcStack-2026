function M = viz_arg_cmap(cmap)
% VIZ_ARG_CMAP  Циклічна палітра для карт аргументу (рецензія 2: фаза
%   неперервна через 0/2pi, однаковий колір на обох кінцях).
%   cmap — назва з CFG.viz.colormaps: 'gray' -> циклічна сіра
%   (чорний -> білий -> чорний), будь-яка інша -> hsv.
%   Arg на картах — у [0, 2pi] (tp_visualize зводить mod 2pi).
n = 256;
if strcmpi(cmap, 'gray')
    t = linspace(0, 1, n).';
    g = 0.5 - 0.5*cos(2*pi*t);
    M = [g g g];
else
    M = hsv(n);
end
end
