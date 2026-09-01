function tp_sim_stage02_jones(DBG, outDir, S, sample)
% TP_SIM_STAGE02_JONES  Sim 02: компоненти джонсового оператора J(theta,delta).
%   Показуємо Re (верх) та Im (низ) усіх чотирьох елементів J11..J22 (2x4).
%   Це найчесніше подання: Re J11 = cos(δ/2); Im J11 = sin(δ/2)cos2θ;
%   Im J12 = sin(δ/2)sin2θ — три фізичні компоненти вектора затримки.
%   Re J12 = Re J21 = 0 ОЧІКУВАНО (ретардер: off-діагональ чисто уявна) —
%   це факт, а не помилка. arg не показуємо (у off-діаг тривіально ±pi/2).
U = tp_test_util();
fprintf('\n-- Sim 02: Jones operator components J11..J22 (Re, Im) --\n');
comps = {'J11','J12','J21','J22'};

fig = figure('Color','w','Visible','off','Position',[40 40 1600 820]); S.light(fig);
for c = 1:numel(comps)
    Jc = DBG.J.(comps{c});
    U.panelMap(subplot(2,4,c),   real(Jc), sprintf('Re %s', comps{c}), 'jet', S);
    U.panelMap(subplot(2,4,c+4), imag(Jc), sprintf('Im %s', comps{c}), 'jet', S);
end
sgtitle(sprintf(['%s \\cdot Sim 02: Jones J(\\theta,\\delta) — Re (top), Im (bottom)  ', ...
                 '[off-diagonal is purely imaginary: Re J12=Re J21=0]'], sample), ...
        'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
U.saveFig(fig, outDir, 'sim02_jones');
end
