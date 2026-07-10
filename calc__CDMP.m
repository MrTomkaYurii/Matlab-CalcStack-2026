%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Расчет 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = calc__CDMP_TOM(saveTomka)
en='.bmp';                                               % расширение файла
readTomka = evalin('base',  'readTomka');
saveTomka = evalin('base',  'saveTomka');
programspath = evalin('base',  'programspath');

clear CDMP;
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Розрахунок параметрів Стокса S1-S4 (на вході 0);
S10=Z00+Z090;
S20=(Z00-Z090);
S30=(Z045-Z0135);
S40=(Z0180-Z0225);
% Розрахунок параметрів Стокса S1-S4 (на вході 45);
S145=(Z450+Z4590);
S245=(Z450-Z4590);
S345=(Z4545-Z45135);
S445=(Z45180-Z45225);
% Розрахунок параметрів Стокса S1-S4 (на вході 90);
S190=(Z900+Z9090);
S290=(Z900-Z9090);
S390=(Z9045-Z90135);
S490=(Z90180-Z90225);
% Розрахунок параметрів Стокса S1-S4 (на вході prav);
S1prav=(Zprav0+Zprav90);
S2prav=(Zprav0-Zprav90);
S3prav=(Zprav45-Zprav135);
S4prav=(Zprav180-Zprav225);

n1=max(max(S10));
S10n=S10./n1;
S20n=S20./n1;
S30n=S30./n1;
S40n=S40./n1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% MM %%%%%%%%%%%%%%
M11 = (S10 + S190)/2;
M12 = (S10 - S190)/2;
M13 = (S145 - M11);
M14 = (S1prav - M11);


M21 = (S20 + S290)/2;
M22 = (S20 - S290)/2;
M23 = (S245 - M21);
M24 = (S2prav - M21);

M31 = (S30 + S390)/2;
M32 = (S30 - S390)/2;
M33 = (S345 - M31);
M34 = (S3prav - M31);

M41 = (S40 + S490)/2;
M42 = (S40 - S490)/2;
M43 = (S445 - M41);
M44 = (S4prav - M41);

n=max(max(M11));
n1=M11;

M14n=(M14./n);

M22n=(M22./n);
M23n=(M23./n);

M32n=(M32./n);
M33n=(M33./n);
M34n=(M34./n);

M41n=(M41./n);
M44n=(M44./n)*2;

%%%%%%%%%%%%%%%alfa=0%%%%%%%%%%%%%%%%%%%%%%%%%%%%
L0=0.5*atan(S30n./(S20n+0.1));
B0=real(0.5*asin(S40n./(S10n+0.1)));
D0=atan(tan(L0.*2)./(sin(B0.*2)+0.1));

[dim1,dim2]=size(L0);
for k=1:dim1                                                               %усунення невизначеностей
    for j=1:dim2               
        if isnan(L0(k,j))==1;
           L0(k,j)=1;
        end
    end
end
for k=1:dim1                                                               %усунення невизначеностей
    for j=1:dim2               
        if isnan(B0(k,j))==1;
           B0(k,j)=1;
        end
    end
end

for k=1:dim1                                                               %усунення невизначеностей
    for j=1:dim2               
        if isnan(D0(k,j))==1;
           D0(k,j)=1;
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Розрахунок КСВП
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NAPIVSH_AKF  = corr_func_2D_NAPIVshuruna_TOM(Z00);
NAPIVSH_AKF = round(NAPIVSH_AKF);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[dim1,dim2]=size(M11);
I0  = Z00;
I90 = Z090;

for i = 1:dim1
   for j = 1:(dim2-NAPIVSH_AKF) 
       delt1(i,j)=D0(i,j);
       delt2(i,j)=D0(i,j+NAPIVSH_AKF);
       Ione(i,j)=I0(i,j)+I90(i,j);    
       Itwo(i,j)=I0(i,j+NAPIVSH_AKF)+I90(i,j+NAPIVSH_AKF);
   end
end

for i = 1:dim1
   for j = 1:(dim2-NAPIVSH_AKF)
   AAA(i,j) =(sqrt(I0(i,j).*I0(i,j+NAPIVSH_AKF))-sqrt(I90(i,j).*I90(i,j+NAPIVSH_AKF))).^2;
   BBB(i,j) =(sqrt( I0(i,j).*I90(i,j).*I0(i,j+NAPIVSH_AKF).*I90(i,j+NAPIVSH_AKF) ));
   CCC(i,j) = cos(delt1(i,j)-delt2(i,j));
   DDD(i,j) = Ione(i,j).*Itwo(i,j);
   end
end

for i = 1:dim1
   for j = 1:(dim2-NAPIVSH_AKF)
   CDMP(i,j)= (AAA(i,j)+4.*BBB(i,j).*CCC(i,j))./(DDD(i,j)+0.001);
   end
end 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
[dim1,dim2]=size(CDMP);

for k=1:dim1                                                               %усунення невизначеностей
    for j=1:dim2               
        if isnan(CDMP(k,j))==1;
           CDMP(k,j)=0;
        end
        if CDMP(k,j)==inf;
           CDMP(k,j)=1;
        end
        if CDMP(k,j)==-inf;
           CDMP(k,j)=-1;
        end 
    end
end
CDMP=abs(CDMP);

%CDMP=CDMP+abs(min(min(CDMP)));
%CDMP=CDMP./max(max(CDMP));

assignin('base','NAPIVSH_AKF',NAPIVSH_AKF);
cd (saveTomka); mkdir ('CDMP'); saveTomka_CDMP = [saveTomka, 'CDMP\']; pause (1);
cd (programspath);
body_akf_psd_stat(CDMP, 0, saveTomka_CDMP, 'CDMP');

end