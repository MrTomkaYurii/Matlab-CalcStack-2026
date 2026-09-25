% RUN_ALL_VERIFY  Прогін усіх перевірок: спершу кожен з 5 блоків
%   ОКРЕМО (independently), потім наскрізна перевірка повного Кроку B.
verify_block_B1_LB_0_90();    fprintf('\n');
verify_block_B2_LB_45_135();  fprintf('\n');
verify_block_B3_CB();         fprintf('\n');
verify_block_B4_rho();        fprintf('\n');
verify_block_B5_LB_total();   fprintf('\n');
verify_tp_LB_CB_rho();        fprintf('\n');
verify_known_values_and_edges(); fprintf('\n');
verify_theory_formulas();     fprintf('\n');
fprintf('=== ALL BLOCKS + FULL PIPELINE VERIFIED ===\n');
