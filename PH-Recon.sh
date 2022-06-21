#!/bin/bash

host=$1
wordlist="/root/wordlist/all.txt"
resolver="/root/wordlist/resolvers.txt"

domain_enum(){
for domain in $(cat $host);
do
mkdir -p /root/recon/$domain/subdomain /root/recon/$domain/Subomain-Takeover /root/recon/$domain/scan /root/recon/$domain/url /root/recon/$domain/gf /root/recon/$domain/xss /root/recon/$domain/js_url /root/recon/$domain/git_dork /root/recon/$domain/SQL

subfinder -d $domain -o /root/recon/$domain/subdomain/subfinder.txt
assetfinder -subs-only $domain | tee /root/recon/$domain/subdomain/assetfinder.txt 
findomain -t $domain | tee /root/recon/$domain/subdomain/findomain.txt
amass enum -active -d $domain -o /root/recon/$domain/subdomain/amass_sub.txt
curl -s "https://crt.sh/?q=%25.$domain&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u | tee /root/recon/$domain/subdomain/crtsub.txt
curl -s "https://riddler.io/search/exportcsv?q=pld:$domain" | grep -Po "(([\w.-]*)\.([\w]*)\.([A-z]))\w+" | sort -u | tee /root/recon/$domain/subdomain/riddlersub.txt
curl -s https://dns.bufferover.run/dns?q=.$domain |jq -r .FDNS_A[]|cut -d',' -f2|sort -u | tee /root/recon/$domain/subdomain/bufferoversub.txt
curl -s "https://jldc.me/anubis/subdomains/$domain" | grep -Po "((http|https):\/\/)?(([\w.-]*)\.([\w]*)\.([A-z]))\w+" | sort -u | tee /root/recon/$domain/subdomain/jldcsub.txt
sed -ne 's/^\( *\)Subject:/\1/p;/X509v3 Subject Alternative Name/{
N;s/^.*\n//;:a;s/^\( *\)\(.*\), /\1\2\n\1/;ta;p;q; }' << (
openssl x509 -noout -text -in <(
openssl s_client -ign_eof 2>/dev/null <<<$'HEAD / HTTP/1.0\r\n\r' \
-connect $domain:443 ) ) | grep -Po '((http|https):\/\/)?(([\w.-]*)\.([\w]*)\.([A-z]))\w+' | tee /root/recon/$domain/subdomain/altnamesub.txt
cat /root/recon/$domain/subdomain/*.txt > /root/recon/$domain/subdomain/allsub.txt
cat /root/recon/$domain/subdomain/allsub.txt | anew -q /root/recon/$domain/subdomain/all_srot_sub.txt
done
}
domain_enum

resolving_domains(){
for domain in $(cat $host);
do
massdns -r $resolver -t A -o S -w /root/recon/$domain/subdomain/massdns.txt /root/recon/$domain/subdomain/all_srot_sub.txt
cat /root/recon/$domain/subdomain/massdns.txt | sed 's/A.*//; s/CN.*// ; s/\..$//' | tee > /root/recon/$domain/subdomain/final_sub.txt
done
}
resolving_domains

domain_ip(){
for domain in $(cat $host);
do
gf ip /root/recon/$domain/subdomain/massdns.txt | sed 's/.*://' > /root/recon/$domain/subdomain/ip_sub.txt
done
}
domain_ip

http_prob(){
for domain in $(cat $host);
do
cat /root/recon/$domain/subdomain/final_sub.txt | httpx -threads 200 -o /root/recon/$domain/subdomain/active_subdomain.txt 
done
}
http_prob

Subdomai_takeover(){
for domain in $(cat $host);
do
subzy -targets /root/recon/$domain/subdomain/active_subdomain.txt > /root/recon/$domain/Subomain-Takeover/poc.txt
done
}
Subdomai_takeover

web_Screenshot(){
for domain in $(cat $host);
do
gowitness file -f /root/recon/$domain/subdomain/active_subdomain.txt
done
}
web_Screenshot

scanner(){
for domain in $(cat $host);
do
cat /root/recon/$domain/subdomain/active_subdomain.txt | nuclei -t /root/nuclei-templates/cves/ -c 50 -o /root/recon/$domain/scan/new-cves.txt
cat /root/recon/$domain/subdomain/active_subdomain.txt | nuclei -t /root/nuclei-templates/vulnerabilities/ -c 50 -o /root/recon/$domain/scan/new-vulnerabilities.txt
cat /root/recon/$domain/subdomain/active_subdomain.txt | nuclei -t /root/nuclei-templates/technologies/ -c 50 -o /root/recon/$domain/scan/new-technologies.txt
done
}
scanner

find_urls(){
for domain in $(cat $host);
do
cat /root/recon/$domain/subdomain/active_subdomain.txt | waybackurls | tee /root/recon/$domain/url/waybackurls.txt
cat /root/recon/$domain/subdomain/active_subdomain.txt | hakrawler > /root/recon/$domain/url/hakrawler-urls.txt
gospider -S /root/recon/$domain/subdomain/active_subdomain.txt -c 10 -d 1 --other-source | grep $domain | tee /root/recon/$domain/url/gospider-url.txt
cat /root/recon/$domain/subdomain/active_subdomain.txt | gau --threads 5 > /root/recon/$domain/url/gau-urls.txt
cat /root/recon/$domain/url/*.txt > /root/recon/$domain/url/all-url.txt
cat /root/recon/$domain/url/all-url.txt | sort --unique | tee /root/recon/$domain/url/final-url.txt
cat /root/recon/$domain/url/final-url.txt | egrep -v "\.woff|\.ttf|\.svg|\.eot|\.png|\.jpep|\.svg|\.css|\.ico" | sed 's/:88//9;s/:443//g' | sort -u >> /root/recon/$domain/url/valid_urls.txt
done
}
find_urls


Get_js(){
for domain in $(cat $host);
do
cat /root/recon/$domain/url/valid_urls.txt | getJS --complete | tee /root/recon/$domain/js_url/getjs_urls.txt
cat /root/recon/$domain/url/valid_urls.tx | grep '\.js$' | httpx -status-code -mc 200 -content-type | grep 'application/javascript' | tee /root/recon/$domain/js_url/jshttpxurl.txt
done
}
Get_js

gf_patterns(){
for domain in $(cat $host);
do
gf xss /root/recon/$domain/url/valid_urls.txt | tee /root/recon/$domain/gf/xss.txt
gf sqli /root/recon/$domain/url/valid_urls.txt | tee /root/recon/$domain/gf/sqli.txt
gf lfi /root/recon/$domain/url/valid_urls.txt |  tee /root/recon/$domain/gf/lfi.txt
done
}
gf_patterns

Refactors_xss(){
for domain in $(cat $host);
do
cat /root/recon/$domain/url/valid_urls.txt | Gxss -o /root/recon/$domain/xss/gxss.txt
cat /root/recon/$domain/url/valid_urls.txt | kxss > /root/recon/$domain/xss/kxss_url.txt
cat /root/recon/$domain/xss/kxss_url.txt | sed 's/.*on//' | sed 's/=.*/=/' > /root/recon/$domain/xss/kxss_url_active.txt
cat /root/recon/$domain/xss/kxss_url_active.txt | dalfox pipe | tee /root/recon/$domain/xss/dalfoxss.txt
done
}
Refactors_xss

SQL(){
for domain in $(cat $host);
do
sqlmap -m /root/recon/$domain/gf/sqli.txt --batch --random-agent --level 1 | tee /root/recon/$domain/SQL/sqlpoc.txt -v
done
}
SQL

LFI(){
for domain in $(cat $host);
do
cat /root/recon/$domain/gf/lfi.txt | qsreplace FUZZ | while read url ; do ffuf -u $url -mr "root:x" -w ~/tools/lfipayloads.txt -of csv -o $domain/vulnerabilities/LFI/lfi.txt -t 50 -c  ; done
}
menu(){
done
}
LFI

Git_dork(){
for domain in $(cat $host);
do
python3 /root/Okvps/tools/GitDorker/GitDorker.py -tf /root/Okvps/tools/GitDorker/token.txt -q $domain -d /root/Okvps/tools/GitDorker/Dorks/medium_dorks.txt -o /root/recon/$domain/git_dork/medium_dorks.txt
done
}
Git_dork
