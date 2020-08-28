#!/bin/sh

###Tool Configurations:
targetfile=$1
commonspeakwordlist=lists/commonspeak2.txt
fdnsGzFile=/root/Downloads/2020-02-21-1582243548-fdns_any.json.gz


###add a commandline check where you must supply an input file

###freshpy
freshpyoutput=output/$targetfile/resolvers.txt
mkdir -p output/$targetfile
fresh.py -o $freshpyoutput

###Resolve Top Level Domains with massdns
mkdir -p output/$targetfile/ResolveTLDs
topleveldomainresults=output/$targetfile/ResolveTLDs/resolvedtlds.txt
massdns -r $freshpyoutput -t A $targetfile -o S -w $topleveldomainresults

###Parse TLD results
python3 tools/pythonparsers/TLDparser.py $targetfile ###this outputs to output/{targetfile}/ResolveTLDs/liveTLDs.txt
liveTLDOutput=output/$targetfile/ResolveTLDs/liveTLDs.txt


##########Subdomain Enumeration###########
###Amass
###Test command: amass enum -passive -v -o output/att/subdomains/amass.txt -df output/att/ResolveTLDs/liveTLDs.txt
mkdir -p output/$targetfile/subdomains
amassresults=output/$targetfile/subdomains/amass.txt
amass enum -passive -v -o $amassresults -df $liveTLDOutput

###CommonSpeak2
###Test command: python3 tools/pythonparsers/commonspeak2.py att lists/commonspeak2.txt output/att/subdomains/commonspeak2.txt
commonspeakresults=output/$targetfile/subdomains/commonspeak2.txt
python3 tools/pythonparsers/commonspeak2.py att $commonspeakwordlist $commonspeakresults

###FDNSenum
###Test command: python3 tools/pythonparsers/fDNSenum.py output/att/ResolveTLDs/liveTLDs.txt /root/Downloads/2020-02-21-1582243548-fdns_any.json.gz output/att/subdomains/fdns.txt
#fndsenumresults=output/$targetfile/subdomains/fdns.txt
#python3 tools/pythonparsers/fDNSenum.py $liveTLDOutput $fdnsGzFile $fdnsenumresults



###Subfinder
subfinderresults=output/$targetfile/subdomains/subfinder.txt
subfinder -dL $liveTLDOutput -o $subfinderresults

#############Subdomain Bruteforcing###########



