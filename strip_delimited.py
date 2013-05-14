#!/usr/bin/env python

"""
This script reads text from the standard input.  It removes all text between
delimiters, and prints the result to the standard output.

Example (default delimiters):

    $ python strip_delimited.py < input_file.m > output_file.m

Example (custom delimiters %[ and %]):

    $ python strip_delimited.py -o '%\[' -c '%\]' < input_file.m > output_file.m

Note that with --open and --close, regular expression special characters need be
escaped with a backslash, as in the above example.  These characters are:
.^$*+?\()[]|

"""

import sys
import argparse
import re

# Parse input arguments.
parser = argparse.ArgumentParser(
    formatter_class=argparse.RawDescriptionHelpFormatter,
    description=__doc__,
    epilog='Kevin K. Chen\nMay 11, 2013')

parser.add_argument('-o', '--open',
                    default=r'%#{',
                    help=r"The opening delimiter (default: '%%#{').")
parser.add_argument('-c', '--close',
                    default=r'%#}',
                    help="The closing delimiter (default: '%%#}').")

args = parser.parse_args()

# Read in, strip, and print the text.
text = sys.stdin.read()
text = re.sub(r'{}.*?{}\n?'.format(args.open, args.close), r'', text,
              flags=re.DOTALL)
print text
