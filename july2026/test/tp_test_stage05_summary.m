function tp_test_stage05_summary(F, outDir, S, P, thr) %#ok<INUSD>
% TP_TEST_STAGE05_SUMMARY  Stage 05: ІНТЕРВАЛИ ЗМІНИ кожного елемента f_ik.
%   Головна мета — чітко зафіксувати реальні діапазони розкиду: у яких
%   максимальних межах змінюється кожен елемент (окремо Re, Im, |f|, arg).
%   Для кожного елемента показуємо:
%       тонка сіра лінія  — абсолютний діапазон  [min .. max]
%       товста синя лінія — розкид mean ± std
%       червона крапка    — середнє
%   Плюс повна числова таблиця stage05_summary.csv (min/max/mean/std).

U  = tp_test_util();
fprintf('\n-- Stage 05: intervals of variation per element --\n');

qk    = {'Re','Im','Mod','Arg'};
names = cell(16,1);
mn = zeros(16,4); mx = zeros(16,4); mu = zeros(16,4); sd = zeros(16,4);
rows = zeros(16,12);

idx = 0;
for i = 1:4
    for k = 1:4
        idx = idx + 1; elem = sprintf('f%d%d', i, k); names{idx} = elem;
        Z = F.(elem);  vals = {real(Z), imag(Z), abs(Z), angle(Z)};
        for q = 1:4
            v = vals{q}(:); v = v(isfinite(v));
            mn(idx,q)=min(v); mx(idx,q)=max(v); mu(idx,q)=mean(v); sd(idx,q)=std(v);
        end
        rows(idx,:) = [mn(idx,1) mx(idx,1) mn(idx,2) mx(idx,2) mn(idx,3) mx(idx,3) ...
                       mn(idx,4) mx(idx,4) sd(idx,1) sd(idx,2) sd(idx,3) sd(idx,4)];
        fprintf('   %s: |f| [%.3g .. %.3g]  Re [%.3g .. %.3g]  Im [%.3g .. %.3g]\n', ...
                elem, mn(idx,3),mx(idx,3), mn(idx,1),mx(idx,1), mn(idx,2),mx(idx,2));
    end
end

% --- діаграма інтервалів: 2x2 (Re, Im, |f|, arg) --------------------
fig = figure('Color','w','Visible','off','Position',[50 50 1500 1000]); S.light(fig);
for q = 1:4
    ax = subplot(2,2,q); hold(ax,'on');
    for e = 1:16
        h1 = plot(ax, [mn(e,q) mx(e,q)], [e e], '-', 'Color',[0.6 0.6 0.6], 'LineWidth',1.2);
        h2 = plot(ax, [mu(e,q)-sd(e,q) mu(e,q)+sd(e,q)], [e e], '-', 'Color',[0.10 0.30 0.80], 'LineWidth',4);
        h3 = plot(ax, mu(e,q), e, 'o', 'MarkerFaceColor',[0.85 0.10 0.10], 'MarkerEdgeColor','k', 'MarkerSize',5);
    end
    set(ax,'YTick',1:16,'YTickLabel',names,'YDir','reverse'); ylim(ax,[0 17]);
    gmin = min(mn(:,q)); gmax = max(mx(:,q));
    xlabel(ax, sprintf('%s value', qk{q}), 'FontSize',S.labelSize);
    title(ax, sprintf('%s   —   global bounds [%.3g .. %.3g]', qk{q}, gmin, gmax), ...
          'FontSize',S.subSize,'FontWeight','bold','Interpreter','tex');
    if q == 1
        legend(ax, [h1 h2 h3], {'min..max','mean\pm std','mean'}, ...
               'Location','northeast','FontSize',8);
    end
    S.apply(ax);
end
sgtitle(sprintf('%s \\cdot %s \\cdot Stage 05: intervals of variation of f_{ik}', P.sample, P.direction), ...
        'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
U.saveFig(fig, outDir, 'stage05_ranges');

% --- числова таблиця -----------------------------------------------
T = array2table(rows, 'VariableNames', ...
    {'Re_min','Re_max','Im_min','Im_max','Mod_min','Mod_max','Arg_min','Arg_max', ...
     'std_Re','std_Im','std_Mod','std_Arg'});
T.element = names;
T = movevars(T, 'element', 'Before', 1);
writetable(T, fullfile(outDir, 'stage05_summary.csv'));
fprintf('   wrote %s\n', fullfile(outDir, 'stage05_summary.csv'));
end
