function [PAR0, PAR0upper, PAR0lower, ...
          beta, betaupper, betalower, ...
          ParCorr] = EstimateBeta(depth, var, FigsOn)
% 
% Called from GetDEEPStationSurfaceData.m
% 

z = -depth;
log_var = real(log(var));

% Initialize outputs
errs = NaN * [1 1; 1 1]; % Uncertainty of coeffs
ParCorr = NaN;           % Correlation of logfit
beta = NaN;              % Extinction coeff (m^-1)
PAR0 = NaN;              % Extrapolate surface value

iu = ~isnan(z) & ~isnan(log_var);
if sum(iu) >= 8
    [fo, gof] = fit(double(z(iu)), double(log_var(iu)), 'poly1');
    errs = confint(fo, 0.68);
    ParCorr = gof.rsquare;
    beta = fo.p1;
    PAR0 = exp(fo.p2);
end
betaupper = errs(2,1);
betalower = errs(1,1);
PAR0upper = exp(errs(2,2));
PAR0lower = exp(errs(1,2));

if FigsOn == 1
    figure;
    semilogx(var, z, '+'); hold on;
    semilogx(PAR0, 0, 'rs', 'MarkerFaceColor', 'r');
    semilogx([PAR0upper PAR0lower], [0 0], 'r-', 'linewidth', 2);
    semilogx(PAR0*exp(z*beta), z, 'r-', 'linewidth', 2);
end

end