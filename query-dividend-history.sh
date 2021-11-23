#!/bin/bash
stockcode="601006"
startdate="19950101"
enddate="`date '+%Y'`1231"

_stockcode=`echo $0 | awk -F'.' '{print $(NF-1)}'`

if [[ ${_stockcode} != "query-dividend-history" ]]; then
	stockcode=$_stockcode
fi

echo "stockcode: $stockcode"

mkdir -p ~/Library/Mobile\ Documents/com~apple~Numbers/Documents/Stock-Data/historic

if [[ ! -e ~/stock-data ]]; then
   mkdir -p ~/stock-data
fi
cd ~/stock-data/

secret_properties=~/stock-data/secret.properties

if [[ ! -e ${secret_properties} ]]; then
    touch ${secret_properties}
    echo "api_cninfo_access_key=" >> ${secret_properties}
    echo "api_cninfo_access_secret=" >> ${secret_properties}
fi
source $secret_properties
if [[ "${api_cninfo_access_key}" = "" ]]; then
    echo "api_cninfo_access_key not cofigured in ${secret_properties}"
    exit 1
fi
if [[ "${api_cninfo_access_secret}" = "" ]]; then
    echo "api_cninfo_access_secret not cofigured in ${secret_properties}"
    exit 1
fi

mac_arch=`uname -m`
if [[ ${mac_arch} = "i386" ]]; then
	JQ=/usr/local/bin/jq
elif [[ ${mac_arch} = "arm64" ]]; then
	JQ=/opt/homebrew/bin/jq
else
	JQ=jq
fi


echo "jq is required. to install, run: brew install jq"
echo

curl --location --request POST 'http://webapi.cninfo.com.cn/api-cloud-platform/oauth2/token?grant_type=client_credentials' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-raw "grant_type=client_credentials&client_id=${api_cninfo_access_key}&client_secret=${api_cninfo_access_secret}" \
-o cninfo-key-latest.json

token=`$JQ -r '[.access_token] | @csv' cninfo-key-latest.json | sed -e 's/\"//g'`

curl --location --request GET "http://webapi.cninfo.com.cn/api/stock/p_stock2201?scode=${stockcode}&sdate=${startdate}&edate=${enddate}&state=1&access_token=${token}" -o dividend-history-${stockcode}.json

printf '%s\n' "code,name,term,doc,giftshare_per_10share,addshare_per_10share,int_per_10share,cutoff_date,reg_date,exit_right_date,int_date" > dividend-history-${stockcode}.csv

$JQ -r '.records[] | [.SECCODE, .SECNAME, .F044V, .F036V, .F010N, .F011N, .F012N, .F001D, .F018D, .F020D, .F023D] | @csv' dividend-history-${stockcode}.json >> dividend-history-${stockcode}.csv

cp dividend-history-${stockcode}.csv ~/Library/Mobile\ Documents/com~apple~Numbers/Documents/Stock-Data/

echo 
echo "open csv file use: open -a \"Numbers\" dividend-history-${stockcode}.csv"
echo
open -a "Numbers" ~/Library/Mobile\ Documents/com~apple~Numbers/Documents/Stock-Data/dividend-history-${stockcode}.csv

