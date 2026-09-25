function name = tp_phase_folder_name(CFG, k)
% TP_PHASE_FOLDER_NAME  Назва теки фазового вікна k: номер (для сортування)
%   + верхня межа вікна прямо в назві (щоб не лізти в phase_info.txt, аби
%   зрозуміти, яке це вікно): phase_01_[0-2.00pi] ... phase_08_[0-0.25pi].
%   Єдине місце форматування — використовується і при записі (run_TwoPoint_
%   Pipeline), і при читанні (tp_phase_trend, run_TwoPoint_CollectForHorsky).

U = tp_phase_window_bounds(CFG);
name = sprintf('phase_%02d_[0-%.2fpi]', k, U(k)/pi);
end
