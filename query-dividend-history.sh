#!/bin/bash

data_folder=~/stock-data
config_folder=~/stock-data/config
template_folder=~/stock-data/template
historic_folder=~/stock-data/historic
icloud_data=~/Library/Mobile\ Documents/com~apple~Numbers/Documents/Stock-Data
icloud_historic=$icloud_data/historic

secret_properties=$config_folder/secret.properties
application_config=$config_folder/application.yaml

stockcode="601006"
startdate="19950101"
enddate="`date '+%Y'`1231"

mac_arch=`uname -m`
if [[ ${mac_arch} = "i386" ]] || [[ ${mac_arch} = "x86_64" ]]; then
  JQ=/usr/local/bin/jq
  YQ=/usr/local/bin/yq
elif [[ ${mac_arch} = "arm64" ]]; then
  JQ=/opt/homebrew/bin/jq
  YQ=/opt/homebrew/bin/yq
else
  JQ=jq
  YQ=yq
fi

langs=(`defaults read NSGlobalDomain AppleLanguages`);
lang=`echo ${langs[1]/,/} | sed -e 's/\"//g'  | awk -F'-' '{print $1}'`
if [[ "$lang" != "zh" ]]; then
  lang=en
fi

LANG_DIVIDEND_HISTORTY=`$YQ e ".translation.output.dividend-history.$lang" $application_config`

if [[ $0 == *.sh ]]; then
    _stockcode=`echo $0 | awk -F'.' '{print $(NF-1)}'`
else
    _stockcode=`echo $0 | awk -F'.' '{print $NF}'`
fi

if [[ ${_stockcode} != *query-dividend-history ]] && [[ ${_stockcode} != *${LANG_DIVIDEND_HISTORTY} ]]; then
	stockcode=$_stockcode
fi

echo "stockcode: $stockcode"

mkdir -p ~/Library/Mobile\ Documents/com~apple~Numbers/Documents/Stock-Data/historic

if [[ ! -e $data_folder ]]; then
   mkdir -p $data_folder
fi
cd $data_folder


if [[ ! -e ${secret_properties} ]]; then
    touch ${secret_properties}
    echo "api_cninfo_access_key=" >> ${secret_properties}
    echo "api_cninfo_access_secret=" >> ${secret_properties}
fi
source $secret_properties
if [[ "${api_cninfo_access_key}" = "" ]]; then
    echo "api_cninfo_access_key not cofigured in ${secret_properties}"

osascript <<EOD
display notification "$secret_properties" with title "Stock Data" subtitle "api_cninfo_access_key not configured" sound name "Frog"
EOD

    exit 1
fi
if [[ "${api_cninfo_access_secret}" = "" ]]; then
    echo "api_cninfo_access_secret not cofigured in ${secret_properties}"

osascript <<EOD
display notification "$secret_properties" with title "Stock Data" subtitle "api_cninfo_access_secret not configured" sound name "Frog"
EOD

    exit 1
fi


echo "jq is required. to install, run: brew install jq"
echo

curl --location --request POST 'http://webapi.cninfo.com.cn/api-cloud-platform/oauth2/token?grant_type=client_credentials' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-raw "grant_type=client_credentials&client_id=${api_cninfo_access_key}&client_secret=${api_cninfo_access_secret}" \
-o $config_folder/cninfo-key-latest.json

token=`$JQ -r '[.access_token] | @csv' $config_folder/cninfo-key-latest.json | sed -e 's/\"//g'`

curl --location --request GET "http://webapi.cninfo.com.cn/api/stock/p_stock2201?scode=${stockcode}&sdate=${startdate}&edate=${enddate}&state=1&access_token=${token}" -o dividend-history-${stockcode}.json

printf '%s\n' "code,name,term,doc,giftshare_per_10share,addshare_per_10share,int_per_10share,cutoff_date,reg_date,exit_right_date,int_date" > dividend-history-${stockcode}.csv

$JQ -r '.records[] | [.SECCODE, .SECNAME, .F044V, .F036V, .F010N, .F011N, .F012N, .F001D, .F018D, .F020D, .F023D] | @csv' dividend-history-${stockcode}.json >> dividend-history-${stockcode}.csv

FILENAME=${LANG_DIVIDEND_HISTORTY}-${stockcode}.csv

cp dividend-history-${stockcode}.csv ~/Library/Mobile\ Documents/com~apple~Numbers/Documents/Stock-Data/$FILENAME

echo 
echo "open csv file use: open -a \"Numbers\" dividend-history-${stockcode}.csv"
echo
open -a "Numbers" ~/Library/Mobile\ Documents/com~apple~Numbers/Documents/Stock-Data/$FILENAME

