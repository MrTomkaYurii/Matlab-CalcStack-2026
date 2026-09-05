function R = s6_fik(C, paths, U, F)
% S6_FIK  Крок 6 — фінальна збірка f_ik (розділ 4): комбінації a_i, b_i
%   чотирьох освітлень. Лінійні комбінації -> масштаб a,b (~1e-6) зберігається.
R = struct('figs',{{}}, 'lines',{{}}, 'budget',{{}});

els = cell(4,4);
for i=1:4, for k=1:4, els{i,k} = sprintf('f%d%d',i,k); end, end

allM = [];  zeroEls = {};
fig = figure('Color','w','Visible','off','Position',[40 40 1250 1200]);
for i = 1:4
    for k = 1:4
        Z = F.(els{i,k});  M = abs(Z);
        allM = [allM; M(isfinite(M))]; %#ok<AGROW>
        if max(M(:)) == 0; zeroEls{end+1} = els{i,k}; end %#ok<AGROW>
        ax = subplot(4,4,(i-1)*4+k);
        imagesc(ax, M);  axis(ax,'image');  set(ax,'YDir','normal','XTick',[],'YTick',[]);
        colormap(ax, C.fig.cmapMod);
        v = M(isfinite(M)); if ~isempty(v) && max(v)>min(v); clim(ax,[min(v) max(v)]); end
        title(ax, sprintf('|f_{%d%d}|  ~%s', i, k, U.eng(mean(v(v>0),'omitnan'))), ...
              'Interpreter','tex','FontName',C.fig.font,'FontSize',C.fig.fontSize-1,'FontWeight','normal');
    end
end
sgtitle(sprintf(['Крок 6. Зібрані |f_{ik}| (розділ 4). Масштаб ~10^{%d} — успадкований ' ...
    'від a_i,b_i.\nРозділ 4 лише лінійно комбінує складові, множника не додає.'], U.orderOf(allM)), ...
    'FontName',C.fig.font,'FontSize',C.fig.fontSize+1,'Interpreter','tex','Color','k');
R.figs{end+1} = U.save(fig, paths.steps, 6, 'fik_mod_grid', C);

% Re/Im/|f|/arg для двох показових елементів
for el = {'f11','f33'}
    Z = F.(el{1});
    fig = figure('Color','w','Visible','off','Position',[50 50 1150 850]);
    U.panel(subplot(2,2,1), real(Z), sprintf('Re(%s)', tx(el{1})), C.fig.cmapMod, C);
    U.panel(subplot(2,2,2), imag(Z), sprintf('Im(%s)', tx(el{1})), C.fig.cmapMod, C);
    U.panel(subplot(2,2,3), abs(Z),  sprintf('|%s|',   tx(el{1})), C.fig.cmapMod, C);
    U.panel(subplot(2,2,4), angle(Z),sprintf('arg(%s), рад', tx(el{1})), C.fig.cmapArg, C);
    sgtitle(sprintf('Крок 6. %s:  Re/Im/|f| ~ %s,  arg — повний [-\\pi,\\pi]', ...
        tx(el{1}), U.eng(mean(abs(Z(isfinite(Z))),'omitnan'))), ...
        'FontName',C.fig.font,'FontSize',C.fig.fontSize+1,'Interpreter','tex','Color','k');
    R.figs{end+1} = U.save(fig, paths.steps, 6, sprintf('fik_parts.%s', el{1}), C);
end

k = U.orderOf(allM);
R.lines{end+1} = sprintf(['Зібрані |f_{ik}| ~ 10^{%d} — той самий порядок, що й a_i,b_i. ' ...
    'Розділ 4 (f_{i1}=½(A+iB), f_{i3}=(A_{45}-A_{sum})+i(…) …) лише СКЛАДАЄ вже готові ' ...
    'складові, нового множника не вносить.'], k);
if ~isempty(zeroEls)
    R.lines{end+1} = sprintf(['Тут же видно наслідок дефекту даних: елементи %s ' ...
        'тотожно нульові (див. крок 8).'], strjoin(zeroEls, ', '));
end
R.budget{end+1} = struct('stage','f_{ik}  (розділ 4)', 'quantity','|f_{ik}| комплексні', ...
    'order',k, 'note','лінійна комбінація a,b — масштаб не змінюється');
end

function s = tx(e); s = ['f_{' e(2:end) '}']; end
