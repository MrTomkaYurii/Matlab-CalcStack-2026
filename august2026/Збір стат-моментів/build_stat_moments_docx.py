# -*- coding: utf-8 -*-
r"""
Збір статистичних моментів Z1-Z4 з поелементних файлів fXX_stats.txt
у 12 Word-файлів: зразок (Серце, Мозг, Мяз живота) x алгоритм (XY, generalized, OX, OY).
У шапці кожного — опис алгоритму і схема (schemes\scheme_<алгоритм>.png, draw_algo_schemes.m).

Сторінка = елемент. Рядки = приклад 1/2/3 x 8 фазових вікон.
Колонки = три групи моментів:
  1) |f|                          - лінійні (Z1 сер., Z2 СКВ, Z3 асиметрія, Z4 ексцес)
  2) arg, кругові                 - як у fXX_stats.txt (tp_moments, isPhase)
  3) arg, центральні на [0, 2pi)  - fXX_stats_arg_central_0-2pi.txt (run_ArgCentralMoments.m,
                                      C:\August 2026-Results-3)

Запуск:  python build_stat_moments_docx.py [корінь_результатів] [тека_виводу] [корінь_центральних]
"""
import sys, re, pathlib, datetime
from docx import Document
from docx.shared import Pt, Cm, RGBColor
from docx.enum.section import WD_ORIENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

ROOT = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else
                    r'C:\August 2026-Results\Розрахунки - Двот. елем. ММ')
OUT  = pathlib.Path(sys.argv[2] if len(sys.argv) > 2 else pathlib.Path(__file__).parent)
CEN  = pathlib.Path(sys.argv[3] if len(sys.argv) > 3 else
                    r'C:\August 2026-Results-3\Розрахунки - Двот. елем. ММ')

SAMPLES  = ['Серце', 'Мозг', 'Мяз живота']
EXAMPLES = [1, 2, 3]
VARIANTS = ['XY', 'generalized', 'OX', 'OY']
WINDOWS  = [2.00, 1.75, 1.50, 1.25, 1.00, 0.75, 0.50, 0.25]
ELEMENTS = [f'f{i}{k}' for i in range(1, 5) for k in range(1, 5)]

MOD_SCALE = 1.0        # |f| показується в сирих одиницях (масштаб між прикладами різний)
SMALL     = 1e-5         # |Z3|, |Z4| < SMALL -> прочерк
DASH      = '—'

# (назва групи, колір шапки, колір комірок)
GROUPS = [
    ('|f|',                         '9DC3E6', 'DEEAF6'),
    ('arg — кругові',               'A9D08E', 'E2EFDA'),
    ('arg — центральні на [0, 2π)', 'F4B183', 'FBE5D6'),
]
ZNAMES = ['Z1', 'Z2', 'Z3', 'Z4']


# ---------------------------------------------------------------- читання
LINE = re.compile(r'^(\|f\||Arg \[rad\])\s+(\d+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)')

def read_stats(path):
    r = {}
    for line in path.read_text(encoding='utf-8').splitlines():
        m = LINE.match(line)
        if m:
            k = 'mod' if m.group(1) == '|f|' else 'arg'
            r[k] = [float(m.group(i)) for i in range(3, 7)]
            r['N'] = int(m.group(2))
    return r

def key_of(f, root):
    p = f.relative_to(root).parts
    m = re.search(r'0-([\d.]+)pi', p[2])
    if not m:
        return None
    variant = p[4] if p[3] == 'orthogonal' else p[3]
    return (p[0], int(p[1]), variant, round(float(m.group(1)), 2), f.name[:3])

def collect():
    """{(sample, example, variant, window, element): {'mod': [...], 'arg': [...], 'cen': [...], 'N': n}}"""
    D = {}
    for f in ROOT.rglob('f??_stats.txt'):
        k = key_of(f, ROOT)
        if k:
            D[k] = read_stats(f)
    nCen = 0
    if CEN.is_dir():
        for f in CEN.rglob('f??_stats_arg_central_0-2pi.txt'):
            k = key_of(f, CEN)
            if k:
                D.setdefault(k, {})['cen'] = read_stats(f).get('arg')
                nCen += 1
    print(f'Центральні моменти arg: {nCen} файлів у {CEN}')
    return D


# ---------------------------------------------------------------- формат чисел
def fmt(v, z, scale=1.0):
    if v is None or v != v:                       # None або NaN
        return DASH
    v = v * scale
    if z >= 2 and abs(v) < SMALL:                 # Z3, Z4 ~ 0
        return DASH
    if v == 0:
        return '0'
    a = abs(v)
    if a >= 1e4 or a < 1e-3:
        return f'{v:.2e}'
    return f'{v:.4g}'

def win_label(w):
    return '0–2π' if w == 2.0 else f'0–{w:g}π'


# ---------------------------------------------------------------- docx-утиліти
def shade(cell, hex_color):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:val'), 'clear'); shd.set(qn('w:color'), 'auto'); shd.set(qn('w:fill'), hex_color)
    tcPr.append(shd)

def border(cell, **edges):
    """edges: top/bottom/left/right = товщина у восьмих пункта (4 = тонка, 18 = жирна)"""
    tcPr = cell._tc.get_or_add_tcPr()
    b = tcPr.find(qn('w:tcBorders'))
    if b is None:
        b = OxmlElement('w:tcBorders'); tcPr.append(b)
    for edge, sz in edges.items():
        el = b.find(qn(f'w:{edge}'))
        if el is None:
            el = OxmlElement(f'w:{edge}'); b.append(el)
        el.set(qn('w:val'), 'single'); el.set(qn('w:sz'), str(sz)); el.set(qn('w:color'), '000000')

def put(cell, text, bold=False, size=7.5, align=WD_ALIGN_PARAGRAPH.CENTER):
    cell.text = ''
    p = cell.paragraphs[0]
    p.alignment = align
    pf = p.paragraph_format; pf.space_before = Pt(0); pf.space_after = Pt(0); pf.line_spacing = 1.0
    run = p.add_run(text); run.bold = bold; run.font.size = Pt(size)
    cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER

def landscape(doc):
    s = doc.sections[0]
    s.orientation = WD_ORIENT.LANDSCAPE
    s.page_width, s.page_height = Cm(29.7), Cm(21.0)
    for side in ('left_margin', 'right_margin'):
        setattr(s, side, Cm(1.2))
    s.top_margin = s.bottom_margin = Cm(1.0)

def heading(doc, text, size=12, before=0):
    p = doc.add_paragraph()
    pf = p.paragraph_format; pf.space_before = Pt(before); pf.space_after = Pt(3)
    r = p.add_run(text); r.bold = True; r.font.size = Pt(size)
    return p


# ---------------------------------------------------------------- алгоритми
SCHEMES = pathlib.Path(__file__).parent / 'schemes'      # draw_algo_schemes.m
SHOW_SCHEMES = False                                     # True — вставити схему алгоритму в шапку

ALGO_TITLE = {
    'OX':          'OX — ортогональний уздовж осі X',
    'OY':          'OY — ортогональний уздовж осі Y',
    'XY':          'XY — хрест X + Y (зведена карта)',
    'generalized': 'generalized — узагальнений (усі рознесення)',
}
ALGO_TEXT = {
    'OX': ('Для кожної першої точки r₁ = (x, y) кадру друга точка береться на відстані d = 1 px праворуч, '
           'r₂ = r₁ + (d, 0), і для цієї пари рахується f_ik(r₁, r₂). Результат — карта розміром із кадр у '
           'координатах першої точки; кожен піксель — окрема пара, без усереднення. Крайовий стовпець без пари '
           'та точки поза фазовим вікном — NaN і в моменти не входять. |f| — у сирих одиницях поля.'),
    'OY': ('Те саме, що OX, але друга точка стоїть на d = 1 px вище: r₂ = r₁ + (0, d). Карта в координатах першої '
           'точки, кожен піксель — окрема пара; крайовий рядок без пари та точки поза фазовим вікном — NaN. '
           'Порівняння OX і OY показує анізотропію (відмінність уздовж двох осей). |f| — у сирих одиницях поля.'),
    'XY': ('Для кожної першої точки r₁ рахуються обидві пари — праворуч r₁ + (d, 0) і вгору r₁ + (0, d), d = 1 px, — '
           'і складаються КОМПЛЕКСНО, до модуля й аргумента, без ділення: f_ik = f_ik(OX) + f_ik(OY). Потім уся '
           'карта ділиться на одне число — медіану |f₁₁| (нормування масштабу), тому |f| у XY має порядок 1, '
           'на відміну від OX/OY/generalized (~10⁻⁷). Фазове вікно накладається на вже складену карту за її власним arg.'),
    'generalized': ('Узагальнений двоточковий скан (2D псевдо-АКФ). Для кожного рознесення Δ = (Δx, Δy), |Δx|, |Δy| < N, '
           'Δ ≠ 0, беруться ВСІ перші точки r₁, для яких друга точка r₁ + Δ лежить у кадрі, і по них усереднюється: '
           'модуль — арифметично, аргумент — кругово, atan2(Σ sin, Σ cos). Результат — одна Δ-карта '
           '(799 × 799 − 1 = 638 400 значень — це N у таблицях), а не карта в координатах кадру. '
           'Пари з Δ і −Δ — ті самі точки у зворотному порядку, тому розподіл arg дзеркально-симетричний: '
           'кругова асиметрія Z3 тотожно 0 (у таблиці «—»), середній напрям — 0 або π, а сам arg близький до '
           'рівномірного (Z4 ≈ 0). Інформативні тут насамперед моменти модуля.'),
}


# ---------------------------------------------------------------- легенда
def legend(doc, sample, variant):
    t = doc.add_paragraph()
    r = t.add_run(f'Статистичні моменти Z1–Z4 — «{sample}» · {variant}'); r.bold = True; r.font.size = Pt(16)
    doc.add_paragraph(f'Сформовано: {datetime.date.today():%d.%m.%Y}.  '
                      f'Джерело: fXX_stats.txt у «{ROOT}», fXX_stats_arg_central_0-2pi.txt у «{CEN}».')

    heading(doc, f'Алгоритм: {ALGO_TITLE[variant]}', 12, 6)
    doc.add_paragraph(ALGO_TEXT[variant])
    img = SCHEMES / f'scheme_{variant}.png'
    if SHOW_SCHEMES and img.is_file():
        p = doc.add_paragraph(); p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.add_run().add_picture(str(img), width=Cm(22 if variant == 'generalized' else 17))

    heading(doc, 'Структура', 12, 6)
    for s in [
        'Одна сторінка = один елемент f_ik (f11 … f44).',
        'Рядки: приклади 1, 2, 3 (розділені жирною лінією), у кожному — 8 фазових вікон від 0–2π до 0–0.25π.',
        'Колонки: три групи моментів, розділені жирними вертикальними лініями та кольором (див. нижче).',
    ]:
        doc.add_paragraph(s, style='List Bullet')

    heading(doc, 'Групи моментів', 12, 6)
    tbl = doc.add_table(rows=4, cols=3); tbl.style = 'Table Grid'; tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    for j, h in enumerate(['Група', 'Що означають Z1 … Z4', 'Одиниці']):
        put(tbl.cell(0, j), h, bold=True, size=9)
    rows = [
        ('|f| — модуль',
         'Z1 — середнє; Z2 — СКВ (1/K); Z3 — асиметрія; Z4 — надлишковий ексцес (норма 0)',
         ('Z1, Z2: нормовано на медіану |f₁₁| (безрозмірні)' if variant == 'XY' else
          'Z1, Z2: сирі одиниці поля (масштаб між прикладами різний)') + '; Z3, Z4: безрозмірні'),
        ('arg — кругові',
         'Z1 — середній напрям μ; Z2 — кругове СКВ √(−2 ln R); Z3 — кругова асиметрія; Z4 — круговий ексцес (Фішер)',
         'Z1, Z2: рад; Z3, Z4: безрозмірні'),
        ('arg — центральні на [0, 2π)',
         'Звичайні центральні моменти arg, зведеного до [0, 2π): Z1 — середнє; Z2 — СКВ (1/K); Z3 — асиметрія; Z4 — надлишковий ексцес',
         'Z1, Z2: рад; Z3, Z4: безрозмірні'),
    ]
    for i, (g, desc, unit) in enumerate(rows, start=1):
        put(tbl.cell(i, 0), g, bold=True, size=9, align=WD_ALIGN_PARAGRAPH.LEFT)
        put(tbl.cell(i, 1), desc, size=9, align=WD_ALIGN_PARAGRAPH.LEFT)
        put(tbl.cell(i, 2), unit, size=9, align=WD_ALIGN_PARAGRAPH.LEFT)
        for j in range(3):
            shade(tbl.cell(i, j), GROUPS[i - 1][2])
        shade(tbl.cell(i, 0), GROUPS[i - 1][1])

    heading(doc, 'Прочерк «—» означає', 12, 6)
    for s in [
        'елемент у цьому вікні не рахувався: понад 95 % точок поза фазовим вікном (вузькі вікна XY / OX / OY);',
        'значення NaN: порожні канали ex_90 / ey_0 (Мозг 1–3, Серце 1 — елементи f11, f12, f21, f22, f31, f32, f41, f42);',
        f'|Z3| або |Z4| < {SMALL:g} — практично нуль (напр. асиметрія arg у generalized ~10⁻¹⁹);',
    ]:
        doc.add_paragraph(s, style='List Bullet')

    heading(doc, 'Фазові вікна', 12, 6)
    doc.add_paragraph('Фазове вікно 0–wπ: у моменти входять лише точки з різницею фаз у цьому діапазоні '
                      '(8 вікон: 0–2π, 0–1.75π, …, 0–0.25π).')


# ---------------------------------------------------------------- сторінка
def page(doc, sample, variant, elem, D):
    heading(doc, f'{sample}  ·  {variant}  ·  {elem}', 12)
    nW = len(WINDOWS)
    t = doc.add_table(rows=2 + len(EXAMPLES) * nW, cols=2 + 12)
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    t.style = 'Table Grid'
    t.autofit = False
    widths = [Cm(1.4), Cm(1.6)] + [Cm(2.0)] * 12
    for row in t.rows:
        row.height = Cm(0.5)
        for j, w in enumerate(widths):
            row.cells[j].width = w

    # шапка
    a = t.cell(0, 0).merge(t.cell(1, 0)); put(a, 'При-\nклад', bold=True)
    b = t.cell(0, 1).merge(t.cell(1, 1)); put(b, 'Вікно', bold=True)
    for g, (name, hc, _) in enumerate(GROUPS):
        c0 = 2 + 4 * g
        m = t.cell(0, c0).merge(t.cell(0, c0 + 3)); put(m, name, bold=True, size=8.5); shade(m, hc)
        for z in range(4):
            c = t.cell(1, c0 + z); put(c, ZNAMES[z], bold=True); shade(c, hc)
    for j in range(14):
        border(t.cell(1, j), bottom=18)

    # дані
    for e_i, ex in enumerate(EXAMPLES):
        r0 = 2 + e_i * nW
        m = t.cell(r0, 0).merge(t.cell(r0 + nW - 1, 0)); put(m, str(ex), bold=True, size=14)
        for w_i, w in enumerate(WINDOWS):
            r = r0 + w_i
            put(t.cell(r, 1), win_label(w))
            rec = D.get((sample, ex, variant, w, elem), {})
            vals = [
                [fmt(v, z, MOD_SCALE if z < 2 else 1.0) for z, v in enumerate(rec.get('mod', [None] * 4))],
                [fmt(v, z) for z, v in enumerate(rec.get('arg', [None] * 4))],
                [fmt(v, z) for z, v in enumerate(rec.get('cen') or [None] * 4)],
            ]
            for g in range(3):
                for z in range(4):
                    c = t.cell(r, 2 + 4 * g + z); put(c, vals[g][z]); shade(c, GROUPS[g][2])
        if e_i > 0:
            for j in range(14):
                border(t.cell(r0, j), top=18)

    # жирні вертикалі між групами та по краях
    for row_i in range(len(t.rows)):
        for g in range(3):
            border(t.cell(row_i, 2 + 4 * g), left=18)
        border(t.cell(row_i, 0), left=18); border(t.cell(row_i, 13), right=18)
    for j in range(14):
        border(t.cell(0, j), top=18); border(t.cell(len(t.rows) - 1, j), bottom=18)


# ---------------------------------------------------------------- main
def main():
    D = collect()
    print(f'Прочитано файлів статистики: {len(D)}')
    OUT.mkdir(parents=True, exist_ok=True)
    for sample in SAMPLES:
        for variant in VARIANTS:
            doc = Document()
            st = doc.styles['Normal']; st.font.name = 'Calibri'; st.font.size = Pt(10)
            landscape(doc)
            legend(doc, sample, variant)
            for elem in ELEMENTS:
                doc.add_page_break()
                page(doc, sample, variant, elem, D)
            out = OUT / f'Стат-моменти_{sample}_{variant}.docx'
            doc.save(out)
            n = sum(1 for k in D if k[0] == sample and k[2] == variant)
            print(f'  {out.name}  ({n} файлів статистики)')

if __name__ == '__main__':
    main()
