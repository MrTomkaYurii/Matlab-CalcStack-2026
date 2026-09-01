function tp_test_complexity_check(DBG, F, outDir)
% TP_TEST_COMPLEXITY_CHECK  Явний звіт: де величини дійсні, а де комплексні.
%   Перевіряє всі проміжні величини (мають бути ДІЙСНІ) та елементи f_ik
%   (КОМПЛЕКСНІ за побудовою). Для кожної друкує REAL/COMPLEX і max|Im|.
%   Записує також outDir/complexity_report.txt.

fprintf('\n-- Complexity check (real vs complex) --\n');
rep = {};

% проміжні: Ex, Ey, delta — мають бути REAL
qs = {'Ex1','Ex2','Ey1','Ey2','d1','d2'};
for p = 1:numel(DBG.pols)
    P = DBG.pols{p};  g = DBG.perPol.(P);
    for q = 1:numel(qs)
        [s, mi] = chk(g.(qs{q}));
        rep{end+1} = sprintf('%-5s %-4s : %-7s (max|Im|=%.2g)', P, qs{q}, s, mi); %#ok<AGROW>
    end
end

% проміжні a_i, b_i — мають бути REAL
for i = 1:4
    for p = 1:numel(DBG.pols)
        P = DBG.pols{p};
        [sa, ma] = chk(DBG.a{i}.(P));  [sb, mb] = chk(DBG.b{i}.(P));
        rep{end+1} = sprintf('%-5s a%d/b%d : a:%-7s(%.2g)  b:%-7s(%.2g)', P, i, i, sa, ma, sb, mb); %#ok<AGROW>
    end
end

% f_ik — COMPLEX за побудовою (показуємо діапазони Re та Im)
fn = fieldnames(F);
for n = 1:numel(fn)
    Z = F.(fn{n});
    rep{end+1} = sprintf('%-5s      : COMPLEX  Re[%.3g..%.3g]  Im[%.3g..%.3g]', fn{n}, ...
        min(real(Z(:))), max(real(Z(:))), min(imag(Z(:))), max(imag(Z(:)))); %#ok<AGROW>
end

for i = 1:numel(rep), fprintf('   %s\n', rep{i}); end
fid = fopen(fullfile(outDir,'complexity_report.txt'),'w');
if fid > 0, fprintf(fid,'%s\n', rep{:}); fclose(fid); end
fprintf('   wrote %s\n', fullfile(outDir,'complexity_report.txt'));

% попередження, якщо проміжна величина несподівано комплексна
warnAny = false;
for p = 1:numel(DBG.pols)
    P = DBG.pols{p};  g = DBG.perPol.(P);
    for q = 1:numel(qs), if ~isRealish(g.(qs{q})), warnAny = true; end, end
    for i = 1:4
        if ~isRealish(DBG.a{i}.(P)) || ~isRealish(DBG.b{i}.(P)), warnAny = true; end
    end
end
if warnAny
    fprintf(2,'   WARNING: деякі проміжні величини комплексні (перевір відʼємні інтенсивності)!\n');
end
end

% ------------------------------------------------------------------------
function [s, mi] = chk(Z)
mi = max(abs(imag(Z(:))));
if isreal(Z) || mi == 0, s = 'REAL'; else, s = 'COMPLEX'; end
end
function tf = isRealish(Z)
tf = isreal(Z) || max(abs(imag(Z(:)))) == 0;
end
