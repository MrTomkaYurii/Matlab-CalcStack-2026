function name = tp_phase_field_name(CFG, k)
% TP_PHASE_FIELD_NAME  Валідне ім'я поля структури (не теки!) для фазового
%   вікна k — повний інтервал [0, U_k] у градусах: 'phase_0to360deg'
%   (найширше) ... 'phase_0to45deg' (найвужче). Дефіс ("0-45") у назві
%   поля struct заборонений -> замінено на "to". На відміну від
%   tp_phase_folder_name.m (яке пише "[0-2.00pi]" — валідно для імені
%   файлу/теки, де дефіс/дужки/крапка дозволені), тут лише цифри й "to"/"deg".

U = tp_phase_window_bounds(CFG);
degVal = round(U(k)/pi*180);
name = sprintf('phase_0to%ddeg', degVal);
end
