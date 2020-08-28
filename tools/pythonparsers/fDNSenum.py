#!/bin/python3

import sys 
import subprocess
import os

liveTLDinput = sys.argv[1]
fdnsGzFile = sys.argv[2]
fdnsResults = sys.argv[3]
 
        
def gatherFDNSdomains():
    liveTLDs = open(f"{liveTLDinput}").readlines()
    for domain in liveTLDs:
        replace = domain.replace(".", "\.")
        stringReady = "\."+replace +"\","
        print(stringReady)
        command = f"zgrep '{stringReady}' {fdnsGzFile} | jq -r .name > {fdnsResults}"
        print(command)
        subprocess.run([command],shell=True)

gatherFDNSdomains()
