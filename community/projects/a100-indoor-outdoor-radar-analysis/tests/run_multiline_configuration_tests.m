function run_multiline_configuration_tests()
%RUN_MULTILINE_CONFIGURATION_TESTS Preserve multiline HXX geometry and TX data.
project = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(project, 'functions')));
directory = tempname();
mkdir(directory);
cleanup = onCleanup(@() rmdir(directory, 's'));
file = fullfile(directory, 'profile.hxx');

fid = fopen(file, 'w');
fprintf(fid, ['.tx_groups = {0x0001U,\r\n // group comment\r\n 0x0010, 0, 0},\r\n' ...
    '.ant_pos = {\r\n {0, 0},\r\n {1.25F, -2},\r\n {3, 4}\r\n},\r\n' ...
    '.ddma_phase_increment_deg = {\r\n .25F,\r\n -.5,\r\n 1., 0},\r\n' ...
    '.nchirp = 64,\r\n .nchirp = 32,\r\n .enabled = true,\r\n']);
fclose(fid);
cfg = load_ctsaia100_config(file);
assert(isequal(cfg.tx_groups, [1 16 0 0]));
assert(isequal(cfg.ant_pos, [0 0;1.25 -2;3 4]));
assert(isequal(cfg.ddma_phase_increment_deg,[.25 -.5 1 0]));
assert(cfg.nchirp == 32 && cfg.enabled);
assert(cfg.parse_metadata.parsed_field_count == 6);
assert(isequal(cfg.parse_metadata.duplicate_fields, {'nchirp'}));

% An unfinished geometry must not become a one-row matrix plus guessed ULA.
fid = fopen(file, 'w');
fprintf(fid, '.ant_pos = {{0, 0},\n {1, 2},\n');
fclose(fid);
rejected = false;
try
    load_ctsaia100_config(file);
catch err
    rejected = strcmp(err.identifier, 'CTSAI:UnclosedConfigArray');
end
assert(rejected);

fid = fopen(file, 'w');
fprintf(fid, '.ant_pos = {{0, 0},\n .nchirp = 32,\n};\n');
fclose(fid);
rejected = false;
try
    load_ctsaia100_config(file);
catch err
    rejected = strcmp(err.identifier, 'CTSAI:UnclosedConfigArray');
end
assert(rejected);

% Keep every profile supplied by this project compatible with the reader.
profiles = dir(fullfile(project, 'config', 'sensor_config_init*.hxx'));
assert(~isempty(profiles));
for i = 1:numel(profiles)
    cfg = load_ctsaia100_config(fullfile(project, 'config', profiles(i).name));
    assert(isequal(size(cfg.ant_pos), [16 2]));
    assert(numel(cfg.tx_groups) == 4);
    assert(isfinite(cfg.fmcw_chirp_period));
end
fprintf('Multiline HXX and %d supplied profiles passed.\n', numel(profiles));
end
