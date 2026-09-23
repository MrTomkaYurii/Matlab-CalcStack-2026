function tp_visualize_LB_CB_rho(R2, dir, CFG)
% TP_VISUALIZE_LB_CB_RHO  Візуалізація Кроку B: для кожного з 5 елементів
%   (LB_0_90, LB_45_135, CB, rho, LB) — ТІ САМІ подання, що раніше для
%   f_ik (tp_visualize.m), усі, не лише карти+контури:
%     (1)  2x2 карти модуля/аргументу + гістограми     — viz_maps_hist.m
%     Блок1 карти->гістограми->АКФ ОДНІЄЮ фігурою      — viz_block1_summary.m
%     (2)  2x2 3D-поверхні + контурні карти             — viz_sections.m
%     (2b) контурні лінії у 3D (contour3)                — viz_contour3d.m
%     Блок3 2D контур + 3D контур ОДНІЄЮ фігурою         — viz_block3_contours.m
%     Блок4 спектр f(h) з WTMM                           — viz_multifractal.m
%           + D(q), τ(q)                                 — viz_multifractal_dimensions.m
%     (3)  вейвлет W(a,b) (мод+арг)                       — viz_wavelet.m
%     (4A) 2D АКФ + 2D PSD (мод+арг)                      — viz_acf_psd.m
%     (4B) 1D перерізи ACF + їх PSD (log-log)              — viz_acf_cuts.m
%     (5)  вейвлет-скелетон + гістограма максимумів        — viz_skeleton.m
%     (6)  смуговий аналіз концентрації біля рівнів         — viz_level_bands.m
%     —    mean/std/skew/kurt (мод+арг) у текстовий файл    — viz_stats_table.m
%   Усі функції — НЕЗМІНЕНІ копії з august2026\viz\.
%
%   R2  : вихід tp_LB_CB_rho_from_result.m (R2.elements = 5 нових імен)
%   dir : той самий напрям/крок, що передавався туди
%   CFG : як cfg_TwoPoint() (потрібні поля .viz, .out, .qc, .acf, .paths.saveRoot)

% Короткий підпис "<зразок>/<приклад>" -- R2.sample у наших даних тягне за
% собою ще й теку фазового вікна (напр. 'Серце\2\phase_01_[0-2.00pi]'):
% повністю в заголовку і задовгий, і ламає TeX (цифри після '_' стають
% підрядковими). Беремо лише перші 2 сегменти шляху.
sampleParts = strsplit(R2.sample, {'\','/'});
sampleShort = strjoin(sampleParts(1:min(2,numel(sampleParts))), '/');
ax = R2.axes.(dir);  lb = R2.label.(dir);
dirDisp = strrep(dir, '_', '\_');
algoBase = strtok(R2.algorithm, '+');    % 'XY+LB_CB_rho' -> 'XY' (сама LB_CB_rho
                                          % частина зайва в заголовку -- це й так
                                          % єдине, що тут будується)
baseParts = {R2.sample, R2.algorithm, dir};   % для ШЛЯХІВ лишаємо повним і сирим

% Позначення -- ТОЧНО як у зелених формулах докс (перевірено по картинці
% з документа): |...| для модуля всюди; arg[...] (квадратні дужки) для
% LB_0,90 / LB_45,135 / CB, але arg(...) (круглі) для rho / LB.
elemTeX = struct( ...
    'LB_0_90',   'LB_{0,90}', ...
    'LB_45_135', 'LB_{45,135}', ...
    'CB',        'CB', ...
    'rho',       '\rho', ...
    'LB',        'LB');
argBracket = struct( ...
    'LB_0_90',   '[', ...
    'LB_45_135', '[', ...
    'CB',        '[', ...
    'rho',       '(', ...
    'LB',        '(');

for e = 1:numel(R2.elements)
    elem = R2.elements{e};
    D = R2.data.(dir).(elem);

    [ok, reason] = tp_validate(D.mod, CFG);
    if ~ok
        fprintf('   [skip] %s/%s/%s: %s\n', R2.algorithm, dir, elem, reason);
        continue;
    end

    tex = elemTeX.(elem);
    br  = argBracket.(elem);
    if br == '[', brC = ']'; else, brC = ')'; end   % відповідна закривна дужка
    argLabel = sprintf('arg%s%s%s [rad]', br, tex, brC);
    method = lower(CFG.acf.method);
    [amod, pmod, lxm, lym] = tp_acf_psd(D.mod, method);
    [aarg, parg, lxa, lya] = tp_acf_psd(D.arg, method);
    acfData = struct( ...
        'method', method, ...
        'mod', struct('acf',amod, 'psd',pmod, 'lagx',lxm, 'lagy',lym), ...
        'arg', struct('acf',aarg, 'psd',parg, 'lagx',lxa, 'lagy',lya));

    meta = struct( ...
        'x', ax.x, 'y', ax.y, 'xlabel', lb.x, 'ylabel', lb.y, ...
        'elemTeX', tex, ...
        'modLabel', sprintf('|%s|', tex), ...
        'argLabel', argLabel, ...
        'titlePrefix', sprintf('%s \\cdot %s \\cdot %s \\cdot %s', ...
                               sampleShort, algoBase, dirDisp, tex), ...
        'acfData', acfData);
    ctx = struct('parts', {[baseParts, {elem}]}, 'name', elem);

    tag = sprintf('%s/%s/%s', R2.algorithm, dir, elem);
    runViz(@viz_maps_hist,               D, meta, ctx, CFG, tag, 'maps_hist');
    runViz(@viz_block1_summary,          D, meta, ctx, CFG, tag, 'block1_summary');
    runViz(@viz_sections,                D, meta, ctx, CFG, tag, 'surf_contour');
    runViz(@viz_contour3d,               D, meta, ctx, CFG, tag, 'contour3');
    runViz(@viz_block3_contours,         D, meta, ctx, CFG, tag, 'block3_contours');
    runViz(@viz_multifractal,            D, meta, ctx, CFG, tag, 'multifractal');
    runViz(@viz_multifractal_dimensions, D, meta, ctx, CFG, tag, 'multifractal_dims');
    runViz(@viz_wavelet,                 D, meta, ctx, CFG, tag, 'wavelet');
    runViz(@viz_acf_psd,                 D, meta, ctx, CFG, tag, 'acf_psd');
    runViz(@viz_acf_cuts,                D, meta, ctx, CFG, tag, 'acf_cuts');
    runViz(@viz_skeleton,                D, meta, ctx, CFG, tag, 'skeleton');
    runViz(@viz_level_bands,             D, meta, ctx, CFG, tag, 'level_bands');
    runViz(@viz_stats_table,             D, meta, ctx, CFG, tag, 'stats_table');
end
end

% ------------------------------------------------------------------------
function runViz(fn, D, meta, ctx, CFG, tag, name)
% Виклик модуля візуалізації з обробкою помилок: збій одного рисунка
% логується і НЕ валить решту (та сама політика, що й tp_visualize.m).
try
    fn(D, meta, ctx, CFG);
catch ME
    fprintf(2, '   [viz fail] %s %s: %s\n', tag, name, ME.message);
end
end
