#!/usr/bin/env python3
#
# Copyright 2021 reyalp (at) gmail.com

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# with this program. If not, see <http://www.gnu.org/licenses/>.

import re
import sys
import os
import argparse
import io

VERSION = "0.1.0"

def parse_args():
    parser = argparse.ArgumentParser(description="Build CHDK script with modules inlined")
    parser.add_argument("-V", "--version", action="version", version="%(prog)s {}".format(VERSION))
    parser.add_argument(
        'infile',
        help='Input file',
        nargs='?',
        type=argparse.FileType('r'),
        default=sys.stdin
    )
    parser.add_argument(
        'outfile',
        help='Output file',
        nargs='?',
        type=argparse.FileType('w'),
        default=sys.stdout
    )
    parser.add_argument(
        "-v",
        "--verbose",
        help="print details of inlined modules",
        action='count',
        default=0,
    )
    parser.add_argument(
        "-l",
        "--lib-path",
        help="Path to search for modules to inline",
        action='store',
        default=".",
    )
    return parser.parse_args()

def process_file(infile, verbose = 0, lib_path = '.', level = 0, max_level = 10, seen={}):
    if level > max_level:
        raise ValueError(f'max nesting {max_level} in {infile.name}')

    ostr = ''
    if verbose and infile != sys.stdin:
        sys.stderr.write(f'processing {infile.name} {level}\n')

    for line in infile:
        # if inlining, handle start/end tags
        if level > 0:
            # discard everything up to and including inline_start
            if re.match('\s*--\[!inline_start\]\s*$',line):
                ostr = ''
                continue
            # discard everything including and after inline_end
            if re.match('\s*--\[!inline_end\]\s*$',line):
                break
        m = re.match('''\s*((local)?\s*([A-Za-z0-9_]+)\s*=\s*)?require\(?['"]([^'"]+)['"]\)?\s*--\[!inline\]''',line)
        if not m:
            ostr += line
            continue

        modname = m[4]

        vartext = ''
        if m[2]:
            vartext = 'local '
        if m[3]:
            vartext += m[3]+'='
            varname = m[3]
        else:
            vartext=';'
            varname = 'true' # for package.loaded when no var used

        if modname in seen:
            if verbose:
                sys.stderr.write(f'already inlined {modname}\n')

            ostr += f'''\
{vartext}require'{modname}' -- previously inlined
'''
            continue

        seen[modname]=True

        # TODO lib_path should be an array to search
        modpath = os.path.join(lib_path,modname + '.lua')
        if verbose:
            sys.stderr.write(f'inline {modname} {modpath}\n')

        with open(modpath) as modfile:
            modtext = process_file(modfile, verbose, lib_path, level + 1, max_level, seen)

        ostr += f'''\
{vartext}(function() -- inline {modname}
{modtext}
end)()
package.loaded['{modname}']={varname} -- end inline {modname}
'''
    return ostr

def main():
    args = parse_args()
    ostr = process_file(args.infile, args.verbose, args.lib_path)
    # processed files are always output as unix style to reduce camera memory use
    if args.outfile != sys.stdout:
        args.outfile.reconfigure(newline='\n')
    args.outfile.write(ostr)

main()
