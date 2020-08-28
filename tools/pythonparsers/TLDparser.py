#!/bin/python3
import sys

targetfile = sys.argv[1]
print(targetfile)

def parseTLDs():
    delimeter = " "
    lines_seen = set()
    fh = open(f"output/{targetfile}/ResolveTLDs/resolvedtlds.txt","r")
    for line in fh:
        firstSpaceDelimeter = line.split(delimeter, 1)[0]
        firstSpaceDelimeter = firstSpaceDelimeter.rstrip('.')
        if firstSpaceDelimeter not in lines_seen:
            tld = open(f"output/{targetfile}/ResolveTLDs/liveTLDs.txt","a")
            tld.write(firstSpaceDelimeter + "\n")
            tld.close()
            lines_seen.add(firstSpaceDelimeter)

parseTLDs()
