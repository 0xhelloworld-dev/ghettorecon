#!/bin/sh

###Tool Configurations:
#rundate=$(date +"%m%d%Y")
#echo Run date: $rundate
targetfile=$1
#echo Target filename: $targetfile
commonspeakwordlist=lists/best-dns-wordlist.txt
fdnsGzFile=/root/Downloads/2020-02-21-1582243548-fdns_any.json.gz
altdnswordlist=lists/altdnswords.txt
dirsearchwordlist=lists/dicc.txt
pwd=$(pwd)


###add a commandline check where you must supply an input file

###freshpy
freshpyoutput=output/$targetfile/resolvers.txt
mkdir -p output/$targetfile
if [ -f "$freshpyoutput" ]; then #output/$targetfile/resolvers.txt
	echo "fresh.py results detected"
else
	fresh.py -o $freshpyoutput
fi

###Resolve Top Level Domains with massdns
mkdir -p output/$targetfile/ResolveTLDs
topleveldomainresults=output/$targetfile/ResolveTLDs/resolvedtlds.txt
if [ -f "$topleveldomainresults" ]; then #output/$targetfile/ResolveTLDs/resolvedtlds.txt
	echo "previous TLD resolution results detected... moving on"
else 
	massdns -r $freshpyoutput -t A $targetfile -o S -w $topleveldomainresults
fi

###Parse TLD results
liveTLDOutput=output/$targetfile/ResolveTLDs/liveTLDs.txt
if [ -f "$liveTLDOutput" ]; then #output/$targetfile/ResolveTLDs/liveTLDs.txt
	echo "TLDs parsed... moving on"
else
	python3 tools/pythonparsers/massdnsparser.py $topleveldomainresults $liveTLDOutput  ###this outputs to output/{targetfile}/ResolveTLDs/liveTLDs.txt
fi

##########Subdomain Enumeration###########
###Amass
###Test command: amass enum -passive -v -o output/att/subdomains/amass.txt -df output/att/ResolveTLDs/liveTLDs.txt
mkdir -p output/$targetfile/subdomains
amassresults=output/$targetfile/subdomains/amass.txt
if [ -f "$amassresults" ]; then #output/$targetfile/subdomains/amass.txt
	echo "Amass results detected... moving on"
else
	echo "Running amass scan...." 
	amass enum -passive -v -o $amassresults -df $liveTLDOutput -config ./config.ini
fi

###CommonSpeak2
###Test command: python3 tools/pythonparsers/commonspeak2.py att lists/commonspeak2.txt output/att/subdomains/commonspeak2.txt
commonspeakresults=output/$targetfile/subdomains/commonspeak2.txt
if [ -f "$commonspeakresults" ]; then #output/$targetfile/subdomains/commonspeak2.txt
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
if [ -f "$subfinderresults" ]; then #output/$targetfile/subdomains/subfinder.txt
	echo "subfinder results detected... moving on"
else
	subfinder -dL $liveTLDOutput -o $subfinderresults
fi

#############Subdomain Bruteforcing###########
#Test command:  cat output/att/subdomains/* | sort -u > output/att/subdomains/compiled.txt
compilesubdomainsresults=output/$targetfile/subdomains/compiled.txt
if [ -f "$compilesubdomainsresults" ]; then #output/$targetfile/subdomains/compiled.txt
	echo "subdomains have been previously compiled... moving on"
else
	cat output/$targetfile/subdomains/*.txt | sort -u > $compilesubdomainsresults
fi

###massdns resolve gathered subdomains
### Test command: massdns -r output/att/resolvers.txt -t A -o S -w output/att/subdomainbruteforce/massdns.txt --flush output/att/subdomains/compiled.txt 
mkdir -p output/$targetfile/subdomainbruteforce
massdnsoutput=output/$targetfile/subdomainbruteforce/massdns.txt
if [ -f "$massdnsoutput" ]; then #output/$targetfile/subdomainbruteforce/massdns.txt
	echo "compiled subdomains have been resolved... moving on"
else
	massdns -r $freshpyoutput -t A -o S -w $massdnsoutput --flush $compilesubdomainsresults
fi


###parse massdns results for domains
## Test command: python3 tools/pythonparsers/massdnsparser.py output/att/subdomainbruteforce/massdns.txt output/att/subdomainbruteforce/altdnsinput.txt
permutationfolder=output/$targetfile/subdomainbruteforce/permutations
pcounter=1 #pcounter
mkdir -p $permutationfolder/$pcounter
altdnsinput=$permutationfolder/$pcounter/perm.txt #this eventually becomes input for altdns
if [ -f "$altdnsinput" ]; then #output/$targetfile/subdomainbruteforce/permutations/1/perm.txt
	echo  "compiled subdomains have been parsed... moving on"
else
	python3 tools/pythonparsers/massdnsparser.py $massdnsoutput $altdnsinput
fi

### find webservers
httprobefolder=output/$targetfile/subdomainanalysis/httprobe #do we need to add $pwd?
mkdir -p $httprobefolder
if [ -f "$httprobefolder/massdnshttprobe.txt" ]; then 
	echo massdns  httprobe scan completed...moving  on
else
	echo performing httprobe scan on massdns output
        cat $altdnsinput | sort -u | fprobe -c 100 -t 3000  > $httprobefolder/massdnshttprobe.txt
fi

###this is where we will integrate the permutation scan. if wc $massdnsaltdnsoutput > 1, continue performing permutation scan on resulting subdomains. 
echo permutation counter is $pcounter
if [ -d "$permutationfolder/2" ]; then #come BACK and finish this conditional there is a logic flaw with this and when mkdir -p $permutationfolder/$pcounter is created. reasoning for this condition is permutation scan will have to  run at least once if there are ANY live subdomains. 
	echo "permutation scan has been run already... skipping"
else
	while [ -s $permutationfolder/$pcounter/perm.txt ] || [ "$pcounter" -le 10  ]; #check if previous permutation scan has contents, if it does run this. 
	do
		permplusone=$(($pcounter+1))
		echo beginning altdns scan on permutation $pcounter
		altdns -i $permutationfolder/$pcounter/perm.txt -o $permutationfolder/$pcounter/altdnsoutput.txt -w $altdnswordlist #input first set of domains into massdns (perm1.txt)
		echo resolving altdns domains for permutation $pcounter
		if [ ! -s "$permutationfolder/$pcounter/altdnsoutput.txt" ]; then #if altdns output is empty then exit the while loop
			echo altdnsoutput is empty.. exiting loop
			break;
		fi
		massdns -r $freshpyoutput -t A -o S -w $permutationfolder/$pcounter/resolved.txt --flush $permutationfolder/$pcounter/altdnsoutput.txt #resolve all domains generated by altdns into resolved$pcounter.txt
		echo parsing massdns results for permutation $pcounter
		cat $permutationfolder/$pcounter/resolved.txt | cut -d " " -f 1 | sed 's/.$//' | sort -u  > $permutationfolder/$pcounter/probeinput.txt 
		echo checking which domains are alive for permutation $pcounter
		cat $permutationfolder/$pcounter/probeinput.txt | fprobe -c 100 -t 3000  > $httprobefolder/httprobe$pcounter.txt
		echo prepping httprobe results for next permutation
		mkdir -p $permutationfolder/$permplusone
		cat $httprobefolder/httprobe$pcounter.txt | unfurl domains | sort -u > $permutationfolder/$permplusone/perm.txt
		pcounter=$(($pcounter+1))
	done 
fi

#getting unique IP addresses from massdns, then passing them to naabu
#cat massdns.txt  | cut -d " " -f 3|  sort -u | grep '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' 

#### create httprobe masterlist
httprobemasterlist=$pwd/$httprobefolder/masterlisthttprobe.txt #do we need to add $pwd?
if [ -f "$httprobemasterlist" ]; then
	echo httprobe masterlist has been previously created
else
	echo parsing all httprobe files... creating masterlist
	cat $httprobefolder/* | sort -u > $httprobemasterlist
fi

### get http titles
### grab http title
httptitleoutput=$pwd/output/$targetfile/subdomainanalysis/httprobe/httptitles.txt
if [ -f "$httptitleoutput" ]; then
	echo httptitles have been previously scanned.. skipping task
else
	touch $httptitleoutput
	for i in $(cat $httprobemasterlist); do
		echo "$i | $(curl --connect-timeout 0.5 $i -so - | grep -iPo '(?<=<title>)(.*)(?=</title>)')";
	done | tee -a $httptitleoutput
fi

##ffuf shit up
ffuffolder=$pwd/output/$targetfile/subdomainanalysis/ffuf
ffufresults=$ffuffolder/results.txt
if [  -d "$ffuffolder" ]; then
	echo ffuf has been previously run... skipping ffuf scan
else
	echo performing ffuf scan
	mkdir -p $ffuffolder
	echo 1: $httprobemasterlist 2: $ffuffolder/results.txt 3: $targetfile
	echo usage: ./ffufplus.sh targethostsfile workingdirectory wordlist companyfilename
	/root/Desktop/ghettobash/tools/ffufplus.sh $httprobemasterlist $ffuffolder 1 #the ffufpluscontentdiscovery.sh script runs out of the 
fi

#ffuf 403/401
bypassffuffolder=$pwd/output/$targetfile/subdomainanalysis/ffuf/401403
if [ -d "$bypassffuffolder" ]; then
	echo recursive directory bypass scan has been previously run..  skipping task
else
	echo recursively scanning 401/403 directories
	mkdir -p $bypassffuffolder
	cat $ffufresults | awk '$1 == 401 || $1 == 403' | cut -d " " -f 3 > $ffuffolder/targets.txt
	/root/Desktop/ghettobash/tools/ffufplus.sh $ffuffolder/targets.txt $bypassffuffolder 1
fi

#critical ffuf
critffuffolder=$pwd/output/$targetfile/subdomainanalysis/ffuf/criticalffuf
if [ -d "$critffuffolder" ]; then
	echo critical ffuf has run ... skipping task
else
	echo starting critical ffuf scan
	mkdir -p $critffuffolder
	/root/Desktop/ghettobash/tools/ffufplus.sh $httprobemasterlist $critffuffolder 2
fi


###gau
gaufolder=$pwd/output/$targetfile/subdomainanalysis/gau
if [ -d "$gaufolder" ]; then
	echo  gau scan has been run...skipping task
else
	echo  gau scanning all live URLs
	mkdir -p $gaufolder
	cat $httprobemasterlist | unfurl domains | sort -u  > $gaufolder/gaudomains.txt
	while read domain; do
  		echo $domain | gau > $gaufolder/$domain
	done <$gaufolder/gaudomains.txt
fi

###jsfile scan
jsfolder=$pwd/output/$targetfile/subdomainanalysis/javascript
if [ -d "$jsfolder" ]; then
	echo js scan has been run...skipping task
else 
	echo js scanning all live URLs
	mkdir -p $jsfolder
	cat $ffuffolder/results.txt | awk '$1 == 200' | grep " 0 " -v | cut  -d " " -f 3| sort -u >> $jsfolder/ffuf200.txt
	cat $httprobemasterlist $jsfolder/ffuf200.txt | sort -u | subjs >> $jsfolder/jsfilelinks.txt
	while read domain;  do 
		echo $domain | gau | grep ".js$" | uniq | sort >> $jsfolder/jsfilelinks.txt
	done <$gaufolder/gaudomains.txt
	cat $jsfolder/jsfilelinks.txt | sort -u | hakcheckurl -t 80 | grep "200" | cut -d " " -f 2 | sort -u > $jsfolder/livejslinks.txt
fi

###jsfile endpoint discovery scan
jsendpoints=$jsfolder/endpoints
if [ -d "$jsendpoints" ]; then
	echo js endpoint discovery has been run... skipping task
else
	echo js endpoint scanning all live URLs
	mkdir -p $jsendpoints
	cd $jsendpoints
	while read domain; do
		echo $domain | python3 /root/Downloads/tools/LinkFinder/linkfinder.py -d -i $domain  -o cli >> endpoints.txt
	done <$jsfolder/livejslinks.txt
#	interlace -tL $jsfolder/livejslinks.txt -threads 5 -c "echo 'Scanning _target_ Now' ; python3 /root/Downloads/tools/LinkFinder/linkfinder.py -d -i _target_ -o cli >> endpoints.txt" -v
fi

###building customized wordlist based on javascript files
jswordlist=$jsfolder/endpoints/wordlist
if [ -d "$jswordlist" ]; then
	echo javascript wordlist has already been created... skipping task
else
	echo creating custom wordlist from javascript files
	mkdir -p $jswordlist
	cd $jsendpoints
	cat endpoints.txt | grep "Running against" -v | grep "Invalid input" -v | sort -u |  grep http | unfurl path | sed 's/^\///' >> $jswordlist/wordlist.txt
	cat endpoints.txt | grep "Running against" -v | grep "Invalid input" -v | sort -u |  grep http -v | sed 's/^\///g; s/^\///; s/^\///' | sed 's/^\.\///g; s/^\.\.\///g' | sed 's/^\.\///g; s/^\.\.\///g' | sed 's/^\.\///g; s/^\.\.\///g' | sed 's/^\.\///g; s/^\.\.\///g' | sed 's/^\.\///g; s/^\.\.\///g' | sed 's/^\.\///g; s/^\.\.\///g' | sed 's/^\.\///g; s/^\.\.\///g'  | sed 's/^\.\///g; s/^\.\.\///g' >> $jswordlist/wordlist.txt
	cat $jswordlist/wordlist.txt | sort -u >> $jswordlist/finalwordlist.txt
fi

secretfinder=$jsfolder/secrets
if [ -d "$secretfinder" ]; then
	echo secret finder has been run... skipping task
else 
	echo running secret finder on all urls
	mkdir -p $secretfinder
	cd $secretfinder
	while read domain; do 
		python3 /root/Downloads/tools/SecretFinder/SecretFinder.py -i $domain -o cli >> jssecrets.txt 
	done <$jsfolder/livejslinks.txt
fi








#############
############
###############

longwordlistffuffolder=$pwd/output/$targetfile/subdomainanalysis/ffuf/longwordlist
if [ -d "$longwordlistffuffolder" ]; then
	echo longwordlist ffuf has run ... skipping task
else
	echo starting  longwordlist ffuf scan
	mkdir -p $longwordlistffuffolder
	/root/Desktop/ghettobash/tools/ffufplus.sh $httprobemasterlist $longwordlistffuffolder 3
fi
###create masterlist of resolved subdomains
#Test command: cat output/att/subdomainbruteforce/massaltresult.txt output/att/subdomainbruteforce/massdns.txt | cut -d " " -f1 | sed 's/.$//' | sort -u > output/att/subdomainbruteforce/masterlist.txt
#masterlistoutput=output/$targetfile/subdomainbruteforce/masterlist.txt
#if [ -f "$masterlistoutput" ]; then
#	echo "all subdomains have been compiled in a masterlist... moving on"
#else
#	cat $permutationfolder/perm*.txt $massdnsoutput | cut -d " " -f 1 |sed 's/.$//' | sort -u > $masterlistoutput #add output/$targetfile/subdomainbruteforce/permutations/perm*.txt
#fi

####create websitemasterlist.txt


### portscan
#Test command: cat output/att/subdomainbruteforce/masterlist.txt | naabu -silent -exclude-ports 80,443 -ports top-1000 output/att/subdomainanalysis/naabu/naabu.txt
#mkdir -p output/$targetfile/subdomainanalysis/naabu
#naabuoutput=output/$targetfile/subdomainanalysis/naabu/naabu.txt
#cat $masterlistoutput | naabu -silent -exclude-ports  80,443 -ports top-1000 $naabuoutput


### grab http title
#websitespath=$websites
#httptitleoutput=output/$targetfile/subdomainalysis/httprobe/httptitles.txt
#for i in $(cat $websitespath); do 
#	echo "$i | $(curl --connect-timeout 0.5 $i -so - | grep -iPo '(?<=<title>)(.*)(?=</title>)')"; 
#done | tee -a $httptitleoutput


#ffuf -w "output.txt:DOMAIN" -w $dirsearchwordlist -u DOMAIN/FUZZ -t 400 -recursion -recursion-depth 2 -maxtime-job 90
#format of data in output.txt is https://target.com or http://target.com

