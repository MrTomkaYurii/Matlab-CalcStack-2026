function outDir = tp_sim_analysis(CFG, sample, example, SIM, DBG)
% TP_SIM_ANALYSIS  Покроковий вивід ЕТАПІВ симуляції БТ для одного
%   зразка/прикладу. ПЕРЕНЕСЕНО з july2026\run_TwoPoint_Simulation_analysis.m
%   (тіло те саме, окремо -- лише джерело CFG і шляхи):
%     Sim 01  архітектоніка: орієнтація оптичної осі theta + затримка delta
%     Sim 02  джонсів оператор J(theta,delta): компоненти J11..J22 (Re/Im)
%     Sim 03  когерентний спекл-носій: |s|, фаза, інтенсивність
%     Sim 04  вихідні поля Ex, Ey (амплітуда/фаза) на кожне з 6 освітлень
%     Sim 05  сформовані інтенсивності I0..Iprav на кожне освітлення
%   Результати: <CFG.paths.saveRoot>\<зразок>\<приклад>\SIM_ANALYSIS\
%
%   SIM, DBG : виходи tp_sim_speckle_BT(CFG, example)

label  = sprintf('%s / %s', sample, example);      % '/' -- щоб не ламати TeX у заголовках
outDir = fullfile(CFG.paths.saveRoot, sample, example, 'SIM_ANALYSIS');
if ~exist(outDir,'dir'), mkdir(outDir); end
S = viz_style(CFG.style);

fprintf('=== SIMULATION STAGE-BY-STAGE: %s ===\n', label);
fprintf('crop=%d | axisL=%g retL=%g speckleL=%g retMax=%.3g | seed=%d\n', ...
        CFG.crop.size, CFG.sim.axisCorrLen, CFG.sim.retCorrLen, ...
        CFG.sim.speckleCorrLen, CFG.sim.retMax, SIM.seed);

try, tp_sim_stage01_tissue(SIM, outDir, S, label);      catch ME, fprintf(2,'  [fail] sim01: %s\n', ME.message); end
try, tp_sim_stage02_jones(DBG, outDir, S, label);       catch ME, fprintf(2,'  [fail] sim02: %s\n', ME.message); end
try, tp_sim_stage03_speckle(SIM, outDir, S, label);     catch ME, fprintf(2,'  [fail] sim03: %s\n', ME.message); end
try, tp_sim_stage04_fields(DBG, outDir, S, label);      catch ME, fprintf(2,'  [fail] sim04: %s\n', ME.message); end
try, tp_sim_stage05_intensities(DBG, outDir, S, label); catch ME, fprintf(2,'  [fail] sim05: %s\n', ME.message); end

fprintf('=== simulation analysis done -> %s ===\n', outDir);
end
