#!/usr/bin/env python3

"""This script reads text from the standard input.  It removes all text between
the delimiters DELIM_OPEN and DELIM_CLOSE, and prints the result to the standard
output.  To avoid unexpected behavior, the delimiters should appear alone in
their own lines.

Example (default delimiters '%#{' and '%#}'):

    python strip_delimited.py < input_file.m > output_file.m

Example (custom delimiters '%[' and '%]'):

    python strip_delimited.py -o '%\[' -c '%\]' < input_file.m > output_file.m

Note that in DELIM_OPEN and DELIM_CLOSE, regular expression special characters
need be escaped with a backslash, as in the above example.  These characters
are: .^$*+?\()[]|

"""

import sys
import argparse
import re

# Parse input arguments.
parser = argparse.ArgumentParser(
    formatter_class=argparse.RawDescriptionHelpFormatter,
    description=__doc__,
    epilog='Kevin K. Chen\nMay 12, 2013')

parser.add_argument('-o', '--open',
                    default=r'%#{',
                    help=r"The opening delimiter (default: '%%#{').",
                    metavar='DELIM_OPEN')
parser.add_argument('-c', '--close',
                    default=r'%#}',
                    help="The closing delimiter (default: '%%#}').",
                    metavar='DELIM_CLOSE')

args = parser.parse_args()

# Read in, strip, and print the text.
text = sys.stdin.read()
text = re.sub(r'{}.*?{}\s?'.format(args.open, args.close), r'', text,
              flags=re.DOTALL)
print(text, end='')
