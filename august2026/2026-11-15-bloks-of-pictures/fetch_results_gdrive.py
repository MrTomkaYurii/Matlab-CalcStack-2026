# -*- coding: utf-8 -*-
r"""
Скачує з Google Диска лише ті result.mat, що потрібні для рисунків ТЗ (без перерахунку).
Тека на Диску відкрита за посиланням — авторизація не потрібна.

  <ROOT_ID> = «Розрахунки - Двот. елем. ММ»
  беремо:  <тканина>\<приклад>\phase_0k_*\XY\step_1\result.mat
                                         \orthogonal\OY\step_1\result.mat
  кладемо: C:\August 2026-Results\Розрахунки - Двот. елем. ММ\ (та сама структура)

Запуск:
  python fetch_results_gdrive.py --dry       # лише показати, що буде скачано
  python fetch_results_gdrive.py             # скачати (готові файли того ж розміру пропускаються)
"""
import argparse
import html
import pathlib
import re
import sys
import time
import urllib.request

ROOT_ID = '1EBAnGVmq8O-pDbaoUxCdsLy979vpPlnO'
OUT = pathlib.Path(r'C:\August 2026-Results\Розрахунки - Двот. елем. ММ')
TISSUES = ['Мяз живота', 'Мозг', 'Серце']
EXAMPLES = ['1', '2', '3']
PHASES = ['phase_01', 'phase_02', 'phase_04']          # 0–2π, 0–1.75π, 0–1.25π
LEAVES = [('XY', 'step_1'), ('orthogonal', 'OY', 'step_1')]

ENTRY = re.compile(r'id="entry-([\w-]+)".*?class="flip-entry-title">(.*?)</div>', re.S)


def get(url, tries=4):
    for k in range(tries):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'}),
                                        timeout=60) as r:
                return r.read()
        except Exception as e:                       # noqa: BLE001
            if k == tries - 1:
                raise
            time.sleep(2 + 3 * k)


def children(fid):
    """{ім'я: id} дочірніх елементів теки (embeddedfolderview — без авторизації)."""
    page = get(f'https://drive.google.com/embeddedfolderview?id={fid}').decode('utf-8', 'replace')
    return {html.unescape(n).strip(): i for i, n in ENTRY.findall(page)}


def walk(fid, parts):
    for p in parts:
        ch = children(fid)
        if p not in ch:
            return None
        fid = ch[p]
    return fid


def plan():
    """Генератор (id, шлях): видає кожен result.mat одразу, як знайде — скачування починається без очікування."""
    print('Читаю теки на Диску...', flush=True)
    root = children(ROOT_ID)
    for t in TISSUES:
        if t not in root:
            print(f'  ! немає теки {t}', flush=True); continue
        tex = children(root[t])
        for ex in EXAMPLES:
            if ex not in tex:
                print(f'  ! немає {t}\\{ex}', flush=True); continue
            ph = children(tex[ex])
            for pk in PHASES:
                name = next((n for n in ph if n.startswith(pk)), None)
                if not name:
                    print(f'  ! немає {t}\\{ex}\\{pk}*', flush=True); continue
                for leaf in LEAVES:
                    rel = pathlib.Path(t, ex, name, *leaf, 'result.mat')
                    print(f'  шукаю {rel} ...', flush=True)
                    d = walk(ph[name], leaf)
                    f = children(d).get('result.mat') if d else None
                    if f:
                        yield f, rel
                    else:
                        print(f'  ! немає {rel}', flush=True)


def download(fid, dst):
    url = f'https://drive.usercontent.google.com/download?id={fid}&export=download&confirm=t'
    tmp = dst.with_suffix('.part')
    dst.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'}),
                                timeout=300) as r, open(tmp, 'wb') as f:
        if 'text/html' in r.headers.get('Content-Type', ''):
            raise RuntimeError('Диск повернув HTML замість файлу (ліміт / доступ)')
        while True:
            b = r.read(1 << 20)
            if not b:
                break
            f.write(b)
    tmp.replace(dst)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dry', action='store_true')
    a = ap.parse_args()
    print(f'Куди: {OUT}', flush=True)
    n = fail = 0
    for fid, rel in plan():
        n += 1
        dst = OUT / rel
        if a.dry:
            print(f'[{n}] знайдено {rel}', flush=True); continue
        if dst.is_file() and dst.stat().st_size > 0:
            print(f'[{n}] вже є   {rel}', flush=True); continue
        try:
            download(fid, dst)
            print(f'[{n}] ok      {rel}  ({dst.stat().st_size / 1e6:.1f} МБ)', flush=True)
        except Exception as e:                       # noqa: BLE001
            fail += 1
            print(f'[{n}] FAIL    {rel}: {e}', flush=True)
    print(f'Готово: {n - fail} з {n} у {OUT}')
    sys.exit(1 if fail else 0)


if __name__ == '__main__':
    main()
