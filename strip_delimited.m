function strip_delimited(varargin)
%STRIP_DELIMITED Read in a file, strip text between delimiters, and write file.
%   STRIP_DELIMITED(INPUT_FILE, OUTPUT_FILE) reads in INPUT_FILE and removes all
%   text between the delimiters '%#{' and '%#}'.  To avoid unexpected behavior,
%   these delimiters should appear alone in their own lines.  The output is
%   written to OUTPUT_FILE.
%
%   STRIP_DELIMITED(..., {IDENTIFIER1, IDENTIFIER2, ...}) also functions as a
%   simple C-like macro processor in the following way.  If the identifier
%   IDENTIFIER is provided, then code in a
%
%      %#ifdef IDENTIFIER
%      ...
%      %#endif
%
%   block will be preserved (except for the %# lines), and
%
%      %#ifndef IDENTIFIER
%      ...
%      %#endif
%
%   blocks will be removed.  In addition, if OTHER_IDENTIFIER is not provided as
%   an identifier, then
%
%      %#ifdef OTHER_IDENTIFIER
%      ...
%      %#endif
%
%   blocks will be removed, and
%
%      %#ifndef OTHER_IDENTIFIER
%      ...
%      %#endif
%
%   blocks will be preserved (except for the %# lines).
%
%   Multiple identifiers can be provided.  These special comments should also
%   appear in their own lines.  Furthermore, nested blocks, such as
%
%      %#ifdef OUTER
%      %#ifndef INNER
%          ...
%      %#endif
%      %#endif
%
%   are allowed.
%
%   STRIP_DELIMITED(..., 'delim_open', DELIM_OPEN, 'delim_close', DELIM_CLOSE)
%   uses custom delimiters DELIM_OPEN and DELIM_CLOSE.  Note that in DELIM_OPEN
%   and DELIM_CLOSE, regular expression special characters need be escaped with
%   a backslash. These characters are: .^$*+?\()[]|
%
%   Examples
%
%   Remove text between the default delimiters '%#{' and '%#}':
%
%      strip_delimited('input_file.m', 'output_file.m')
%
%   Custom delimiters '%[' and '%]':
%
%      strip_delimited('input_file.m', 'output_file.m', '%\[', '%\]');
%
%   Remove text between the default delimiters, and define the identifiers
%   VERBOSE and TEST:
%
%      strip_delimited('input_file.m', 'output_file.m', {'VERBOSE', 'TEST'});
%
%   Kevin K. Chen
%   September 20, 2014

args = parse(varargin{:});
process(args);
end

function args = parse(varargin)
%PARSE Parse the inputs to the main function.
%   ARGS = PARSE(VARARGIN) parses all inputs VARARGIN to the main function, and
%   returns the struct of input argument names and values.

% Get the function name.
[stack, ~] = dbstack();
func = stack(2).name;

% Parse the input arguments.
p = inputParser;

p.addRequired('input_file', ...
    @(f) validateattributes(f, {'char'}, {'row', 'nonempty'}, func, ...
    'INPUT_FILE', 1))
p.addRequired('output_file', ...
    @(f) validateattributes(f, {'char'}, {'row', 'nonempty'}, func, ...
    'OUTPUT_FILE', 2))
p.addOptional('identifiers', {}, ...
    @(id) validateattributes(id, {'cell'}, {}, func, 'IDENTIFIER', 3))
p.addParamValue('delim_open', '%#{', ...
    @(d) validateattributes(d, {'char'}, {'row', 'nonempty'}, func, ...
    'DELIM_OPEN'))
p.addParamValue('delim_close', '%#}', ...
    @(d) validateattributes(d, {'char'}, {'row', 'nonempty'}, func, ...
    'DELIM_CLOSE'))

p.parse(varargin{:});
args = p.Results;
end

function process(args)
%PROCESS Process the text from the given input arguments.
%   PROCESS(ARGS) takes in the input argument struct ARGS from PARSE and does
%   the text editing.

%% Strip the text between delimiters.

% Read in the text.
file_in = fopen(args.input_file, 'rt');
text = fread(file_in, '*char')';
fclose(file_in);
clear file_in

% Strip the text between delimiters.
text = regexprep(text, ...
    [args.delim_open, '.*?', args.delim_close, '\s?'], '', 'dotall');

% Write the result to file.
write(text, args.output_file);

%% Process the %#ifdef and %#ifndef blocks.

% Scan the file line by line to process the %#ifdef and %#ifndef blocks.
text = [];
depth = 0; % How many levels in nested %#ifdef and %#ifndef we are in.
tokens = []; % Array, where tokens[depth] is the token at the given depth.
% Boolean array, where defined[depth] is true if tokens[depth] is a %#ifdef;
% false if it is a %#ifndef.
defined = [];

file_out = fopen(args.output_file, 'rt');
line = fgets(file_out); % Read the first line.

while ischar(line)
    keep = true; % Whether the current line should be kept.
    
    % Increase the nesting depth at the start of a block.
    if ~isempty(regexp(line, '%#if(n|)def', 'once'))
        keep = false;
        depth = depth + 1;
        
        % Get the token name.
        match = regexp(line, '%#if(n|)def\s*(\w+)', 'tokens', 'once');
        tokens{depth} = match{2}; %#ok<AGROW>
        % Mark whether this is a %#ifdef or %#ifndef test.
        defined(depth) = isempty(regexp(line, '%#ifndef', 'once')); %#ok<AGROW>
    end

    % Decrease the nesting depth if necessary.
    if ~isempty(regexp(line, '%#endif', 'once'))
        keep = false;
        
        % This depth no longer exists; get rid of it.
        tokens(depth) = []; %#ok<AGROW>
        defined(depth) = []; %#ok<AGROW>
        
        depth = depth - 1;
        if depth < 0
            throw(MException('strip_delimited:endif', ...
                'Extra %%#endif detected.'))
        end
    end
    
    % Check this block and its parents to see if this line should be killed.
    for d = 1:depth
        if xor(defined(d), any(strcmp(tokens{d}, args.identifiers)))
            keep = false;
            break
        end
    end
    
    if keep
        text = [text, line]; %#ok<AGROW> % Add this line to the output.
    end
    line = fgets(file_out); % Read the next line.
end

fclose(file_out);
write(text, args.output_file);
end

function write(text, output_file)
%WRITE Write text to file.
%   WRITE(TEXT, OUTPUT_FILE) writes the contents of TEXT to the file
%   OUTPUT_FILE.

% Because we will use fprintf to print the resulting text, we need to escape the
% percent (%) and backslash (\) characters.
text = regexprep(text, '%', '%%');
text = regexprep(text, '\\', '\\\\');

file_out = fopen(output_file, 'wt');
if file_out == -1
    throw(MException('strip_delimited:process:fopen', ...
        'File %s failed to open.', output_file));
end
fprintf(file_out, text);
fclose(file_out);
end