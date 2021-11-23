#!/bin/bash

config_file=~/stock-data/config.yaml
data_file=~/stock-data/records-latest.csv

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

if [[ ! -e $data_file ]]; then

  curl 'https://www.jisilu.cn/data/stock/dividend_rate_list/?___jsl=LST' -o records-latest.json
  printf '%s\n' "code,name,price,dividend_rate,dividend_rate_static,dividend_rate_5y,dividend_rate_average,date,time,industry" > records-latest.csv
  $JQ -r '.rows[] | [.id, .cell.stock_nm, .cell.price, .cell.dividend_rate, .cell.dividend_rate2, .cell.dividend_rate5, .cell.dividend_rate_average, .cell.last_dt, .cell.last_time, .cell.industry_nm] | @csv' records-latest.json >> records-latest.csv

fi


if [[ ! -e $data_file ]]; then

osascript <<EOD
display notification "$data_file" with title "Stock Data" subtitle "Failed to get stock codes and prices" sound name "Frog"
EOD
exit 1;

fi

CODES=`cat $data_file | awk -F',' '{print $1","$2}' | tail -n +2 | sed -e 's/","/,/g' | sort | tr '\n' ','`

if [[ "$CODES" = *, ]]; then
  CODES=`echo "$CODES" | rev | cut -c 2- | rev`
fi

AS_OUTPUT="$(osascript <<EOD
  set theFruitChoices to {$CODES}
set theFavoriteFruit to choose from list theFruitChoices with prompt "Select your stock code:" default items {}
theFavoriteFruit
EOD
2>&1)"
INPUT_TEXT=`echo "$AS_OUTPUT" | xargs`

echo "user input: $INPUT_TEXT"

if [[ "$INPUT_TEXT" = "false" ]]; then
	exit 0;
fi

INPUT_TEXT=`echo "$INPUT_TEXT" | awk -F',' '{print $1}' `
INPUT_NAME=`echo "$INPUT_TEXT" | awk -F',' '{print $2}' `


if [[ ! -e $config_file ]]; then
  touch $config_file
  yq e -i ".selected.stockcode[0] = $INPUT_TEXT" $config_file
else
  LENGTH=`yq e '.selected.stockcode | length' $config_file`
  if [[ "$LENGTH" = "" ]] || [[ "$LENGTH" = "0" ]]; then
  	yq e -i ".selected.stockcode[0] = $INPUT_TEXT" $config_file
  else
  	CONTAINS=`yq e ".selected.stockcode | contains([$INPUT_TEXT])" $config_file`
  	if [[ "$CONTAINS" = "true" ]]; then

osascript <<EOD
display notification "$config_file" with title "Stock Data" subtitle "Already exists stock code $INPUT_TEXT" sound name "Frog"
EOD
		exit 0
  	else
  		yq e -i ".selected.stockcode[$LENGTH] = $INPUT_TEXT" $config_file
  	fi
  fi
fi

MSG="Added stock code $INPUT_TEXT to $config_file"
echo $MSG
cat $config_file

osascript <<EOD
display notification "$config_file" with title "Stock Data" subtitle "Added stock code $INPUT_TEXT" sound name "Frog"
EOD
