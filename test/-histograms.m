A.mu_is_Zero = randn(10^5, 1);   % mean of 0
A.mu_is_Two = randn(10^5, 1) + 2;  % mean of 2

% This assumes you know the distribution
dist1 = fitdist(A.mu_is_Zero, 'Normal');  % fit to a normal distribution
dist2 = fitdist(A.mu_is_Two, 'Normal');   % fit to a normal distribution

x = -10:0.1:10;
y1 = pdf(dist1, x);
y2 = pdf(dist2, x);

% Plot PDFs
figure('name', 'PDFs and Histograms', 'Color', 'white');
subplot(2, 1, 1);
plot(x, y1, x, y2);
legend(fieldnames(A), 'interpreter', 'none');
title('Probability Density Functions');

% Plot histograms
subplot(2, 1, 2);
histogram(A.mu_is_Zero, 'Normalization', 'pdf', 'EdgeColor', 'none');
hold on;
histogram(A.mu_is_Two, 'Normalization', 'pdf', 'EdgeColor', 'none');
title('Histograms');
legend(fieldnames(A), 'interpreter', 'none');
hold off;

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
%  Ящиковые диаграммы для двух наборов данных, A.mu_is_Zero и A.mu_is_Two, с использованием функции boxplot. 
%  Ящик представляет межквартильный размах, а линия внутри ящика обозначает медиану. 
%  Усы (линии, выходящие из ящика) показывают разброс данных за пределами межквартильного размаха, и точки могут 
%  представлять выбросы.
%  Обычно ящиковые диаграммы используются для сравнения распределений и выявления потенциальных выбросов в данных.

figure('name', 'v2', 'Color', 'white');
boxplot([A.mu_is_Zero, A.mu_is_Two],'labels',fieldnames(A))
grid on;

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% Создание случайных данных
data = randn(100, 5); % Пример: 100 наблюдений по 5 групп

% Построение box plot
figure('name', 'v2', 'Color', 'white');
boxplot(data, 'Labels', {'Group 1', 'Group 2', 'Group 3', 'Group 4', 'Group 5'});
xlabel('Groups');
ylabel('Values');
title('Box Plot Example');

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
figure('name', 'v3.1', 'Color', 'white');
nhist(A)
figure('name', 'v3.2', 'Color', 'white');
nhist(A,'color',[.3 .8 .3],'separate','samebins','maxbins',50)

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

xs = 10:10:100;
ys = normrnd(50,20,numel(xs),5000);

colors = jet(numel(xs));
for i = 1:numel(xs)
    histogram2(repmat(xs(i),1,size(ys,2)),ys(i,:),'FaceColor',colors(i,:))
    hold on
end
hold off

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
load patients
tbl = table(LastName,Diastolic,Systolic,Smoker);
s = scatterhistogram(tbl,'Diastolic','Systolic','GroupVariable','Smoker');

fig2plotly(gcf);
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
load carsmall
tbl = table(Horsepower,MPG,Cylinders);
s = scatterhistogram(tbl,'Horsepower','MPG', ...
    'GroupVariable','Cylinders','HistogramDisplayStyle','smooth', ...
    'LineStyle','-');

fig2plotly(gcf);
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
x = randn(2000,1);
y = 1 + randn(5000,1);
h1 = histogram(x);
hold on
h2 = histogram(y);
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

load patients
[idx,genderStatus,smokerStatus] = findgroups(string(Gender),string(Smoker));
SmokerGender = strcat(genderStatus(idx),"-",smokerStatus(idx));
s = scatterhistogram(Diastolic,Systolic,'GroupData',SmokerGender,'LegendVisible','on');
xlabel('Diastolic')
ylabel('Systolic')

fig2plotly(gcf);

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 