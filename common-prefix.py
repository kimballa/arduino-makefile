#!/usr/bin/env python3
# Return the common prefix dir of all the arguments.
# e.g. for inputs: "src/a src/foo/b src/bar/c" this should return "src/" on stdout.

import os.path
import sys

def main(argv):
    if len(argv) <= 1:
        print("Expected: common-prefix.py <filenames...>")
        return 1

    common = os.path.commonpath(argv[1:])
    print(common + os.path.sep)
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))

