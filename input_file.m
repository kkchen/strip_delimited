function input_file
%INPUT_FILE A test input file for strip_delimited.py.

%#{
fprintf('Picking random number.\n')
%#}
x = getRandomNumber;
fprintf('The number chosen is ''%i.''\n', x)
end

function x = getRandomNumber
%GETRANDOMNUMBER Get a random number.  Source: http://xkcd.com/221/

x = 4; % Chosen by fair dice roll.  Guaranteed to be random.
%#ifdef VERBOSE
fprintf('Generating number.  The result is guaranteed to be random.\n')
%#endif
%#ifndef VERBOSE
fprintf('Generating number.'\n)
%#endif

%#ifdef TEST
assert(x == 4, 'x is not 4.');
%#endif
%#{

fprintf('%i\n', x)

%#}
end