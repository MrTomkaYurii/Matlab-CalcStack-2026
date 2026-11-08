function run_Overnight_All(firstStage)
% RUN_OVERNIGHT_ALL  Повний нічний перерахунок (листопад 2026), без участі людини:
%   1) тести формул  2) звірка GPU=CPU  3) усі result.mat (GPU)
%   4) рисунки статті + таблиці Z  5) таблиця кругових моментів (16 елементів)
%   6) аналітика  7) збірка для Горського  8) аналітика статистичних моментів.
%   Етапи 1-3 обов'язкові (падіння — стоп); 4-8 незалежні (падіння — запис у лог, далі).
%   Прогрес: смуга етапів тут + смуга «зразок / приклад / вікно» на етапі 3 (tp_progress).
%   Лог усього виводу: C:\August 2026-Results\overnight_<дата_час>.log
%   Запуск: відкрити цей файл у MATLAB і натиснути Run (F5),
%           або  matlab -batch "run_Overnight_All"   (з теки august2026)
%
%   ЖУРНАЛ (на випадок вимкнення світла): C:\August 2026-Results\overnight_journal.txt
%   Кожен завершений етап дописується рядком "DONE | <етап> | <час>". Після
%   перезапуску ці етапи пропускаються — просто запусти скрипт ще раз.
%   Рядок "START | <етап>" без "DONE" після нього = на цьому етапі впало (лог — у рядку).
%   Етап 4 пропускає вже збережені рисунки (fig_exists), етап 9 — теки з viz_done.txt.
%   Перерахувати етап заново — видалити його рядок з журналу.
%   run_Overnight_All(k) — почати не раніше етапу k (рядка k у списку).

if nargin < 1, firstStage = 1; end
here = fileparts(mfilename('fullpath'));
addpath(here, fullfile(here,'config'), genpath(fullfile(here,'core')), ...
    fullfile(here,'paper_figures'), fullfile(here,'paper_figures','common'), fullfile(here,'tests'), ...
    fullfile(here,'analysis_stats'));
oldVis = get(groot, 'DefaultFigureVisible');
set(groot, 'DefaultFigureVisible', 'off');           % рисунки не показуються 
logFile = fullfile('C:\August 2026-Results', ['overnight_' char(datetime('now','Format','yyyyMMdd_HHmm')) '.log']);
diary(logFile);
diaryOff = onCleanup(@() diary('off'));
    '1. Тести формул',                      @() test_recalc_formulas(),          true

stages = {
    '2. Звірка GPU/CPU',                    @() run_Recalc_August_GPU(true),     true
    '3. Повний перерахунок result.mat',     @() run_Recalc_August_GPU(),         true
    '4. Рисунки статті + таблиці Z',        @() run_all_figures(),               false   % вікна FIG.phase (01 і 06)
    '5. Кругові моменти',                   @() make_circular_table(cfg_figures(), cfg_TwoPoint().elements), false
    '6. Аналітика',                         @() run_TwoPoint_Analytics(),        false
    '7. Збірка для Горського',              @() run_TwoPoint_CollectForHorsky(), false
    '8. Аналітика статистичних моментів',   @() run_analysis_stats(),            false   % читає stats.*.txt рисунків (етап 4)
    '9. Поелементні рисунки пайплайну',     @() run_TwoPoint_VizFromResults(),   false   % усі CFG.viz.* з result.mat; найдовший — останнім
    };
n = size(stages, 1);
journal = fullfile('C:\August 2026-Results', 'overnight_journal.txt');
done = readJournal(journal);
T0 = tic;
failed = {};
for i = firstStage:n
    if any(strcmp(done, stages{i,1}))
        fprintf('#### ЕТАП %d/%d: %s — вже виконано (журнал), пропускаю ####\n', i, n, stages{i,1});
        continue;
    end
    fprintf('\n\n#### ЕТАП %d/%d: %s  [%s] ####\n', i, n, stages{i,1}, char(datetime('now','Format','HH:mm')));
    writeJournal(journal, 'START', stages{i,1}, logFile);   % START без DONE = тут упало
    if step(stages{i,:})
        writeJournal(journal, 'DONE', stages{i,1}, '');
    else
        writeJournal(journal, 'FAIL', stages{i,1}, logFile);
        failed{end+1} = stages{i,1}; %#ok<AGROW>
    end
    tp_progress(i, n, T0, ['етап ' stages{i,1}]);
end

fprintf('\n=== УСЕ ЗАВЕРШЕНО за %.1f год ===\n', toc(T0)/3600);
if ~isempty(failed)
    fprintf(2, 'Етапи з помилками (див. лог %s):\n', logFile);
    fprintf(2, '  - %s\n', failed{:});
end
end

function writeJournal(journal, tag, stage, note)
fid = fopen(journal, 'a', 'n', 'UTF-8');
fprintf(fid, '%s | %s | %s | %s\n', tag, stage, char(datetime('now','Format','yyyy-MM-dd HH:mm')), note);
fclose(fid);
end

function done = readJournal(journal)
done = {};
if ~isfile(journal), return; end
L = readlines(journal, 'Encoding', 'UTF-8');
for j = 1:numel(L)
    p = strtrim(split(L(j), '|'));
    if numel(p) >= 2 && p(1) == "DONE", done{end+1} = char(p(2)); end %#ok<AGROW>
end
end

function ok = step(name, fn, required)
t = tic;
ok = true;
try
    fn();
    fprintf('=== %s: OK (%.1f хв) ===\n', name, toc(t)/60);
catch ME
    ok = false;
    fprintf(2, '=== %s: ПОМИЛКА — %s ===\n%s\n', name, ME.message, getReport(ME, 'extended', 'hyperlinks', 'off'));
    if required, rethrow(ME); end
end
close all force;
end
