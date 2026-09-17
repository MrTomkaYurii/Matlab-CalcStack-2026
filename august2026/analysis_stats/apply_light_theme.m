function apply_light_theme(fig)
% APPLY_LIGHT_THEME  Примусово робить фігуру світлою, контрастною та читабельною.
%   Вбиває темну тему MATLAB (чорний фон осей, світло-сірий текст).

if nargin < 1 || isempty(fig)
    fig = gcf;
end

set(fig, 'Color', 'w');

% Для MATLAB R2023b+ з підтримкою theme()
try
    theme(fig, 'light');
catch
end

% Усі осі (axes)
axs = findall(fig, 'Type', 'axes');
for i = 1:numel(axs)
    ax = axs(i);
    set(ax, 'Color', 'w', ...
            'XColor', 'k', ...
            'YColor', 'k', ...
            'ZColor', 'k', ...
            'GridColor', [0.8 0.8 0.8], ...
            'GridAlpha', 0.6);
    if isprop(ax, 'Title') && ~isempty(ax.Title)
        ax.Title.Color = 'k';
    end
    if isprop(ax, 'XLabel') && ~isempty(ax.XLabel)
        ax.XLabel.Color = 'k';
    end
    if isprop(ax, 'YLabel') && ~isempty(ax.YLabel)
        ax.YLabel.Color = 'k';
    end
end

% Усі легенди
legs = findall(fig, 'Type', 'legend');
for i = 1:numel(legs)
    set(legs(i), 'TextColor', 'k', 'Color', 'w', 'EdgeColor', [0.7 0.7 0.7]);
end

% Усі колірні шкали (colorbar)
cbs = findall(fig, 'Type', 'colorbar');
for i = 1:numel(cbs)
    set(cbs(i), 'Color', 'k');
end

% Загальний заголовок sgtitle та весь інший текст
allText = findall(fig, 'Type', 'text');
for i = 1:numel(allText)
    t = allText(i);
    if isprop(t, 'Tag') && strcmp(t.Tag, 'CellTextWhite')
        continue;
    end
    t.Color = 'k';
end

end
