#!/bin/sh

###Tool Configurations:
#rundate=$(date +"%m%d%Y")
#echo Run date: $rundate
targetfile=$1
#echo Target filename: $targetfile
commonspeakwordlist=lists/commonspeak2.txt
fdnsGzFile=/root/Downloads/2020-02-21-1582243548-fdns_any.json.gz
altdnswordlist=lists/altdnswords.txt


###add a commandline check where you must supply an input file

###freshpy
freshpyoutput=output/$targetfile/resolvers.txt
mkdir -p output/$targetfile
if [ -f "$freshpyoutput" ]; then
	echo "fresh.py results detected"
else
	fresh.py -o $freshpyoutput
fi

###Resolve Top Level Domains with massdns
mkdir -p output/$targetfile/ResolveTLDs
topleveldomainresults=output/$targetfile/ResolveTLDs/resolvedtlds.txt
if [ -f "$topleveldomainresults" ]; then
	echo "previous TLD resolution results detected... moving on"
else 
	massdns -r $freshpyoutput -t A $targetfile -o S -w $topleveldomainresults
fi

###Parse TLD results
liveTLDOutput=output/$targetfile/ResolveTLDs/liveTLDs.txt
if [ -f "$liveTLDOutput" ]; then
	echo "TLDs parsed... moving on"
else
	python3 tools/pythonparsers/massdnsparser.py $topleveldomainresults $liveTLDOutput  ###this outputs to output/{targetfile}/ResolveTLDs/liveTLDs.txt
fi

##########Subdomain Enumeration###########
###Amass
###Test command: amass enum -passive -v -o output/att/subdomains/amass.txt -df output/att/ResolveTLDs/liveTLDs.txt
mkdir -p output/$targetfile/subdomains
amassresults=output/$targetfile/subdomains/amass.txt
if [ -f "$amassresults" ]; then 
	echo "Amass results detected... moving on"
else
	echo "Running amass scan...." 
	amass enum -passive -v -o $amassresults -df $liveTLDOutput
fi

###CommonSpeak2
###Test command: python3 tools/pythonparsers/commonspeak2.py att lists/commonspeak2.txt output/att/subdomains/commonspeak2.txt
commonspeakresults=output/$targetfile/subdomains/commonspeak2.txt
if [ -f "$commonspeakresults" ]; then
	echo "commonspeak results detected... moving on"
else
	python3 tools/pythonparsers/commonspeak2.py $targetfile $commonspeakwordlist $commonspeakresults
fi

###FDNSenum
###Test command: python3 tools/pythonparsers/fDNSenum.py output/att/ResolveTLDs/liveTLDs.txt /root/Downloads/2020-02-21-1582243548-fdns_any.json.gz output/att/subdomains/fdns.txt
#fndsenumresults=output/$targetfile/subdomains/fdns.txt
#python3 tools/pythonparsers/fDNSenum.py $liveTLDOutput $fdnsGzFile $fdnsenumresults



###Subfinder
#Test command: subfinder -dL att -o output/att/subdomains/subfinder.txt
subfinderresults=output/$targetfile/subdomains/subfinder.txt
if [ -f "$subfinderresults" ]; then
	echo "subfinder results detected... moving on"
else
	subfinder -dL $liveTLDOutput -o $subfinderresults
fi

#############Subdomain Bruteforcing###########
#Test command:  cat output/att/subdomains/* | sort -u > output/att/subdomains/compiled.txt
compilesubdomainsresults=output/$targetfile/subdomains/compiled.txt
if [ -f "$compilesubdomainsresults" ]; then
	echo "subdomains have been previously compiled... moving on"
else
	cat output/$targetfile/subdomains/*.txt | sort -u > $compilesubdomainsresults
fi

###massdns resolve gathered subdomains
### Test command: massdns -r output/att/resolvers.txt -t A -o S -w output/att/subdomainbruteforce/massdns.txt --flush output/att/subdomains/compiled.txt 
mkdir -p output/$targetfile/subdomainbruteforce
massdnsoutput=output/$targetfile/subdomainbruteforce/massdns.txt
if [ -f "$massdnsoutput" ]; then
	echo "compiled subdomains have been resolved... moving on"
else
	massdns -r $freshpyoutput -t A -o S -w $massdnsoutput --flush $compilesubdomainsresults
fi

###parse massdns results for domains
## Test command: python3 tools/pythonparsers/massdnsparser.py output/att/subdomainbruteforce/massdns.txt output/att/subdomainbruteforce/altdnsinput.txt
altdnsinput=output/$targetfile/subdomainbruteforce/altdnsinput.txt
if [ -f "$altdnsinput" ]; then
	echo  "compiled subdomains have been parsed... moving on"
else
	python3 tools/pythonparsers/massdnsparser.py $massdnsoutput $altdnsinput
fi

###altdns generation
### Test command: altdns -i output/att/subdomainbruteforce/altdnsinput.txt -o output/att/subdomainbruteforce/altdnsoutput.txt -w lists/altdnswords.txt
altdnsoutput=output/$targetfile/subdomainbruteforce/altdnsoutput.txt
if [ -f "$altdnsoutput" ]; then
	echo "altdns scan results detected... moving on"
else	
	altdns -i $altdnsinput -o $altdnsoutput -w $altdnswordlist
fi

####resolving altdns wordlist
#Test comand:massdns -r output/att/resolvers.txt -t A -o S -w output/att/subdomainbruteforce/massaltresult.txt --flush output/att/subdomainbruteforce/altdnsoutput.txt
permutationfolder=output/$targetfile/subdomainbruteforce/permutations
mkdir -p $permutationfolder
massdnsaltdnsoutput=$permutationfolder/perm1.txt
if [ -f "$massdnsaltdnsoutput" ]; then
	echo "altdns scan have been resolved... moving on"
else
	massdns -r $freshpyoutput -t A -o S -w $massdnsaltdnsoutput --flush $altdnsoutput
fi

###this is where we will integrate the permutation scan. if wc $massdnsaltdnsoutput > 1, continue performing permutation scan on resulting subdomains. 
pcounter=1 #permutationcounter
echo pcounter is $pcounter
while [ -s output/$targetfile/subdomainbruteforce/permutations/perm$pcounter.txt ] || [ "$pcounter" -le 10  ]; #check if previous permutation scan has contents, if it does run this. 
do
	permplusone=$(($pcounter+1))
	altdns -i output/$targetfile/subdomainbruteforce/permutations/perm$pcounter.txt -o output/$targetfile/subdomainbruteforce/permutations/altdnsoutput$permplusone.txt -w $altdnswordlist
	massdns -r $freshpyoutput -t A -o S -w output/$targetfile/subdomainbruteforce/permutations/perm$permplusone.txt --flush output/$targetfile/subdomainbruteforce/permutations/altdnsoutput$permplusone.txt
	pcounter=$(($pcounter+1))
done 


###create masterlist of resolved subdomains
#Test command: cat output/att/subdomainbruteforce/massaltresult.txt output/att/subdomainbruteforce/massdns.txt | cut -d " " -f1 | sed 's/.$//' | sort -u > output/att/subdomainbruteforce/masterlist.txt
masterlistoutput=output/$targetfile/subdomainbruteforce/masterlist.txt
if [ -f "$masterlistoutput" ]; then
	echo "all subdomains have been compiled in a masterlist... moving on"
else
	cat $permutationfolder/perm*.txt $massdnsoutput | cut -d " " -f 1 |sed 's/.$//' | sort -u > $masterlistoutput #add output/$targetfile/subdomainbruteforce/permutations/perm*.txt
fi




### portscan
#Test command: cat output/att/subdomainbruteforce/masterlist.txt | naabu -silent -exclude-ports 80,443 -ports top-1000 output/att/subdomainanalysis/naabu/naabu.txt
#mkdir -p output/$targetfile/subdomainanalysis/naabu
#naabuoutput=output/$targetfile/subdomainanalysis/naabu/naabu.txt
#cat $masterlistoutput | naabu -silent -exclude-ports  80,443 -ports top-1000 $naabuoutput


### find webservers
#Test command: cat output/att/subdomainbruteforce/masterlist.txt output/att/subdomainanalysis/naabu/naabu.txt | sort -u | fprobe -c 100 -t 3000 > output/att/subdomainanalysis/httprobe/websites.txt
#mkdir -p output/$targetfile/subdomainanalysis/httprobe
#websites=output/$targetfile/subdomainanalysis/httprobe/websites.txt
#cat $masterlistoutput $naabuoutput | sort -u | fprobe -c 100 -t 3000 > $websites

### grab http title
#websitespath=$websites
#httptitleoutput=output/$targetfile/subdomainalysis/httprobe/httptitles.txt
#for i in $(cat $websitespath); do 
#	echo "$i | $(curl --connect-timeout 0.5 $i -so - | grep -iPo '(?<=<title>)(.*)(?=</title>)')"; 
#done | tee -a $httptitleoutput




