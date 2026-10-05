function run_complete_cpi_fft_tests()
%RUN_COMPLETE_CPI_FFT_TESTS Compare every chirp with direct DFT evaluation.
project = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(project, 'functions')));
opts.window = 'rect';
opts.remove_static_clutter = false;
opts.normalize = 'coherent_gain';
cfg.vel_nfft = 4;
[actual, ~] = doppler_fft([zeros(1,4) ones(1,4)], cfg, opts);
assert(abs(actual(1,3)-0.5) < 1e-12);

numChirps = 9;
index = 1:2*numChirps*3;
input = reshape(sin(index/7) + 1i*cos(index/11), 2, numChirps, 3);
windows = {'rect', 'hann'};
for w = 1:numel(windows)
    opts.window = windows{w};
    for removeMean = [false true]
        opts.remove_static_clutter = removeMean;
        samples = input;
        if removeMean
            samples = samples - mean(samples,2);
        end
        window = make_window(opts.window,numChirps);
        samples = samples .* reshape(window,1,[],1);
        for nfft = [3 4 8 16]
            cfg.vel_nfft = nfft;
            [actual, ~] = doppler_fft(input, cfg, opts);
            basis = exp(-1i*2*pi*(0:numChirps-1).'*(0:nfft-1)/nfft);
            expected = complex(zeros(2,nfft,3));
            for channel = 1:3
                expected(:,:,channel) = samples(:,:,channel) * basis;
            end
            expected = fftshift(expected,2) / sum(window);
            assert(norm(actual(:)-expected(:)) < 1e-11*max(1,norm(expected(:))));
        end
    end
end
fprintf('Complete-CPI FFT: truncating, exact and padded grids passed direct DFT checks.\n');
end
