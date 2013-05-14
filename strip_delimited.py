#!/usr/bin/env python3

"""This script reads text from the standard input.  It removes all text between the
delimiters DELIM_OPEN and DELIM_CLOSE (which are '%#{' and '%#}' by default),
and prints the result to the standard output.  To avoid unexpected behavior, the
delimiters should appear alone in their own lines.

Note that in DELIM_OPEN and DELIM_CLOSE, regular expression special characters
need be escaped with a backslash.  These characters are: .^$*+?\()[]|

In addition, it functions as a simple C-like macro processor in the following
way.  If the identifier IDENTIFIER is provided with the -d flag, then code in a

    %#ifdef IDENTIFIER
    ...
    %#endif

block will be preserved (except for the %# lines), and

    %#ifndef IDENTIFIER
    ...
    %#endif

blocks will be removed.  In addition, if OTHER_IDENTIFIER is not provided as an
identifier, then

    %#ifdef OTHER_IDENTIFIER
    ...
    %#endif

blocks will be removed, and

    %#ifndef OTHER_IDENTIFIER
    ...
    %#endif

blocks will be preserved (except for the %# lines).

Multiple identifiers can be provided.  These special comments should also appear
in their own lines.

Examples

Remove text between the default delimiters '%#{' and '%#}':

    python strip_delimited.py < input_file.m > output_file.m

Custom delimiters '%[' and '%]':

    python strip_delimited.py -o '%\[' -c '%\]' < input_file.m > output_file.m

Remove text between the default delimiters, and define the identifiers VERBOSE
and TEST:

    python strip_delimited.py -d VERBOSE TEST < input_file.m > output_file.m

Kevin K. Chen
May 14, 2013
"""

import sys
import argparse
import re

def parse():
    """Parse input arguments.  Return the namespace of inputs."""

    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=__doc__)

    parser.add_argument('-o', '--open',
                        default=r'%#{',
                        help="""
The opening delimiter (default: '%%#{').  Regular expression special characters
must be escaped.""",
                        metavar='DELIM_OPEN')
    parser.add_argument('-c', '--close',
                        default=r'%#}',
                        help="""
The closing delimiter (default: '%%#}').  Regular expression special characters
must be escaped.""",
                        metavar='DELIM_CLOSE')
    parser.add_argument('-d', '--define',
                        nargs='+',
                        default=[],
                        help='Identifiers to define.',
                        metavar='IDENTIFIER')

    return parser.parse_args()


def process(args):
    """Read in, process, and print the text."""

    text = sys.stdin.read()

    # Remove text between the delimiters.
    text = re.sub(r'{}.*?{}\s?'.format(args.open, args.close), r'', text,
                  flags=re.S)

    # Process the %#ifdef and %#ifndef blocks.
    text = strip_blocks(text, args.define, 'ifdef')
    text = strip_blocks(text, args.define, 'ifndef')

    # All blocks to be removed have been removed.  Remove the remaining %# block
    # delimiters.
    text = re.sub(r'%#(if(n|)def|endif).*\n', r'', text)

    print(text, end='')


def strip_blocks(text, define, block):
    """Process %#ifdef and %#ifndef blocks, and remove them accordingly.

    "define" is a list of identifiers that have been defined, and "block" must
    be either 'ifdef' or 'ifndef'.

    Returns the processed text.

    """

    assert block in ['ifdef', 'ifndef'], \
        'block is "{}" but must be "ifdef" or "ifndef".'.format(block)

    offset = 0 # text index offset as blocks get removed.
    # Find all instances of the block.
    matches = re.finditer(r'%#{}[ \t]+(\S*)[\w\W]*?%#endif.*\n'.format(block),
                          text)

    # Iterate over all blocks.
    for match in matches:
        # See if the block needs to be removed.  \1 is the identifier.
        do_remove = match.expand(r'\1') in define # For %#ifndef.
        if block == 'ifdef':
            do_remove = not do_remove

        if do_remove:
            # The identifier wasn't provided by the user.  Remove the block.
            text = text[:match.start()-offset] + text[match.end()-offset:]
            # Increase the offset by the size of this block.
            offset += match.end() - match.start()

    return text


if __name__ == '__main__':
    args = parse()
    process(args)
