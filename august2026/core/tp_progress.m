function tp_progress(done, total, t0, label)
% TP_PROGRESS  Рядок прогресу в командному вікні:
%   [████████░░░░░░░░░░░░]  12/72  16.7% | минуло 0:35 | залишилось ~2:55 | Серце / 1 / phase_04
%   done, total — виконано / усього кроків; t0 — tic від початку; label — що щойно завершено.
%   Залишок — лінійна оцінка за середнім часом кроку.

W = 30;
frac = min(max(done / max(total, 1), 0), 1);
nFull = round(W * frac);
bar = [repmat(char(9608), 1, nFull) repmat(char(9617), 1, W - nFull)];
el = toc(t0);
if done > 0
    left = el / done * (total - done);
    leftTxt = ['~' hm(left)];
else
    leftTxt = '?';
end
fprintf('[%s] %3d/%d %5.1f%% | минуло %s | залишилось %s | %s\n', ...
        bar, done, total, 100*frac, hm(el), leftTxt, label);
end

function s = hm(sec)
s = sprintf('%d:%02d', floor(sec/3600), floor(mod(sec, 3600)/60));
end
