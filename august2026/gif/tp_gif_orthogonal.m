function tp_gif_orthogonal(outDir)
% TP_GIF_ORTHOGONAL  Демонстраційна анімація механіки ОРТОГОНАЛЬНОГО алгоритму,
%   З ПОЯСНЕННЯМ ПРЯМО НА КАДРІ (формула + живий числовий приклад щокадру).
%   Головна властивість, яку показує gif: КОЖНА перша точка r1 отримує СВОЄ
%   власне значення (без усереднення по зображенню).
%
%   Використовує ту саму формулу (tp_fik_pair) і той самий спосіб
%   формування пар, що й core/algo/orthogonal/tp_algo_orthogonal.m, лише на маленькому
%   зображенні (N=80) — для швидкості й компактного розміру gif.

CFG = cfg_TwoPoint();
CFG.crop.size = 80;         % малий розмір — лише для демонстрації механіки
CFG.samples   = {'Demo'};
CFG.source    = 'synthetic';
tp_check_config(CFG);
N = CFG.crop.size;
d = 8;                      % представницький крок (як один із CFG.ortho.steps)

IMG = tp_load_images(CFG, 'Demo');
bg  = IMG.in0.I0;           % фонове зображення для наочності (інтенсивність 0°)

% ---- еталонні карти OX/OY для елемента f11 (формули як у tp_algo_orthogonal) ----
c1 = 1:(N-d);  c2 = c1 + d;
Fx = tp_fik_pair(tp_slice(IMG,1:N,c1), tp_slice(IMG,1:N,c2));
ModOX = nan(N);  ModOX(:,c1) = abs(Fx.f11);

r1 = 1:(N-d);  r2 = r1 + d;
Fy = tp_fik_pair(tp_slice(IMG,r1,1:N), tp_slice(IMG,r2,1:N));
ModOY = nan(N);  ModOY(r1,:) = abs(Fy.f11);

cRange = [min([ModOX(:);ModOY(:)],[],'omitnan'), max([ModOX(:);ModOY(:)],[],'omitnan')];
colExample = c1(ceil(numel(c1)/2));   % представницький стовпець для прикладу OX
rowExample = r1(ceil(numel(r1)/2));   % представницький рядок    для прикладу OY

S = viz_style();
gifPath = fullfile(outDir, 'orthogonal_algorithm.gif');
fig = figure('Color','w','Visible','off','Position',[60 60 1500 900]); S.light(fig);

legendText = {
 'ЯК ПРАЦЮЄ ОРТОГОНАЛЬНИЙ АЛГОРИТМ:'
 '1) Обирається крок d (відстань між точками пари).'
 '2) Перша точка r1 проходить по ВСІХ пікселях зображення'
 '   (суцільна лінія = напрям OX, штрих-пунктир = напрям OY).'
 '3) Друга точка:  OX: r2 = r1 + (d, 0)     OY: r2 = r1 + (0, d)'
 '4) Для КОЖНОЇ пари (r1,r2) обчислюється комплексний елемент'
 '   матриці Мюллера f11(r1,r2) (формули (1),(6)-(13)).'
 '5) Значення |f11(r1,r2)| записується РІВНО в позицію r1 карти.'
 '   Жодного усереднення по зображенню — кожен піксель має ВЛАСНЕ значення.'
};

fprintf('  building orthogonal_algorithm.gif (%d frames) ...\n', N);
for t = 1:N
    clf(fig);
    tl = tiledlayout(fig,2,2,'Padding','compact','TileSpacing','compact');

    % --- панель 1: джерело з позначеними точками поточної пари -------
    ax1 = nexttile(tl);
    imagesc(ax1, bg); colormap(ax1,'gray'); axis(ax1,'image'); set(ax1,'YDir','normal');
    hold(ax1,'on');
    plot(ax1, c1, t*ones(size(c1)), '-',  'Color',[0.85 0.1 0.1], 'LineWidth',2);    % r1, OX
    plot(ax1, c2, t*ones(size(c2)), '.',  'Color',[0.10 0.30 0.90], 'MarkerSize',5); % r2=r1+(d,0)
    plot(ax1, t*ones(size(r1)), r1, '-.', 'Color',[0.85 0.1 0.1], 'LineWidth',2);    % r1, OY
    plot(ax1, t*ones(size(r2)), r2, '.',  'Color',[0.10 0.30 0.90], 'MarkerSize',5); % r2=r1+(0,d)
    text(ax1, c1(1), t-3, 'r_1', 'Color',[0.85 0.1 0.1], 'FontWeight','bold', ...
         'BackgroundColor','w', 'Margin',1);
    text(ax1, c2(end), t-3, 'r_2=r_1+(d,0)', 'Color',[0.10 0.30 0.90], 'FontWeight','bold', ...
         'BackgroundColor','w', 'Margin',1, 'HorizontalAlignment','right');
    title(ax1, sprintf('Джерело: точки поточної пари,  d = %d px', d));
    xlabel(ax1,'x (px)'); ylabel(ax1,'y (px)'); S.apply(ax1);

    % --- панель 2: карта OX, поступово розкривається по рядках -------
    ax2 = nexttile(tl);
    partOX = nan(N); partOX(1:t,:) = ModOX(1:t,:);
    imagesc(ax2, partOX); axis(ax2,'image'); set(ax2,'YDir','normal');
    colormap(ax2,'jet'); caxis(ax2, cRange); colorbar(ax2);
    hold(ax2,'on'); yline(ax2, t, 'w-', 'LineWidth',1);
    title(ax2, sprintf('Карта OX  |f_{11}|   (рядок %d/%d)', t, N));
    xlabel(ax2,'x (px)'); ylabel(ax2,'y (px)'); S.apply(ax2);

    % --- панель 3: карта OY, поступово розкривається по стовпцях -----
    ax3 = nexttile(tl);
    partOY = nan(N); partOY(:,1:t) = ModOY(:,1:t);
    imagesc(ax3, partOY); axis(ax3,'image'); set(ax3,'YDir','normal');
    colormap(ax3,'jet'); caxis(ax3, cRange); colorbar(ax3);
    hold(ax3,'on'); xline(ax3, t, 'w-', 'LineWidth',1);
    title(ax3, sprintf('Карта OY  |f_{11}|   (стовпець %d/%d)', t, N));
    xlabel(ax3,'x (px)'); ylabel(ax3,'y (px)'); S.apply(ax3);

    % --- панель 4: текстова легенда + живий числовий приклад ---------
    ax4 = nexttile(tl); axis(ax4,'off');
    valOX = ModOX(t, colExample);
    if t >= rowExample, valOY = ModOY(rowExample, t); else, valOY = NaN; end
    exampleText = { ...
        ' ', 'ПОТОЧНИЙ КАДР — ЖИВИЙ ПРИКЛАД:', ...
        sprintf('  OX:  r_1=(%d,%d) \\rightarrow r_2=(%d,%d)   |f_{11}| = %.4f', ...
                colExample, t, colExample+d, t, valOX) };
    if isfinite(valOY)
        exampleText{end+1} = sprintf('  OY:  r_1=(%d,%d) \\rightarrow r_2=(%d,%d)   |f_{11}| = %.4f', ...
                                     t, rowExample, t, rowExample+d, valOY);
    end
    text(ax4, 0, 1, [legendText(:); exampleText(:)], 'Units','normalized', ...
         'VerticalAlignment','top', 'FontSize',11, 'FontName','Consolas', ...
         'Interpreter','tex', 'Color',S.ink);

    title(tl, 'Ортогональний алгоритм: кожен піксель r_1 отримує СВОЄ значення (БЕЗ усереднення)', ...
          'FontWeight','bold','Interpreter','tex');

    tp_gif_writeframe(fig, gifPath, 0.08, t==1);
end
tp_gif_writeframe(fig, gifPath, 1.8, false);   % довша пауза на фінальному кадрі
close(fig);
fprintf('  wrote %s\n', gifPath);
end
