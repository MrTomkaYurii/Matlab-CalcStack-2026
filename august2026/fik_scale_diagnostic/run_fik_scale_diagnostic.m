function run_fik_scale_diagnostic(cfgOverride)
% RUN_FIK_SCALE_DIAGNOSTIC  Покрокова діагностика: ЧОМУ елементи двоточкової
%   матриці Мюллера f_ik виходять малими (~10^-6). Проходить усю цепочку від
%   сирих реконструйованих полів Ex,Ey до комплексних f_ik, на кожному кроці
%   зберігає картинки з діапазонами величин, і збирає підсумковий .docx.
%
%       run_fik_scale_diagnostic              % бере cfg_fik_scale_diagnostic()
%       run_fik_scale_diagnostic(myCfg)
%
%   Скрипти:   august2026\fik_scale_diagnostic\
%   Результати: <C.outRoot>\<sample>.ex<example>\
%                 steps\NN.<name>.png        — усі проміжні картинки
%                 magnitude_budget.csv       — сходинка порядків величини
%                 <docx.name>.docx           — уся аналітика + картинки

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(here, fullfile(root,'core'));
if nargin >= 1 && isstruct(cfgOverride); C = cfgOverride; else; C = cfg_fik_scale_diagnostic(); end
U = fs_util();

% R2025b: у headless-режимі тема фігур може резолвитись у "dark" -> чорні осі
% на експорті. Фіксуємо світлу тему на всю сесію.
try
    st = settings;
    st.matlab.appearance.figure.GraphicsTheme.TemporaryValue = 'light';
catch
end

caseTag = sprintf('%s.ex%s', C.sample, C.example);
paths = struct();
paths.case  = fullfile(C.outRoot, caseTag);
paths.steps = fullfile(paths.case, 'steps');
if ~isfolder(paths.steps); mkdir(paths.steps); end

fprintf('=== ДІАГНОСТИКА МАЛОСТІ f_ik ===\n');
fprintf('основний приклад: %s / %s   (crop %d, RC=%s)\n', C.sample, C.example, C.crop.size, C.rcSource);
fprintf('вихід: %s\n\n', paths.case);

[IMG, meta] = U.loadFields(C.matRoot, C.sample, C.example, C.crop, C.rcSource);
if ~isempty(meta.zero)
    fprintf(2, '  примітка: у цьому прикладі порожні канали: %s\n', strjoin(meta.zero, ', '));
end

steps = {};
steps{end+1} = guard(@() s1_context(C, paths, U),           '1  постановка задачі');
steps{end+1} = guard(@() s2_fields(C, paths, U, IMG, meta), '2  сирі поля Ex, Ey');
steps{end+1} = guard(@() s3_intensity(C, paths, U, IMG),    '3  інтенсивність I');

fprintf('-- крок 4  двоточковий зріз --\n');
try
    [R4, DBG, F] = s4_pair(C, paths, U, IMG);
    printlines(R4);
catch ME
    fprintf(2, '   [fail] %s\n', ME.message);
    R4 = emptyStep(ME.message);  DBG = [];  F = [];
end
steps{end+1} = R4;

if ~isempty(DBG)
    steps{end+1} = guard(@() s5_ab(C, paths, U, DBG), '5  проміжні a_i, b_i');
    steps{end+1} = guard(@() s6_fik(C, paths, U, F),  '6  збірка f_ik');
else
    steps{end+1} = emptyStep('крок 4 не дав DBG');
    steps{end+1} = emptyStep('крок 4 не дав F');
end

budgetRows = {};
for s = 1:numel(steps); budgetRows = [budgetRows, steps{s}.budget]; end %#ok<AGROW>
fprintf('-- крок 7  бюджет масштабу + модель july2026 --\n');
try
    R7 = s7_budget(C, paths, U, IMG, budgetRows);  printlines(R7);
catch ME
    fprintf(2, '   [fail] %s\n', ME.message);  R7 = emptyStep(ME.message);
end
steps{end+1} = R7;

steps{end+1} = guard(@() s8_defect(C, paths, U), '8  дефект нульових кадрів');

% ---- зведений CSV бюджету масштабу ---------------------------------
allBudget = {};
for s = 1:numel(steps); allBudget = [allBudget, steps{s}.budget]; end %#ok<AGROW>
if ~isempty(allBudget)
    T = struct2table([allBudget{:}]);
    writetable(T, fullfile(paths.case, 'magnitude_budget.csv'));
    fprintf('\n[ok] %s\n', fullfile(paths.case, 'magnitude_budget.csv'));
end

% ---- .docx --------------------------------------------------------
if C.docx.make
    try
        p = build_docx_fik(C, paths, steps);
        fprintf('[ok] %s\n', p);
    catch ME
        fprintf(2, '[docx skip] %s\n', ME.message);
    end
end

fprintf('\n=== готово -> %s ===\n', paths.case);
end

% ======================================================================
function R = guard(fn, label)
fprintf('-- крок %s --\n', label);
try
    R = fn();  printlines(R);
catch ME
    fprintf(2, '   [fail] %s\n', ME.message);
    R = emptyStep(ME.message);
end
end

function printlines(R)
for L = 1:numel(R.lines); fprintf('   %s\n', R.lines{L}); end
end

function R = emptyStep(msg)
R = struct('figs',{{}}, 'lines',{{sprintf('[крок не виконано: %s]', msg)}}, 'budget',{{}});
end
