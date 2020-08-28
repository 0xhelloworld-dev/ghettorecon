#!/bin/python3
import sys

inputfile = sys.argv[1]
outputlocation = sys.argv[2]
print(inputfile)

def parseTLDs():
    delimeter = " "
    lines_seen = set()
    fh = open(f"{inputfile}","r")
    for line in fh:
        firstSpaceDelimeter = line.split(delimeter, 1)[0]
        firstSpaceDelimeter = firstSpaceDelimeter.rstrip('.')
        if firstSpaceDelimeter not in lines_seen:
            tld = open(f"{outputlocation}","a")
            tld.write(firstSpaceDelimeter + "\n")
            tld.close()
            lines_seen.add(firstSpaceDelimeter)

parseTLDs()
