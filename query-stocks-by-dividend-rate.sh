#!/bin/bash
if [[ ! -e ~/stock-data ]]; then
   mkdir -p ~/stock-data
fi
cd ~/stock-data/
echo "jq is required. to install, run: brew install jq"
echo "see records.csv for result"
echo
curl 'https://www.jisilu.cn/data/stock/dividend_rate_list/?___jsl=LST' -o records-latest.json
printf '%s\n' "code,name,price,dividend_rate,dividend_rate_static,dividend_rate_5y,dividend_rate_average,date,time,industry" > records-latest.csv
/usr/local/bin/jq -r '.rows[] | [.id, .cell.stock_nm, .cell.price, .cell.dividend_rate, .cell.dividend_rate2, .cell.dividend_rate5, .cell.dividend_rate_average, .cell.last_dt, .cell.last_time, .cell.industry_nm] | @csv' records-latest.json >> records-latest.csv
lines=`wc -l records-latest.csv | awk -F' ' '{print $1}'`
if [[ $lines -lt 2 ]]; then
   exit 1;
fi
filename=prices-`date '+%Y-%m-%d_%H-%M-%S'`.csv
cp records-latest.csv $filename
cp $filename ~/Library/Mobile\ Documents/com~apple~Numbers/Documents
cp records-latest.csv ~/Library/Mobile\ Documents/com~apple~Numbers/Documents/prices-latest.csv
echo 
echo "open csv file use: open -a \"Numbers\" records-latest.csv"
echo
open -a "Numbers" ~/Library/Mobile\ Documents/com~apple~Numbers/Documents/$filename

