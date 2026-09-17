% Параметры
n = 1000; m = 1000;
[X, Y] = meshgrid(1:n, 1:m);
centerX = n/2; centerY = m/2;
R = sqrt((X - centerX).^2 + (Y - centerY).^2);

% Периоды для разных параметров
T_LB1 = 100; T_LB2 = 200;  % для LB
T_rho1 = 50; T_rho2 = 100; % для ρ

% Вычисление карт параметров
LB1 = 2*pi*sin(2*pi*R/T_LB1);
LB2 = 2*pi*sin(2*pi*R/T_LB2);
rho1 = pi*sin(2*pi*R/T_rho1);
rho2 = pi*sin(2*pi*R/T_rho2);

% Вычисление знаменателя
denominator = LB2 .* cos(2*rho2) - LB1 .* cos(2*rho1);

% Анализ сингулярностей
epsilon_base = 1e-6;

% 1. Строгие сингулярности (почти нулевой знаменатель)
strict_singular = abs(denominator) < epsilon_base;

% 2. Анализ градиента для выявления "плоских" областей
[denom_dx, denom_dy] = gradient(denominator);
grad_magnitude = sqrt(denom_dx.^2 + denom_dy.^2);

% 3. Адаптивный порог на основе статистики
denom_abs = abs(denominator);
median_denom = median(denom_abs(:));
mad_denom = mad(denom_abs(:));
adaptive_epsilon = max(epsilon_base, 0.01 * mad_denom);

% 4. Классификация точек
true_singular = (denom_abs < epsilon_base) & (grad_magnitude < 0.1*median(grad_magnitude(:)));
near_singular = (denom_abs < adaptive_epsilon) & ~true_singular;
large_response = abs(1./denominator) > 1000;

% 5. Радиальный анализ сингулярностей
R_singular = R(true_singular);
if ~isempty(R_singular)
    R_bins = 0:10:max(R(:));
    [counts, centers] = hist(R_singular, R_bins);
    singular_radii = centers(counts > 10); % Радиусы с множественными сингулярностями
    
    fprintf('Радиусы концентрации сингулярностей:\n');
    for i = 1:length(singular_radii)
        fprintf('R ≈ %.1f пикселей\n', singular_radii(i));
    end
end

% 6. Обработка сингулярностей
denominator_safe = denominator;
epsilon_reg = adaptive_epsilon;

% Регуляризация с сохранением знака
sign_mask = sign(denominator);
sign_mask(sign_mask == 0) = 1;
denominator_safe(abs(denominator) < epsilon_reg) = sign_mask(abs(denominator) < epsilon_reg) * epsilon_reg;

% Вычисление результата
theta_2alpha_c = 1 ./ denominator_safe;

% Маскировка экстремальных значений
extreme_mask = abs(theta_2alpha_c) > 1000;
theta_2alpha_c(extreme_mask) = sign(theta_2alpha_c(extreme_mask)) * 1000;

% Визуализация результатов
figure('Position', [100, 100, 1200, 800]);

subplot(2,3,1);
imagesc(abs(denominator)); colorbar; title('|Знаменатель|');
colormap(gca, 'hot'); set(gca, 'CLim', [0, prctile(abs(denominator(:)), 95)]);

subplot(2,3,2);
imagesc(true_singular); colorbar; title('Истинные сингулярности');
colormap(gca, 'gray');

subplot(2,3,3);
imagesc(near_singular); colorbar; title('Околосингулярные точки');
colormap(gca, 'gray');

subplot(2,3,4);
imagesc(abs(theta_2alpha_c)); colorbar; title('|theta\_2alpha\_c|');
colormap(gca, 'jet'); set(gca, 'CLim', [0, prctile(abs(theta_2alpha_c(:)), 95)]);

subplot(2,3,5);
imagesc(grad_magnitude); colorbar; title('|∇denominator|');
colormap(gca, 'hot');

subplot(2,3,6);
% Профиль вдоль центральной линии
central_line = theta_2alpha_c(m/2, :);
plot(1:n, central_line, 'b-', 'LineWidth', 2);
title('Профиль theta\_2alpha\_c вдоль центра');
xlabel('Пиксель'); ylabel('theta\_2alpha\_c');
grid on;

% Статистика
fprintf('\nСтатистика сингулярностей:\n');
fprintf('Истинные сингулярности: %d точек (%.2f%%)\n', sum(true_singular(:)), 100*sum(true_singular(:))/(n*m));
fprintf('Околосингулярные: %d точек (%.2f%%)\n', sum(near_singular(:)), 100*sum(near_singular(:))/(n*m));
fprintf('Экстремальные значения: %d точек (%.2f%%)\n', sum(extreme_mask(:)), 100*sum(extreme_mask(:))/(n*m));
fprintf('Адаптивный порог: %.2e\n', adaptive_epsilon);
fprintf('Диапазон |theta_2alpha_c|: [%.2e, %.2e]\n', min(abs(theta_2alpha_c(:))), max(abs(theta_2alpha_c(:))));

% Рекомендации по обработке
fprintf('\n=== РЕКОМЕНДАЦИИ ===\n');
fprintf('1. Используйте адаптивный порог: %.2e\n', adaptive_epsilon);
fprintf('2. Регуляризируйте знаменатель с сохранением знака\n');
fprintf('3. Ограничьте экстремальные значения порогом ~1000\n');
fprintf('4. Обратите внимание на радиальную структуру сингулярностей\n');