# -*- coding: utf-8 -*-
r"""
Стат-моменти Z1-Z4 для Fig1 «формат статті» — у тому ж вигляді, що й у «Збір стат-моментів»
(build_stat_moments_docx.py): файл = тканина x алгоритм, сторінка = елемент,
рядки = приклад 1/2/3 x 8 фазових вікон, колонки = |f| | arg кругові | arg центральні [0, 2π).
Лише елементи Fig1 (f33, f44, f23, f24); файли кладуться в теку Fig1 поруч із рисунками.

Запуск:  python make_fig1_stats_docx.py [тека_виводу]
"""
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent.parent / 'Збір стат-моментів'))
out = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else
                   r'C:\August 2026-Results\Розрахунки - Скомпановані рисунки - Формат статті 09.11\Fig1')
sys.argv = sys.argv[:1]                      # модуль читає sys.argv при імпорті — беремо його типові шляхи

import build_stat_moments_docx as B         # noqa: E402

B.OUT = out
B.ELEMENTS = ['f33', 'f44', 'f23', 'f24']   # елементи Fig1 (пари f33-f44, f23-f24)
B.main()
