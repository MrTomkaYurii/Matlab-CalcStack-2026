function run_ArgCentralMoments(dstBase)
% RUN_ARGCENTRALMOMENTS  Центральні (звичайні, не кругові) моменти аргументу,
%   зведеного до [0, 2pi), для всіх result.mat. Нічого не перераховує в f_ik —
%   лише читає готові result.mat.
%
%   Z1 — середнє, Z2 — СКВ (1/K), Z3 — асиметрія, Z4 — надлишковий ексцес (норма 0).
%   Ті самі точки, що й у fXX_stats.txt: arg = mod(arg, 2pi), скінченні значення;
%   елементи, які tp_visualize пропускає (tp_validate), пропускаються й тут.
%
%   Вивід — у C:\August 2026-Results-3 з тією самою структурою тек:
%     ...\<крок>\fXX\fXX_stats_arg_central_0-2pi.txt   (окреме ім'я — при копіюванні
%                                                         поверх НЕ перезапише fXX_stats.txt)
%     ...\<крок>\arg_central_done.txt                   (службовий, для відновлення)
%     C:\August 2026-Results-3\arg_central_moments_0-2pi.csv   (усе однією таблицею)
%
%   Після вимкнення світла — запустити ще раз: теки з arg_central_done.txt пропускаються.

if nargin < 1, dstBase = 'C:\August 2026-Results-3'; end
here = fileparts(mfilename('fullpath'));
repo = fileparts(here);
addpath(repo, fullfile(repo,'config'), genpath(fullfile(repo,'core')), fullfile(repo,'io'));

CFG = cfg_TwoPoint();
srcRoot = CFG.paths.saveRoot;                                      % ...\Розрахунки - Двот. елем. ММ
dstRoot = strrep(srcRoot, 'C:\August 2026-Results', dstBase);
if ~exist(dstRoot, 'dir'); mkdir(dstRoot); end

L = dir(fullfile(srcRoot, '**', 'result.mat'));
files = fullfile({L.folder}, {L.name});
fprintf('=== Центральні моменти arg на [0, 2pi): %d result.mat -> %s ===\n', numel(files), dstRoot);
t0 = tic; nOk = 0; nSkip = 0; nFail = 0;
for i = 1:numel(files)
    f = files{i};
    srcDir = fileparts(f);
    dstDir = strrep(srcDir, srcRoot, dstRoot);
    doneFile = fullfile(dstDir, 'arg_central_done.txt');
    if isfile(doneFile); nSkip = nSkip + 1; continue; end
    fprintf('[%d/%d] %s\n', i, numel(files), erase(srcDir, [srcRoot filesep]));
    try
        S = load(f);
        if isfield(S,'R'); R = S.R; else; R = S.Rd; end
        if numel(R.dirs) ~= 1
            error('очікувався 1 напрям у result.mat, а є %d', numel(R.dirs));
        end
        dirn = R.dirs{1};
        for e = 1:numel(R.elements)
            elem = R.elements{e};
            D = R.data.(dirn).(elem);
            if ~tp_validate(D.mod, CFG); continue; end            % як у tp_visualize
            v = mod(D.arg(:), 2*pi);  v = v(isfinite(v));
            [z1, z2, z3, z4] = centralMoments(v);
            outDir = fullfile(dstDir, elem);
            if ~exist(outDir, 'dir'); mkdir(outDir); end
            fid = fopen(fullfile(outDir, [elem '_stats_arg_central_0-2pi.txt']), 'w', 'n', 'UTF-8');
            fprintf(fid, 'Центральні моменти Arg на [0, 2pi): %s | %s\n', ...
                    erase(srcDir, [srcRoot filesep]), elem);
            fprintf(fid, '=================================================================\n\n');
            fprintf(fid, '%-12s %10s %12s %10s %10s %10s\n', 'Величина', 'N', 'mean', 'std', 'skew', 'exkurt');
            fprintf(fid, '%s\n', repmat('-', 1, 66));
            fprintf(fid, '%-12s %10d %12.6g %10.4g %10.4g %10.4g\n', 'Arg [rad]', numel(v), z1, z2, z3, z4);
            fprintf(fid, '\nexkurt — надлишковий ексцес = куртозис - 3 (норма 0); std — з 1/K.\n');
            fclose(fid);
        end
        if ~exist(dstDir, 'dir'); mkdir(dstDir); end     % усі елементи могли бути пропущені
        fid = fopen(doneFile, 'w', 'n', 'UTF-8');
        fprintf(fid, '%s\n', char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'))); fclose(fid);
        nOk = nOk + 1;
    catch ME
        fprintf(2, '  [fail] %s\n', ME.message);
        nFail = nFail + 1;
    end
    tp_progress(nOk + nFail, numel(files) - nSkip, t0, sprintf('файли %d/%d', i, numel(files)));
end
fprintf('=== Готово: %d ок, %d з помилками, %d пропущено ===\n', nOk, nFail, nSkip);
writeSummary(dstBase, dstRoot);
end

% ------------------------------------------------------------------------
function [z1, z2, z3, z4] = centralMoments(v)
if isempty(v); z1 = NaN; z2 = NaN; z3 = NaN; z4 = NaN; return; end
z1 = mean(v);
d  = v - z1;
z2 = sqrt(mean(d.^2));
if z2 > 0
    z3 = mean(d.^3) / z2^3;
    z4 = mean(d.^4) / z2^4 - 3;
else
    z3 = NaN; z4 = NaN;
end
end

function writeSummary(dstBase, dstRoot)
% усі fXX_stats_arg_central_0-2pi.txt -> одна CSV
L = dir(fullfile(dstRoot, '**', '*_stats_arg_central_0-2pi.txt'));
out = fullfile(dstBase, 'arg_central_moments_0-2pi.csv');
fid = fopen(out, 'w', 'n', 'UTF-8');
fprintf(fid, '\xFEFFpath,element,N,Z1_mean,Z2_std,Z3_skew,Z4_exkurt\n');
for k = 1:numel(L)
    txt = fileread(fullfile(L(k).folder, L(k).name));
    tok = regexp(txt, 'Arg \[rad\]\s+(\d+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)', 'tokens', 'once');
    if isempty(tok); continue; end
    stepDir = fileparts(L(k).folder);
    fprintf(fid, '"%s",%s,%s,%s,%s,%s,%s\n', erase(stepDir, [dstRoot filesep]), ...
            L(k).name(1:3), tok{:});
end
fclose(fid);
fprintf('Зведена таблиця: %s (%d рядків)\n', out, numel(L));
end
