function tp_gif_generalized(outDir)
% TP_GIF_GENERALIZED  Демонстраційна анімація механіки УЗАГАЛЬНЕНОГО алгоритму,
%   З ПОЯСНЕННЯМ ПРЯМО НА КАДРІ (формула + живий числовий приклад щокадру).
%   Головна властивість, яку показує gif: для кожного зсуву Δ=(Δx,Δy) дві
%   копії поля накладаються одна на одну (як в АКФ), зона перекриття
%   УСЕРЕДНЮЄТЬСЯ в ОДНЕ значення діаграми.
%
%   Використовує ту саму формулу (tp_fik_pair) і той самий спосіб
%   формування допустимої області, що й core/algo/generalized/tp_algo_generalized.m, лише
%   на маленькому зображенні (N=80) і розрідженій сітці зсувів — для
%   швидкості й компактного розміру gif.

CFG = cfg_TwoPoint();
CFG.crop.size = 80;
CFG.samples   = {'Demo'};
CFG.source    = 'synthetic';
tp_check_config(CFG);
N = CFG.crop.size;

IMG = tp_load_images(CFG, 'Demo');
bg  = IMG.in0.I0;

% ---- розріджена сітка зсувів лише для демонстрації (менша за бойову) ----
R = 20; h = 5;
dxs = -R:h:R;  dys = -R:h:R;
nx = numel(dxs); ny = numel(dys);
total = nx*ny - 1;   % мінус нульовий зсув

Mod = nan(ny,nx);    % діаграма, що поступово заповнюється

S = viz_style();
gifPath = fullfile(outDir, 'generalized_algorithm.gif');
fig = figure('Color','w','Visible','off','Position',[60 60 1400 900]); S.light(fig);

legendText = {
 'ЯК ПРАЦЮЄ УЗАГАЛЬНЕНИЙ АЛГОРИТМ (2D псевдо-АКФ):'
 '1) Обирається зсув \Delta=(\Deltax,\Deltay).'
 '2) Червона рамка r_1 і синя пунктирна рамка r_2=r_1+\Delta —'
 '   ЦЕ Й Є зображення, накладене саме на себе зі зсувом \Delta'
 '   (точно як при обчисленні автокореляції).'
 '3) Обидві рамки ОДНАКОВОГО розміру — кожна точка з червоної'
 '   рамки має відповідну пару в синій.'
 '4) Для КОЖНОЇ такої пари обчислюється f_{11}(r_1, r_1+\Delta).'
 '5) Модуль УСЕРЕДНЮЄТЬСЯ по всіх парах:'
 '     M(\Delta) = mean( |f_{11}(r_1,r_1+\Delta)| )  за всіма r_1'
 '   Результат — ОДНЕ число в комірку (\Deltax,\Deltay) діаграми.'
};

fprintf('  building generalized_algorithm.gif (%d frames) ...\n', total);
frame = 0;
for ix = 1:nx
    dx = dxs(ix);
    if dx >= 0, c1 = 1:(N-dx); else, c1 = (1-dx):N; end
    c2 = c1 + dx;
    for iy = 1:ny
        dy = dys(iy);
        if dx == 0 && dy == 0, continue; end
        if dy >= 0, r1 = 1:(N-dy); else, r1 = (1-dy):N; end
        r2 = r1 + dy;
        if isempty(c1) || isempty(r1), continue; end

        F = tp_fik_pair(tp_slice(IMG,r1,c1), tp_slice(IMG,r2,c2));
        z = F.f11(:);
        Mval = mean(abs(z), 'omitnan');
        Mod(iy,ix) = Mval;
        nPairs = numel(z);
        frame = frame + 1;

        clf(fig);
        tl = tiledlayout(fig,2,2,'Padding','compact','TileSpacing','compact');

        % --- панель 1: накладання поля на самого себе, зсунутого на Δ --
        ax1 = nexttile(tl);
        imagesc(ax1, bg); colormap(ax1,'gray'); axis(ax1,'image'); set(ax1,'YDir','normal');
        hold(ax1,'on');
        rectangle(ax1,'Position',[c1(1)-0.5, r1(1)-0.5, numel(c1), numel(r1)], ...
                  'EdgeColor',[0.85 0.10 0.10], 'LineWidth',2.5);                  % область r1
        rectangle(ax1,'Position',[c2(1)-0.5, r2(1)-0.5, numel(c2), numel(r2)], ...
                  'EdgeColor',[0.10 0.30 0.90], 'LineWidth',2.5, 'LineStyle','--'); % область r2=r1+Δ
        text(ax1, mean(c1), mean(r1), 'r_1', 'Color',[0.85 0.1 0.1], 'FontWeight','bold', ...
             'BackgroundColor','w', 'Margin',1, 'HorizontalAlignment','center');
        text(ax1, mean(c2), mean(r2), 'r_2=r_1+\Delta', 'Color',[0.10 0.30 0.90], 'FontWeight','bold', ...
             'BackgroundColor','w', 'Margin',1, 'HorizontalAlignment','center');
        title(ax1, sprintf('\\Delta = (%d, %d) px', dx, dy), 'Interpreter','tex');
        xlabel(ax1,'x (px)'); ylabel(ax1,'y (px)'); S.apply(ax1);

        % --- панель 2: діаграма зсувів, що поступово заповнюється -----
        ax2 = nexttile(tl);
        imagesc(ax2, dxs, dys, Mod); axis(ax2,'image'); set(ax2,'YDir','normal');
        colormap(ax2,'jet'); colorbar(ax2);
        hold(ax2,'on');
        plot(ax2, dx, dy, 's', 'MarkerEdgeColor','w', 'MarkerSize',10, 'LineWidth',1.5);
        title(ax2, sprintf('Псевдо-АКФ діаграма |f_{11}|   (%d/%d комірок)', frame, total));
        xlabel(ax2,'\Delta x (px)'); ylabel(ax2,'\Delta y (px)'); S.apply(ax2);

        % --- панель 3: (порожня, лишена для балансу сітки 2x2) --------
        ax3 = nexttile(tl); axis(ax3,'off');

        % --- панель 4: текстова легенда + живий числовий приклад ------
        ax4 = nexttile(tl); axis(ax4,'off');
        exampleText = { ' ', 'ПОТОЧНИЙ КАДР — ЖИВИЙ ПРИКЛАД:', ...
            sprintf('  \\Delta = (%d, %d) px', dx, dy), ...
            sprintf('  розмір спільної області = %d \\times %d = %d пар', numel(c1), numel(r1), nPairs), ...
            sprintf('  M(\\Delta) = mean(|f_{11}|)  за %d парами  =  %.4f', nPairs, Mval) };
        text(ax4, 0, 1, [legendText(:); exampleText(:)], 'Units','normalized', ...
             'VerticalAlignment','top', 'FontSize',11, 'FontName','Consolas', ...
             'Interpreter','tex', 'Color',S.ink);

        title(tl, 'Узагальнений алгоритм: для кожного \Delta — ОДНЕ усереднене значення', ...
              'FontWeight','bold','Interpreter','tex');

        tp_gif_writeframe(fig, gifPath, 0.07, frame==1);
    end
end
tp_gif_writeframe(fig, gifPath, 1.8, false);
close(fig);
fprintf('  wrote %s\n', gifPath);
end
