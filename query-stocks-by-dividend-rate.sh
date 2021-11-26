#!/bin/bash

data_folder=~/stock-data
config_folder=~/stock-data/config
template_folder=~/stock-data/template
historic_folder=~/stock-data/historic
icloud_data=~/Library/Mobile\ Documents/com~apple~Numbers/Documents/Stock-Data
icloud_historic=$icloud_data/historic

config_file=$config_folder/config.yaml
application_config=$config_folder/application.yaml

mkdir -p ~/Library/Mobile\ Documents/com~apple~Numbers/Documents/Stock-Data/historic

mkdir -p $data_folder
mkdir -p $config_folder
mkdir -p $template_folder
mkdir -p $historic_folder

cd $data_folder

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

echo "jq is required. to install, run: brew install jq"
echo "see records.csv for result"
echo

echo > $data_folder/curl.out
curl 'https://www.jisilu.cn/data/stock/dividend_rate_list/?___jsl=LST' -o records-latest.json 2>$data_folder/curl.out
CURL_OUT=`cat $data_folder/curl.out | tail -1`
if [[ $CURL_OUT != "" ]] && [[ $CURL_OUT = curl* ]]; then
  echo $CURL_OUT

osascript <<EOD
display notification "$CURL_OUT" with title "Stock Data" subtitle "Unable to access jisilu.cn" sound name "Frog"
EOD
  exit 1;

fi

printf '%s\n' "code,name,price,dividend_rate,dividend_rate_static,dividend_rate_5y,dividend_rate_average,date,time,industry" > records-latest.csv

$JQ -r '.rows[] | [.id, .cell.stock_nm, .cell.price, .cell.dividend_rate, .cell.dividend_rate2, .cell.dividend_rate5, .cell.dividend_rate_average, .cell.last_dt, .cell.last_time, .cell.industry_nm] | @csv' records-latest.json >> records-latest.csv

lines=`wc -l records-latest.csv | awk -F' ' '{print $1}'`
if [[ $lines -lt 2 ]]; then
   exit 1;
fi

langs=(`defaults read NSGlobalDomain AppleLanguages`);
lang=`echo ${langs[1]/,/} | sed -e 's/\"//g'  | awk -F'-' '{print $1}'`
if [[ "$lang" != "zh" ]]; then
  lang=en
fi

LANG_PRICES=`$YQ e ".translation.output.prices.$lang" $application_config`
LANG_SELECTION=`$YQ e ".translation.output.selection.$lang" $application_config`
LANG_DATE=`$YQ e ".translation.output.date.$lang" $application_config`
LANG_LATEST=`$YQ e ".translation.output.latest.$lang" $application_config`

filename=${LANG_PRICES}-`date "+${LANG_DATE}"`.csv
cp records-latest.csv $filename
cp $filename ~/Library/Mobile\ Documents/com~apple~Numbers/Documents/Stock-Data/historic/$filename
cp records-latest.csv ~/Library/Mobile\ Documents/com~apple~Numbers/Documents/Stock-Data/${LANG_PRICES}-${LANG_LATEST}.csv

echo 
echo "open csv file use: open -a \"Numbers\" records-latest.csv"
echo
open -a "Numbers" ~/Library/Mobile\ Documents/com~apple~Numbers/Documents/Stock-Data/historic/$filename

