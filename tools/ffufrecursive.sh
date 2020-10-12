#!/bin/bash
echo "Beast Mode ON"


#https://unix.stackexchange.com/questions/332691/how-to-insert-variables-inside-a-string-containing

targetfile=$3

cd /root/Desktop/ghettobash/output/$targetfile/subdomainanalysis/ffuf/401403
#lists/content_discovery_nullenc0de.txt

#ffuf -w "$httprobemasterlist:DOMAIN" -w $dirsearchwordlist -u DOMAIN/FUZZ -t 80 -recursion -recursion-depth 2 -maxtime-job 90 -o $ffuffolder/output.json

xargs -P10 -I {} sh -c 'url="{}"; ffuf -s -mc all -c -H "X-Forwarded-For: 127.0.0.1" -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:72.0) Gecko/20100101 Firefox/72.0" -u "{}/FUZZ" -w /root/Desktop/ghettobash/lists/dicc.txt -t 80 -D  -ac -se -o ${url##*/}-${url%%:*}.json' < $1


cd /root/Desktop/ghettobash/

cat /root/Desktop/ghettobash/output/$3/subdomainanalysis/ffuf/401403/* | jq '[.results[]|{status: .status, length: .length, url: .url}]' | grep -oP "status\":\s(\d{3})|length\":\s(\d{1,7})|url\":\s\"(http[s]?:\/\/.*?)\"" | paste -d' ' - - - | awk '{print $2" "$4" "$6}' | sed 's/\"//g' > $2


printf "\nDone. Result is stored in $2\n"

