%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Расчет 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = calc__CDMA_TOM(saveTomka)
en='.bmp';                                               % расширение файла
readTomka = evalin('base',  'readTomka');
saveTomka = evalin('base',  'saveTomka');
programspath = evalin('base',  'programspath');
%% Зчитування зображень%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[Z00,mapZ00]=imread([readTomka, '0-0', en]);
[Z045,mapZ045]=imread([readTomka, '0-45', en]);
[Z090,mapZ090]=imread([readTomka, '0-90', en]);
[Z0135,mapZ0135]=imread([readTomka, '0-135', en]);
[Z0180,mapZ0180]=imread([readTomka, '0-prav', en]);
[Z0225,mapZ0225]=imread([readTomka, '0-liv', en]);

[Z450,mapZ450]=imread([readTomka, '45-0', en]);
[Z4545,mapZ4545]=imread([readTomka, '45-45', en]);
[Z4590,mapZ4590]=imread([readTomka, '45-90', en]);
[Z45135,mapZ45135]=imread([readTomka, '45-135', en]);
[Z45180,mapZ45180]=imread([readTomka, '45-prav', en]);
[Z45225,mapZ45225]=imread([readTomka, '45-liv', en]);

[Z900,mapZ900]=imread([readTomka, '90-0', en]);
[Z9045,mapZ9045]=imread([readTomka, '90-45', en]);
[Z9090,mapZ9090]=imread([readTomka, '90-90', en]);
[Z90135,mapZ90135]=imread([readTomka, '90-135', en]);
[Z90180,mapZ90180]=imread([readTomka, '90-prav', en]);
[Z90225,mapZ90225]=imread([readTomka, '90-liv', en]);

[Zprav0,mapZprav0]=imread([readTomka, 'prav-0', en]);
[Zprav45,mapZprav45]=imread([readTomka, 'prav-45', en]);
[Zprav90,mapZprav90]=imread([readTomka, 'prav-90', en]);
[Zprav135,mapZprav135]=imread([readTomka, 'prav-135', en]);
[Zprav180,mapZprav180]=imread([readTomka, 'prav-prav', en]);
[Zprav225,mapZprav225]=imread([readTomka, 'prav-liv', en]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Z00=rgb2gray(Z00);
Z045=rgb2gray(Z045);
Z090=rgb2gray(Z090);
Z0135=rgb2gray(Z0135);
Z0180=rgb2gray(Z0180);
Z0225=rgb2gray(Z0225);

Z450=rgb2gray(Z450);
Z4545=rgb2gray(Z4545);
Z4590=rgb2gray(Z4590);
Z45135=rgb2gray(Z45135);
Z45180=rgb2gray(Z45180);
Z45225=rgb2gray(Z45225);

Z900=rgb2gray(Z900);
Z9045=rgb2gray(Z9045);
Z9090=rgb2gray(Z9090);
Z90135=rgb2gray(Z90135);
Z90180=rgb2gray(Z90180);
Z90225=rgb2gray(Z90225);

Zprav0=rgb2gray(Zprav0);
Zprav45=rgb2gray(Zprav45);
Zprav90=rgb2gray(Zprav90);
Zprav135=rgb2gray(Zprav135);
Zprav180=rgb2gray(Zprav180);
Zprav225=rgb2gray(Zprav225);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Z00=double(Z00);
Z090=double(Z090);
Z045=double(Z045);
Z0135=double(Z0135);
Z0180=double(Z0180);
Z0225=double(Z0225);

Z900=double(Z900);
Z9090=double(Z9090);
Z9045=double(Z9045);
Z90135=double(Z90135);
Z90180=double(Z90180);
Z90225=double(Z90225);

Z450=double(Z450);
Z4590=double(Z4590);
Z4545=double(Z4545);
Z45135=double(Z45135);
Z45180=double(Z45180);
Z45225=double(Z45225);

Zprav0=double(Zprav0);
Zprav90=double(Zprav90);
Zprav45=double(Zprav45);
Zprav135=double(Zprav135);
Zprav180=double(Zprav180);
Zprav225=double(Zprav225);

Zprav0=Zprav0./sqrt(2);
Zprav90=(Zprav90./sqrt(2));
Zprav45=(Zprav45)./sqrt(2);
Zprav135=(Zprav135)./sqrt(2);
Zprav180=(Zprav180)./sqrt(2);
Zprav225=(Zprav225)./sqrt(2);

%% нормировка Zik %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Z00=(Z00)./max(max(Z00));
Z090=(Z090)./max(max(Z090));

Z900=(Z900)./max(max(Z900));
Z9090=(Z9090)./max(max(Z9090));

Z450=(Z450)./max(max(Z450));
Z4590=(Z4590)./max(max(Z4590));

Zprav0=Zprav0./max(max(Zprav0));
Zprav90=Zprav90./max(max(Zprav90));

%% Rik %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
R11=sqrt(Z00);
R12=sqrt(Z090);
R21=sqrt(Z900);
R22=sqrt(Z9090);
%% рассчет A,B,C,D %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
A=real(0.5*asin((2*Zprav0-sqrt(R11)-sqrt(R12))./(R11.*R12+0.1)));
B=real(0.5*asin((2*Zprav90-sqrt(R22)-sqrt(R21))./(R22.*R21+0.1)));
C=real(0.5*acos((2*Z450-sqrt(R11)-sqrt(R12))./(R11.*R12+0.1)));
D=real(0.5*acos((2*Z4590-sqrt(R22)-sqrt(R21))./(R22.*R21+0.1)));

%A=real(0.5*asin((2*Zprav0-(R11)-(R12))./(R11.*R12+0.1)));
%B=real(0.5*asin((2*Zprav90-(R22)-(R21))./(R22.*R21+0.1)));
%C=real(0.5*acos((2*Z450-(R11)-(R12))./(R11.*R12+0.1)));
%D=real(0.5*acos((2*Z4590-(R22)-(R21))./(R22.*R21+0.1)));

%% рассчет Тета ik %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T11=exp((3*C-A-3*B-D)./2);
T12=exp((3*C-3*A-3*B-D)./2);
T21=exp((C-A-3*B-D)./2);
T22=exp((C-A-B-D)./2);

%  рассчет d ik %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
d11=R11.*(T11);
d12=R12.*(T12);
d21=R21.*(T21);
d22=R22.*(T22);

%% рассчет КСВА %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 I0=Z00;
 I90=Z090;
 I=I0+I90;    
     
[dim1,dim2]=size(Z090);

NAPIVSH_AKF  = corr_func_2D_NAPIVshuruna_TOM(Z00);
NAPIVSH_AKF = round(NAPIVSH_AKF);

for i = 1:dim1
   for j = 1:(dim2-NAPIVSH_AKF) 
   AAA=(d11(i,j)*d11(i,j+NAPIVSH_AKF)+d12(i,j)*d12(i,j+NAPIVSH_AKF)+d21(i,j)*d21(i,j+NAPIVSH_AKF)+d22(i,j)*d22(i,j+NAPIVSH_AKF));%.^2;
   BBB= (I0(i,j)+I90(i,j));%*(I0(i,j+NAPIVSH_AKF)+I90(i,j+NAPIVSH_AKF));
   RESULT0=AAA/(BBB+0.1);
   RESULT1(i,j)=RESULT0;
   end
end 
RESULT = abs(RESULT1);
CDMA = RESULT./max(max(RESULT));

[dim1,dim2]=size(CDMA);
for k=1:dim1                                                               
        if isnan(CDMA(k,j))==1;
           CDMA(k,j)=0;
        end
        if CDMA(k,j)==inf;
           CDMA(k,j)=1;
        end
        if CDMA(k,j)==-inf;
           CDMA(k,j)=-1;
        end 
end

assignin('base','NAPIVSH_AKF',NAPIVSH_AKF);
cd (saveTomka); mkdir ('CDMA'); saveTomka_CDMA = [saveTomka, 'CDMA\']; pause (1);
cd (programspath);
body_akf_psd_stat(CDMA, 0, saveTomka_CDMA, 'CDMA');

end
