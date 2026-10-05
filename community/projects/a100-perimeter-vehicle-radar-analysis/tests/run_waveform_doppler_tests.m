function run_waveform_doppler_tests()
%RUN_WAVEFORM_DOPPLER_TESTS Compare waveform and ADC-frame velocity signs.
project = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(project, 'functions')));
addpath(fullfile(project, 'config'));
cfg = simulation_config();
cfg.clutter = [];
cfg.noise_sigma = 0;

for velocity = [-5 0 5]
    cfg.target.velocity_mps = velocity;
    wave = simulate_lfmcw_waveforms(cfg);
    sim = simulate_lfmcw_frame(cfg);
    valid = find(abs(wave.beat) > 0);
    phaseStep = angle(wave.beat(valid(2:end)) .* conj(wave.beat(valid(1:end-1))));
    beatFrequency = mean(phaseStep) * wave.sample_rate_hz / (2*pi);
    expectedDoppler = 2 * velocity / cfg.lambda;
    waveformDoppler = beatFrequency - cfg.slope * wave.delay_s;
    frameDoppler = angle(sim.beat(1,2) * conj(sim.beat(1,1))) / (2*pi*cfg.chirp_period);
    assert(abs(waveformDoppler - expectedDoppler) < 1e-3);
    assert(abs(frameDoppler - expectedDoppler) < 1e-9);
    assert(abs(waveformDoppler - frameDoppler) < 1e-3);
    assert(abs(wave.doppler_hz - expectedDoppler) < 1e-9);
    fprintf('v=%g m/s: waveform fd=%.6f Hz, frame fd=%.6f Hz\n', ...
        velocity, waveformDoppler, frameDoppler);
end
fprintf('Waveform Doppler convention tests passed.\n');
end
