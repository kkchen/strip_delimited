function input_file
%INPUT_FILE A test input file for strip_delimited.py.

x = getRandomNumber;
fprintf('The number chosen is ''%i.''\n', x)
end

function x = getRandomNumber
%GETRANDOMNUMBER Get a random number.  Source: http://xkcd.com/221/

fprintf('The result is guaranteed to be random.\n')
end