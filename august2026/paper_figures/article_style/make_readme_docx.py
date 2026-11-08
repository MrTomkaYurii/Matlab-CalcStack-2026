# -*- coding: utf-8 -*-
r"""
«Прочитати обов'язково.docx» — пояснення, чому частина рисунків Fig7 має порожні панелі
(підтека «Відсутні вхідні канали») і чим вони відрізняються від повних («Усі вхідні канали»).
Той самий файл кладеться в обидві підтеки кожного алгоритму.

Стан вхідних каналів перевірено безпосередньо в .mat-файлах (09.11.2026):
  C:\August 2026-Results\Зразки - нові (серпень 2026) mat\<зразок>\<приклад>\mat\ex_<стан>.mat, ey_<стан>.mat

Запуск:  python make_readme_docx.py <тека_1> [<тека_2> ...]
"""
import pathlib
import sys

from docx import Document
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

NAME = "Прочитати обов'язково.docx"
MATROOT = r'C:\August 2026-Results\Зразки - нові (серпень 2026) mat'
STATES = ['0', '45', '90', '135', 'liv', 'prav']
# стан кожного вхідного каналу: c — комплексне поле (норма), 0 — масив з одних нулів (дійсний, не комплексний)
ZERO = {('Серце', 1): {'ex_90', 'ey_0'},
        ('Мозг', 1): {'ex_90', 'ey_0'},
        ('Мозг', 2): {'ex_90'},
        ('Мозг', 3): {'ex_90', 'ey_0'}}
SAMPLES = [('Серце', 1), ('Серце', 2), ('Серце', 3), ('Мозг', 1), ('Мозг', 2), ('Мозг', 3),
           ('Мяз живота', 1), ('Мяз живота', 2), ('Мяз живота', 3)]
EMPTY = 'f11, f12, f21, f22, f31, f32, f41, f42'
RED, GREEN = 'F4CCCC', 'D9EAD3'


def shade(cell, hex_color):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:val'), 'clear'); shd.set(qn('w:color'), 'auto'); shd.set(qn('w:fill'), hex_color)
    tcPr.append(shd)


def put(cell, text, bold=False, size=9, center=True):
    cell.text = ''
    p = cell.paragraphs[0]
    if center:
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run(text); r.bold = bold; r.font.size = Pt(size)


def para(doc, text, bold=False, size=11, before=0, after=4):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(before); p.paragraph_format.space_after = Pt(after)
    r = p.add_run(text); r.bold = bold; r.font.size = Pt(size)
    return p


def build():
    doc = Document()
    st = doc.styles['Normal']; st.font.name = 'Calibri'; st.font.size = Pt(11)
    s = doc.sections[0]
    s.left_margin = s.right_margin = Cm(2.0); s.top_margin = s.bottom_margin = Cm(1.8)

    para(doc, "Прочитати обов'язково", bold=True, size=18, after=2)
    para(doc, 'Fig7 — повна матриця Мюллера f11 … f44: чому частина рисунків має порожні панелі', size=12, after=10)

    para(doc, 'Що лежить у підтеках', bold=True, size=13, before=4)
    for t in [
        '«Усі вхідні канали» — рисунки, де пораховані всі 16 елементів f_ik (усі вхідні дані в порядку).',
        '«Відсутні вхідні канали» — рисунки, де 8 елементів порожні (білі панелі): ' + EMPTY + ' '
        '(стовпці k = 1 і k = 2 матриці). Це не помилка побудови рисунка, а відсутні вхідні дані.',
        'Рисунок потрапляє в «Відсутні вхідні канали», якщо хоча б один елемент не має жодного значення '
        'в усіх фазових вікнах.',
    ]:
        doc.add_paragraph(t, style='List Bullet')

    para(doc, 'Причина', bold=True, size=13, before=8)
    para(doc, 'Для кожного зразка є 12 вхідних файлів — комплексні поля Ex та Ey для 6 станів освітлення '
              '(0°, 45°, 90°, 135°, ліва й права циркулярні): ex_<стан>.mat, ey_<стан>.mat у теці')
    para(doc, MATROOT + r'\<зразок>\<приклад>\mat', size=9)
    para(doc, 'У частині зразків файли ex_90.mat і/або ey_0.mat містять не комплексне поле, а дійсний масив '
              '400 × 400 з одних нулів (max |E| = 0, жодного ненульового значення). За приміткою в коді розрахунку, '
              'сира голограма цих кадрів не мала інтерференційних смуг, тому реконструкція поля дала нулі.')

    para(doc, 'Стан вхідних каналів (перевірено в .mat-файлах)', bold=True, size=13, before=8)
    t = doc.add_table(rows=1 + len(SAMPLES), cols=4); t.style = 'Table Grid'; t.alignment = WD_TABLE_ALIGNMENT.CENTER
    for j, h in enumerate(['Зразок / приклад', 'Порожні канали (нулі)', 'Решта каналів', 'Підтека Fig7']):
        put(t.cell(0, j), h, bold=True)
    for i, (smp, ex) in enumerate(SAMPLES, start=1):
        z = ZERO.get((smp, ex), set())
        put(t.cell(i, 0), f'{smp} / {ex}', center=False)
        put(t.cell(i, 1), ', '.join(sorted(z, reverse=True)) if z else '—')
        put(t.cell(i, 2), 'комплексні, у нормі')
        put(t.cell(i, 3), 'Відсутні вхідні канали' if z else 'Усі вхідні канали')
        for j in range(4):
            shade(t.cell(i, j), RED if z else GREEN)
    for row, w in zip(range(4), [Cm(3.6), Cm(4.0), Cm(4.0), Cm(4.4)]):
        for r in t.rows:
            r.cells[row].width = w

    para(doc, 'Чому з нулів виходять саме порожні (білі) панелі', bold=True, size=13, before=10)
    for tx in [
        'Під час читання полів (core\\tp_load_mat.m) пікселі, де |Ex| = 0 або |Ey| = 0, стають NaN: при нульовому '
        'модулі фаза не визначена (методика, п. 2.2). Якщо вся карта ey_0 (або ex_90) — нулі, то NaN стає ВЕСЬ кадр '
        'цього освітлення (0° або 90°).',
        'Елементи матриці (core\\tp_fik_pair.m, рівн. (10), (11), (13) статті) рахуються з двоточкових векторів '
        'Стокса SC_i для пар освітлень:  f_i1 = (SC_i(0°) + SC_i(90°)) / 2,   f_i2 = (SC_i(0°) − SC_i(90°)) / 2,   '
        'f_i3 = (SC_i(45°) − SC_i(135°)) / 2,   f_i4 = (SC_i(RC) − SC_i(LC)) / 2,   i = 1 … 4.',
        'Освітлення 0° і 90° входять лише у f_i1 і f_i2, тому NaN дістається рівно 8 елементам — ' + EMPTY + '. '
        'Елементи f_i3 (45°/135°) і f_i4 (циркулярні) рахуються нормально, їх карти й статистика коректні.',
        'У таблицях стат-моментів ці 8 елементів для таких зразків мають N = 0 і прочерки «—».',
    ]:
        doc.add_paragraph(tx, style='List Bullet')

    para(doc, 'Що з цим робити', bold=True, size=13, before=10)
    for tx in [
        'Для порівняння тканин за всіма 16 елементами використовувати лише «Усі вхідні канали»: '
        'Серце / 2, 3 та Мяз живота / 1, 2, 3.',
        'Елементи f13, f14, f23, f24, f33, f34, f43, f44 (у тому числі пари рисунків Fig1–Fig6: f33–f44, f23–f24) '
        'коректні в усіх 9 зразках.',
        'Щоб отримати повну матрицю для Серце / 1 і Мозг / 1–3, потрібно заново реконструювати поля ex_90 '
        '(і ey_0) з сирих голограм на стороні вимірювань.',
    ]:
        doc.add_paragraph(tx, style='List Bullet')
    return doc


def main():
    doc = build()
    for d in sys.argv[1:]:
        p = pathlib.Path(d); p.mkdir(parents=True, exist_ok=True)
        doc.save(p / NAME)
        print(f'  {p / NAME}')


if __name__ == '__main__':
    main()
