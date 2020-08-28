#!/bin/bash

GREEN_START="\033[92m"                                                                                                                                                                                       
GREEN_END="\033[01m"

#echo -e "$GREEN_START [+] Assuming GO is installed. How to install GO: https://tecadmin.net/install-go-on-debian/$GREEN_END"


#Install GO
apt-get update -y
apt-get upgrade -y
mkdir -p /root/Downloads
cd /root/Downloads
wget https://dl.google.com/go/go1.13.3.linux-amd64.tar.gz
tar -xvf go1.13.3.linux-amd64.tar.gz
sudo mv go /usr/local
mkdir -p /root/go

cd /root/Desktop/recon/autorecon/reconscripts/
cat bashconfigs >> /root/.profile
cat bashconfigs >> /root/.bashrc
source /root/.profile


apt-get install unzip
apt-get install curl
apt-get install wget
apt-get install git 
apt-get install python-pip
apt-get install make
apt-get install jq

#Set env variables
mkdir -p /root/Downloads/tools

#install AMASS
echo -e "$GREEN_START [+] Installing Amass.... $GREEN_END"
export GO111MODULE=on
go get -v -u github.com/OWASP/Amass/v3/...
echo -e "$GREEN_START [+] Amass installation conplete! $GREEN_END"

#install dirsearch
echo -e "$GREEN_START [+] Installing Dirsearch.... $GREEN_END"
cd /root/Downloads/tools
git clone https://github.com/maurosoria/dirsearch.git
echo -e "$GREEN_START [+] Dirsearch installation complete! $GREEN_END"

#install massdns
echo -e "$GREEN_START [+] Installing Massdns.... $GREEN_END"
cd /root/Downloads/tools
git clone https://github.com/blechschmidt/massdns.git
cd massdns/
make
echo -e "$GREEN_START [+] Massdns installation complete! $GREEN_END"

#install httprobe
echo -e "$GREEN_START [+] Installing httprobe....$GREEN_END"
cd /root/Downloads/tools
go get -u github.com/tomnomnom/httprobe
echo -e "$GREEN_START [+] Httprobe installation complete! $GREEN_END"

#install filter-resolved by tomnomnom
echo -e "$GREEN_START [+] Installing filter-resolved....$GREEN_END"
cd /root/Downloads/tools
go get github.com/tomnomnom/hacks/filter-resolved
echo -e "$GREEN_START [+] Filter-resolved installation complete! $GREEN_END"

echo -e "$GREEN_START [+] Installing altdns.....$GREEN_END"
pip install py-altdns
echo -e "Don't forget to change the Queue python module"
echo -e "$GREEN_START [+] altdns installation complete! $GREEN_END"

echo -e "$GREEN_START [+] Installing meg...... $GREEN_END"
cd /root/Downloads/tools
go get -u github.com/tomnomnom/meg
echo -e "$GREEN_START [+] meg installation complete! $GREEN_END"


echo -e "$GREEN_START [+] Installing waybackurls..... $GREEN_END"
cd /root/Downloads/tools
go get github.com/tomnomnom/waybackurls
echo -e "$GREEN_START [+] waybackurls installation complete! $GREEN_END"

echo -e "$GREEN_START [+] Installing gowitness..... $GREEN_END"
cd /root/Downloads/tools
go get -u github.com/sensepost/gowitness
echo -e "$GREEN_START [+] gowitness installation complete! $GREEN_END"

echo -e "$GREEN_START [+] Installing kxss....... $GREEN_END"
cd /root/Downloads/tools
git clone https://github.com/tomnomnom/hacks.git
hacks/kxss
go build main.go
mv main kxss
echo -e "$GREEN_START [+] kxss installation complete! $GREEN_END"

echo -e "$GREEN_START [+] Installing ffuf..... $GREEN_END"
cd /root/Downloads/tools
go get github.com/ffuf/ffuf
echo -e "$GREEN_START [+] ffuf installation complete! $GREEN_END"

echo -e "$GREEN_START [+] Installing gf....... $GREEN_END"
cd /root/Downloads/tools
go get -u github.com/tomnomnom/gf
echo -e "$GREEN_START [+] gf installation complete! $GREEN_END"

echo -e "$GREEN_START [+] Installing fprobe....... $GREEN_END"
cd /root/Downloads/tools
go get -u github.com/theblackturtle/fprobe
echo -e "$GREEN_START [+] fprobe installation complete! $GREEN_END"

echo -e "$GREEN_START [+] Installing smuggler.py...... $GREEN_END"
cd /root/Downloads/tools
mkdir smuggler
git clone https://github.com/0xghostwriter/pentest-tools
mv /root/Downloads/tools/pentest-tools/smuggler.py /root/Downloads/tools/smuggler/
rm -rf /root/Downloads/tools/pentest-tools
# we need to figure out which python libraries this tool needs to run. and add the command here: pip3 install colored
echo -e "$GREEN_START [+] smuggler.py installation complete! $GREEN_END"

echo -e "$GREEN_START [+] Installing CRLF-Injection-Scanner.... $GREEN_END"
cd /root/Downloads/tools
git clone https://github.com/0xghostwriter/CRLF-Injection-Scanner.git
cd CRLF-Injection-Scanner/
python3 setup.py install
echo -e "$GREEN_START [+] CRLF-Injection-Scanner installation complete! $GREEN_END"

echo -e "$GREEN_START [+] openredirect scanner..... $GREEN_END"
cd /root/Downloads/tools
git clone https://github.com/0xghostwriter/open-redirect-scanner.git
echo -e "$GREEN_START [+] openredirect scanner installation complete! $GREEN_END"



#https://blog.softhints.com/ubuntu-16-04-server-install-headless-google-chrome/
#https://gist.github.com/ipepe/94389528e2263486e53645fa0e65578b
echo -e "$GREEN_START [+] Installing headless chrome....$GREEN_END"
sudo apt-get update
sudo apt-get install -y libappindicator1 fonts-liberation
cd /tmp
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome*.deb
sudo apt-get -f install 
sudo dpkg --configure -a


echo -e "$GREEN_START [+] headless chrome installation complete! $GREEN_END"
pip3 install tldextract
echo -e "$GREEN_START [+] Installing github-subdomains.py..... $GREEN_END"

echo -e "$GREEN_START [+] Installing Arjun.... $GREEN_END"
cd /root/Downloads/tools
git clone https://github.com/edduu/Arjun.git
echo -e "$GREEN_START [+] Arjun installation complete! $GREEN_END"

echo -e "$GREEN_START [+] Installing SubOver...... $GREEN_END"
go get github.com/Ice3man543/SubOver
cd /root/Desktop/recon/autorecon/reconscripts
wget https://raw.githubusercontent.com/Ice3man543/SubOver/master/providers.json
echo -e "$GREEN_START [+] Subover installation complete!" 

echo -e "$GREEN_START [+] Installing unfurl..... $GREEN_END"
go get -u github.com/tomnomnom/unfurl
echo -e "$GEEN_START [+] unfurl installation complete! $GREEN_END"

echo -e "$GREEN_START [+] Installing dalfox..... $GREEN_END"
go get -u github.com/hahwul/dalfox
echo -e "$GREEN_START [+] Dalfox installation complete $GREEN_END"

echo -e "$GREEN_START [+] Installing qsreplace.... $GREEN_END"
go get -u github.com/tomnomnom/qsreplace
echo -e "$GREEN_START [+] qsreplace installation complete $GREEN_END"

echo -e "$GREEN_START [+] Installing naabu..... $GREEN_END"
apt-get install libpcap-dev
go get -v github.com/projectdiscovery/naabu/cmd/naabu
echo -e "$GREEN_START [+] naabu installation complete! $GREEN_END" 

echo -e "$GREEN_START [+] Installing subfinder...... $GREEN_END"
go get -u -v github.com/projectdiscovery/subfinder/cmd/subfinder
echo -e "$GREEN_START [+] subfinder installation complete! $GREEN_END"

source /root/.bashrc
