function [PAR0, PAR0upper, PAR0lower, beta, ...
          betaupper, betalower, ParCorr] = EstimateBeta(depth, yy, FigsOn)

y = log(yy);
z = -depth;
ig = find(~isnan(z+y));

if length(ig) >= 8
    [fo, foFit] = fit(double(z(ig)), double(y(ig)), 'poly1');
    errs = confint(cfit(fo), 0.68); % get the uncertainty in coeffs
    ParCorr = foFit.rsquare;        % get the correlation of logfit
    beta = fo.p1;                   % get extinction coeff (m^-1)
    betaupper = errs(2,1); betalower = errs(1,1);
    PAR0 = exp(fo.p2);              % extrapolate surface value
    PAR0upper = exp(errs(2,2)); PAR0lower=exp(errs(1,2));
else
    errs = NaN * [1 1; 1 1];
    ParCorr = NaN;                  % get the correlation of logfit
    beta = NaN;                     % get extinction coeff (m^-1)
    betaupper = errs(2,1); betalower = errs(1,1);
    PAR0 = NaN;                     % extrapolate surface value
    PAR0upper = exp(errs(2,2)); PAR0lower=exp(errs(1,2));
end

if FigsOn == 1
    figure;
    semilogx(yy, z, '+'); hold on;
    semilogx(PAR0, 0, 'rs', 'MarkerFaceColor', 'r');
    semilogx([PAR0upper PAR0lower], [0 0], 'r-', 'linewidth', 2);
    semilogx(PAR0*exp(z*beta), z, 'r-', 'linewidth', 2);
end

end