function run_angle_observability_tests()
%RUN_ANGLE_OBSERVABILITY_TESTS Unknown direction never becomes the first bin.
project = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(project,'functions'));
addpath(fullfile(project,'config'));
options = default_processing_options();
opts = options.angle;
angles = -75:75;
positions = (0:3).'/2;

% No signal and a single antenna both produce uninformative spectra.
assert_unknown(zeros(4,1),positions,angles,opts);
assert_unknown(1,0,angles,opts);
assert_unknown(ones(4,1),zeros(4,1),angles,opts);

% Keep a resolved, calibrated ULA source valid for every estimator.
targetAngle = 15;
snapshot = exp(1i*2*pi*positions*sind(targetAngle));
results = estimates(snapshot,positions,angles,opts);
for i = 1:numel(results)
    assert(results{i}.valid);
    assert(abs(results{i}.angle_deg-targetAngle) <= 1);
end
fprintf('DOA observability: four estimators reject flat spectra and preserve a resolved source.\n');
end

function assert_unknown(snapshot,positions,angles,opts)
results = estimates(snapshot,positions,angles,opts);
for i = 1:numel(results)
    assert(~results{i}.valid && isnan(results{i}.angle_deg));
end
assert(isempty(results{4}.selected_indices));
end

function results = estimates(snapshot,positions,angles,opts)
dictionary = steering_dictionary(positions,angles);
snapshots = repmat(snapshot,1,5);
results = {estimate_angle_fft(snapshot,positions,angles,opts), ...
    estimate_angle_dml(snapshot,dictionary,angles), ...
    estimate_angle_music(snapshots,dictionary,angles,opts), ...
    estimate_angle_omp(snapshot,dictionary,angles,opts)};
end
