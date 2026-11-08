# -*- coding: utf-8 -*-
r"""
Перекладання готових рисунків «формат статті» (Fig1–Fig7) у дві групи БЕЗ перерахунку:

  <DST>\Відсутні вхідні канали\FigN\png\<алгоритм>\*.png  + Word-файли в FigN
  <DST>\Усі вхідні канали\FigN\png\<алгоритм>\*.png       + Word-файли в FigN
  (опис і пояснення дефекту — «Прочитати обов'язково.docx» у корені DST, make_root_readme_docx.py)

Належність зразка (тканина + приклад) до групи береться з уже відсортованого Fig7
(SRC\Fig7\png\<алгоритм>\<група>\...) — тобто з фактичної перевірки порожніх елементів.
PNG КОПІЮЮТЬСЯ (вихідна тека не змінюється); Word-файли збираються заново тими самими
скриптами make_figures_docx.py і (для Fig1) build_stat_moments_docx.py — лише по образцях групи.

Запуск:  python regroup_by_channels.py [SRC] [DST]
"""
import pathlib
import re
import shutil
import subprocess
import sys
from collections import defaultdict

HERE = pathlib.Path(__file__).resolve().parent
SRC = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else
                   r'C:\August 2026-Results\Розрахунки - Скомпановані рисунки - Формат статті 09.11')
DST = pathlib.Path(sys.argv[2] if len(sys.argv) > 2 else
                   str(SRC) + ' - За групами каналів')
GROUPS = ['Відсутні вхідні канали', 'Усі вхідні канали']
TISSUE = {'heart': 'Серце', 'brain': 'Мозг', 'muscle': 'Мяз живота'}
NAME = re.compile(r'^Fig\d\.(?:f\d\d-f\d\d|mueller)\.([^.]+)\.(\w+)\.zrazok(\d+)\.')


def group_map():
    """{(tissue, example): група} з підтек Fig7; перевіряє, що всі алгоритми згодні."""
    M = {}
    for f in (SRC / 'Fig7' / 'png').glob('*/*/Fig7*.png'):
        g = f.parent.name
        m = NAME.match(f.name)
        if g not in GROUPS or not m:
            continue
        key = (m.group(2), int(m.group(3)))
        if M.setdefault(key, g) != g:
            sys.exit(f'Суперечність для {key}: {M[key]} / {g}')
    return M


def copy_pngs(M):
    n = defaultdict(int)
    for f in SRC.glob('Fig*/png/**/Fig*.png'):
        m = NAME.match(f.name)
        fig = f.relative_to(SRC).parts[0]
        variant = f.relative_to(SRC).parts[2]
        key = (m.group(2), int(m.group(3)))
        if key not in M:
            sys.exit(f'Невідома група для {key} ({f.name})')
        g = M[key]
        out = DST / g / fig / 'png' / variant / f.name
        out.parent.mkdir(parents=True, exist_ok=True)
        if not out.is_file() or out.stat().st_size != f.stat().st_size:
            shutil.copy2(f, out)
        n[(g, fig)] += 1
    return n


def stats_docx(M, g, out):
    """Стат-моменти Fig1 лише для прикладів цієї групи (сторінка = елемент, як у make_fig1_stats_docx)."""
    code = f'''
import sys, pathlib
sys.argv = sys.argv[:1]
sys.path.insert(0, r"{HERE.parent.parent / 'Збір стат-моментів'}")
import build_stat_moments_docx as B
if not B.CEN.is_dir(): B.CEN = B.ROOT      # fXX_stats_arg_central_0-2pi.txt лежать поруч із fXX_stats.txt
D = B.collect(); B.collect = lambda: D
B.OUT = pathlib.Path(r"{out}")
B.ELEMENTS = ['f33', 'f44', 'f23', 'f24']
for sample, exs in {sorted(_by_tissue(M, g).items())!r}:
    B.SAMPLES = [sample]; B.EXAMPLES = exs
    B.main()
'''
    subprocess.run([sys.executable, '-c', code], check=True)


def _by_tissue(M, g):
    T = defaultdict(list)
    for (t, ex), gg in M.items():
        if gg == g:
            T[TISSUE[t]].append(ex)
    return {k: sorted(v) for k, v in T.items()}


def main():
    M = group_map()
    for g in GROUPS:
        print(f'{g}: ' + ', '.join(f'{t} {v}' for t, v in sorted(_by_tissue(M, g).items())))
    n = copy_pngs(M)
    for k in sorted(n):
        print(f'  {k[0]} \\ {k[1]}: {n[k]} PNG')
    for g in GROUPS:
        gdir = DST / g
        for figdir in sorted(p for p in gdir.iterdir() if p.is_dir()):
            print(f'\n=== {g} \\ {figdir.name}: Word ===', flush=True)
            subprocess.run([sys.executable, str(HERE / 'make_figures_docx.py'), str(figdir)], check=True)
            if figdir.name == 'Fig1':
                stats_docx(M, g, figdir)
    print('\nГотово:', DST)


if __name__ == '__main__':
    main()
