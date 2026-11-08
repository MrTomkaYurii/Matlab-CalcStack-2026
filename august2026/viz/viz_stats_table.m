function viz_stats_table(D, meta, ctx, CFG)
% VIZ_STATS_TABLE  Статистичні моменти елемента (модуль+аргумент) — у
%   текстовий файл (не картинка), у ту ж теку, де й рисунки цього елемента
%   (Етап 2.1 ТЗ: "статистичні моменти, винести в окремі таблиці"). Один
%   файл на елемент і крок/напрям — щоб не зводити 16 елементів в один
%   суцільний текст, де важко щось знайти.
%   Формули — tp_moments (та сама, що й текст на гістограмі viz_maps_hist,
%   щоб цифри завжди збігались).

outDir = fullfile(CFG.paths.saveRoot, ctx.parts{:});
if ~exist(outDir,'dir'); mkdir(outDir); end
outFile = fullfile(outDir, [matlab.lang.makeValidName(ctx.name) '_stats.txt']);

vMod = D.mod(isfinite(D.mod));
vArg = D.arg(isfinite(D.arg));
[muM,sdM,skM,kuM,nM] = tp_moments(vMod, false);
[muA,sdA,skA,kuA,nA] = tp_moments(vArg, true);

ttl = strrep(meta.titlePrefix, '\cdot', '|');
ttl = strrep(ttl, '\Delta', 'd');

fid = fopen(outFile, 'w', 'n', 'UTF-8');
fprintf(fid, 'Статистичні моменти: %s\n', ttl);
fprintf(fid, '=================================================================\n\n');
fprintf(fid, '%-12s %10s %12s %10s %10s %10s\n', 'Величина', 'N', 'mean', 'std', 'skew', 'exkurt');
fprintf(fid, '%s\n', repmat('-', 1, 66));
fprintf(fid, '%-12s %10d %12.6g %10.4g %10.4g %10.4g\n', '|f|',       nM, muM, sdM, skM, kuM);
fprintf(fid, '%-12s %10d %12.6g %10.4g %10.4g %10.4g\n', 'Arg [rad]', nA, muA, sdA, skA, kuA);
fprintf(fid, '\nexkurt: |f| — надлишковий ексцес = куртозис - 3 (норма 0);\n');
fprintf(fid, '        Arg — круговий ексцес Фішера (кругові моменти, tp_moments).\n');
fclose(fid);
end
