function rows = tp_stats_LB_CB_rho(R2, dName, CFG, k, writeText)
% TP_STATS_LB_CB_RHO  Статистика Кроку B для одного напряму/кроку:
%   для КОЖНОГО з 5 елементів (LB_0_90, LB_45_135, CB, rho, LB) --
%     (1) ST = tp_stats_element(...)   (числа: карта, рівні, АКФ, PSD, вейвлет, скелетон, мультифрактал)
%     (2) текстовий файл <елемент>_stats.txt у теці ЦЬОГО елемента (tp_stats_write), якщо writeText
%     (3) рядок таблиці аналітики (tp_an_row_from_stats) -- повертається в rows
%
%   R2       : вихід tp_LB_CB_rho_from_result.m (R2.sample = 'зразок\приклад\фаза')
%   dName    : напрям/крок ('step_1' | 'OX_step_1' | 'OY_step_1')
%   k        : номер фазового вікна (1..CFG.phase.numWindows)
%   writeText: писати текстові файли (типово true; false -- лише рядки для аналітики)
%   rows     : 1 x 5 cell таблиць (по рядку на елемент) для tp_an_append_rows

if nargin < 5, writeText = true; end

U = tp_phase_window_bounds(CFG);
phaseDeg = round(U(k)/pi*180);

sp = strsplit(R2.sample, {'\','/'});
smp = sp{1};  ex = sp{2};
algo = strtok(R2.algorithm, '+');                 % 'XY+LB_CB_rho' -> 'XY'
% dName: 'step_1' -> напрям XY (зведена карта), 'OX_step_1' -> OX, 'OY_step_1' -> OY
tokS = regexp(dName, 'step_(\d+)$', 'tokens', 'once');
tp_assert(~isempty(tokS), 'tp_stats_LB_CB_rho: не розпізнано напрям/крок "%s"', dName);
step = str2double(tokS{1});
direction = regexprep(dName, '_?step_\d+$', '');
if isempty(direction), direction = 'XY'; end

rows = cell(1, numel(R2.elements));
for e = 1:numel(R2.elements)
    elem = R2.elements{e};
    [meta, ctx, D] = tp_element_meta(R2, dName, elem, CFG);
    ST = tp_stats_element(D, meta, CFG);
    if writeText
        tp_stats_write(ST, meta, ctx, CFG);
    end
    rows{e} = tp_an_row_from_stats(ST, smp, ex, algo, direction, step, k, phaseDeg, elem);
end
end
