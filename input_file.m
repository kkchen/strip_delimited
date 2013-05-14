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

%#ifdef FOUR
x = 4; % Chosen by fair dice roll.  Guaranteed to be random.
%#endif
%#ifdef FIVE
x = 5; % Made up in my head.  No guarantees on randomness.
%#endif % FIVE
%#ifndef FIVE
fprintf('The result is guaranteed to be random.\n')
%#endif
%#{

fprintf('%i\n', x)

%#}
end