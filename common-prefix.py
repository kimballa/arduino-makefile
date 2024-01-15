#!/usr/bin/env python3
# Return the common prefix dir of all the arguments.
# e.g. for inputs: "src/a src/foo/b src/bar/c" this should return "src/" on stdout.

import os.path
import sys

def main(argv):
    if len(argv) <= 1:
        print("Expected: common-prefix.py <filenames...>")
        return 1

    #print(argv[1:], file=sys.stderr)
    dirnames = list(set(argv[1:]))
    #print(dirnames, file=sys.stderr)

    if len(dirnames) == 1 and dirnames[0] in [".", "." + os.path.sep]:
        # If we strip the solo '.' then we are left with '/' which breaks out of the cwd.
        #print("./", file=sys.stderr)
        print("." + os.path.sep)
        return 0

    common = os.path.commonpath(dirnames)
    if not os.path.isdir(common):
        # It's not a valid directory, this is a file.
        # (occurs when a single filename was given as argument to this script.)
        common = os.path.dirname(common)

    #print(common + os.path.sep, file=sys.stderr)
    print(common + os.path.sep)
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))

