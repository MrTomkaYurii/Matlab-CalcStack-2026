function rowsCell = tp_analytics_rows_for_result(R, sampleName, example, algo, dirLabel, step, phaseIndex, phaseDeg, CFG)
% TP_ANALYTICS_ROWS_FOR_RESULT  Один результат (Rd з одним напрямом для
%   orthogonal, або R з "XY" для generalized) -> cell-масив рядків таблиці
%   аналітики, по одному на елемент f_ik. Контекст (зразок/приклад/
%   алгоритм/напрям/крок/фазове вікно) передається аргументами, бо сам R
%   цього не знає.
%
%   Спільна логіка для ДВОХ шляхів:
%     - tp_analytics_collect_summaries.m (Крок 1, post-hoc, з диска),
%     - run_TwoPoint_Pipeline.m (наживо, одразу після розрахунку —
%       без повторного читання result.mat і повторного ACF/мультифракталу).

dirName = R.dirs{1};
els = fieldnames(R.data.(dirName));
rowsCell = cell(1, numel(els));
for e = 1:numel(els)
    D = R.data.(dirName).(els{e});
    Sm = tp_analytics_compute_summary(D, CFG);
    row = struct2table(Sm, 'AsArray', true);
    row.sample      = string(sampleName);
    row.example     = string(example);
    row.algorithm   = string(algo);
    row.direction   = string(dirLabel);
    row.step        = step;
    row.phase_index = phaseIndex;
    row.phase_deg   = phaseDeg;
    row.element     = string(els{e});
    idCols = {'sample','example','algorithm','direction','step','phase_index','phase_deg','element'};
    row = movevars(row, idCols, 'Before', 1);
    rowsCell{e} = row;
end
end
