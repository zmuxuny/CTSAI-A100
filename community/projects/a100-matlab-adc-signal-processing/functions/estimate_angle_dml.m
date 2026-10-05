function result = estimate_angle_dml(snapshot, dictionary, angleGridDeg)
%ESTIMATE_ANGLE_DML Single-source deterministic maximum likelihood search.
snapshot = snapshot(:);
projectionPower = abs(dictionary' * snapshot).^2;
residualPower = max(norm(snapshot)^2 - projectionPower, eps);
spectrum = 1 ./ residualPower;
[result.angle_deg, result.valid] = angle_spectrum_peak(spectrum, angleGridDeg);
result.spectrum = spectrum.';
end
