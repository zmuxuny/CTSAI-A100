function result = estimate_angle_omp(snapshot, dictionary, angleGridDeg, angleOpts)
%ESTIMATE_ANGLE_OMP Sparse angle recovery on a steering dictionary.
snapshot = snapshot(:);
residual = snapshot;
selected = [];
correlationSpectrum = abs(dictionary' * residual).^2;
for iSource = 1:angleOpts.omp_max_sources
    [~, index] = max(abs(dictionary' * residual));
    selected = unique([selected, index], 'stable'); %#ok<AGROW>
    coefficients = dictionary(:, selected) \ snapshot;
    residual = snapshot - dictionary(:, selected) * coefficients;
end
[result.angle_deg, result.valid] = angle_spectrum_peak(correlationSpectrum, angleGridDeg);
if ~result.valid
    selected = [];
end
result.spectrum = correlationSpectrum.';
result.selected_indices = selected;
end
