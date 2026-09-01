function S = viz_style()
% VIZ_STYLE  Спільний вигляд усіх фігур (стиль за old/calc_2025_vis_DvotMM).
%   Білий фон, світла тема, читабельні шрифти, англомовні підписи.

S.titleSize = 14;   % загальний заголовок (sgtitle)
S.subSize   = 12;   % заголовок панелі
S.labelSize = 11;   % підписи осей
S.ink       = [0.12 0.12 0.12];   % колір тексту/осей
S.lineRed   = [0.85 0.10 0.10];   % масштаб a = 10
S.lineBlue  = [0.10 0.30 0.85];   % масштаб a = 50

S.light = @applyLight;   % примусово світла фігура з білим фоном
S.apply = @applyAxes;    % світлий стиль осей
end

% ------------------------------------------------------------------------
function applyLight(fig)
% Білий фон і світла тема (щоб фон не був чорним у тёмній темі MATLAB).
set(fig, 'Color', 'w');
try, theme(fig, 'light'); catch, end
end

function applyAxes(ax)
ink = [0.12 0.12 0.12];
set(ax, 'FontName','Helvetica', 'FontSize',11, 'Box','on', 'Layer','top', ...
        'Color','w', 'XColor',ink, 'YColor',ink, 'ZColor',ink, ...
        'GridColor',[0.35 0.35 0.35], 'GridAlpha',0.3);
grid(ax,'on');
try
    ax.Title.Color  = ink; ax.XLabel.Color = ink;
    ax.YLabel.Color = ink; ax.ZLabel.Color = ink;
catch, end
end
