function fit = fit_subbin_peak(logPatch, opts)
%FIT_SUBBIN_PEAK Fit a local maximum to a 3x3 log-power patch.
fit.offset_bins = [0;0]; % [range; Doppler]
fit.valid = false;
fit.r2 = NaN;
fit.method = 'COARSE';
if any(~isfinite(logPatch(:)))
    return;
end
persistent design;
if isempty(design)
    [d,r] = meshgrid(-1:1,-1:1);
    design = [r(:).^2,d(:).^2,r(:).*d(:),r(:),d(:),ones(9,1)];
end
coefficients = design \ logPatch(:);
hessian = [2*coefficients(1),coefficients(3); ...
    coefficients(3),2*coefficients(2)];
gradient = coefficients(4:5);
residualEnergy = sum((logPatch(:)-design*coefficients).^2);
totalEnergy = sum((logPatch(:)-mean(logPatch(:))).^2);
if totalEnergy > 0
    fit.r2 = 1-residualEnergy/totalEnergy;
end

if all(eig(hessian) < -opts.min_negative_curvature) && rcond(hessian) > 1e-10
    [offset,valid] = bounded_offset(-hessian \ gradient,opts.max_abs_offset_bins);
    if valid
        fit.offset_bins = offset;
        fit.valid = true;
        fit.method = 'QUADRATIC_2D_LOG';
        return;
    end
end

if ~opts.use_separable_fallback || logPatch(2,2) < max(logPatch(:))
    return;
end
[deltaR,validR] = axis_peak(logPatch(1,2),logPatch(2,2),logPatch(3,2),opts);
[deltaD,validD] = axis_peak(logPatch(2,1),logPatch(2,2),logPatch(2,3),opts);
if validR && validD
    fit.offset_bins = [deltaR;deltaD];
    fit.valid = true;
    fit.method = 'SEPARABLE_LOG';
end
end

function [offset,valid] = axis_peak(left,center,right,opts)
curvature = left-2*center+right;
offset = 0;
valid = false;
if curvature >= -opts.min_negative_curvature
    return;
end
candidate = 0.5*(left-right)/curvature;
[offset,valid] = bounded_offset(candidate,opts.max_abs_offset_bins);
end

function [offset,valid] = bounded_offset(candidate,maxAbs)
offset = zeros(size(candidate));
% Preserve exact half-bin peaks when solving introduces rounding error.
tolerance = 100*eps(max(1,maxAbs));
valid = all(isfinite(candidate)) && all(abs(candidate) <= maxAbs+tolerance);
if valid
    offset = max(-maxAbs,min(maxAbs,candidate));
end
end
