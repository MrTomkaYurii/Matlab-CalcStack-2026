# -*- coding: utf-8 -*-
"""
Генерує core/cet_c6.m — циклічну палітру CET-C6 = cyclic_rygcbmr_50_90_c64 (Peter Kovesi, colorcet)
з таблицею 256x3, вшитою в .m (MATLAB-у не потрібен colorcet.m).

Потрібно:  python -m pip install colorcet
Запуск:    python make_cet_c6_table.py
"""
import pathlib
import colorcet as cc

rgb = [[int(h[i:i + 2], 16) / 255 for i in (1, 3, 5)] for h in cc.CET_C6]   # 256 hex -> [r, g, b] у [0, 1]
assert len(rgb) == 256

out = pathlib.Path(__file__).resolve().parents[1] / 'core' / 'cet_c6.m'
rows = '\n'.join(f'    {r:.6f} {g:.6f} {b:.6f}' for r, g, b in rgb)
out.write_text(f"""function M = cet_c6(n)
% CET_C6  Циклічна палітра CET-C6 (Peter Kovesi, colorcet; рівномірна за сприйняттям).
%   Для карт аргументу на [0, 2pi]: кінці одного кольору, без хибних смуг hsv.
%   M = cet_c6(n) — n x 3 (за замовч. 256). Таблицю згенеровано
%   «Перерахунок кругова палітра 2026-11-04/make_cet_c6_table.py» з colorcet.
if nargin < 1, n = 256; end
T = [
{rows}
];
if n == size(T,1)
    M = T;
else
    t = linspace(0, 1, size(T,1)).';
    M = interp1(t, T, linspace(0, 1, n).');
end
end
""", encoding='utf-8')
print('written', out)
