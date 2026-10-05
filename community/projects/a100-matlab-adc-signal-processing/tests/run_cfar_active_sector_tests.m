function run_cfar_active_sector_tests()
%RUN_CFAR_ACTIVE_SECTOR_TESTS Exercise one-axis and full two-axis windows.
project = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(project, 'functions'));
addpath(fullfile(project, 'config'));
options = default_processing_options();
opts = options.cfar;
algorithms = {'CA','OS','GOCA','SOCA','VI'};
layouts = [2 0;0 3;2 3];
power = ones(19,21);
power(10,11) = 400;

for layout = 1:size(layouts,1)
    opts.training_cells = layouts(layout,:);
    opts.guard_cells = [1 1];
    [full, sectors, counts] = build_cfar_kernels( ...
        opts.training_cells(1),opts.training_cells(2),1,1);
    assert(all(counts > 0));
    assert(isequal(sum(sectors,3),full));
    assert(sum(counts) == sum(full(:)));
    expectedSectors = 2 + 2*all(opts.training_cells > 0);
    assert(numel(counts) == expectedSectors);
    for method = 1:numel(algorithms)
        opts.algorithm = algorithms{method};
        result = cfar_2d(power,opts);
        assert(isfinite(result.threshold(10,11)));
        assert(abs(result.noise(10,11)-1) < 1e-12);
        assert(result.mask(10,11));
    end
end

opts.training_cells = [0 0];
for method = 1:numel(algorithms)
    opts.algorithm = algorithms{method};
    rejected = false;
    try
        cfar_2d(power,opts);
    catch err
        rejected = strcmp(err.identifier,'CTSAI:NoTrainingCells');
    end
    assert(rejected);
end
fprintf('CFAR active sectors: all five methods and both one-axis windows passed.\n');
end
