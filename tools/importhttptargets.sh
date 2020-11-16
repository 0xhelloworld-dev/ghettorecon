#!/bin/sh

targetfile=$1
pwd
mkdir -p output/$targetfile
mkdir -p output/$targetfile/ResolveTLDs
mkdir -p output/$targetfile/subdomains
mkdir -p output/$targetfile/subdomainbruteforce
mkdir -p output/$targetfile/subdomainbruteforce/permutations/1

touch output/$targetfile/resolvers.txt
touch output/$targetfile/ResolveTLDs/resolvedtlds.txt
touch output/$targetfile/ResolveTLDs/liveTLDs.txt
touch output/$targetfile/subdomains/amass.txt
touch output/$targetfile/subdomains/commonspeak2.txt
touch output/$targetfile/subdomains/subfinder.txt
touch output/$targetfile/subdomains/compiled.txt
touch output/$targetfile/subdomainbruteforce/massdns.txt
touch output/$targetfile/subdomainbruteforce/permutations/1/perm.txt

mkdir -p output/$targetfile/subdomainanalysis/httprobe
cat $targetfile | fprobe -c 100 -t 3000  > output/$targetfile/subdomainanalysis/httprobe/massdnshttprobe.txt
