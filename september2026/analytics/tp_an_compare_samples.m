function [discrim, consist] = tp_an_compare_samples(T, metricVars)
% TP_ANALYTICS_COMPARE_SAMPLES  Дві таблиці порівняння:
%
%   consist  — узгодженість між прикладами (1/2/3) ОДНОГО зразка: для
%              кожної (sample,algorithm,direction,step,phase_index,element)
%              рахує mean_<metric> і std_<metric> ПО ПРИКЛАДАХ. Малий
%              std_ => ефект відтворюваний (не шум одного знімку).
%
%   discrim  — дискримінативність між ЗРАЗКАМИ (Мозг/Мяз/Серце): бере
%              mean_<metric> (уже усереднене по прикладах, з consist) і
%              для кожної (algorithm,direction,step,phase_index,element)
%              рахує range_<metric> = max-min ПО ЗРАЗКАХ. Великий range_
%              => цей елемент/метрика добре розрізняє типи тканини.

if isempty(T)
    discrim = table(); consist = table(); return;
end

groupVarsSample = {'sample','algorithm','direction','step','phase_index','element'};
[G, keys] = findgroups(T(:, groupVarsSample));
nG = max(G);
rowsCell = cell(nG,1);
for gi = 1:nG
    idx = (G == gi);
    row = keys(gi, :);
    for m = 1:numel(metricVars)
        v = T.(metricVars{m})(idx);
        row.(['mean_' metricVars{m}]) = mean(v, 'omitnan');
        row.(['std_'  metricVars{m}]) = std(v, 'omitnan');
    end
    rowsCell{gi} = row;
end
consist = vertcat(rowsCell{:});

groupVarsCond = {'algorithm','direction','step','phase_index','element'};
[G2, keys2] = findgroups(consist(:, groupVarsCond));
nG2 = max(G2);
rowsCell2 = cell(nG2,1);
for gi = 1:nG2
    idx = (G2 == gi);
    row = keys2(gi, :);
    for m = 1:numel(metricVars)
        v = consist.(['mean_' metricVars{m}])(idx);
        v = v(isfinite(v));
        if numel(v) < 2
            row.(['range_' metricVars{m}]) = NaN;
        else
            row.(['range_' metricVars{m}]) = max(v) - min(v);
        end
    end
    rowsCell2{gi} = row;
end
discrim = vertcat(rowsCell2{:});
end
