# Математичні викладки: LB₀,₉₀, LB₄₅,₁₃₅, CB, ρ, LB

Джерело: `techn-zavd\Теорія поляризаційно-кореляційна томографія.docx`
(зелені блоки). Тут кожна формула **виведена з нуля** (а не переписана з
Word), фінальні формули зведені в §9, розбіжності з Word — в §8.
Код: `LB_CB_rho\tp_B1_LB_0_90.m … tp_B5_LB_total.m`.

**Зміст**
1. Вхідні величини
2. Лема про логарифм комплексного відношення
3. B.1 — LB₀,₉₀
4. B.2 — LB₄₅,₁₃₅
5. B.3 — CB
6. B.4 — ρ
7. B.5 — LB
8. Розбіжності з Word і межі цього документа
9. Фінальні формули (зведення)
10. Чисельна перевірка
11. Особливі випадки, гілки, масштаб

---

## 1. Вхідні величини

Крок A (`august2026_copy\tp_fik_pair.m`, не змінювався і тут не виводиться) дає
комплексні елементи двоточкової матриці Мюллера

$$f^{c}_{mn}=\Delta A_{mn}+i\,\Delta B_{mn},\qquad i^2=-1,$$

де $\Delta A_{mn},\Delta B_{mn}$ — **дійсні**, тобто

$$\Delta A_{mn}=\operatorname{Re} f^{c}_{mn},\qquad \Delta B_{mn}=\operatorname{Im} f^{c}_{mn}.$$

Верхні індекси у Word ($RC,LC$; $45,135$; $0,90$) позначають, з яких
освітлень складено відповідний $f^{c}_{mn}$. Це робить Крок A; для
Кроку B важливі лише самі числа $\Delta A,\Delta B$.

Кожен із $f_{34},f_{43},f_{24},f_{42},f_{23},f_{32}$ — це 2D-карта
(комплексне число в кожному пікселі); усі формули нижче діють
**поелементно** (піксель за пікселем).

Вихідні співвідношення (Word, (1)–(5)):

$$
\begin{aligned}
LB_{0,90}&=\ln\frac{f^c_{34}}{f^c_{43}}, &
LB_{45,135}&=\ln\frac{f^c_{24}}{f^c_{42}}, &
CB&=\ln\frac{f^c_{23}}{f^c_{32}},\\[2pt]
\rho&=\frac12\arctan\frac{LB_{45,135}}{LB_{0,90}}, &
LB&=\sqrt{LB_{0,90}^{2}+LB_{45,135}^{2}}.
\end{aligned}
$$

Тут $\ln$, $\arctan$, $\sqrt{\ }$ — **комплексні, головні значення**.

---

## 2. Лема про логарифм комплексного відношення

Це єдиний "будівельний блок" для B.1, B.2, B.3.

Нехай $z_1=a_1+ib_1$ (чисельник), $z_2=a_2+ib_2$ (знаменник),
$z_1\neq0,\ z_2\neq0$, $a_k,b_k\in\mathbb R$. Тоді

$$\ln\frac{z_1}{z_2}=\ln\left|\frac{z_1}{z_2}\right|+i\operatorname{Arg}\frac{z_1}{z_2}=\mathrm{Re}+i\,\mathrm{Im}.$$

**Дійсна частина.**

$$\left|\frac{z_1}{z_2}\right|=\sqrt{\frac{a_1^2+b_1^2}{a_2^2+b_2^2}}
\;\Rightarrow\;
\boxed{\mathrm{Re}=\frac12\ln\frac{a_1^2+b_1^2}{a_2^2+b_2^2}}$$

**Уявна частина.** Помножимо чисельник і знаменник на $\bar z_2=a_2-ib_2$:

$$\frac{z_1}{z_2}=\frac{z_1\bar z_2}{|z_2|^2},\qquad
z_1\bar z_2=(a_1a_2+b_1b_2)+i\,(b_1a_2-a_1b_2).$$

Оскільки $|z_2|^2=a_2^2+b_2^2>0$, воно не змінює аргумент, тому

$$\boxed{\mathrm{Im}=\operatorname{atan2}\!\bigl(b_1a_2-a_1b_2,\;a_1a_2+b_1b_2\bigr)}$$

(двоаргументний $\operatorname{atan2}(y,x)$, значення в $(-\pi,\pi]$ — головне
значення аргументу.)

**Модуль і аргумент самого логарифма** (число $\mathrm{Re}+i\,\mathrm{Im}$):

$$\boxed{\left|\ln\frac{z_1}{z_2}\right|=\sqrt{\mathrm{Re}^2+\mathrm{Im}^2}},\qquad
\boxed{\arg\!\left[\ln\frac{z_1}{z_2}\right]=\operatorname{atan2}(\mathrm{Im},\mathrm{Re})}$$

> **Позначення Word.** У Word записано $\operatorname{atan2}\!\left(\frac{\text{чисельник}}{\text{знаменник}}\right)$
> з дробом усередині дужок. Це читається як двоаргументний
> $\operatorname{atan2}(\text{чисельник},\text{знаменник})$: лише так зберігається
> квадрант. Односаргументний $\arctan(\text{дріб})$ квадрант губить.
> Так само читаються всі `atan2(·/·)` у документі.

---

## 3. B.1 — $LB_{0,90}=\ln(f^c_{34}/f^c_{43})$

Підстановка в лему: $z_1=f^c_{34}$, $z_2=f^c_{43}$:

$$a_1=\Delta A_{34}^{RC,LC},\; b_1=\Delta B_{34}^{RC,LC},\qquad
a_2=\Delta A_{43}^{45,135},\; b_2=\Delta B_{43}^{45,135}.$$

$$\mathrm{Re}_{34,43}=\frac12\ln\frac{\bigl(\Delta A_{34}^{RC,LC}\bigr)^2+\bigl(\Delta B_{34}^{RC,LC}\bigr)^2}
{\bigl(\Delta A_{43}^{45,135}\bigr)^2+\bigl(\Delta B_{43}^{45,135}\bigr)^2}$$

$$\mathrm{Im}_{34,43}=\operatorname{atan2}\!\Bigl(
\Delta B_{34}^{RC,LC}\Delta A_{43}^{45,135}-\Delta A_{34}^{RC,LC}\Delta B_{43}^{45,135},\;
\Delta A_{34}^{RC,LC}\Delta A_{43}^{45,135}+\Delta B_{34}^{RC,LC}\Delta B_{43}^{45,135}\Bigr)$$

**Результат (зелені блоки):**

$$\boxed{|LB_{0,90}|=\sqrt{(\mathrm{Re}_{34,43})^2+(\mathrm{Im}_{34,43})^2}},\qquad
\boxed{\arg[LB_{0,90}]=\operatorname{atan2}(\mathrm{Im}_{34,43},\mathrm{Re}_{34,43})}$$

$$LB_{0,90}=\mathrm{Re}_{34,43}+i\,\mathrm{Im}_{34,43}.$$

---

## 4. B.2 — $LB_{45,135}=\ln(f^c_{24}/f^c_{42})$

$z_1=f^c_{24}$, $z_2=f^c_{42}$:
$a_1=\Delta A_{24}^{RC,LC}$, $b_1=\Delta B_{24}^{RC,LC}$,
$a_2=\Delta A_{42}^{0,90}$, $b_2=\Delta B_{42}^{0,90}$.

$$\mathrm{Re}_{24,42}=\frac12\ln\frac{\bigl(\Delta A_{24}^{RC,LC}\bigr)^2+\bigl(\Delta B_{24}^{RC,LC}\bigr)^2}
{\bigl(\Delta A_{42}^{0,90}\bigr)^2+\bigl(\Delta B_{42}^{0,90}\bigr)^2}$$

$$\mathrm{Im}_{24,42}=\operatorname{atan2}\!\Bigl(
\Delta B_{24}^{RC,LC}\Delta A_{42}^{0,90}-\Delta A_{24}^{RC,LC}\Delta B_{42}^{0,90},\;
\Delta A_{24}^{RC,LC}\Delta A_{42}^{0,90}+\Delta B_{24}^{RC,LC}\Delta B_{42}^{0,90}\Bigr)$$

$$\boxed{|LB_{45,135}|=\sqrt{(\mathrm{Re}_{24,42})^2+(\mathrm{Im}_{24,42})^2}},\qquad
\boxed{\arg[LB_{45,135}]=\operatorname{atan2}(\mathrm{Im}_{24,42},\mathrm{Re}_{24,42})}$$

---

## 5. B.3 — $CB=\ln(f^c_{23}/f^c_{32})$

$z_1=f^c_{23}$, $z_2=f^c_{32}$:
$a_1=\Delta A_{23}^{45,135}$, $b_1=\Delta B_{23}^{45,135}$,
$a_2=\Delta A_{32}^{0,90}$, $b_2=\Delta B_{32}^{0,90}$.

$$\mathrm{Re}_{23,32}=\frac12\ln\frac{\bigl(\Delta A_{23}^{45,135}\bigr)^2+\bigl(\Delta B_{23}^{45,135}\bigr)^2}
{\bigl(\Delta A_{32}^{0,90}\bigr)^2+\bigl(\Delta B_{32}^{0,90}\bigr)^2}$$

$$\mathrm{Im}_{23,32}=\operatorname{atan2}\!\Bigl(
\Delta B_{23}^{45,135}\Delta A_{32}^{0,90}-\Delta A_{23}^{45,135}\Delta B_{32}^{0,90},\;
\Delta A_{23}^{45,135}\Delta A_{32}^{0,90}+\Delta B_{23}^{45,135}\Delta B_{32}^{0,90}\Bigr)$$

$$\boxed{|CB|=\sqrt{(\mathrm{Re}_{23,32})^2+(\mathrm{Im}_{23,32})^2}},\qquad
\boxed{\arg[CB]=\operatorname{atan2}(\mathrm{Im}_{23,32},\mathrm{Re}_{23,32})}$$

---

## 6. B.4 — $\rho=\tfrac12\arctan\!\bigl(LB_{45,135}/LB_{0,90}\bigr)$

Вхід — **комплексні** $LB_{0,90}$ і $LB_{45,135}$ з §3–§4:

$$A_1+iB_1=LB_{0,90}=\mathrm{Re}_{34,43}+i\,\mathrm{Im}_{34,43}\quad(\text{знаменник}),$$
$$A_2+iB_2=LB_{45,135}=\mathrm{Re}_{24,42}+i\,\mathrm{Im}_{24,42}\quad(\text{чисельник}).$$

### 6.1 Комплексне відношення $w=X+iY$

$$w=\frac{LB_{45,135}}{LB_{0,90}}=\frac{A_2+iB_2}{A_1+iB_1}
=\frac{(A_2+iB_2)(A_1-iB_1)}{A_1^2+B_1^2}
=\frac{(A_1A_2+B_1B_2)+i\,(A_1B_2-A_2B_1)}{A_1^2+B_1^2}$$

$$\boxed{X=\frac{A_1A_2+B_1B_2}{A_1^2+B_1^2}},\qquad
\boxed{Y=\frac{A_1B_2-A_2B_1}{A_1^2+B_1^2}}$$

(У Word: $X=\dfrac{\mathrm{Re}_{34,43}\mathrm{Re}_{24,42}+\mathrm{Im}_{34,43}\mathrm{Im}_{24,42}}{(\mathrm{Re}_{34,43})^2+(\mathrm{Im}_{34,43})^2}$
— те саме при $A_1=\mathrm{Re}_{34,43}$ і т. д.)

### 6.2 Комплексний арктангенс $\arctan(X+iY)$

Головне значення: $\arctan w=\dfrac{1}{2i}\ln\dfrac{1+iw}{1-iw}$.
При $w=X+iY$: $iw=iX-Y$, тому

$$1+iw=(1-Y)+iX,\qquad 1-iw=(1+Y)-iX.$$

*Модуль відношення:*

$$\left|\frac{1+iw}{1-iw}\right|^2=\frac{X^2+(1-Y)^2}{X^2+(1+Y)^2}.$$

*Аргумент відношення* (множимо на спряжений знаменник $(1+Y)+iX$):

$$\bigl[(1-Y)+iX\bigr]\bigl[(1+Y)+iX\bigr]=(1-Y^2-X^2)+i\,2X$$

(cross-члени $iX(1-Y)+iX(1+Y)=2iX$, а $i^2X^2=-X^2$). Знаменник
$|1-iw|^2>0$ аргумент не змінює, тож аргумент відношення
$=\operatorname{atan2}(2X,\;1-X^2-Y^2)$. Разом:

$$\ln\frac{1+iw}{1-iw}=\underbrace{\frac12\ln\frac{X^2+(1-Y)^2}{X^2+(1+Y)^2}}_{a}
+i\underbrace{\operatorname{atan2}(2X,\,1-X^2-Y^2)}_{b}.$$

$$\arctan w=\frac{1}{2i}(a+ib)=\frac12 b-\frac i2 a
\;\Rightarrow\;
\begin{cases}
\operatorname{Re}\arctan w=\dfrac12\operatorname{atan2}(2X,\,1-X^2-Y^2)\\[6pt]
\operatorname{Im}\arctan w=\dfrac14\ln\dfrac{X^2+(1+Y)^2}{X^2+(1-Y)^2}
\end{cases}$$

(знак у $\operatorname{Im}$: $-\tfrac12 a=-\tfrac14\ln\frac{X^2+(1-Y)^2}{X^2+(1+Y)^2}=+\tfrac14\ln\frac{X^2+(1+Y)^2}{X^2+(1-Y)^2}$.)

### 6.3 Множник ½ і фінальна форма ρ

$\rho=\tfrac12\arctan w$, отже

$$\boxed{\rho=P+iQ},\qquad
\boxed{P=\frac14\operatorname{atan2}\!\bigl(2X,\,1-X^2-Y^2\bigr)},\qquad
\boxed{Q=\frac18\ln\frac{X^2+(1+Y)^2}{X^2+(1-Y)^2}}$$

Це збігається з Word (сторінка 3).

### 6.4 Модуль

$$\boxed{|\rho|=\sqrt{P^2+Q^2}=\sqrt{\Bigl\{\tfrac14\operatorname{atan2}\!\bigl(2X,1-X^2-Y^2\bigr)\Bigr\}^2+\Bigl\{\tfrac18\ln\tfrac{X^2+(1+Y)^2}{X^2+(1-Y)^2}\Bigr\}^2}}$$

Це збігається з Word (зелений блок $|\rho|$).

### 6.5 Аргумент

Позначимо $T=\operatorname{atan2}(2X,\,1-X^2-Y^2)$ і $L=\ln\dfrac{X^2+(1+Y)^2}{X^2+(1-Y)^2}$.
Тоді $P=T/4$, $Q=L/8$. За означенням аргументу комплексного числа $P+iQ$:

$$\arg\rho=\operatorname{atan2}(Q,P)=\operatorname{atan2}\!\Bigl(\tfrac{L}{8},\tfrac{T}{4}\Bigr)
=\operatorname{atan2}(L,\,2T),$$

бо $\operatorname{atan2}(ky,kx)=\operatorname{atan2}(y,x)$ для будь-якого $k>0$
(тут $k=8$). Відношення $Q/P=L/(2T)$, а **не** $L/T$.

$$\boxed{\arg(\rho)=\operatorname{atan2}(Q,P)=\operatorname{atan2}\!\Bigl(\frac{\tfrac18\ln\tfrac{X^2+(1+Y)^2}{X^2+(1-Y)^2}}{\tfrac14\operatorname{atan2}\!\bigl(2X,\,1-X^2-Y^2\bigr)}\Bigr)
=\operatorname{atan2}(L,\,2T)}$$

Це **відрізняється від Word** (там `atan4(L/T)`) — див. §8.

---

## 7. B.5 — $LB=\sqrt{LB_{0,90}^2+LB_{45,135}^2}$

З тими самими $A_1+iB_1=LB_{0,90}$, $A_2+iB_2=LB_{45,135}$ (див. §8, п.5
про походження цих позначень на сторінці 4):

$$(A_1+iB_1)^2+(A_2+iB_2)^2=(A_1^2-B_1^2+A_2^2-B_2^2)+i\,2(A_1B_1+A_2B_2)=C+iD,$$

$$\boxed{C=A_1^2-B_1^2+A_2^2-B_2^2},\qquad \boxed{D=2(A_1B_1+A_2B_2)}.$$

Головне значення комплексного кореня $LB=\sqrt{C+iD}$: для будь-якого
комплексного $z$, $|\sqrt z|=|z|^{1/2}$ і $\arg\sqrt z=\tfrac12\arg z$
(головна гілка, $\arg\sqrt z\in(-\pi/2,\pi/2]$). Тому, з $|z|=\sqrt{C^2+D^2}$:

$$\boxed{|LB|=\bigl(C^2+D^2\bigr)^{1/4}=\Bigl((A_1^2-B_1^2+A_2^2-B_2^2)^2+4(A_1B_1+A_2B_2)^2\Bigr)^{1/4}}$$

$$\boxed{\arg(LB)=\frac12\operatorname{atan2}(D,C)=\frac12\operatorname{atan2}\!\Bigl(\frac{2(A_1B_1+A_2B_2)}{A_1^2-B_1^2+A_2^2-B_2^2}\Bigr)}$$

(У Word є проміжне $R=\sqrt{C^2+D^2}$; тоді $|LB|=\sqrt R$.)
Це збігається з Word (зелені блоки $|LB|$ і $\arg(LB)$).

---

## 8. Розбіжності з Word і межі цього документа

**Виправлення до Word (є в коді, позначені в коментарях):**

1. **$\arg(\rho)$ — помилка.** У Word `atan4(ln[…] / atan2(…))`. Функції
   `atan4` не існує в стандартній математиці й у документі не визначена
   (переглянуто всі 4 сторінки). Виведення §6.5 дає
   $\arg\rho=\operatorname{atan2}(L,2T)$. У Word у відношенні
   $L/T$ бракує множника $\tfrac12$ (правильне $Q/P=L/(2T)$). Формула у Word
   невірна; реалізовано за §6.5.
2. **CB — одруківка індексів.** Перший рядок виводу CB (сторінка 2) у
   чисельнику/знаменнику має $\Delta A_{34}^{45,135}$ і $\Delta A_{43}^{0,90}$.
   Усі наступні рядки ($\mathrm{Re}_{23,32}$, $\mathrm{Im}_{23,32}$) і сам
   $CB=\ln(f_{23}/f_{32})$ мають $23/32$. Реалізовано $23/32$.
3. **ρ — регістр.** У блоці "де $P=\ldots$, $Q=\ldots$" (сторінка 3) стоять
   малі $x,y$; з контексту це $X,Y$.
4. **atan2 з дробом.** Див. примітку в §2 — читається як двоаргументний
   $\operatorname{atan2}$.
5. **LB — позначення на сторінці 4.** Word там пише $LB'_{0,90}$,
   $LB'_{45,135}$ (зі штрихом; зміст штриха не пояснено) і використовує
   $A_1,B_1,A_2,B_2$, не визначаючи їх знову. Прийнято: $A_1+iB_1=LB_{0,90}$,
   $A_2+iB_2=LB_{45,135}$ (як на сторінці 3). Алгебра $C,D$ у Word
   узгоджується з цим читанням ($C+iD=(A_1+iB_1)^2+(A_2+iB_2)^2$), але
   сам документ на сторінці 4 позначень не повторює — це припущення,
   а не прямо написане.

**Що цей документ НЕ доводить:**

- Задум автора Word щодо "atan4" (що це — одруківка чи власна функція).
  Доведено лише, що правильний $\arg\rho$ — це $\operatorname{atan2}(L,2T)$.
- Формули Кроку A ($f_{mn}$ з полів $E_x,E_y$) не виводилися; вони
  скопійовані з `august2026` без змін.
- Фізична інтерпретація $LB,CB,\rho$ не розглядається — лише математика.

---

## 9. Фінальні формули (зведення)

Позначення: $\operatorname{atan2}(y,x)$ — двоаргументний, значення в $(-\pi,\pi]$.

| Блок | Формула |
|---|---|
| **B.1** | $\mathrm{Re}_{34,43}=\tfrac12\ln\dfrac{(\Delta A_{34}^{RC,LC})^2+(\Delta B_{34}^{RC,LC})^2}{(\Delta A_{43}^{45,135})^2+(\Delta B_{43}^{45,135})^2}$;  $\mathrm{Im}_{34,43}=\operatorname{atan2}\!\bigl(\Delta B_{34}\Delta A_{43}-\Delta A_{34}\Delta B_{43},\ \Delta A_{34}\Delta A_{43}+\Delta B_{34}\Delta B_{43}\bigr)$;  $\lvert LB_{0,90}\rvert=\sqrt{\mathrm{Re}_{34,43}^2+\mathrm{Im}_{34,43}^2}$;  $\arg[LB_{0,90}]=\operatorname{atan2}(\mathrm{Im}_{34,43},\mathrm{Re}_{34,43})$ |
| **B.2** | ті самі, з $34\to24$, $43\to42$, $(45,135)\to(0,90)$ у знаменнику: $\mathrm{Re}_{24,42},\mathrm{Im}_{24,42}$; $\lvert LB_{45,135}\rvert$; $\arg[LB_{45,135}]$ |
| **B.3** | ті самі, з $34\to23$, $43\to32$, індекси $45,135$ (чисельник), $0,90$ (знаменник): $\mathrm{Re}_{23,32},\mathrm{Im}_{23,32}$; $\lvert CB\rvert$; $\arg[CB]$ |
| **B.4** | $X=\dfrac{A_1A_2+B_1B_2}{A_1^2+B_1^2}$, $Y=\dfrac{A_1B_2-A_2B_1}{A_1^2+B_1^2}$ ($A_1{+}iB_1=LB_{0,90}$, $A_2{+}iB_2=LB_{45,135}$);  $P=\tfrac14\operatorname{atan2}(2X,1-X^2-Y^2)$, $Q=\tfrac18\ln\dfrac{X^2+(1+Y)^2}{X^2+(1-Y)^2}$;  $\lvert\rho\rvert=\sqrt{P^2+Q^2}$;  $\arg\rho=\operatorname{atan2}(Q,P)=\operatorname{atan2}(L,2T)$ |
| **B.5** | $C=A_1^2-B_1^2+A_2^2-B_2^2$, $D=2(A_1B_1+A_2B_2)$;  $\lvert LB\rvert=(C^2+D^2)^{1/4}$;  $\arg LB=\tfrac12\operatorname{atan2}(D,C)$ |

Відповідність Word ↔ код: на початку кожного `tp_B?_*.m` є таблиця
(`dA34_RCLC` = $\Delta A_{34}^{RC,LC}$, `Re_34_43` = $\mathrm{Re}_{34,43}$, `absLB_0_90` =
$\lvert LB_{0,90}\rvert$ тощо).

---

## 10. Чисельна перевірка

Метод: кожен блок порівняно з **нативною** комплексною арифметикою MATLAB
(`log`, `atan`, `sqrt`) на 100 000 випадкових комплексних чисел
(`verify\verify_block_B1…B5_*.m`, повний ланцюг — `verify_tp_LB_CB_rho.m`;
запуск усього — `verify\run_all_verify.m`). Допуск $10^{-9}$.

| Блок | еталон | max похибка $\lvert\cdot\rvert$ | max похибка $\arg$ |
|---|---|---|---|
| B.1 | `log(f34./f43)` | 8.9e-16 | 1.7e-14 |
| B.2 | `log(f24./f42)` | 8.9e-16 | 9.3e-15 |
| B.3 | `log(f23./f32)` | 8.9e-16 | 3.4e-14 |
| B.4 | `0.5*atan(LB45./LB0)` | 1.8e-14 | 9.8e-15 |
| B.5 | `sqrt(LB0.^2+LB45.^2)` | 8.9e-16 | 8.9e-16 |

Крім `mod` і `arg`, перевіряється й комплексний вихід `cplx`
($\mathrm{Re}+i\,\mathrm{Im}$ напряму): похибка ≤ 2.4e-14 в усіх п'яти блоках.

Додатково `verify\verify_known_values_and_edges.m` — значення, що
рахуються вручну ($\ln e=1$, $\ln i=i\pi/2$, $\ln(-1)=i\pi$,
$\tfrac12\arctan1=\pi/8$, $\sqrt{3^2+4^2}=5$, $\sqrt{-1}=i$): похибка 0;
ділення на нуль (без винятку, не-скінченний результат); розбіжність
розмірів вхідних карт (`N×1` проти `1×N`) відхиляється помилкою, а не
мовчки розширюється до `N×N`; 2D-карта на вході дає 2D-карту на виході.

Окремо `verify\verify_theory_formulas.m` звіряє формули з Word
з нативною арифметикою. У розділі про $\arg\rho$ є **негативний контроль**:
запис Word без множника 2, $\operatorname{atan2}(L,T)$, дає похибку
до 0.34 рад (≈19°) проти $\arg(\tfrac12\arctan(X+iY))$, тоді як
$\operatorname{atan2}(L,2T)$ — 1.3e-14. Тобто помилка Word у $\arg\rho$
підтверджена чисельно, а не лише алгебраїчно.

---

## 11. Особливі випадки, гілки, масштаб

- **Гілки.** $\mathrm{Im}$ і всі $\arg$ — головні значення в $(-\pi,\pi]$;
  $\arg(LB)\in(-\pi/2,\pi/2]$. Розріз у $\pm\pi$ (стрибок карти $\arg$
  з $+\pi$ на $-\pi$) — властивість головного значення, а не помилка коду.
  $\operatorname{Re}\rho=P\in(-\pi/4,\pi/4]$ — головна гілка $\arctan$,
  збігається з нативним `atan` (перевірено).
- **Ділення на нуль.** Якщо $z_2=0$ (B.1–B.3) або $A_1^2+B_1^2=0$ (B.4):
  за IEEE-754 маємо $\mathrm{NaN}/\mathrm{Inf}$ **без помилки**; епсилон
  СВІДОМО не підставляється (він намалював би фіктивний сплеск). Візуалізація
  відфільтровує їх через `isfinite`. Особливі точки $\arctan$:
  $w=\pm i$ (тобто $X=0,\ Y=\pm1$) — тоді $\ln$ розбігається.
- **Масштаб.** Усі 5 величин залежать лише від відношень $f_{mn}/f_{kl}$ і
  тому **інваріантні** до спільного дійсного додатного множника у всіх
  $f_{mn}$. Зокрема, нормування `XY` (`f_ik / median|f11|` у `tp_algo_XY.m`)
  на результат не впливає: $\ln\dfrac{s f_{34}}{s f_{43}}=\ln\dfrac{f_{34}}{f_{43}}$.
