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
    todo = []
    root = children(ROOT_ID)
    for t in TISSUES:
        if t not in root:
            print(f'  ! немає теки {t}'); continue
        tex = children(root[t])
        for ex in EXAMPLES:
            if ex not in tex:
                print(f'  ! немає {t}\\{ex}'); continue
            ph = children(tex[ex])
            for pk in PHASES:
                name = next((n for n in ph if n.startswith(pk)), None)
                if not name:
                    print(f'  ! немає {t}\\{ex}\\{pk}*'); continue
                for leaf in LEAVES:
                    d = walk(ph[name], leaf)
                    f = children(d).get('result.mat') if d else None
                    rel = pathlib.Path(t, ex, name, *leaf, 'result.mat')
                    if f:
                        todo.append((f, rel))
                    else:
                        print(f'  ! немає {rel}')
    return todo


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
    todo = plan()
    print(f'Знайдено {len(todo)} result.mat')
    if a.dry:
        for _, rel in todo:
            print('  ', rel)
        return
    fail = 0
    for i, (fid, rel) in enumerate(todo, 1):
        dst = OUT / rel
        if dst.is_file() and dst.stat().st_size > 0:
            print(f'[{i}/{len(todo)}] є     {rel}'); continue
        try:
            download(fid, dst)
            print(f'[{i}/{len(todo)}] ok    {rel}  ({dst.stat().st_size / 1e6:.1f} МБ)', flush=True)
        except Exception as e:                       # noqa: BLE001
            fail += 1
            print(f'[{i}/{len(todo)}] FAIL  {rel}: {e}', flush=True)
    print(f'Готово: {len(todo) - fail} з {len(todo)} у {OUT}')
    sys.exit(1 if fail else 0)


if __name__ == '__main__':
    main()
