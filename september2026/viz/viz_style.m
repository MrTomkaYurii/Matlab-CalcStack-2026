function S = viz_style(P)
% VIZ_STYLE  Спільний вигляд усіх фігур (стиль за old/calc_2025_vis_DvotMM).
%   Білий фон, світла тема, читабельні шрифти, англомовні підписи.
%
%   P (опційно) : struct із частковим/повним перевизначенням --
%   зазвичай CFG.style із cfg_LB_CB_rho_viz.m (кегль/шрифт/колір тексту
%   в ОДНОМУ місці, той самий принцип, що й paper_figures\cfg_figures.m
%   секція 7 "ШРИФТ/ЛІНІЇ"). Без аргументу -- ті самі значення за
%   замовчуванням, що були тут раніше (зворотна сумісність).

if nargin < 1 || isempty(P), P = struct(); end

S.fontName  = getOr(P, 'fontName',  'Helvetica');
S.titleSize = getOr(P, 'titleSize', 14);   % загальний заголовок (sgtitle)
S.subSize   = getOr(P, 'subSize',   12);   % заголовок панелі
S.labelSize = getOr(P, 'labelSize', 11);   % підписи осей
S.smallSize = getOr(P, 'smallSize', 10);   % компактні багатопанельні рисунки (level_bands і т.п.)
S.ink       = getOr(P, 'ink',       [0.12 0.12 0.12]);   % колір тексту/осей
S.lineRed   = getOr(P, 'lineRed',   [0.85 0.10 0.10]);   % масштаб a = 10
S.lineBlue  = getOr(P, 'lineBlue',  [0.10 0.30 0.85]);   % масштаб a = 50

S.light = @applyLight;                       % примусово світла фігура з білим фоном
S.apply = @(ax) applyAxes(ax, S.fontName, S.ink);   % світлий стиль осей
end

% ------------------------------------------------------------------------
function v = getOr(P, field, default)
if isfield(P, field) && ~isempty(P.(field)), v = P.(field); else, v = default; end
end

% ------------------------------------------------------------------------
function applyLight(fig)
% Білий фон і світла тема (щоб фон не був чорним у тёмній темі MATLAB).
set(fig, 'Color', 'w');
try, theme(fig, 'light'); catch, end
end

function applyAxes(ax, fontName, ink)
set(ax, 'FontName',fontName, 'FontSize',11, 'Box','on', 'Layer','top', ...
        'Color','w', 'XColor',ink, 'YColor',ink, 'ZColor',ink, ...
        'GridColor',[0.35 0.35 0.35], 'GridAlpha',0.3);
grid(ax,'on');
try
    ax.Title.Color  = ink; ax.XLabel.Color = ink;
    ax.YLabel.Color = ink; ax.ZLabel.Color = ink;
catch, end
end
