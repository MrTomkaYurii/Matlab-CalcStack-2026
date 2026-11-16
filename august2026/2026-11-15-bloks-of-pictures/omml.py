# -*- coding: utf-8 -*-
"""
Мінімальний конструктор формул Word (OMML — ті самі рівняння, що «Вставка → Рівняння»),
без LaTeX-конвертерів і Office XSL. Приклад:

    from omml import math, r, f, sup, sub, nary, rad, d
    math(doc, r('Z'), sub(r('Z'), r('1')), r('='), f(r('1'), r('K')), nary('∑', r('k=1'), r('K'), sub(r('x'), r('k'))))
"""
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.enum.text import WD_ALIGN_PARAGRAPH


def _e(tag, *kids):
    el = OxmlElement(tag)
    for k in kids:
        el.append(k)
    return el


def r(text, plain=False):
    """Текст/символи. Латинські букви Word робить курсивом; plain=True — прямий шрифт (sin, ln, числа)."""
    run = OxmlElement('m:r')
    if plain:
        rpr = OxmlElement('m:rPr'); sty = OxmlElement('m:sty'); sty.set(qn('m:val'), 'p'); rpr.append(sty)
        run.append(rpr)
    t = OxmlElement('m:t'); t.text = text
    t.set('{http://www.w3.org/XML/1998/namespace}space', 'preserve')
    run.append(t)
    return run


def _arg(tag, items):
    a = OxmlElement(tag)
    for it in (items if isinstance(items, (list, tuple)) else [items]):
        a.append(it)
    return a


def f(num, den):
    return _e('m:f', _arg('m:num', num), _arg('m:den', den))


def sup(base, s):
    return _e('m:sSup', _arg('m:e', base), _arg('m:sup', s))


def sub(base, s):
    return _e('m:sSub', _arg('m:e', base), _arg('m:sub', s))


def subsup(base, s, p):
    return _e('m:sSubSup', _arg('m:e', base), _arg('m:sub', s), _arg('m:sup', p))


def rad(x):
    pr = OxmlElement('m:radPr'); h = OxmlElement('m:degHide'); h.set(qn('m:val'), '1'); pr.append(h)
    return _e('m:rad', pr, OxmlElement('m:deg'), _arg('m:e', x))


def d(x, beg='(', end=')'):
    pr = OxmlElement('m:dPr')
    b = OxmlElement('m:begChr'); b.set(qn('m:val'), beg); pr.append(b)
    e = OxmlElement('m:endChr'); e.set(qn('m:val'), end); pr.append(e)
    return _e('m:d', pr, _arg('m:e', x))


def nary(op, lo, hi, body):
    pr = OxmlElement('m:naryPr'); c = OxmlElement('m:chr'); c.set(qn('m:val'), op); pr.append(c)
    lim = OxmlElement('m:limLoc'); lim.set(qn('m:val'), 'undOvr'); pr.append(lim)
    return _e('m:nary', pr, _arg('m:sub', lo or []), _arg('m:sup', hi or []), _arg('m:e', body))


def math(doc, *items, label=None):
    """Окремий абзац з формулою (по центру); label — пояснення ліворуч звичайним текстом."""
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    p.paragraph_format.space_after = 0
    if label:
        p.add_run(label + '   ')
    om = OxmlElement('m:oMath')
    for it in items:
        om.append(it)
    p._p.append(om)
    return p
