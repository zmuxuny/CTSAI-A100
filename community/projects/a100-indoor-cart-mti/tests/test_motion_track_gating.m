function test_motion_track_gating()
%TEST_MOTION_TRACK_GATING A valid track survives impossible strong returns.
targets = fixture([4;3.8;4.5;3.6],[-.2;-.2;-.2;-.2]);
track = extract_motion_track(targets);
assert(track.point_count == 3);
assert(isequal(track.range_m,[4;3.8;3.6]));
assert(strcmp(track.inferred_direction,'approaching'));
assert(abs(track.range_slope_mps+.2) < 1e-12);

targets = fixture([1.4;1.6;.9;1.8],[.2;.2;.2;.2]);
track = extract_motion_track(targets);
assert(isequal(track.range_m,[1.4;1.6;1.8]));
assert(strcmp(track.inferred_direction,'receding'));
assert(abs(track.range_slope_mps-.2) < 1e-12);

% A distant, strong candidate is excluded by the range-step gate.
targets = fixture([4;3.8;1.1;3.6],[-.2;-.2;-.2;-.2]);
targets.snr_db(3) = 1000;
track = extract_motion_track(targets);
assert(isequal(track.range_m,[4;3.8;3.6]));

% Real acquisition gaps still split segments rather than bridging them.
targets = fixture([4;3.8;3.2;3],[-.2;-.2;-.2;-.2]);
targets.frame_sequence = [0;1;2;3];
targets.elapsed_s = [0;1;5;6];
targets.snr_db(:) = 20;
track = extract_motion_track(targets);
assert(track.point_count == 2);
assert(all(diff(track.elapsed_s) <= 2));
fprintf('Motion-track association gates passed.\n');
end

function targets = fixture(range,velocity)
targets.frame_sequence = [0;1;1;2];
targets.elapsed_s = [0;1;1;2];
targets.range_m = range;
targets.speed_mps = velocity;
targets.angle_deg = zeros(4,1);
targets.snr_db = [20;20;250;20];
targets.polar_x_m = zeros(4,1);
targets.polar_y_m = range;
end
