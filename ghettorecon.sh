#!/bin/sh

###Tool Configurations:
targetfile=$1
commonspeakwordlist=lists/commonspeak2.txt
fdnsGzFile=/root/Downloads/2020-02-21-1582243548-fdns_any.json.gz
altdnswordlist=lists/altdnswords.txt


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
liveTLDOutput=output/$targetfile/ResolveTLDs/liveTLDs.txt
python3 tools/pythonparsers/massdnsparser.py $topleveldomainresults $liveTLDOutput  ###this outputs to output/{targetfile}/ResolveTLDs/liveTLDs.txt


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
#Test command: subfinder -dL att -o output/att/subdomains/subfinder.txt
subfinderresults=output/$targetfile/subdomains/subfinder.txt
subfinder -dL $liveTLDOutput -o $subfinderresults

#############Subdomain Bruteforcing###########
#Test command:  cat output/att/subdomains/* | sort -u > output/att/subdomains/compiled.txt
compilesubdomainsresults=output/$targetfile/subdomains/compiled.txt
cat output/$targetfile/subdomains/* | sort -u > $compilesubdomainresults

###massdns resolve gathered subdomains
### Test command: massdns -r output/att/resolvers.txt -t A -o S -w output/att/subdomainbruteforce/massdns.txt --flush output/att/subdomains/compiled.txt 
mkdir -p output/$targetfile/subdomainbruteforce
massdnsoutput=output/$targetfile/subdomainbruteforce/massdns.txt
massdns -r $freshpyoutput -t A -o S -w $massdnsoutput --flush $compilesubdomainresults

###parse massdns results for domains
## Test command: python3 tools/pythonparsers/massdnsparser.py output/att/subdomainbruteforce/massdns.txt output/att/subdomainbruteforce/altdnsinput.txt
altdnsinput=output/$targetfile/subdomainbruteforce/altdnsinput.txt
python3 tools/pythonparsers/massdnsparser.py $massdnsoutput $altdnsinput


###altdns generation
### Test command: altdns -i output/att/subdomainbruteforce/altdnsinput.txt -o output/att/subdomainbruteforce/altdnsoutput.txt -w lists/altdnswords.txt
$altdnsoutput=output/$targetfile/subdomainbruteforce/altdnsoutput.txt
altdns -i $altdnsinput -o $altdnsoutput -w $altdnswordlist

####resolving altdns wordlist
#Test comand:massdns -r output/att/resolvers.txt -t A -o S -w output/att/subdomainbruteforce/massaltresult.txt --flush output/att/subdomainbruteforce/altdnsoutput.txt
$massdnsaltdnsoutput=output/$targetfile/subdomainbruteforce/massaltresult.txt
massdns -r $freshpyoutput -t A -o S -w $massdnsaltdnsoutput --flush $altdnsoutput

###create masterlist of resolved subdomains
#Test command: cat output/att/subdomainbruteforce/massaltresult.txt output/att/subdomainbruteforce/massdns.txt | cut -d " " -f1 | sed 's/.$//' | sort -u > output/att/subdomainbruteforce/masterlist.txt
$masterlistoutput=output/$targetfile/subdomainbruteforce/masterlist.txt
cat $massdnsaltdnsoutput $massdnsoutput | cut -d " " -f 1 |sed 's/.$//' | sort -u > $masterlistoutput


### portscan
#Test command: cat output/att/subdomainbruteforce/masterlist.txt | naabu -silent -exclude-ports 80,443 -ports top-1000 output/att/subdomainanalysis/naabu/naabu.txt
mkdir -p output/$targetfile/subdomainanalysis/naabu
naabuoutput=output/$targetfile/subdomainanalysis/naabu/naabu.txt
cat $masterlistoutput | naabu -silent -exclude-ports  80,443 -ports top-1000 $naabuoutput


### find webservers
#Test command: cat output/att/subdomainbruteforce/masterlist.txt output/att/subdomainanalysis/naabu/naabu.txt | sort -u | fprobe -c 100 -t 3000 > output/att/subdomainanalysis/httprobe/websites.txt
mkdir -p output/$targetfile/subdomainanalysis/httprobe
websites=output/$targetfile/subdomainanalysis/httprobe/websites.txt
cat $masterlistoutput $naabuoutput | sort -u | fprobe -c 100 -t 3000 > $websites

### grab http title
websitespath=$websites
httptitleoutput=output/$targetfile/subdomainalysis/httprobe/httptitles.txt
for i in $(cat $websitespath); do 
	echo "$i | $(curl --connect-timeout 0.5 $i -so - | grep -iPo '(?<=<title>)(.*)(?=</title>)')"; 
done | tee -a $httptitleoutput




