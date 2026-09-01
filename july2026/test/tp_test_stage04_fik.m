function thr = tp_test_stage04_fik(F, outDir, S, cmap, P)
% TP_TEST_STAGE04_FIK  Stage 04: збірка кожного f_ik: Re | Im | |f| | arg.
%   Прапорець FLAT — коли модуль майже сталий (фон). Повертає пороги thr.
U = tp_test_util();
fprintf('\n-- Stage 04: assembly of f_ik (Re, Im, |f|, arg) --\n');
thr = struct('rel',1e-3,'abs',1e-9);
for i = 1:4
    for k = 1:4
        elem = sprintf('f%d%d', i, k);  Z = F.(elem);
        Re = real(Z); Im = imag(Z); Mo = abs(Z); Ar = angle(Z);
        flat = std(Mo(isfinite(Mo))) < max(thr.abs, thr.rel*mean(abs(Mo(isfinite(Mo)))));

        fig = figure('Color','w','Visible','off','Position',[80 80 1150 900]); S.light(fig);
        U.panelMap(subplot(2,2,1), Re, sprintf('Re(f_{%d%d})', i,k),       cmap, S);
        U.panelMap(subplot(2,2,2), Im, sprintf('Im(f_{%d%d})', i,k),       cmap, S);
        U.panelMap(subplot(2,2,3), Mo, sprintf('|f_{%d%d}|', i,k),         cmap, S);
        U.panelMap(subplot(2,2,4), Ar, sprintf('arg(f_{%d%d}) [rad]', i,k), cmap, S);
        flagTxt = ''; if flat, flagTxt = '   [FLAT — near-constant module]'; end
        sgtitle(sprintf('%s \\cdot %s \\cdot Stage 04: f_{%d%d}%s', P.sample, P.direction, i,k, flagTxt), ...
                'FontSize',S.titleSize,'FontWeight','bold','Interpreter','tex','Color',S.ink);
        U.saveFig(fig, outDir, sprintf('stage04_%s', elem));

        ff = ''; if flat, ff = '  <-- FLAT'; end
        fprintf('   %s: Re [%s]  Im [%s]  |f| [%s]%s\n', elem, U.rng(Re), U.rng(Im), U.rng(Mo), ff);
    end
end
end
