function [beta, PAR0] = EstimateBeta(depth, PAR, FigOn)
% 
% Called from VisualizeClimMonthAvg.m
% 

z = -depth;
log_PAR = real(log(PAR));

% Initialize outputs
beta = NaN;              % Extinction coeff (m^-1)
PAR0 = NaN;              % Extrapolate surface value
errs = NaN * [1 1; 1 1]; % Uncertainty of coeffs

iu = ~isnan(z) & ~isnan(log_PAR);
if sum(iu) >= 8
    fo = fit(double(z(iu)), double(log_PAR(iu)), 'poly1');
    beta = fo.p1;
    PAR0 = exp(fo.p2);
    errs = confint(fo, 0.68);
end

PAR0_upper = exp(errs(2,2));
PAR0_lower = exp(errs(1,2));

if FigOn > 0
    figure;
    semilogx(PAR, z, '+'); hold on;
    semilogx(PAR0, 0, 'rs', 'MarkerFaceColor', 'r');
    semilogx([PAR0_upper PAR0_lower], [0 0], 'r-', 'linewidth', 2);
    semilogx(PAR0*exp(z*beta), z, 'r-', 'linewidth', 2);
end

end