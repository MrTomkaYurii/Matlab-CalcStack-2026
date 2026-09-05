function R = s1_context(C, paths, U)
% S1_CONTEXT  Крок 1 — постановка задачі: показати САМ факт малості.
%   Бере готовий result.mat основного прикладу (generalized/step_1,
%   найширше фазове вікно) і будує сітку 4x4 |f_ik| з реальною шкалою.
R = struct('figs',{{}}, 'lines',{{}}, 'budget',{{}});

resDir = fullfile(C.resultRoot, C.sample, C.example);
rf = '';
if isfolder(resDir)
    ph = dir(fullfile(resDir, 'phase_01*'));
    if ~isempty(ph)
        cand = fullfile(resDir, ph(1).name, 'generalized', 'step_1', 'result.mat');
        if isfile(cand); rf = cand; end
    end
end

if isempty(rf)
    R.lines{end+1} = sprintf(['Готового result.mat для %s/%s не знайдено — ' ...
        'крок 1 пропущено, суть проблеми див. далі за сирими даними.'], C.sample, C.example);
    return;
end

S = load(rf);  Rr = S.R;  dir1 = Rr.dirs{1};
D = Rr.data.(dir1);
els = fieldnames(D);

fig = figure('Color','w','Visible','off','Position',[60 60 1250 1200]);
allv = [];
for e = 1:16
    M = D.(els{e}).mod;
    allv = [allv; M(isfinite(M))]; %#ok<AGROW>
end
cl = [prctile(allv,1) prctile(allv,99)];
for e = 1:16
    ax = subplot(4,4,e);
    M = D.(els{e}).mod;
    imagesc(ax, M);  axis(ax,'image');  set(ax,'YDir','normal','XTick',[],'YTick',[]);
    colormap(ax, C.fig.cmapMod);  if cl(2)>cl(1); clim(ax, cl); end
    title(ax, sprintf('|%s|', tex(els{e})), 'Interpreter','tex', ...
          'FontName',C.fig.font, 'FontSize',C.fig.fontSize, 'FontWeight','normal');
end
cb = colorbar('Position',[0.93 0.11 0.015 0.8]);
set(cb,'FontName',C.fig.font,'FontSize',C.fig.fontSize-1);
sgtitle(sprintf(['Крок 1. Спостережуваний факт: |f_{ik}| у готовому результаті ' ...
    '(%s / %s, generalized, вікно 0–2\\pi)\nтиповий масштаб ~10^{%d}, шкала [%s … %s]'], ...
    C.sample, C.example, U.orderOf(allv), U.eng(cl(1)), U.eng(cl(2))), ...
    'FontName',C.fig.font, 'FontSize',C.fig.fontSize+1, 'Interpreter','tex','Color','k');

R.figs{end+1} = U.save(fig, paths.steps, 1, 'problem.f_ik_mod_grid', C);
k = U.orderOf(allv);
R.lines{end+1} = sprintf(['Готовий результат: медіанний |f_{ik}| ~ 10^{%d} ' ...
    '(діапазон по 1–99 перцентилю %s … %s). Це і є "мала" величина, причину якої шукаємо.'], ...
    k, U.eng(cl(1)), U.eng(cl(2)));
R.budget{end+1} = struct('stage','результат (result.mat)', 'quantity','|f_{ik}| (mod-карта)', ...
    'order',k, 'note','те, що бачимо на рисунках статті');
end

function s = tex(e)
s = ['f_{' e(2:end) '}'];
end
