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
%   appear in their own lines.
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
%   May 14, 2013

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
    @(id) validateattributes(id, {'cell'}, {'nonempty'}, func, 'IDENTIFIER', ...
    3))
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

% Read in the text.
file_in = fopen(args.input_file, 'rt');
text = fread(file_in, '*char')';
fclose(file_in);

% Strip the text between delimiters.
text = regexprep(text, ...
    [args.delim_open, '.*?', args.delim_close, '\s?'], '', 'dotall');

% Process the %#ifdef and %#ifndef blocks.
text = strip_blocks(text, args.identifiers, 'ifdef');
text = strip_blocks(text, args.identifiers, 'ifndef');

% All blocks to be removed have been removed.  Remove the remaining %# block
% delimiters.
text = regexprep(text, '%#(if(n|)def|endif).*\n', '', 'dotexceptnewline');

% Because we will use fprintf to print the resulting text, we need to escape the
% percent (%) and backslash (\) characters.
text = regexprep(text, '%', '%%');
text = regexprep(text, '\\', '\\\\');

% Write the result to file.
file_out = fopen(args.output_file, 'wt');
if file_out == -1
    throw(MException('strip_delimited:process:fopen', ...
        'File %s failed to open.', args.output_file));
end
fprintf(file_out, text);
fclose(file_out);
end

function text = strip_blocks(text, identifiers, block)
%STRIP_BLOCKS Profess %#ifdef and %#ifndef blocks, and remove them accordingly.
%   TEXT = STRIP_BLOCKS(TEXT, IDENTIFIERS, BLOCK) scans TEXT for %#ifdef and
%   %#ifndef blocks.  These blocks are conditionally removed, depending on
%   whether an %#ifdef or %#ifndef identifier is in the cell array IDENTIFIERS.
%   BLOCK is one of 'ifdef' and 'ifndef', and specifies the type of block to
%   check.  The text is returned as TEXT.

if ~any(strcmp(block, {'ifdef', 'ifndef'}))
    throw(MException('strip_delimited:strip_blocks:block', ...
        'block is ''%s'' but must be ''ifdef'' or ''ifndef''.', block))
end

offset = 0; % text index offset as blocks get removed.
% Find all instances of the block.
[matchstart, matchend, ~, ~, tokenstring] = ...
    regexp(text, ['%#', block ,'[ \t]+(\S*)[\w\W]*?%#endif.*\n'], ...
    'dotexceptnewline');

% Iterate over all blocks.
for j = 1:numel(matchstart)
    do_remove = any(strcmp(tokenstring{j}, identifiers)); % For %#ifndef.
    if strcmp(block, 'ifdef')
        do_remove = ~do_remove;
    end

    if do_remove
        % The identifier wasn't provided by the user.  Remove the block.
        text(matchstart(j)-offset:matchend(j)-offset) = [];
        % Increase the offset by the size of this block.
        offset = offset + matchend(j) - matchstart(j) + 1;
    end
end
end