#!/bin/bash
echo "Beast Mode ON"


#https://unix.stackexchange.com/questions/332691/how-to-insert-variables-inside-a-string-containing

echo usage: ./ffufplus.sh targethostsfile workingdirectory wordlist companyfilename

targethostsfile=$1
workingdirectory=$2
bruteforcewordlist=$3

echo targetfile = $targethostsfile
echo workingdirectory = $workingdirectory
echo bruteforcewordlist = $bruteforcewordlist


cd $workingdirectory

if [[ "$bruteforcewordlist" == 1 ]]; then
	xargs -P10 -I {} sh -c 'url="{}"; ffuf -s -mc all -c -H "X-Forwarded-For: 127.0.0.1" -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:72.0) Gecko/20100101 Firefox/72.0" -u "{}/FUZZ" -w /root/Desktop/ghettobash/lists/dicc.txt -t 80 -D -e asp,aspx,bak,config,gz,htm,html,jar,js,json,jsp,log,old,php,ppk,rsa,save,shtml,sql,swp,tar,tgz,txt,yaml,yml,zip -ac -se -of csv -o ${url##*/}-${url%%:*}.csv' < $targethostsfile
fi
if [[ "$bruteforcewordlist" == 2 ]]; then
	xargs -P10 -I {} sh -c 'url="{}"; ffuf -s -mc all -c -H "X-Forwarded-For: 127.0.0.1" -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:72.0) Gecko/20100101 Firefox/72.0" -u "{}/FUZZ" -w /root/Desktop/ghettobash/lists/critical.txt -t 80 -ac -se -of csv -o ${url##*/}-${url%%:*}.csv' < $targethostsfile
fi
if [[ "$bruteforcewordlist" == 3 ]]; then
	xargs -P10 -I {} sh -c 'url="{}"; ffuf -s -mc all -c -H "X-Forwarded-For: 127.0.0.1" -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:72.0) Gecko/20100101 Firefox/72.0" -u "{}/FUZZ" -w /root/Desktop/ghettobash/lists/content_discovery_all.txt -t 80 -ac -se -of csv -o ${url##*/}-${url%%:*}.csv' < $targethostsfile
fi


cd /root/Desktop/ghettobash/

cat $workingdirectory/* |  cut -d "," -f 2,5,6 | sed 's/,/ /g' | awk '{print $2" "$3" "$1}' > $workingdirectory/results.txt


printf "\nDone. Result is stored in $workingdirectory/results.txt\n"


###workingdirectory
###wordlist
###companyfile
###targetfile
