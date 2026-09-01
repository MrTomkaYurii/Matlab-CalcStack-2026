function U = tp_test_util()
% TP_TEST_UTIL  Спільні допоміжні функції для тестового (діагностичного) проходу.
%   Повертає структуру дескрипторів, щоб стадії test/ ділили один код:
%       U.panelMap(ax,Z,ttl,cmap,S)   мапа + колорбар + діапазон у заголовку
%       U.stdMapPanel(ax,M,ttl,S)     4x4 карта std з підписами значень
%       U.saveFig(fig,outDir,name)    експорт PNG (200 dpi) + close
%       U.rng(Z)                      рядок 'min .. max'
%       U.minv(Z) / U.maxv(Z)         min/max без NaN

U.panelMap    = @panelMap;
U.stdMapPanel = @stdMapPanel;
U.saveFig     = @saveFig;
U.rng         = @rngstr;
U.minv        = @minv;
U.maxv        = @maxv;
end

% ------------------------------------------------------------------------
function panelMap(ax, Z, ttl, cmap, S)
if ~isreal(Z)                       % несподівано комплексна величина — позначити
    mi = max(abs(imag(Z(:))));
    if mi > 0, ttl = sprintf('%s  (complex! max|Im|=%.2g)', ttl, mi); end
    Z = real(Z);                    % показуємо реальну частину
end
im = imagesc(ax, Z); set(im,'AlphaData',isfinite(Z));
set(ax,'YDir','normal'); axis(ax,'image'); colormap(ax, cmap);
lo = minv(Z); hi = maxv(Z);
if isfinite(lo) && isfinite(hi) && lo < hi, caxis(ax,[lo hi]); end
colorbar(ax);
title(ax, sprintf('%s   [%.3g .. %.3g]', ttl, lo, hi), ...
      'FontSize',10,'FontWeight','bold','Interpreter','tex');
S.apply(ax);
end

function stdMapPanel(ax, M, ttl, S)
imagesc(ax, M); axis(ax,'image'); colormap(ax,'parula'); colorbar(ax);
set(ax,'XTick',1:4,'YTick',1:4,'XTickLabel',{'k1','k2','k3','k4'}, ...
       'YTickLabel',{'i1','i2','i3','i4'});
for i = 1:4
    for k = 1:4
        text(ax, k, i, sprintf('%.2g', M(i,k)), 'HorizontalAlignment','center', ...
            'Color','k','FontSize',9,'FontWeight','bold');
    end
end
title(ax, ttl,'FontSize',12,'FontWeight','bold','Interpreter','tex');
S.apply(ax);
end

function saveFig(fig, outDir, name)
try
    exportgraphics(fig, fullfile(outDir,[name '.png']), 'Resolution', 200);
catch
    print(fig, fullfile(outDir,[name '.png']), '-dpng', '-r200');
end
close(fig);
end

function s = rngstr(Z), s = sprintf('%.3g .. %.3g', minv(Z), maxv(Z)); end
function v = minv(Z), v = min(Z(isfinite(Z))); if isempty(v), v = NaN; end, end
function v = maxv(Z), v = max(Z(isfinite(Z))); if isempty(v), v = NaN; end, end
