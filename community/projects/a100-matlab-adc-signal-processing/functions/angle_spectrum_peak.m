function [angleDeg, valid] = angle_spectrum_peak(spectrum, angleGridDeg)
%ANGLE_SPECTRUM_PEAK A flat or zero spectrum carries no angle information.
angleDeg = NaN;
valid = false;
values = spectrum(:);
if isempty(values) || any(~isfinite(values))
    return;
end
[peak, index] = max(values);
% Permit floating-point roundoff in nominally constant steering spectra.
if peak <= 0 || peak-min(values) <= 100*eps(peak)
    return;
end
angleDeg = angleGridDeg(index);
valid = isfinite(angleDeg);
end
