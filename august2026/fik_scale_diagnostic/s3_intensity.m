function R = s3_intensity(C, paths, U, IMG)
% S3_INTENSITY  Крок 3 — інтенсивність I = |Ex|^2 + |Ey|^2 на кожен стан.
%   Ключ: підносимо поле ~1e-3 у КВАДРАТ -> I ~ 1e-6. Саме стільки й буде
%   у f_ik, бо f_ik — теж білінійні за полем (добутки пар амплітуд).
R = struct('figs',{{}}, 'lines',{{}}, 'budget',{{}});

states = {'in0','in45','in90','in135','inliv','inprav'};
labels = {'0°','45°','90°','135°','ліва цирк.','права цирк.'};

fig = figure('Color','w','Visible','off','Position',[50 50 1200 760]);
allI = [];
for s = 1:numel(states)
    P = states{s};
    I = abs(IMG.(P).Ex).^2 + abs(IMG.(P).Ey).^2;
    allI = [allI; I(I>0)]; %#ok<AGROW>
    ax = subplot(2,3,s);
    U.panel(ax, I, sprintf('I = |Ex|^2+|Ey|^2   %s', labels{s}), C.fig.cmapMod, C);
end
sgtitle(sprintf(['Крок 3. Інтенсивність на кожен стан: I ~ 10^{%d}\n' ...
    '(поле |E| ~ 10^{%d}  ->  I = |E|^2 ~ 10^{%d})'], ...
    U.orderOf(allI), U.orderOf(allI)/2, U.orderOf(allI)), ...
    'FontName',C.fig.font,'FontSize',C.fig.fontSize+1,'Interpreter','tex','Color','k');
R.figs{end+1} = U.save(fig, paths.steps, 3, 'intensity_by_state', C);

% гістограма сукупної I + позначка масштабу
fig = figure('Color','w','Visible','off','Position',[60 60 760 430]);
ax = axes(fig);  histogram(ax, log10(allI), 60, 'FaceColor',[0.55 0.55 0.55], 'EdgeColor','k','LineWidth',0.3);
set(ax,'FontName',C.fig.font,'FontSize',C.fig.fontSize,'XColor','k','YColor','k');
xlabel(ax,'log_{10} I','Color','k');  ylabel(ax,'к-сть пікселів','Color','k');
title(ax, sprintf('Крок 3. Розподіл log_{10} I — центр біля %.1f (тобто I ~ 10^{%d})', ...
      median(log10(allI)), U.orderOf(allI)), 'FontName',C.fig.font,'FontSize',C.fig.fontSize+1,'Interpreter','tex','Color','k');
R.figs{end+1} = U.save(fig, paths.steps, 3, 'intensity_hist_log10', C);

kI = U.orderOf(allI);
R.lines{end+1} = sprintf(['Інтенсивність I = |Ex|^2+|Ey|^2 ~ 10^{%d}: це просто КВАДРАТ ' ...
    'масштабу поля (10^{%d})^2. Оскільки елементи f_{ik} формуються з ДОБУТКІВ пар ' ...
    'амплітуд (Ex_1·Ex_2, Ey_1·Ey_2·cos… — див. крок 5), вони мають той самий порядок, що й I.'], ...
    kI, kI/2);
R.budget{end+1} = struct('stage','I = |Ex|^2 + |Ey|^2', 'quantity','інтенсивність', ...
    'order',kI, 'note','квадрат масштабу поля -> те, що успадкує f_{ik}');
end
