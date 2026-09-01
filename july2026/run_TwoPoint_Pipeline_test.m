function run_TwoPoint_Pipeline_test(cfgOverride)
% RUN_TWOPOINT_PIPELINE_TEST  Покроковий діагностичний аналіз обчислення f_ik.
%   Проходить УСЮ цепочку від вхідних поляризаційних зображень до комплексних
%   елементів матриці Мюллера, фіксуючи КОЖЕН крок картинками з діапазонами:
%     Stage 01  вхідні зображення I0..Iprav (на кожне освітлення)
%     Stage 02  амплітуди Ex,Ey та фаза delta у точках 1 і 2
%     Stage 03  проміжні РЕАЛЬНІ складові a_i, b_i (i=1..4) на кожне освітлення
%     Stage 04  збірка f_ik: Re | Im | |f| | arg  (+ прапорець FLAT)
%     Stage 05  зведення: 4x4 карти std(Re)/std(Im)/std(|f|) + таблиця CSV
%
%   Мета: чітко бачити ЩО звідки береться, де реальна/уявна частина, які
%   діапазони, і чому окремі елементи (напр. f23) виходять «фоном», а інші ні.
%
%   Лаунчер тонкий: логіка стадій — у допоміжних скриптах test/tp_test_*.
%   Результати: <saveRoot>/<sample>/TEST_ANALYSIS/<DIR>_step_<step>/

here = fileparts(mfilename('fullpath'));   % корінь проєкту (поруч із run_TwoPoint_Pipeline)
addpath(fullfile(here,'config'), fullfile(here,'core'), fullfile(here,'io'), ...
        fullfile(here,'viz'),    fullfile(here,'test'), fullfile(here,'simulation'));

if nargin >= 1 && isstruct(cfgOverride), CFG = cfgOverride; else, CFG = cfg_TwoPoint(); end
tp_check_config(CFG);   % рання перевірка конфігу

% --- параметри аналізу (одна конфігурація) --------------------------
sample    = CFG.samples{1};
direction = 'OX';                 % 'OX' або 'OY'
step      = CFG.ortho.steps(1);   % рознесення d
cmap      = 'jet';
if isfield(CFG,'test')            % необовʼязкові перевизначення через CFG.test.*
    if isfield(CFG.test,'sample'),    sample    = CFG.test.sample;    end
    if isfield(CFG.test,'direction'), direction = CFG.test.direction; end
    if isfield(CFG.test,'step'),      step      = CFG.test.step;      end
end
S = viz_style();

fprintf('=== STEP-BY-STEP ANALYSIS ===\n');
fprintf('sample=%s | source=%s | dir=%s | d=%d | crop=%d\n', ...
        sample, CFG.source, direction, step, CFG.crop.size);

% --- дані та пара точок ---------------------------------------------
IMG = tp_load_images(CFG, sample);
N   = CFG.crop.size;  d = step;
if strcmpi(direction,'OY')
    A1 = tp_slice(IMG, 1:N-d, 1:N);  A2 = tp_slice(IMG, 1+d:N, 1:N);
else
    A1 = tp_slice(IMG, 1:N, 1:N-d);  A2 = tp_slice(IMG, 1:N, 1+d:N);
end
[F, DBG] = tp_fik_pair(A1, A2);

outDir = fullfile(CFG.paths.saveRoot, sample, 'TEST_ANALYSIS', sprintf('%s_step_%d', direction, step));
if ~exist(outDir,'dir'), mkdir(outDir); end
P = struct('sample',sample,'direction',direction,'step',step,'source',CFG.source);

% --- звіт комплексності + стадії (кожна з обробкою помилок) ----------
try, tp_test_complexity_check(DBG, F, outDir);         catch ME, fprintf(2,'  [fail] complexity: %s\n', ME.message); end
try, tp_test_stage01_inputs(IMG, outDir, S, cmap, P);  catch ME, fprintf(2,'  [fail] stage01: %s\n', ME.message); end
try, tp_test_stage02_ampphase(DBG, outDir, S, cmap, P);catch ME, fprintf(2,'  [fail] stage02: %s\n', ME.message); end
try, tp_test_stage03_ab(DBG, outDir, S, cmap, P);      catch ME, fprintf(2,'  [fail] stage03: %s\n', ME.message); end
thr = struct('rel',1e-3,'abs',1e-9);                   % дефолт на випадок збою stage04
try, thr = tp_test_stage04_fik(F, outDir, S, cmap, P); catch ME, fprintf(2,'  [fail] stage04: %s\n', ME.message); end
try, tp_test_stage05_summary(F, outDir, S, P, thr);    catch ME, fprintf(2,'  [fail] stage05: %s\n', ME.message); end

fprintf('\n=== analysis done -> %s ===\n', outDir);
end
