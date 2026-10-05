function run_sector_threshold_tests()
%RUN_SECTOR_THRESHOLD_TESTS Check analytic max/min and unequal-sector cases.
project = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(project,'functions'));
pfa = 0.1;
go = sector_cfar_alpha([1 1 1 1],pfa,'GOCA');
so = sector_cfar_alpha([1 1 1 1],pfa,'SOCA');
% Max of four exponential powers: E[exp(-a*Z)]=24/prod(a+(1:4)).
assert(abs(24/prod(go+(1:4))-pfa) < 1e-8);
% Min of four exponential powers is exponential with rate four.
assert(abs(4/(4+so)-pfa) < 1e-8);
assert(abs(sector_cfar_alpha(12,0.01,'GOCA')-cfar_alpha_ca(12,0.01)) < 1e-12);
assert(abs(sector_cfar_alpha(12,0.01,'SOCA')-cfar_alpha_ca(12,0.01)) < 1e-12);

counts = [26 26 12 12];
go = sector_cfar_alpha(counts,0.01,'GOCA');
so = sector_cfar_alpha(counts,0.01,'SOCA');
assert(go < so);
% Permuting sector order leaves the selected-statistic distribution intact.
assert(go == sector_cfar_alpha(counts([3 1 4 2]),0.01,'GOCA'));
assert(so == sector_cfar_alpha(counts([3 1 4 2]),0.01,'SOCA'));
power = ones(19,21);
power(4:7,:) = 3;
for mode = {'GOCA','SOCA'}
    [~,noise,threshold,alphaMap] = sector_cfar_map(power,2,4,1,2,0.01,mode{1});
    expected = sector_cfar_alpha(counts,0.01,mode{1});
    assert(all(abs(alphaMap(:)-expected) < 1e-12));
    assert(norm(threshold(:)-expected*noise(:)) < 1e-10);
end
fprintf('Sector threshold analytic and unequal-ring checks passed.\n');
fprintf('CALIBRATED_GOCA=%.15g\nCALIBRATED_SOCA=%.15g\n',go,so);
end
