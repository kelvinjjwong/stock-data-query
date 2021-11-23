#!/bin/bash
config_file=~/stock-data/config.yaml

mkdir -p ~/Library/Mobile\ Documents/com~apple~Numbers/Documents/Stock-Data/historic

if [[ ! -e ~/stock-data ]]; then
   mkdir -p ~/stock-data
fi
cd ~/stock-data/

mac_arch=`uname -m`
if [[ ${mac_arch} = "i386" ]]; then
	JQ=/usr/local/bin/jq
	YQ=/usr/local/bin/yq
elif [[ ${mac_arch} = "arm64" ]]; then
	JQ=/opt/homebrew/bin/jq
	YQ=/opt/homebrew/bin/yq
else
	JQ=jq
	YQ=yq
fi

if [[ ! -e $config_file ]]; then
  touch $config_file
fi

FILTER=`$YQ e '.selected.stockcode | join("|")' $config_file`

echo "jq is required. to install, run: brew install jq"
echo "see records.csv for result"
echo

curl 'https://www.jisilu.cn/data/stock/dividend_rate_list/?___jsl=LST' -o records-latest.json

printf '%s\n' "code,name,price,dividend_rate,dividend_rate_static,dividend_rate_5y,dividend_rate_average,date,time,industry" > selection-latest.csv

$JQ -r '.rows[] | [.id, .cell.stock_nm, .cell.price, .cell.dividend_rate, .cell.dividend_rate2, .cell.dividend_rate5, .cell.dividend_rate_average, .cell.last_dt, .cell.last_time, .cell.industry_nm] | @csv' records-latest.json | egrep "$FILTER" >> selection-latest.csv

lines=`wc -l selection-latest.csv | awk -F' ' '{print $1}'`
if [[ $lines -lt 2 ]]; then
   exit 1;
fi

filename=prices-selection-`date '+%Y-%m-%d_%H-%M-%S'`.csv
cp selection-latest.csv $filename
cp $filename ~/Library/Mobile\ Documents/com~apple~Numbers/Documents/Stock-Data/historic/
cp selection-latest.csv ~/Library/Mobile\ Documents/com~apple~Numbers/Documents/Stock-Data/selection-latest.csv

echo 
echo "open csv file use: open -a \"Numbers\" selection-latest.csv"
echo
open -a "Numbers" ~/Library/Mobile\ Documents/com~apple~Numbers/Documents/Stock-Data/historic/$filename

