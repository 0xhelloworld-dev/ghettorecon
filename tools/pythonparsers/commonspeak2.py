#!/bin/python3
import sys

targetfile = sys.argv[1]
csWordlist = sys.argv[2]
csOutput = sys.argv[3]

def createCommonSpeakWordlist():
###Pull input  from  parseTLDs "output/{targetfile}/ResolveTLDs/liveTLDs.txt"
    topleveldomains = open(f"output/{targetfile}/ResolveTLDs/liveTLDs.txt").readlines()
    for domain in topleveldomains:
        scope = domain.strip().rstrip()
        wordlist = open(csWordlist).readlines()
        print(scope)

        for word in wordlist:
            wordStrip = word.strip().rstrip()
            result = f'{wordStrip}.{scope}'
            resultfile = open(csOutput,"a")
            resultfile.write(result + "\n")
            resultfile.close()
        

createCommonSpeakWordlist()
