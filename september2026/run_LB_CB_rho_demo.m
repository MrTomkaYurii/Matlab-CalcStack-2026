% RUN_LB_CB_rho_DEMO  Наскрізна перевірка Кроку B на реальних даних.
%   Бере вже порахований (Крок A, старі скрипти, тут НЕ перераховується)
%   result.mat для одного зразка/кроку, рахує з нього 5 зелених елементів
%   (LB_0_90, LB_45_135, CB, rho, LB) і будує ту саму візуалізацію
%   (карти+гістограми, 2D/3D-контури), що раніше для f_ik. Результати
%   (і числа, і рисунки) зберігаються під C:\September 2026-Results,
%   кожен зелений елемент — у СВОЇЙ підтеці.
%
%   Тестовий зразок: Серце/2 -- підтверджено СКАНУВАННЯМ (не зі старої
%   пам'яті) через verify\scan_september_data_health.m, що усі 12
%   комплексних каналів (ex_/ey_ x {0,45,90,135,liv,prav}) у новій теці
%   НЕ биті (isreal(...)==false для кожного). Серце/1 і всі Мозг/* --
%   биті (ey_0/ex_90 дійсні замість комплексних), тому НЕ використовуються.

addpath('LB_CB_rho', 'core', 'viz', 'io', 'config');

% ---- ТЕСТОВИЙ ЗРАЗОК ----------------------------------------------------
% Серце/2 -- єдиний явний перемикач нижче. Підтверджено СКАНУВАННЯМ (не зі
% старої пам'яті) через verify\scan_september_data_health.m: усі 12
% комплексних каналів (ex_/ey_ x {0,45,90,135,liv,prav}) у новій теці
% C:\September 2026-Results НЕ биті (isreal(...)==false для кожного).
% Серце/1 і всі Мозг/* -- биті (ey_0/ex_90 дійсні замість комплексних),
% Мяз живота/1-3 теж чисті (альтернативний вибір). Щоб перевірити інший
% зразок -- поміняти SAMPLE/EXAMPLE тут і перескочити на
% scan_september_data_health.m перед цим.
SAMPLE  = 'Серце';
EXAMPLE = '2';

% ---- стиль + шляхи: ОКРЕМИЙ конфіг для наших рисунків (LB_CB_rho/cfg_LB_CB_rho_viz.m,
% той самий принцип, що й august2026\paper_figures\cfg_figures.m -- шрифт/
% кегль/DPI/кольори в ОДНОМУ місці, не в cfg_TwoPoint.m Кроку A) ----------
CFG = cfg_LB_CB_rho_viz();

% ---- вхід: готовий result.mat Кроку A (жодного перерахунку) -----------
% (сам f_ik ще рахувався старими скриптами на старих даних august2026 --
% це той самий незмінений розрахунок, лише поки що не перезапущений на
% новоскопійованих у September даних; коли знадобиться повний перерахунок
% з нуля -- CFG.paths.matRoot вище вже вказує, де брати сирі ex_*/ey_*.)
resultFile = fullfile('C:\August 2026-Results\Розрахунки - Двот. елем. ММ', ...
    SAMPLE, EXAMPLE, 'phase_01_[0-2.00pi]', 'XY', 'step_1', 'result.mat');
S = load(resultFile);
R = S.R;
dir = R.dirs{1};   % 'step_1'

fprintf('Завантажено %s: algorithm=%s, sample=%s, dir=%s\n', resultFile, R.algorithm, R.sample, dir);

% ---- Крок B: похідні величини з готових f23,f32,f24,f42,f34,f43 -------
R2 = tp_LB_CB_rho_from_result(R, dir);

for e = 1:numel(R2.elements)
    elem = R2.elements{e};
    D = R2.data.(dir).(elem);
    v = D.mod(isfinite(D.mod));
    a = D.arg(isfinite(D.arg));
    fprintf('  %-10s |.| mean=%10.4g std=%10.4g   arg mean=%7.4f std=%7.4f  (n=%d/%d finite)\n', ...
        elem, mean(v), std(v), mean(a), std(a), numel(v), numel(D.mod));
end

% ---- збереження числових результатів (окремо від рисунків) ------------
matOut = tp_save_LB_CB_rho_result(R2, dir, CFG);
fprintf('\nЗбережено числові карти (усі 5 елементів): %s\n', matOut);

% ---- візуалізація (карти+гістограми, 2D/3D контури), кожен елемент -----
% ---- у своїй підтеці (.../LB_0_90/, .../LB_45_135/, .../CB/, .../rho/, ---
% ---- .../LB/) -- маршрутизує tp_save_figure.m (io/tp_save_figure.m) ----
tp_visualize_LB_CB_rho(R2, dir, CFG);

fprintf('Рисунки (по підтеках на елемент): %s\n', fullfile(CFG.paths.saveRoot, R2.sample, R2.algorithm, dir));
