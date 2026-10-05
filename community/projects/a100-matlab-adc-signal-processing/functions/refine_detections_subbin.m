function detections = refine_detections_subbin( ...
    detections, powerMap, cfg, subbinOpts)
%REFINE_DETECTIONS_SUBBIN Refine range and Doppler with a local quadratic.
% A two-dimensional quadratic surface is fitted to the 3x3 log-power patch
% around every coarse FFT peak. The cross term captures local coupling. If
% the fitted Hessian is not a valid local maximum, separable parabolic
% interpolation is used as a robust fallback.

numDetections = height(detections);
detections.RangeOffset_bin = zeros(numDetections,1);
detections.DopplerOffset_bin = zeros(numDetections,1);
detections.RangeRefined_m = zeros(numDetections,1);
detections.VelocityRefined_mps = zeros(numDetections,1);
detections.SubbinFitR2 = nan(numDetections,1);
detections.SubbinFitValid = false(numDetections,1);
detections.SubbinMethod = repmat({''}, numDetections,1);

if numDetections == 0
    return;
end

if isfield(subbinOpts, 'method') && ...
        ~strcmpi(subbinOpts.method, 'QUADRATIC_2D_LOG')
    error('Unsupported sub-bin method: %s', subbinOpts.method);
end

if ~isfield(subbinOpts, 'enable') || ~subbinOpts.enable
    detections.RangeRefined_m = detections.Range_m;
    detections.VelocityRefined_mps = detections.Velocity_mps;
    detections.SubbinMethod(:) = {'DISABLED'};
    return;
end

logPowerMap = 10*log10(double(powerMap) + eps);
numRange = size(powerMap,1);
numDoppler = size(powerMap,2);

for iDetection = 1:numDetections
    r = detections.RangeBin(iDetection);
    d = detections.DopplerBin(iDetection);
    deltaR = 0;
    deltaD = 0;
    fitR2 = NaN;
    fitValid = false;
    methodName = 'COARSE';

    if r > 1 && r < numRange
        rIdx = r-1:r+1;
        dIdx = mod((d-1:d+1)-1, numDoppler) + 1;
        patch = logPowerMap(rIdx, dIdx);
        fit = fit_subbin_peak(patch,subbinOpts);
        deltaR = fit.offset_bins(1);
        deltaD = fit.offset_bins(2);
        fitR2 = fit.r2;
        fitValid = fit.valid;
        methodName = fit.method;
    end

    detections.RangeOffset_bin(iDetection) = deltaR;
    detections.DopplerOffset_bin(iDetection) = deltaD;
    detections.RangeRefined_m(iDetection) = max(0, ...
        (r-1+deltaR) * cfg.range_resolution_m);
    refinedVelocity = cfg.velocity_axis_mps(d) + ...
        deltaD * cfg.velocity_resolution_mps;
    velocityPeriod = numDoppler * cfg.velocity_resolution_mps;
    velocityMin = cfg.velocity_axis_mps(1);
    refinedVelocity = velocityMin + mod(refinedVelocity-velocityMin, velocityPeriod);
    detections.VelocityRefined_mps(iDetection) = refinedVelocity;
    detections.SubbinFitR2(iDetection) = fitR2;
    detections.SubbinFitValid(iDetection) = fitValid;
    detections.SubbinMethod{iDetection} = methodName;
end
end
