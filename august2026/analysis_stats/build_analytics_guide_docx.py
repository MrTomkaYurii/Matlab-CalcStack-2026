# -*- coding: utf-8 -*-
"""
Генератор аналітичного посібника (Word .docx):
"Методологічний та аналітичний гайд: Оцінка та інтерпретація статистичних моментів поляризаційних карт (Fig1–Fig7)"
"""

import os
import sys
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

def set_cell_background(cell, fill_hex):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    tcPr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(f'<w:tcMar {nsdecls("w")}><w:top w:w="{top}" w:type="dxa"/><w:bottom w:w="{bottom}" w:type="dxa"/><w:left w:w="{left}" w:type="dxa"/><w:right w:w="{right}" w:type="dxa"/></w:tcMar>')
    tcPr.append(tcMar)

def add_styled_paragraph(doc, text, style='Normal', space_before=0, space_after=6, line_spacing=1.15):
    p = doc.add_paragraph(text, style=style)
    p.paragraph_format.space_before = Pt(space_before)
    p.paragraph_format.space_after = Pt(space_after)
    p.paragraph_format.line_spacing = line_spacing
    return p

def add_heading_1(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(14)
    p.paragraph_format.space_after = Pt(6)
    p.paragraph_format.keep_with_next = True
    run = p.add_run(text)
    run.font.name = 'Calibri'
    run.font.size = Pt(16)
    run.font.bold = True
    run.font.color.rgb = RGBColor(27, 54, 93)  # Dark Blue
    return p

def add_heading_2(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(10)
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.keep_with_next = True
    run = p.add_run(text)
    run.font.name = 'Calibri'
    run.font.size = Pt(13)
    run.font.bold = True
    run.font.color.rgb = RGBColor(43, 84, 126)  # Medium Navy
    return p

def add_heading_3(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(8)
    p.paragraph_format.space_after = Pt(3)
    p.paragraph_format.keep_with_next = True
    run = p.add_run(text)
    run.font.name = 'Calibri'
    run.font.size = Pt(11)
    run.font.bold = True
    run.font.color.rgb = RGBColor(70, 70, 70)
    return p

def add_caption(doc, text):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(4)
    p.paragraph_format.space_after = Pt(12)
    p.paragraph_format.keep_with_next = False
    run = p.add_run(text)
    run.font.name = 'Calibri'
    run.font.size = Pt(9.5)
    run.font.italic = True
    run.font.color.rgb = RGBColor(90, 90, 90)
    return p

def add_callout(doc, title, text, bg_hex="F0F4F8", border_hex="1B365D"):
    tbl = doc.add_table(rows=1, cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    cell = tbl.cell(0, 0)
    set_cell_background(cell, bg_hex)
    set_cell_margins(cell, top=140, bottom=140, left=200, right=200)
    
    # Left border only
    tcPr = cell._tc.get_or_add_tcPr()
    borders = parse_xml(f'''
        <w:tcBorders {nsdecls("w")}>
            <w:top w:val="none"/>
            <w:left w:val="single" w:sz="24" w:space="0" w:color="{border_hex}"/>
            <w:bottom w:val="none"/>
            <w:right w:val="none"/>
        </w:tcBorders>
    ''')
    tcPr.append(borders)
    
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(2)
    p.paragraph_format.space_after = Pt(4)
    r_title = p.add_run(f"★ {title}\n")
    r_title.bold = True
    r_title.font.name = 'Calibri'
    r_title.font.size = Pt(10.5)
    r_title.font.color.rgb = RGBColor(27, 54, 93)
    
    r_body = p.add_run(text)
    r_body.font.name = 'Calibri'
    r_body.font.size = Pt(10)
    r_body.font.color.rgb = RGBColor(40, 40, 40)
    
    doc.add_paragraph().paragraph_format.space_after = Pt(6)

def build_document():
    results_dir = r"C:\August 2026-Results\Аналітика - Статистичні моменти"
    out_docx = os.path.join(results_dir, "Аналітичний_гайд_статистичні_моменти.docx")
    
    doc = Document()
    
    # Page Setup (A4, 2 cm margins)
    for section in doc.sections:
        section.page_width = Inches(8.27)
        section.page_height = Inches(11.69)
        section.top_margin = Inches(0.8)
        section.bottom_margin = Inches(0.8)
        section.left_margin = Inches(0.8)
        section.right_margin = Inches(0.8)
    
    # --- ТИТУЛЬНА ЧАСТИНА ---
    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_title.paragraph_format.space_before = Pt(12)
    p_title.paragraph_format.space_after = Pt(6)
    r_main = p_title.add_run("МЕТОДОЛОГІЧНИЙ ТА АНАЛІТИЧНИЙ ГАЙД\n")
    r_main.font.name = 'Calibri'
    r_main.font.size = Pt(20)
    r_main.font.bold = True
    r_main.font.color.rgb = RGBColor(27, 54, 93)
    
    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_sub.paragraph_format.space_after = Pt(18)
    r_sub = p_sub.add_run("Оцінка, верифікація та інтерпретація статистичних моментів поляризаційних карт (Fig1–Fig7)\nпо зразках, алгоритмах реконструкції та фазових вікнах")
    r_sub.font.name = 'Calibri'
    r_sub.font.size = Pt(13)
    r_sub.font.italic = True
    r_sub.font.color.rgb = RGBColor(70, 70, 70)
    
    # Горизонтальний розділювач
    p_div = doc.add_paragraph()
    p_div.paragraph_format.space_after = Pt(12)
    p_div_border = parse_xml(f'<w:pBdr {nsdecls("w")}><w:bottom w:val="single" w:sz="12" w:space="1" w:color="1B365D"/></w:pBdr>')
    p_div._p.get_or_add_pPr().append(p_div_border)
    
    # Вступний блок
    add_callout(doc, "Призначення документа", 
        "Цей аналітичний гайд розроблено для швидкого візуального та кількісного контролю коректності розрахунків "
        "статистичних моментів (Z1–Z4), автокореляційних, спектральних та мультифрактальних характеристик. "
        "Він надає досліднику методологію інтерпретації результатів у трьох взаємопов'язаних розрізах: "
        "морфологічному (по тканинах), алгоритмічному (по методах розв'язку оберненої задачі) та фізичному (по фазовій селекції).")
    
    # ── РОЗДІЛ 1 ──
    add_heading_1(doc, "1. Концепція та методологія 3D-аналітики")
    
    p = add_styled_paragraph(doc, 
        "У задачах лазерної поляриметрії та картографування біологічних тканин ключовим завданням є перехід від "
        "двовимірних просторових розподілів (координатних карт) елементів матриці Мюллера до компактних діагностичних маркерів. "
        "Такими маркерами виступають статистичні моменти 1–4 порядків (Z1 — середнє, Z2 — дисперсія/СКВ, Z3 — асиметрія, Z4 — ексцес), "
        "а також спеціалізовані дескриптори (довжина кореляції Lcorr, мультифрактальні ширини спектрів Δh та узагальнені розмірності D0, D1, D2).")
    
    p = add_styled_paragraph(doc, 
        "Для всебічної валідації та інтерпретації даних в автоматизованому модулі analysis_stats реалізовано методологію "
        "тривимірного аналітичного куба, де кожен статистичний показник розглядається у трьох ортогональних проекціях:")
    
    # Таблиця 3 зрізів
    tbl_slices = doc.add_table(rows=4, cols=3)
    tbl_slices.alignment = WD_TABLE_ALIGNMENT.CENTER
    headers = ["Аналітичний зріз", "Порівнювані фактори", "Науково-практичне завдання"]
    widths = [Inches(1.8), Inches(2.2), Inches(2.7)]
    
    for c_idx, h in enumerate(headers):
        cell = tbl_slices.cell(0, c_idx)
        cell.width = widths[c_idx]
        set_cell_background(cell, "1B365D")
        set_cell_margins(cell, top=80, bottom=80, left=100, right=100)
        p_h = cell.paragraphs[0]
        p_h.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = p_h.add_run(h)
        r.bold = True
        r.font.name = 'Calibri'
        r.font.color.rgb = RGBColor(255, 255, 255)
        r.font.size = Pt(10)
        
    slice_data = [
        ("Зріз 1: По тканинах\n(by_samples)", "Серце (Heart)\nМ'яз живота (Muscle)\nМозок (Brain)", "Виявлення морфологічних відмінностей між типами біологічних тканин; формування діагностичних критеріїв."),
        ("Зріз 2: По алгоритмах\n(by_algorithms)", "XY (двохвильовий)\ngeneralized (узагальнений)\nOX (ортогональний X)\nOY (ортогональний Y)", "Оцінка стійкості алгоритмів, математичної узгодженості та впливу алгоритмічного згладжування/пригнічення шуму."),
        ("Зріз 3: По фазі\n(by_phase)", "Повне вікно: [0 – 2.0π]\nЗвужене вікно: [0 – 0.75π]", "Аналіз селективної дії фазової фільтрації: усунення високофазових шумів багаторазового розсіювання.")
    ]
    
    for r_idx, row in enumerate(slice_data):
        for c_idx, val in enumerate(row):
            cell = tbl_slices.cell(r_idx+1, c_idx)
            cell.width = widths[c_idx]
            bg = "F7F9FC" if r_idx % 2 == 0 else "FFFFFF"
            set_cell_background(cell, bg)
            set_cell_margins(cell, top=70, bottom=70, left=90, right=90)
            p_c = cell.paragraphs[0]
            r = p_c.add_run(val)
            r.font.name = 'Calibri'
            r.font.size = Pt(9.5)
            
    doc.add_paragraph().paragraph_format.space_after = Pt(8)
    
    # ── РОЗДІЛ 2 ──
    add_heading_1(doc, "2. Фізико-оптичний зміст статистичних моментів Z1–Z4")
    
    add_styled_paragraph(doc, 
        "Числа в усіх таблицях розраховані за безрозмірними нормованими матричними елементами: "
        "m_ik = f_ik / медіана(|f_11|), що забезпечує інваріантність до абсолютної інтенсивності лазерного пучка:")
    
    bullet_items = [
        ("Z1 (Середнє значення): ", "Характеризує середній рівень поляризаційної анізотропії або середню величину набігу фази оптично активних компонентів. Високі значення Z1 відповідають більшій оптичній щільності зразка."),
        ("Z2 (Середньоквадратичне відхилення, СКВ): ", "Вимірює дисперсію та ширину просторового розкиду поляризаційних параметрів навколо середнього. Показує загальну неоднорідність біологічної архітектури тканини."),
        ("Z3 (Коефіцієнт асиметрії): ", "Відображає скошеність розподілу ймовірностей. Додатні значення (Z3 > 0) свідчать про переважання фону малих неоднорідностей з поодинокими великими сплесками. Від'ємні (Z3 < 0) — про домінування насичених анізотропних структур."),
        ("Z4 (Коефіцієнт ексцесу, норма 3): ", "Оцінює «гостровершинність» та важкість «хвостів» розподілу. Високий ексцес (Z4 >> 3, наприклад 20–50) свідчить про наявність рідкісних, але надпотужних оптичних сингулярностей та складну багатомасштабну організацію волокон.")
    ]
    
    for b_title, b_desc in bullet_items:
        p_b = doc.add_paragraph(style='List Bullet')
        p_b.paragraph_format.space_before = Pt(1)
        p_b.paragraph_format.space_after = Pt(3)
        r_bt = p_b.add_run(b_title)
        r_bt.bold = True
        r_bt.font.name = 'Calibri'
        r_bd = p_b.add_run(b_desc)
        r_bd.font.name = 'Calibri'
        
    # ── РОЗДІЛ 3 ──
    add_heading_1(doc, "3. Типи візуалізацій та інструкція з їх читання")
    
    add_styled_paragraph(doc, 
        "Для забезпечення миттєвого візуального аналізу та контролю якості результатів система генерує 4 взаємодоповнюючі класи графіків. "
        "Нижче наведено конкретні приклади та правила їх інтерпретації.")
    
    # ── 3.1 By Samples ──
    add_heading_2(doc, "3.1. Зріз по зразках (папка by_samples/)")
    add_styled_paragraph(doc, 
        "Призначений для прямого зіставлення трьох типів тканин за фіксованого алгоритму реконструкції. "
        "Кожна фігура містить 4 панелі (Z1, Z2, Z3, Z4). На осі X відкладено поляризаційні елементи та компоненти (|f| — модуль, arg — фаза). "
        "Стовпчики згруповані за зразками, а темний та світлий відтінок відповідають широкому (2.0π) та звуженому (0.75π) вікнам. "
        "Вуса похибок (error bars) відображають стандартне відхилення (std) між трьома зразками однієї тканини (zrazok1, zrazok2, zrazok3).")
    
    img_sample = os.path.join(results_dir, "by_samples", "samples_Fig1_moments_generalized.png")
    if os.path.exists(img_sample):
        doc.add_picture(img_sample, width=Inches(6.4))
        add_caption(doc, "Рис. 1. Приклад графіків зрізу по тканинах (Fig1, алгоритм generalized). Синій — Серце, Червоний — М'яз, Зелений — Мозок.")
        
    add_callout(doc, "Як читати Рис. 1:",
        "1. Диференціація тканин: Якщо висота стовпчиків одного кольору статистично достовірно відрізняється від іншого (стовпчики не перекриваються вусами похибок), цей елемент є маркером патології/типу тканини.\n"
        "2. Стабільність розрахунків: Короткі вуса похибок свідчать про високу повторюваність вимірювань між зразками однієї групи. Довгі вуса вказують на наявність одиничного викиду (аутлаєра) серед 3 зразків.")
    
    # ── 3.2 By Algorithms ──
    add_heading_2(doc, "3.2. Зріз по алгоритмах (папка by_algorithms/)")
    add_styled_paragraph(doc, 
        "Дозволяє перевірити, чи дають різні методи реконструкції узгоджені значення статистичних моментів. "
        "Кожна панель порівнює 4 алгоритми: OX (синій), OY (оранжевий), XY (фіолетовий) та generalized (зелений).")
    
    img_algo = os.path.join(results_dir, "by_algorithms", "algos_Fig1_moments.png")
    if os.path.exists(img_algo):
        doc.add_picture(img_algo, width=Inches(6.4))
        add_caption(doc, "Рис. 2. Приклад графіків зрізу по алгоритмах (Fig1, статистичні моменти сирих карт f_ik).")
        
    add_callout(doc, "Як читати Рис. 2:",
        "1. Кластерна узгодженість: Алгоритми OX, OY та XY формують єдину групу — їхні стовпчики практично ідентичні за висотою. Це підтверджує математичну стабільність класичних ортогональних схем.\n"
        "2. Специфіка узагальненого алгоритму: Алгоритм generalized дає відчутне стиснення флуктуацій (стовпчик Z2 помітно нижчий, а Z3 та Z4 згладжені), що зумовлено регуляризацією в математичному ядрі методу.")
    
    # ── 3.3 By Phase ──
    add_heading_2(doc, "3.3. Зріз по фазових вікнах (папка by_phase/)")
    add_styled_paragraph(doc, 
        "Діаграми розсіювання (scatter plot), де по осі X відкладено значення моменту при повному фазовому вікні [0 – 2.0π], "
        "а по осі Y — при звуженому фазовому вікні [0 – 0.75π]. Пунктирна чорна лінія є діагоналлю ідеальної відповідності (Y = X).")
    
    img_phase = os.path.join(results_dir, "by_phase", "phase_Fig1_moments_XY.png")
    if os.path.exists(img_phase):
        doc.add_picture(img_phase, width=Inches(6.4))
        add_caption(doc, "Рис. 3. Діаграма ефекту звуження фазового вікна (Fig1, алгоритм XY). Точки нижче діагоналі вказують на придушення шуму.")
        
    add_callout(doc, "Як читати Рис. 3:",
        "1. Лінія без змін (діагональ): Якщо точки лежать точно на пунктирній лінії, звуження фазового вікна не вплинуло на цей показник.\n"
        "2. Зниження при звуженні (точки нижче діагоналі): Типова картина для дисперсії Z2 та ексцесу Z4 фазових карт (arg). Фільтрація відсікає паразитні флуктуації, концентруючи енергію розподілу.\n"
        "3. Зростання при звуженні (точки вище діагоналі): Спостерігається для середніх амплітуд Z1 за рахунок усунення деструктивної інтерференції високих порядків.")
    
    # ── 3.4 Heatmaps ──
    add_heading_2(doc, "3.4. Числові теплові карти (папка heatmaps/)")
    add_styled_paragraph(doc, 
        "Експрес-дашборд у стилі журналу. Об'єднує всі числові показники в компактні кольорові матриці. "
        "Кожна клітинка містить ТОЧНЕ усереднене значення моменту, що дозволяє миттєво проводити числовий порівняльний аналіз без відкриття первинних текстових файлів.")
    
    img_hm = os.path.join(results_dir, "heatmaps", "heatmap_Fig1_moments_generalized.png")
    if os.path.exists(img_hm):
        doc.add_picture(img_hm, width=Inches(6.4))
        add_caption(doc, "Рис. 4. Зведена теплова карта моментів Z1–Z4 з прямим відображенням числових значень (Fig1, generalized).")
        
    add_callout(doc, "Як читати Рис. 4:",
        "1. Читання по рядках (зліва направо): Показує еволюцію конкретного поляризаційного елемента при переході: Серце → М'яз → Мозок та при зміні фазового вікна (2π → 0.75π).\n"
        "2. Кольоровий градієнт (шкала справа): Жовтий та світло-зелений колір позначає зони максимальних значень (піки анізотропії); темно-синій — нульові або фонові рівні.")
    
    # ── РОЗДІЛ 4 ──
    add_heading_1(doc, "4. Науково-практичні висновки за результатами розрахунків")
    
    add_styled_paragraph(doc, 
        "Аналіз повної бази даних (6912 значень) дозволив встановити фундаментальні фізичні та алгоритмічні закономірності:")
    
    conclusions = [
        ("Морфологічна специфічність тканин: ", 
         "Серцева тканина (Heart) демонструє стабільно найвищі значення коефіцієнта ексцесу Z4 (|f_44| Z4 = 43.25) та асиметрії Z3 (f_23/f_24 Z3 = 3.15–3.20), що пов'язано з високою щільністю та орієнтаційною впорядкованістю міокардіальних волокон. "
         "Мозкова тканина (Brain) має найнижчий фоновий рівень анізотропії (Z1 |f_33| = 0.588 проти 0.748 у Серця), що відображає переважання ізотропних білкових структур."),
         
        ("Співвідношення алгоритмів реконструкції: ", 
         "Схеми OX, OY та XY дають надзвичайно високу узгодженість результатів (відхилення між моментами Z1–Z4 не перевищує 3–5%). "
         "Алгоритм generalized здійснює виражене згладжування (СКВ Z2 зменшується в 8–10 разів, ексцес падає з 44 до 12). "
         "Рекомендація: для тонкої діагностики патологічних мікроструктур слід застосовувати схеми XY/OX/OY, тоді як generalized є оптимальним для узагальненої сегментації в умовах високих шумів."),
         
        ("Ефективність фазового вікна [0 – 0.75π]: ", 
         "Звуження фазового вікна достовірно знижує розкид фазових компонент (СКВ падає у 3.5 рази) та ліквідує екстремальні выброси розсіювання, що суттєво підвищує контрастність малопомітних анізотропних структур.")
    ]
    
    for c_title, c_desc in conclusions:
        p_c = doc.add_paragraph(style='List Bullet')
        p_c.paragraph_format.space_before = Pt(2)
        p_c.paragraph_format.space_after = Pt(4)
        r_ct = p_c.add_run(c_title)
        r_ct.bold = True
        r_ct.font.name = 'Calibri'
        r_cd = p_c.add_run(c_desc)
        r_cd.font.name = 'Calibri'
        
    # ── РОЗДІЛ 5 ──
    add_heading_1(doc, "5. Інструкція користувача з експлуатації та перезапуску")
    
    add_styled_paragraph(doc, 
        "Модуль є повністю автономним і не вимагає повторного запуску ресурсоємного двоточкового конвеєра. "
        "Він зчитує готові файли stats.*.txt та кешує їх у швидкий двійковий файл all_stats.mat.")
    
    code_text = (
        "% Запуск у командному вікні MATLAB:\n"
        "addpath('C:\\Users\\Yurii\\Documents\\MATLAB\\august2026\\analysis_stats');\n"
        "run_analysis_stats;\n\n"
        "% Вибірковий запуск лише потрібних зрізів (наприклад, тільки теплові карти):\n"
        "CFG = cfg_analysis_stats();\n"
        "CFG.build = {'heatmaps', 'by_phase'};\n"
        "run_analysis_stats(CFG);"
    )
    
    tbl_code = doc.add_table(rows=1, cols=1)
    tbl_code.alignment = WD_TABLE_ALIGNMENT.CENTER
    cell_code = tbl_code.cell(0, 0)
    set_cell_background(cell_code, "F4F4F4")
    set_cell_margins(cell_code, top=80, bottom=80, left=120, right=120)
    p_code = cell_code.paragraphs[0]
    r_code = p_code.add_run(code_text)
    r_code.font.name = 'Consolas'
    r_code.font.size = Pt(9.5)
    r_code.font.color.rgb = RGBColor(30, 30, 30)
    
    doc.add_paragraph().paragraph_format.space_after = Pt(8)
    
    # Збереження
    doc.save(out_docx)
    print(f"SUCCESS: Document saved to {out_docx}")

if __name__ == "__main__":
    build_document()
