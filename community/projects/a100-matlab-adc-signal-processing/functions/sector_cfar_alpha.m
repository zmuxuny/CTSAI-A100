function alpha = sector_cfar_alpha(sectorCounts, pfa, mode)
%SECTOR_CFAR_ALPHA Calibrate a max/min of independent sector power means.
% Each training sample and the CUT has unit-mean exponential power. A
% sector mean containing N cells is Gamma(N,1/N). For Z=max/min(means),
% Pfa=E[exp(-alpha*Z)]; the density of Z includes all competing sectors.
counts = sort(double(sectorCounts(:).'));
mode = upper(strtrim(mode));
if isempty(counts) || any(~isfinite(counts) | counts <= 0 | counts ~= floor(counts))
    error('CTSAI:InvalidSectorCounts', 'Sector counts must be positive integers.');
end
if ~isscalar(pfa) || ~isfinite(pfa) || pfa <= 0 || pfa >= 1
    error('CTSAI:InvalidPfa', 'Pfa must be strictly between zero and one.');
end
if ~any(strcmp(mode, {'GOCA','SOCA'}))
    error('CTSAI:InvalidSectorMode', 'Mode must be GOCA or SOCA.');
end

% The same ring is reused for every frame. Cache the last calibration.
persistent cachedCounts cachedPfa cachedMode cachedAlpha;
if isequal(counts,cachedCounts) && isequal(pfa,cachedPfa) && strcmp(mode,cachedMode)
    alpha = cachedAlpha;
    return;
end
if numel(counts) == 1
    alpha = cfar_alpha_ca(counts,pfa);
else
    probability = @(a) quadgk(@(z) selected_density(z,a,counts,mode), ...
        0, Inf, 'AbsTol',pfa*1e-10,'RelTol',1e-9, ...
        'WayPoints',unique([1/(1+a),0.5,1,2]));
    low = 0;
    high = max(1,max(cfar_alpha_ca(counts,pfa)));
    while probability(high) > pfa
        high = 2*high;
    end
    for iteration = 1:42
        middle = (low+high)/2;
        if probability(middle) > pfa
            low = middle;
        else
            high = middle;
        end
    end
    alpha = (low+high)/2;
end
cachedCounts = counts;
cachedPfa = pfa;
cachedMode = mode;
cachedAlpha = alpha;
end

function density = selected_density(z,alpha,counts,mode)
% For a maximum, other sectors are below z; for a minimum, above z.
if strcmp(mode,'GOCA')
    tail = 'lower';
else
    tail = 'upper';
end
density = zeros(size(z));
finite = isfinite(z);
x = z(finite);
weightedDensity = zeros(size(x));
for i = 1:numel(counts)
    n = counts(i);
    term = exp(n*log(n)-gammaln(n)+(n-1)*log(max(x,realmin))-(n+alpha)*x);
    for j = 1:numel(counts)
        if i ~= j
            term = term .* gammainc(counts(j)*x,counts(j),tail);
        end
    end
    weightedDensity = weightedDensity + term;
end
density(finite) = weightedDensity;
end
