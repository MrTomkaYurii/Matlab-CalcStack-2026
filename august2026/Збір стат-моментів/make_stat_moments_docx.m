function make_stat_moments_docx(resultsRoot)
% MAKE_STAT_MOMENTS_DOCX  Збирає Z1-Z4 з усіх fXX_stats.txt у три Word-файли
%   (Серце, Мозг, Мяз живота) поряд із цим скриптом.
%   Сторінка = алгоритм x елемент; рядки = приклад 1/2/3 x 8 фазових вікон;
%   колонки = |f| | arg кругові | arg центральні на [0,2pi) (поки прочерки).

if nargin < 1
    resultsRoot = 'C:\August 2026-Results\Розрахунки - Двот. елем. ММ';
end
here = fileparts(mfilename('fullpath'));
pyScript = fullfile(here, 'build_stat_moments_docx.py');

fprintf('Збір стат-моментів у Word: %s ...\n', resultsRoot);
status = system(sprintf('python "%s" "%s" "%s"', pyScript, resultsRoot, here));
if status == 0
    fprintf('Готово: %s\n', here);
else
    fprintf(2, 'Помилка генерації Word. Перевірте python і бібліотеку python-docx.\n');
end
end
