function [rdCube, rdPower] = doppler_fft(rangeCube, cfg, fftOpts)
%DOPPLER_FFT Doppler processing on slow-time dimension 2.
numSlowChirps = size(rangeCube, 2);
data = rangeCube;
if fftOpts.remove_static_clutter
    data = data - mean(data, 2);
end
win = make_window(fftOpts.window, numSlowChirps).';
data = data .* reshape(win, 1, [], 1);
if cfg.vel_nfft < numSlowChirps
    % Evaluate the requested frequency grid using the complete CPI. FFT's
    % default n < length behavior would silently discard later chirps.
    folded = zeros(size(data,1), cfg.vel_nfft, size(data,3), class(data));
    for first = 1:cfg.vel_nfft:numSlowChirps
        indices = first:min(first+cfg.vel_nfft-1, numSlowChirps);
        folded(:,1:numel(indices),:) = folded(:,1:numel(indices),:) + data(:,indices,:);
    end
    data = folded;
end
rdCube = fftshift(fft(data, cfg.vel_nfft, 2), 2);
if strcmpi(fftOpts.normalize, 'coherent_gain')
    rdCube = rdCube / max(sum(win), eps);
end
rdPower = squeeze(mean(abs(rdCube).^2, 3));
end
