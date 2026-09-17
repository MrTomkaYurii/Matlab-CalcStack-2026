function make_analytics_guide_docx()
% MAKE_ANALYTICS_GUIDE_DOCX  Генерує Word-посібник з аналітики статистичних моментів.
%   Створює файл:
%   "C:\August 2026-Results\Аналітика - Статистичні моменти\Аналітичний_гайд_статистичні_моменти.docx"

here = fileparts(mfilename('fullpath'));
pyScript = fullfile(here, 'build_analytics_guide_docx.py');

fprintf('Генерація Word-гайду: %s ...\n', pyScript);
status = system(sprintf('python "%s"', pyScript));
if status == 0
    fprintf('Успішно згенеровано Word-документ!\n');
else
    fprintf(2, 'Помилка генерації Word-документа. Перевірте наявність python та бібліотеки python-docx.\n');
end

end
