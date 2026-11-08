# -*- coding: utf-8 -*-
r"""
Рисунки FigN «формат статті» -> Word: файл = тканина x алгоритм
(«Рисунки_<тканина>_<алгоритм>.docx», як «Стат-моменти_<тканина>_<алгоритм>.docx»), у теці FigN.
Порядок: пара елементів (f33-f44, f23-f24) -> приклад 1/2/3 -> 8 фазових вікон (-> mod, arg для Fig7);
під рисунком — назва файлу. Рисунок вставляється у справжньому розмірі, PNG 600 dpi без перетиснення.

Запуск:  python make_figures_docx.py <тека_FigN>
"""
import pathlib
import re
import sys

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.shared import Cm, Mm, Pt
from PIL import Image

FIGDIR = pathlib.Path(sys.argv[1])
TISSUE = {'heart': 'Серце', 'brain': 'Мозг', 'muscle': 'Мяз живота'}
PAIRS = ['f33-f44', 'f23-f24', 'mueller']
COMP = {'': 0, 'mod': 0, 'arg': 1}
# Fig1.f33-f44.OX.heart.zrazok1.phase01.0-2pi.png | Fig7.mueller.OX.heart.zrazok1.phase01.0-2pi.mod.png
NAME = re.compile(r'^(Fig\d)\.(f\d\d-f\d\d|mueller)\.([^.]+)\.(\w+)\.zrazok(\d+)\.phase(\d\d)\.0-[\d.]+pi\.?(mod|arg)?\.png$')


def main():
    png = FIGDIR / 'png'
    if not png.is_dir():
        print(f'Немає {png}'); return
    for vdir in sorted(p for p in png.iterdir() if p.is_dir()):
        groups = {}
        for f in vdir.rglob('Fig*.png'):            # Fig7: ще й підтеки «Відсутні / Усі вхідні канали»
            m = NAME.match(f.name)
            if not m:
                continue
            fig, pair, variant, tissue, ex, ph, comp = m.groups()
            key = (PAIRS.index(pair) if pair in PAIRS else 9, int(ex), int(ph), COMP[comp or ''])
            sub = f.parent.name if f.parent != vdir else ''
            groups.setdefault((tissue, sub), []).append((key, f))
        for (tissue, sub), items in groups.items():
            doc = Document()
            st = doc.styles['Normal']; st.font.name = 'Calibri'; st.font.size = Pt(10)
            s = doc.sections[0]
            s.page_width, s.page_height = Mm(210), Mm(297)
            s.left_margin = s.right_margin = Cm(1.5)
            s.top_margin = s.bottom_margin = Cm(1.5)
            t = doc.add_paragraph()
            r = t.add_run(f'{FIGDIR.name} — {TISSUE.get(tissue, tissue)} · {vdir.name}')
            r.bold = True; r.font.size = Pt(14)
            for i, (_, f) in enumerate(sorted(items)):
                if i:
                    doc.add_page_break()
                with Image.open(f) as im:
                    w_mm = im.width / 600 * 25.4
                p = doc.add_paragraph(); p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                p.add_run().add_picture(str(f), width=Mm(min(w_mm, 180)))
                c = doc.add_paragraph(f.stem); c.alignment = WD_ALIGN_PARAGRAPH.CENTER
                c.runs[0].font.size = Pt(9)
            # Fig7: окремий файл на підтеку, поруч із нею (…\png\OX\Відсутні вхідні канали\ -> «… (Відсутні вхідні канали).docx»)
            sfx = f' ({sub})' if sub else ''
            out = FIGDIR / f'Рисунки_{TISSUE.get(tissue, tissue)}_{vdir.name}{sfx}.docx'
            doc.save(out)
            print(f'  {out.name}  ({len(items)} рисунків, {out.stat().st_size / 1e6:.1f} МБ)')


if __name__ == '__main__':
    main()
