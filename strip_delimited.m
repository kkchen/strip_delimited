function strip_delimited(input_file, output_file, varargin)
%STRIP_DELIMITED Read in a file, strip text between delimiters, and write file.
%   STRIP_DELIMITED(INPUT_FILE, OUTPUT_FILE) reads in INPUT_FILE and removes all
%   text between the delimiters '%#{' and '%#}'.  Ideally, these delimiters
%   should appear alone in their own lines.  The output is written to
%   OUTPUT_FILE.
%
%   STRIP_DELIMITED(INPUT_FILE, OUTPUT_FILE, DELIM_OPEN, DELIM_CLOSE) uses
%   custom delimiters DELIM_OPEN and DELIM_CLOSE.  Note that in DELIM_OPEN and
%   DELIM_CLOSE, regular expression special characters need be escaped with a
%   backslash.  These characters are: .^$*+?\()[]|
%
%   Example (custom delimiters '%[' and '%]'):
%
%      strip_delimited('input_file.m', 'output_file.m', '%\[', '%\]');
%
%   Kevin K. Chen
%   May 12, 2013

%% Get the function name.
[stack, ~] = dbstack;
func = stack(end).name;

%% Parse the input arguments.
p = inputParser;

p.addRequired('input_file', ...
    @(f) validateattributes(f, {'char'}, {'row', 'nonempty'}, func, ...
    'input_file', 1))
p.addRequired('output_file', ...
    @(f) validateattributes(f, {'char'}, {'row', 'nonempty'}, func, ...
    'output_file', 2))
p.addOptional('delim_open', '%#{', ...
    @(f) validateattributes(f, {'char'}, {'row', 'nonempty'}, func, ...
    'delim_open', 3))
p.addOptional('delim_close', '%#}', ...
    @(f) validateattributes(f, {'char'}, {'row', 'nonempty'}, func, ...
    'delim_close', 4))

p.parse(input_file, output_file, varargin{:});

%% Process the text.

% Read and strip the text.
text = fileread(p.Results.input_file);
text = regexprep(text, ...
    [p.Results.delim_open, '.*?', p.Results.delim_close, '\s?'], '', 'dotall');
% Because we will use fprintf to print the resulting text, we need to escape the
% percent (%) and backslash (\) characters.
text = regexprep(text, '%', '%%');
text = regexprep(text, '\\', '\\\\');

% Write the result to file.
file = fopen(p.Results.output_file, 'wt');
if file == -1
    throw(MException('strip_delimited:fopen', 'File %s failed to open.', ...
        p.Results.output_file));
end

fprintf(file, text);
fclose(file);
end