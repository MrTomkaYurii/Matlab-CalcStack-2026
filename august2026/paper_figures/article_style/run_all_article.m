function run_all_article(figs, scope)
% RUN_ALL_ARTICLE  Нічний прогін: усі рисунки "як у статті" (Fig1–Fig7) + Word-файли.
%   Усі пари елементів, тканини, приклади, алгоритми й 8 фазових вікон.
%   Готові PNG пропускаються — після зупинки просто запустити ще раз.
%
%       run_all_article                       % усе
%       run_all_article({'Fig2','Fig3'})      % лише ці рисунки
%       run_all_article({}, struct('variants',{{'OX'}}))   % обмежити обсяг
%
%   Вивід: C:\August 2026-Results\Розрахунки - Скомпановані рисунки - Формат статті 09.11\FigN\
%   Журнал: run_all_article.log у тій самій теці.

here = fileparts(mfilename('fullpath'));
addpath(here, fileparts(here), fullfile(fileparts(here), 'common'));
if nargin < 1 || isempty(figs); figs = {'Fig1','Fig2','Fig3','Fig4','Fig5','Fig6','Fig7'}; end
if nargin < 2; scope = struct(); end
warning('off', 'MATLAB:print:ContentTypeImageSuggested');
outRoot = 'C:\August 2026-Results\Розрахунки - Скомпановані рисунки - Формат статті 09.11';
if ~exist(outRoot, 'dir'); mkdir(outRoot); end
diary(fullfile(outRoot, 'run_all_article.log'));  diary on;
tp_paper_normalize('reset');  acf_win('reset');

t0 = tic;
fprintf('=== %s: %s ===\n', datestr(now, 'dd.mm.yyyy HH:MM'), strjoin(figs, ', '));
for i = 1:numel(figs)
    t1 = tic;
    fprintf('\n=== %s ===\n', figs{i});
    try
        if strcmp(figs{i}, 'Fig7'); n = make_fig7_article(scope);
        else;                       n = make_fig_article(figs{i}, scope);
        end
        fprintf('=== %s: %d рисунків за %.0f хв ===\n', figs{i}, n, toc(t1)/60);
    catch ME
        fprintf(2, '=== %s: ПОМИЛКА %s ===\n', figs{i}, ME.message);
    end
end
fprintf('\n=== Готово за %.1f год ===\n', toc(t0)/3600);
diary off;
end
