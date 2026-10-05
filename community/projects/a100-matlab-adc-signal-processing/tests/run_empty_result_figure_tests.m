function run_empty_result_figure_tests()
%RUN_EMPTY_RESULT_FIGURE_TESTS Empty exports remove only their obsolete plots.
project = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(project,'functions'));
directory = tempname();
mkdir(directory);
cleanup = onCleanup(@() rmdir(directory,'s'));
angleFile = fullfile(directory,'angle_spectra.png');
cloudFile = fullfile(directory,'target_point_cloud.png');
unrelated = fullfile(directory,'reference.png');
write_previous_result(angleFile);
write_previous_result(cloudFile);
write_previous_result(unrelated);

opts.save_png = true;
plot_angle_spectra([],opts,directory);
plot_target_point_cloud([],opts,directory);
assert(~isfile(angleFile) && ~isfile(cloudFile));
assert(isfile(unrelated));
% Repeating an empty export is harmless when both files are already absent.
plot_angle_spectra([],opts,directory);
plot_target_point_cloud([],opts,directory);

write_previous_result(angleFile);
write_previous_result(cloudFile);
opts.save_png = false;
plot_angle_spectra([],opts,directory);
plot_target_point_cloud([],opts,directory);
assert(isfile(angleFile) && isfile(cloudFile) && isfile(unrelated));
fprintf('Empty-result figure cleanup passed without opening graphics.\n');
end

function write_previous_result(file)
fid = fopen(file,'w');
assert(fid >= 0);
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'previous generated result');
end
