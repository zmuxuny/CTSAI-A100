function test_adc_numeric_tokens()
%TEST_ADC_NUMERIC_TOKENS Reject damaged fields before signed ADC unpacking.
directory = tempname();
mkdir(directory);
cleanup = onCleanup(@() rmdir(directory, 's'));
file = fullfile(directory, 'capture.txt');

write_capture(file, '0,4,2,65538,196612,327686,458760,0');
[adc, meta] = load_a100_adc(file, 0, 4, 2);
assert(isequal(adc, reshape(1:8, 4, 2)));
assert(meta.padding_count == 1 && meta.padding_verified_zero);

% Formatting and a trailing delimiter preserve the same exact samples.
write_capture(file, sprintf(' 0, 4, 2,\n65538,196612,327686,458760,0,\n'));
assert(isequal(load_a100_adc(file, 0, 4, 2), adc));

invalid = {'invalid_word', '1x', 'NaN', 'Inf'};
for i = 1:numel(invalid)
    write_capture(file, ['0,4,2,1,' invalid{i} ',3,4,0']);
    assert_error_id(@() load_a100_adc(file, 0, 4, 2), 'a100:NonFiniteToken');
end
write_capture(file, '0,4,2,1,,3,4,0');
assert_error_id(@() load_a100_adc(file, 0, 4, 2), 'a100:EmptyNumericToken');
write_capture(file, '0,4,2,1,   ,3,4,0');
assert_error_id(@() load_a100_adc(file, 0, 4, 2), 'a100:EmptyNumericToken');
write_capture(file, '0,4,2,1,2,3,4,0,,');
assert_error_id(@() load_a100_adc(file, 0, 4, 2), 'a100:EmptyNumericToken');
write_capture(file, '0,4,2,1,2.5,3,4,0');
assert_error_id(@() load_a100_adc(file, 0, 4, 2), 'a100:InvalidPackedWord');
write_capture(file, '0,4,2,1,1+2i,3,4,0');
assert_error_id(@() load_a100_adc(file, 0, 4, 2), 'a100:NonRealToken');
fprintf('ADC numeric-field regression tests passed.\n');
end

function write_capture(file, contents)
fid = fopen(file, 'w');
assert(fid >= 0);
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s', contents);
end
