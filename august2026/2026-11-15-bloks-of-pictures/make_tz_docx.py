# -*- coding: utf-8 -*-
r"""
Word-файли одного блоку ТЗ «Нові рисунки» (run_tz_blocks.m кладе в теку блоку captions.csv
і «Стат-моменти_Блок N.csv»):

  Рисунки_Блок N.docx      — усі рисунки блоку в порядку ТЗ, під кожним — підпис за ТЗ
                             (PNG 600 dpi у справжньому розмірі, без перетиснення)
  Стат-моменти_Блок N.docx — таблиці Z1–Z4: сторінка = рисунок; спершу карти (|f| — лінійні,
                             Arg — КРУГОВІ), далі по підблоках: ортогональні перерізи АКФ (+ L),
                             log10 спектрів потужності, вейвлет-коефіцієнти |W| на двох масштабах,
                             |W| у максимумах скелетонів

Запуск:  python make_tz_docx.py <тека_блоку> [примітка]
"""
import csv
import datetime
import pathlib
import re
import sys

from docx import Document
from docx.enum.section import WD_ORIENT
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Mm, Pt
from PIL import Image

BDIR = pathlib.Path(sys.argv[1])
NOTE = sys.argv[2] if len(sys.argv) > 2 else ''
BID = re.match(r'Блок (\S+)', BDIR.name).group(1)
AUX = BDIR / '_службові файли' if (BDIR / '_службові файли').is_dir() else BDIR
DASH = '—'
SMALL = 1e-5
SUBNAME = {'1': 'АКФ', '2': 'спектри потужності', '3': 'вейвлети', '4': 'скелетони'}


def read_csv(p):
    with open(p, encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))


def fmt(v, z):
    try:
        v = float(v)
    except (TypeError, ValueError):
        return DASH
    if v != v:
        return DASH
    if z >= 3 and abs(v) < SMALL:
        return DASH
    if v == 0:
        return '0'
    a = abs(v)
    return f'{v:.2e}' if (a >= 1e4 or a < 1e-3) else f'{v:.4g}'


def shade(cell, hex_color):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:val'), 'clear'); shd.set(qn('w:color'), 'auto'); shd.set(qn('w:fill'), hex_color)
    tcPr.append(shd)


def put(cell, text, bold=False, size=8, center=True):
    cell.text = ''
    p = cell.paragraphs[0]
    if center:
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    pf = p.paragraph_format; pf.space_before = Pt(0); pf.space_after = Pt(0)
    r = p.add_run(text); r.bold = bold; r.font.size = Pt(size)


def para(doc, text, bold=False, size=11, before=0, after=4, center=False):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(before); p.paragraph_format.space_after = Pt(after)
    if center:
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run(text); r.bold = bold; r.font.size = Pt(size)
    return p


def new_doc(landscape=False):
    doc = Document()
    st = doc.styles['Normal']; st.font.name = 'Calibri'; st.font.size = Pt(10)
    s = doc.sections[0]
    if landscape:
        s.orientation = WD_ORIENT.LANDSCAPE
        s.page_width, s.page_height = Mm(297), Mm(210)
    else:
        s.page_width, s.page_height = Mm(210), Mm(297)
    s.left_margin = s.right_margin = Cm(1.5); s.top_margin = s.bottom_margin = Cm(1.5)
    return doc


def figures_doc():
    caps = read_csv(AUX / 'captions.csv')
    doc = new_doc()
    para(doc, f'Блок {BID} — рисунки за ТЗ «Нові рисунки»', bold=True, size=14)
    para(doc, f'{BDIR.name}.  Сформовано {datetime.date.today():%d.%m.%Y}.', size=9)
    if NOTE:
        para(doc, 'Примітка: ' + NOTE, size=9)
    for c in caps:
        f = BDIR / c['file']
        if not f.is_file():
            continue
        doc.add_page_break()
        with Image.open(f) as im:
            w_mm = im.width / 600 * 25.4
        p = doc.add_paragraph(); p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.add_run().add_picture(str(f), width=Mm(min(w_mm, 180)))
        para(doc, c['caption'], size=10, center=False)
        para(doc, f.relative_to(BDIR).as_posix(), size=8)
    out = BDIR / f'Рисунки_Блок {BID}.docx'
    doc.save(out)
    print(f'  {out.name}  ({len(caps)} рисунків)')


HEAD = ['Колонка', 'Приклад', 'Алгоритм', 'Вікно', 'Елемент', 'Величина',
        'Z1', 'Z2', 'Z3', 'Z4', 'Примітка']
WID = [1.3, 1.4, 1.6, 1.6, 1.5, 6.4, 2.0, 2.0, 2.0, 2.0, 3.4]


def table(doc, rows, fill):
    t = doc.add_table(rows=1 + len(rows), cols=len(HEAD)); t.style = 'Table Grid'
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    for j, h in enumerate(HEAD):
        put(t.cell(0, j), h, bold=True); shade(t.cell(0, j), 'D9D9D9')
    for i, r in enumerate(rows, start=1):
        vals = [r['col'], r['example'], r['algo'], r['window'], r['elem'], r['quantity'],
                fmt(r['Z1'], 1), fmt(r['Z2'], 2), fmt(r['Z3'], 3), fmt(r['Z4'], 4), r['extra']]
        for j, v in enumerate(vals):
            put(t.cell(i, j), str(v), center=j != 5)
            if fill:
                shade(t.cell(i, j), fill)
    for j, w in enumerate(WID):
        for row in t.rows:
            row.cells[j].width = Cm(w)


def stats_doc():
    rows = read_csv(AUX / f'Стат-моменти_Блок {BID}.csv')
    doc = new_doc(landscape=True)
    para(doc, f'Стат-моменти — Блок {BID}', bold=True, size=14)
    para(doc, f'{BDIR.name}.  Сформовано {datetime.date.today():%d.%m.%Y}.', size=9)
    for s in [
        'Z1–Z4 розподілів, ПОКАЗАНИХ на панелях рисунків (ті самі дані, що на рисунку).',
        '|f|, АКФ, спектри, вейвлети, скелетони — лінійні моменти: Z1 середнє, Z2 СКВ, Z3 асиметрія, '
        'Z4 надлишковий ексцес (норма 0).',
        'Arg — КРУГОВІ моменти: Z1 середній напрям [0, 2π), Z2 кругове СКВ √(−2 ln R), '
        'Z3 кругова асиметрія, Z4 круговий ексцес (Фішер).',
        'АКФ — значення ортогональних перерізів Δx і Δy у показаному вікні лагів; L — повна ширина на 0.5.',
        'Вейвлети — коефіцієнти |W(a, b)| уздовж b при двох фіксованих масштабах a; a(факт.) — найближчий '
        'масштаб сітки CWT.',
        'Скелетон — |W| у точках WTMM (те, що на гістограмі під скелетоном).',
        '«—» — немає даних (порожній вхідний канал / замало точок у фазовому вікні) або |Z3|, |Z4| < 1e-5.',
    ]:
        doc.add_paragraph(s, style='List Bullet')
    para(doc, 'Формули (x_k — K значень розподілу, NaN відкинуто)', bold=True, size=11, before=6)
    for s in [
        'Лінійні (|f|, АКФ, log10 PSD, |W|, скелетон):  Z1 = (1/K)·Σ x_k;   Z2 = √[(1/K)·Σ (x_k − Z1)²];   '
        'Z3 = (1/K)·Σ ((x_k − Z1)/Z2)³;   Z4 = (1/K)·Σ ((x_k − Z1)/Z2)⁴ − 3.',
        'Кругові (Arg f, φ_k у радіанах):  M1 = (1/K)·Σ e^{iφ_k} = R·e^{iμ};   M2 = (1/K)·Σ e^{2iφ_k} = R2·e^{iμ2};   '
        'Z1 = μ ∈ [0, 2π);   Z2 = √(−2·ln R);   Z3 = R2·sin(μ2 − 2μ) / (1 − R)^{3/2};   '
        'Z4 = (R2·cos(μ2 − 2μ) − R⁴) / (1 − R)².',
        'АКФ: двовимірна автокореляція карти (лише пари справжніх точок), нормована на 1 у нулі; '
        'перерізи Δx і Δy — рядок і стовпець через центр у показаному вікні лагів; '
        'L — повна ширина перерізу на рівні 0.5.',
        'Спектр потужності: |FFT(АКФ)| (теорема Вінера–Хінчина), без нульової частоти, у log10.',
        'Вейвлет: CWT профілю карти (центральний рядок), вейвлет Морле (amor), 12 голосів на октаву; '
        'перерізи |W(a, b)| уздовж b при a = 10 і a = 55.',
        'Скелетон: |W| у локальних максимумах модуля вейвлет-перетворення (WTMM).',
        'Код: august2026\\core\\tp_moments.m (моменти), paper_figures\\common\\paper_prep.m (АКФ, спектр, вейвлет).',
    ]:
        doc.add_paragraph(s, style='List Bullet')
    if NOTE:
        para(doc, 'Примітка до блоку: ' + NOTE, size=9, before=4)

    figs = []
    for r in rows:
        if r['fig'] not in figs:
            figs.append(r['fig'])
    figs.sort(key=lambda s: int(re.sub(r'\D', '', s) or 0))
    for fig in figs:
        doc.add_page_break()
        para(doc, f'Блок {BID} · {fig}', bold=True, size=12)
        fr = [r for r in rows if r['fig'] == fig]
        seen, maps = set(), []
        for r in fr:                                        # карти однакові в усіх підблоках — один раз
            if r['quantity'].startswith('карта') and (r['col'], r['quantity']) not in seen:
                seen.add((r['col'], r['quantity'])); maps.append(r)
        para(doc, 'Карти: модулі (лінійні) і аргументи (кругові)', bold=True, size=10, before=2)
        table(doc, maps, 'DEEAF6')
        subs = sorted({r['sub'] for r in fr if r['sub'] and not r['quantity'].startswith('карта')})
        for sub in subs:
            sr = [r for r in fr if r['sub'] == sub and not r['quantity'].startswith('карта')]
            para(doc, f'{sub} — {SUBNAME.get(sub.split(".")[-1], "")}', bold=True, size=10, before=6)
            table(doc, sr, 'FBE5D6')
    out = BDIR / f'Стат-моменти_Блок {BID}.docx'
    doc.save(out)
    print(f'  {out.name}  ({len(rows)} рядків)')


if __name__ == '__main__':
    figures_doc()
    stats_doc()
