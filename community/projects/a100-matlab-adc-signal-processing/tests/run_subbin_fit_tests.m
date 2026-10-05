function run_subbin_fit_tests()
%RUN_SUBBIN_FIT_TESTS Verify peak validity against known local surfaces.
project = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(project,'functions'));
opts.max_abs_offset_bins = 0.5;
opts.min_negative_curvature = 1e-6;
opts.use_separable_fallback = true;
[d,r] = meshgrid(-1:1,-1:1);

for deltaR = [-.5 -.3 0 .3 .5]
    for deltaD = [-.5 -.3 0 .3 .5]
        patch = -(r-deltaR).^2-2*(d-deltaD).^2+0.4*(r-deltaR).*(d-deltaD);
        fit = fit_subbin_peak(patch,opts);
        assert(fit.valid && strcmp(fit.method,'QUADRATIC_2D_LOG'));
        assert(norm(fit.offset_bins-[deltaR;deltaD]) < 1e-12);
        assert(abs(fit.r2-1) < 1e-12);
    end
end

invalid = {ones(3),-r.^2,r.^2+d.^2,-(r-.8).^2-d.^2, ...
           -(r-(.5+1e-8)).^2-d.^2, ...
           -r.^2-d.^2+4*r.*d};
for i = 1:numel(invalid)
    fit = fit_subbin_peak(invalid{i},opts);
    assert(~fit.valid && strcmp(fit.method,'COARSE'));
    assert(isequal(fit.offset_bins,[0;0]));
end
fit = fit_subbin_peak(ones(3),opts);
assert(isnan(fit.r2));

% A poor joint quadratic can still have two legitimate axis-wise peaks.
patch = zeros(3);
patch(2,[1 3]) = -1;
patch([1 3],2) = -1;
fit = fit_subbin_peak(patch,opts);
assert(fit.valid && strcmp(fit.method,'SEPARABLE_LOG'));
opts.use_separable_fallback = false;
fit = fit_subbin_peak(patch,opts);
assert(~fit.valid);
fprintf('Subbin fits: known maxima, flat/ridge/saddle surfaces and bounds passed.\n');
end
