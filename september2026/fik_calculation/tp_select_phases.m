function [names, ks] = tp_select_phases(CFG, spec)
% TP_SELECT_PHASES  Які фазові вікна обрано в конфігу -> номери k і назви тек.
%   [names, ks] = tp_select_phases(CFG)          % CFG.fik.phases (розрахунок)
%   [names, ks] = tp_select_phases(CFG, spec)    % довільна специфікація, напр. CFG.viz.phases
%
%   spec: 'all' (усі CFG.phase.numWindows) | вектор номерів вікон (1, [1 3 5], 1:4)
%         | cellstr імен тек (сумісність: {'phase_01_[0-2.00pi]'}).
%   names : 1 x n cellstr  ('phase_03_[0-1.50pi]' ...) -- tp_phase_folder_name (core)
%   ks    : 1 x n номери вікон

if nargin < 2, spec = CFG.fik.phases; end
N = CFG.phase.numWindows;
allNames = arrayfun(@(k) tp_phase_folder_name(CFG, k), 1:N, 'UniformOutput', false);

if ischar(spec) || isstring(spec)
    tp_assert(strcmpi(char(spec), 'all'), ...
        'tp_select_phases: текстове значення може бути лише ''all'' (отримано ''%s'')', char(spec));
    ks = 1:N;
elseif iscellstr(spec) %#ok<ISCLSTR>
    ks = find(ismember(allNames, spec));
    tp_assert(numel(ks) == numel(spec), ...
        'tp_select_phases: невідоме вікно в списку імен (є: %s)', strjoin(allNames, ', '));
else
    tp_assert(isnumeric(spec) && all(spec == round(spec)) && all(spec >= 1 & spec <= N), ...
        'tp_select_phases: номери вікон мають бути цілими в 1..%d', N);
    ks = unique(spec(:).', 'stable');
end
names = allNames(ks);
end
