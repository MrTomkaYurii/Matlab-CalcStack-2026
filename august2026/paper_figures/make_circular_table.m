function [T, Tagg] = make_circular_table(FIG, elems)
% MAKE_CIRCULAR_TABLE  Підсумкова таблиця моментів за методикою перерахунку
%   (розд. 7 «Мінімальний склад підсумкової таблиці»): рядок = зразок x
%   приклад x фазове вікно x варіант (алгоритм/напрям) x елемент f_ik.
%
%   Колонки:
%     K, excl_frac               — к-сть допустимих пікселів (|f|>0, скінченні) і частка виключених
%     mod_Z1..mod_Z4             — модуль: середнє, СКВ (K-1), асиметрія, ексцес-3 (відповідь (1)-(4))
%     argF_Z1c..argF_Z4c         — аргумент: кругові моменти Фішера (відповідь (7)-(11))
%     C1,S1,mu,R1,V,R2,R3,R4,sigma_circ — тригонометричні моменти (методика (6)-(10))
%     ctrl_arg_Z1..Z4, ctrl_arg_m1..m4  — контроль: степеневі нецентральні (29), гілка (-pi,pi]
%     ctrl_mod_Z1..Z4            — те саме для модуля
%   Tagg — зведення по повторах (прикладах) на зразок: середнє R_p, V;
%   mu — з середнього M_1 повторів (методика 6.1: кути звичайним середнім не усереднюються).
%
%   Файли: FIG.out.root\stats_circular\circular_moments.csv, circular_moments_by_sample.csv
%
%       make_circular_table                 % cfg_figures(), елементи f33,f44
%       make_circular_table(FIG, CFG.elements)

here = fileparts(mfilename('fullpath'));
addpath(here, fullfile(here,'common'), genpath(fullfile(fileparts(here),'core')));
if nargin < 1 || isempty(FIG); FIG = cfg_figures(); end
if nargin < 2 || isempty(elems); elems = {'f33','f44'}; end

% Сирі значення arg (без зведення в [0,2pi)) — гілку задаємо тут явно.
FIG.color.argClim = [-pi pi];

samples  = FIG.fig07.samples;
examples = FIG.fig07.examples;
variants = FIG.variants;

rows = {};
for si = 1:numel(samples)
    for xi = 1:numel(examples)
        exDir = fullfile(FIG.data.saveRoot, samples{si}, examples{xi});
        pd = dir(fullfile(exDir, 'phase_*'));
        pd = pd([pd.isdir] & ~cellfun('isempty', regexp({pd.name}, '^phase_\d', 'once')));   % без phase_trend
        for w = 1:numel(pd)
            for vi = 1:numel(variants)
                v = variants{vi};
                try
                    D = tp_paper_read(FIG, samples{si}, examples{xi}, v, pd(w).name);
                catch ME
                    fprintf(2, '  [skip] %s/%s/%s/%s : %s\n', samples{si}, examples{xi}, pd(w).name, v.tag, ME.message);
                    continue;
                end
                for e = 1:numel(elems)
                    if ~isfield(D.data, elems{e}); continue; end
                    A = D.data.(elems{e}).mod;
                    th = D.data.(elems{e}).arg;
                    ok = isfinite(A) & isfinite(th) & A > 0;
                    K = nnz(ok);
                    a = A(ok);
                    t = atan2(sin(th(ok)), cos(th(ok)));     % гілка (-pi, pi]

                    [m1,m2,m3,m4] = tp_moments(a, false);
                    [f1,f2,f3,f4] = tp_moments(t, true);
                    C = tp_circ_moments(t);
                    [Za, ma] = tp_power_moments(t);
                    Zm = tp_power_moments(a);

                    rows(end+1,:) = {samples{si}, examples{xi}, pd(w).name, v.tag, elems{e}, ...
                        K, 1 - K/numel(A), m1,m2,m3,m4, f1,f2,f3,f4, ...
                        C.C(1), C.S(1), C.mu, C.R(1), C.V, C.R(2), C.R(3), C.R(4), C.sigma, ...
                        real(C.M(1)), imag(C.M(1)), ...
                        Za(1),Za(2),Za(3),Za(4), ma(1),ma(2),ma(3),ma(4), Zm(1),Zm(2),Zm(3),Zm(4)}; %#ok<AGROW>
                end
            end
        end
    end
end

names = {'sample','example','phase_window','variant','element','K','excl_frac', ...
    'mod_Z1','mod_Z2','mod_Z3','mod_Z4','argF_Z1c','argF_Z2c','argF_Z3c','argF_Z4c', ...
    'C1','S1','mu','R1','V','R2','R3','R4','sigma_circ','M1_re','M1_im', ...
    'ctrl_arg_Z1','ctrl_arg_Z2','ctrl_arg_Z3','ctrl_arg_Z4', ...
    'ctrl_arg_m1','ctrl_arg_m2','ctrl_arg_m3','ctrl_arg_m4', ...
    'ctrl_mod_Z1','ctrl_mod_Z2','ctrl_mod_Z3','ctrl_mod_Z4'};
if isempty(rows)
    T = cell2table(cell(0, numel(names)), 'VariableNames', names);  Tagg = table();
    fprintf(2, 'make_circular_table: даних не знайдено у %s\n', FIG.data.saveRoot);
    return;
end
T = cell2table(rows, 'VariableNames', names);

% ---- зведення по повторах (прикладах) на зразок
[G, gS, gW, gV, gE] = findgroups(T.sample, T.phase_window, T.variant, T.element);
M1 = complex(splitapply(@mean, T.M1_re, G), splitapply(@mean, T.M1_im, G));
Tagg = table(gS, gW, gV, gE, splitapply(@numel, T.K, G), ...
    splitapply(@mean, T.R1, G), splitapply(@mean, T.V, G), ...
    splitapply(@mean, T.R2, G), splitapply(@mean, T.R3, G), splitapply(@mean, T.R4, G), ...
    mod(angle(M1), 2*pi), abs(M1), ...
    'VariableNames', {'sample','phase_window','variant','element','n_repeats', ...
                      'R1_mean','V_mean','R2_mean','R3_mean','R4_mean','mu_from_meanM1','R_of_meanM1'});

outDir = fullfile(FIG.out.root, 'stats_circular');
if ~exist(outDir,'dir'); mkdir(outDir); end
f1 = fullfile(outDir, 'circular_moments.csv');
f2 = fullfile(outDir, 'circular_moments_by_sample.csv');
writetable(T, f1, 'Encoding', 'UTF-8');
writetable(Tagg, f2, 'Encoding', 'UTF-8');
fprintf('  [ok] %s  (%d рядків)\n  [ok] %s  (%d рядків)\n', f1, height(T), f2, height(Tagg));
end
