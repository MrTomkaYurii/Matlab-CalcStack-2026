function outPath = build_docx_fik(C, paths, steps)
% BUILD_DOCX_FIK  Стислий Word-звіт: причина малості f_ik.
%   Формат: коротке пояснення -> 3 таблиці, що показують потік масштабу ->
%   6 ключових рисунків -> рекомендації. Без покрокового «простирадла».
import mlreportgen.dom.*

outPath = fullfile(paths.case, [C.docx.name '.docx']);
d = Document(fullfile(paths.case, C.docx.name), 'docx');  open(d);
AR = {FontFamily('Arial')};

h = append(d, Heading(1, C.docx.title));
h.Style = [AR, {FontSize('15pt')}];
p = append(d, Paragraph(sprintf('Приклад: %s / %s   ·   crop %d×%d   ·   %s', ...
    C.sample, C.example, C.crop.size, C.crop.size, char(datetime('now','Format','yyyy-MM-dd')))));
p.Style = [AR, {FontSize('9pt'), Color('#666666')}];

% ---- причина: 3 речення ------------------------------------------
para(d, AR, ['Елементи f_{ik} — БІЛІНІЙНІ за полем: кожен доданок формул (6)–(13) це ' ...
    'ДОБУТОК двох амплітуд поля (Ex_1·Ex_2, Ey_1·Ey_2·cos… ). Реконструйовані поля Ex, Ey ' ...
    'приходять із масштабом |E| ~ 10^{-3} (довільний множник алгоритму відновлення полів із ' ...
    'голограм — робиться поза цим кодом). Тому |f_{ik}| ~ |E|^2 ~ (10^{-3})^2 = 10^{-6}.']);
para(d, AR, ['Це не фізична помилка: множник спільний для всіх станів освітлення і ' ...
    'скорочується у нормованій матриці m_{ik} = f_{ik}/f_{11}. Після приведення полів до ' ...
    '<I> = 1 значення f_{ik} стають порядку одиниці (Таблиця 2).']);

% ---- Таблиця 1. Потік масштабу ----------------------------------
allB = {};
for s = 1:numel(steps); allB = [allB, steps{s}.budget]; end %#ok<AGROW>
ordOf = @(key) findOrder(allB, key);

% фіксований лінійний ланцюг (не сирий порядок budget-рядків)
flow = {
 'Сирі поля Ex, Ey (вхід конвеєра)',     'масштаб алгоритму реконструкції — поза цим кодом', ordOf('сир')
 'I = |Ex|^2 + |Ey|^2  (довідково)',     'піднесення до квадрата  ->  (масштаб)^2',          ordOf('I =')
 'a_i, b_i  (формули 6–13)',             'ДОБУТОК двох амплітуд  ->  (масштаб)^2',            ordOf('a_i')
 'f_{ik}  (розділ 4)',                   'лінійна сума a, b  ->  масштаб БЕЗ зміни',          ordOf('розділ 4')
 'result.mat / рисунки статті',          'усереднення по парах точок  ->  масштаб БЕЗ зміни', ordOf('результат')
 };
hb = append(d, Heading(2, 'Таблиця 1. Потік масштабу вздовж цепочки'));  hb.Style = AR;
body = cell(size(flow,1), 4);
for r = 1:size(flow,1)
    body(r,:) = { sprintf('%d',r), flow{r,1}, flow{r,2}, sprintf('~10^%d', flow{r,3}) };
end
jtbl(d, AR, {'#','Крок / величина','Що з масштабом','Порядок'}, body, [0.05 0.34 0.45 0.12]);
para(d, AR, ['Ключ: 10^{-3} (поле)  ->  10^{-6} (f_{ik}). Тригонометрія (cos, sin) — порядку ' ...
    'одиниці, масштаб не змінює. Розділ 4 і усереднення множника не додають.']);

% ---- Таблиця 2. Порівняння -------------------------------------
D7 = struct('scaleR',NaN,'kField',-3,'kReal',-6,'kNorm',0,'kModel',-1);
for s = 1:numel(steps)
    if isfield(steps{s},'data') && isstruct(steps{s}.data) && isfield(steps{s}.data,'scaleR')
        f = fieldnames(steps{s}.data);
        for i = 1:numel(f); D7.(f{i}) = steps{s}.data.(f{i}); end
    end
end
h2 = append(d, Heading(2, 'Таблиця 2. Той самий розрахунок за різного масштабу полів'));  h2.Style = AR;
row2 = {
 'Реальні дані (як є)',                 '|E| ~ 10^-3',  sprintf('~10^%d', D7.kReal),  'мала величина (те, що бачимо)'
 sprintf('Реальні, поля / RMS (%s)', numsc(D7.scaleR)), '|E| ~ 1', sprintf('~10^%d', D7.kNorm), '«малість» зникає — та сама картина'
 'Модель july2026 (I у [0,1])',         '|E| ~ 1',      sprintf('~10^%d', D7.kModel), 'та сама формула, нормовані дані'
 };
jtbl(d, AR, {'Варіант','Масштаб полів','median |f_{ik}|','Висновок'}, row2, [0.30 0.16 0.16 0.38]);
para(d, AR, sprintf(['Різниця між реальними даними і моделлю — рівно (масштаб поля)^2 ≈ ' ...
    '(10^%d)^2 = 10^%d.'], D7.kField, 2*D7.kField));

% ---- Таблиця 3. Дефект нульових кадрів ------------------------
h3 = append(d, Heading(2, 'Таблиця 3. Окремий дефект даних (не про масштаб)'));  h3.Style = AR;
row3 = {
 'ey_0, ex_90 — суцільні нулі',  'f_{31}, f_{32}, f_{41}, f_{42} ≡ 0;  f_{11}/f_{12}/f_{21}/f_{22} без крос-складових',  'Серце/1, усі приклади Мозг'
 'усі 6 каналів цілі',           'усі 16 f_{ik} достовірні',  'Серце/2, Серце/3'
 };
jtbl(d, AR, {'Стан вхідних кадрів','Наслідок для матриці','Зразки'}, row3, [0.28 0.46 0.26]);
para(d, AR, ['Причина: у сирій голограмі цих кадрів немає інтерференційних смуг, тож ' ...
    'реконструкція повертає нулі. Проміжні a_3, a_4 для 0° і 90° занулюються  ->  A_{sum}=B_{sum}=0.']);

% ---- ключові рисунки -----------------------------------------
hf = append(d, Heading(2, 'Ключові рисунки'));  hf.Style = AR;
keyFigs = {
 '06.fik_mod_grid.png',            'Проблема: усі 16 |f_{ik}| у масштабі ~10^{-6}.'
 '02.raw_field.scale_by_state.png','Джерело: амплітуда поля |E| ~ 10^{-3}, однаково по всіх станах.'
 '07.magnitude_budget.png',        'Потік масштабу: 10^{-3} (поле) -> 10^{-6} (I, f_{ik}).'
 '07.fik_grid.real_normalized.png','Реальні f_{ik} ПІСЛЯ нормування полів до <I>=1: масштаб ~1, картина та сама.'
 '07.fik_grid.model_july2026.png', 'Модель july2026 (нормовані інтенсивності): f_{ik} ~ 0.1 тією ж формулою.'
 '08.defect.fik_zeros.png',        'Дефект кадрів: f_{31},f_{32},f_{41},f_{42} тотожно нульові.'
 };
for i = 1:size(keyFigs,1)
    fp = fullfile(paths.steps, keyFigs{i,1});
    if isfile(fp); addImage(d, fp, keyFigs{i,2}); end
end

% ---- рекомендації ------------------------------------------
hr = append(d, Heading(2, 'Рекомендації'));  hr.Style = AR;
para(d, AR, ['1) Масштаб: подавати нормовану матрицю m_{ik} = f_{ik}/f_{11} (стандарт для ' ...
    'матриці Мюллера; довільний множник скорочується), або масштабувати поля до <I> = 1, ' ...
    'або лишити як є з приміткою «arbitrary units».']);
para(d, AR, ['2) Дефект кадрів: для Серце/1 і Мозг елементи f_{31},f_{32},f_{41},f_{42} ' ...
    'недостовірні — не показувати їх для цих зразків, або будувати матрицю лише по Серце/2,3.']);

close(d);
end

% ======================================================================
function k = findOrder(allB, key)
k = NaN;
for i = 1:numel(allB)
    if contains(lower(allB{i}.stage), lower(key)); k = allB{i}.order; return; end
end
end

function s = numsc(x)
if ~isfinite(x); s = 'RMS'; return; end
if abs(x) >= 1e-3 && abs(x) < 1e4; s = sprintf('%.4g', x); else; s = sprintf('%.2e', x); end
end

% ======================================================================
function para(d, AR, txt)
import mlreportgen.dom.*
pp = append(d, Paragraph(txt));
pp.Style = [AR, {FontSize('10pt'), OuterMargin('0pt','0pt','0pt','6pt')}];
end

function jtbl(d, AR, head, body, widths)
% Таблиця у стилі журналу (booktabs-подібна).
import mlreportgen.dom.*
tb = Table([head; body]);
tb.Style = [AR, {FontSize('9pt'), Border('solid','black','0.5pt'), ...
                 ColSep('solid','black','0.25pt'), RowSep('solid','black','0.25pt'), ...
                 OuterMargin('0pt','0pt','4pt','10pt'), Width('100%')}];
tb.TableEntriesHAlign = 'left';  tb.TableEntriesVAlign = 'middle';
tb.row(1).Style = {Bold(true), BackgroundColor('#f0f0f0')};
for r = 1:tb.NRows
    for cc = 1:tb.NCols
        st = {InnerMargin('4pt','4pt','2pt','2pt')};
        if nargin >= 5 && ~isempty(widths) && cc <= numel(widths)
            st{end+1} = Width(sprintf('%.0f%%', widths(cc)*100)); %#ok<AGROW>
        end
        tb.entry(r,cc).Style = st;
    end
end
append(d, tb);
end

function addImage(d, imgPath, caption)
import mlreportgen.dom.*
try
    im = Image(imgPath);
    info = imfinfo(imgPath);
    wIn = 6.2;  hIn = wIn * info.Height / info.Width;
    hIn = min(hIn, 8.2);                    % не більше сторінки
    wIn = hIn * info.Width / info.Height;
    im.Width = sprintf('%.2fin', wIn);  im.Height = sprintf('%.2fin', hIn);
    pr = append(d, Paragraph);  pr.Style = {HAlign('center'), OuterMargin('0pt','0pt','6pt','2pt')};
    append(pr, im);
    cap = append(d, Paragraph(caption));
    cap.Style = {FontFamily('Arial'), FontSize('9pt'), Color('#555555'), ...
                 HAlign('center'), OuterMargin('0pt','0pt','0pt','12pt')};
catch
end
end
