function run_TwoPoint_Simulation_analysis(cfgOverride)
% RUN_TWOPOINT_SIMULATION_ANALYSIS  Покроковий вивід ЕТАПІВ симуляції БТ.
%   Показує, як будується синтетичне спекл-поле двопроменезаломної тканини:
%     Sim 01  архітектоніка: орієнтація оптичної осі theta + затримка delta
%     Sim 02  джонсів оператор J(theta,delta): компоненти J11..J22 (Re/Im)
%     Sim 03  когерентний спекл-носій: |s|, фаза, інтенсивність
%     Sim 04  вихідні поля Ex, Ey (амплітуда/фаза) на кожне освітлення
%     Sim 05  сформовані інтенсивності I0..Iprav на кожне освітлення
%
%   Результати: <saveRoot>/<sample>/SIM_ANALYSIS/

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'config'), fullfile(here,'core'), fullfile(here,'io'), ...
        fullfile(here,'viz'), fullfile(here,'test'), fullfile(here,'simulation'));

if nargin >= 1 && isstruct(cfgOverride), CFG = cfgOverride; else, CFG = cfg_TwoPoint(); end
tp_check_config(CFG);   % рання перевірка конфігу
sample = CFG.samples{1};
S = viz_style();

fprintf('=== SIMULATION STAGE-BY-STAGE ===\n');
fprintf('sample=%s | crop=%d | axisL=%g retL=%g speckleL=%g retMax=%.3g\n', ...
        sample, CFG.crop.size, CFG.sim.axisCorrLen, CFG.sim.retCorrLen, ...
        CFG.sim.speckleCorrLen, CFG.sim.retMax);

[IMG, SIM, DBG] = tp_sim_speckle_BT(CFG);

outDir = fullfile(CFG.paths.saveRoot, sample, 'SIM_ANALYSIS');
if ~exist(outDir,'dir'), mkdir(outDir); end

try, tp_sim_stage01_tissue(SIM, outDir, S, sample);      catch ME, fprintf(2,'  [fail] sim01: %s\n', ME.message); end
try, tp_sim_stage02_jones(DBG, outDir, S, sample);       catch ME, fprintf(2,'  [fail] sim02: %s\n', ME.message); end
try, tp_sim_stage03_speckle(SIM, outDir, S, sample);     catch ME, fprintf(2,'  [fail] sim03: %s\n', ME.message); end
try, tp_sim_stage04_fields(DBG, outDir, S, sample);      catch ME, fprintf(2,'  [fail] sim04: %s\n', ME.message); end
try, tp_sim_stage05_intensities(IMG, outDir, S, sample); catch ME, fprintf(2,'  [fail] sim05: %s\n', ME.message); end

fprintf('\n=== simulation analysis done -> %s ===\n', outDir);
end
