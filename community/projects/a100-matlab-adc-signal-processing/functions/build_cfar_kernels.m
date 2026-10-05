function [fullKernel, sectorKernels, sectorCounts] = ...
    build_cfar_kernels(trainR, trainD, guardR, guardD)
%BUILD_CFAR_KERNELS Build a full training ring and four disjoint sectors.
halfR = trainR + guardR;
halfD = trainD + guardD;
fullKernel = zeros(2*halfR+1, 2*halfD+1);
sectorKernels = zeros(2*halfR+1, 2*halfD+1, 4);

for dR = -halfR:halfR
    for dD = -halfD:halfD
        if abs(dR) <= guardR && abs(dD) <= guardD
            continue;
        end
        iR = dR + halfR + 1;
        iD = dD + halfD + 1;
        fullKernel(iR,iD) = 1;
        if dR < -guardR
            sector = 1; % Upper range sector, including both corners.
        elseif dR > guardR
            sector = 2; % Lower range sector, including both corners.
        elseif dD < -guardD
            sector = 3; % Negative-Doppler side strip.
        else
            sector = 4; % Positive-Doppler side strip.
        end
        sectorKernels(iR,iD,sector) = 1;
    end
end
sectorCounts = squeeze(sum(sum(sectorKernels,1),2));
sectorCounts = sectorCounts(:).';
active = sectorCounts > 0;
if ~any(active)
    error('CTSAI:NoTrainingCells', 'CFAR requires at least one training cell.');
end
% A range-only or Doppler-only ring has fewer than four nonempty sectors.
% Exclude empty sectors before computing means and variability indices.
sectorKernels = sectorKernels(:,:,active);
sectorCounts = sectorCounts(active);
end
