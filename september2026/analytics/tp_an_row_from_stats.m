function row = tp_an_row_from_stats(ST, sample, example, algo, direction, step, phaseIndex, phaseDeg, element)
% TP_AN_ROW_FROM_STATS  Один елемент Кроку B за конкретних умов -> ОДИН рядок
%   таблиці аналітики (той самий формат колонок, що в серпневому
%   tp_analytics_rows_for_result: id-колонки + метрики tp_an_metric_names).
%   Числа беруться з ST = tp_stats_element(...) (одне джерело з текстовим
%   файлом статистики -- цифри в таблиці й у файлі не можуть розійтись).
%   Якщо QC не пройдено (ST.qc.ok = false) -- моменти NaN (як у серпні), а АКФ
%   і мультифрактал -- також NaN (на майже порожній карті вони не рахувалися).

names = tp_an_metric_names();
S = cell2struct(num2cell(nan(1, numel(names))), names, 2);

for q = {'mod','arg'}
    sfx = q{1};  Qs = ST.(sfx);
    M = Qs.maps;
    S.(['n_' sfx])    = M.nFinite;
    S.(['mean_' sfx]) = M.mean;  S.(['std_' sfx])  = M.std;
    S.(['skew_' sfx]) = M.skew;  S.(['kurt_' sfx]) = M.kurt;
    if isfield(Qs, 'acf')
        S.(['acf_hwhm_x_' sfx]) = Qs.acf.hwhmX;
        S.(['acf_hwhm_y_' sfx]) = Qs.acf.hwhmY;
    end
    if isfield(Qs, 'mf') && Qs.mf.valid
        S.(['mf_D0_' sfx])     = Qs.mf.D0;   S.(['mf_D1_' sfx]) = Qs.mf.D1;
        S.(['mf_D2_' sfx])     = Qs.mf.D2;
        S.(['mf_deltaH_' sfx]) = Qs.mf.deltaH;
        S.(['mf_asym_' sfx])   = Qs.mf.asymmetry;
    end
end

row = struct2table(S, 'AsArray', true);
row.sample      = string(sample);
row.example     = string(example);
row.algorithm   = string(algo);
row.direction   = string(direction);
row.step        = step;
row.phase_index = phaseIndex;
row.phase_deg   = phaseDeg;
row.element     = string(element);
idCols = {'sample','example','algorithm','direction','step','phase_index','phase_deg','element'};
row = movevars(row, idCols, 'Before', 1);
end
