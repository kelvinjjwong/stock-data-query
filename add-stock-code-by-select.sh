#!/bin/bash

data_folder=~/stock-data
config_folder=~/stock-data/config
template_folder=~/stock-data/template
historic_folder=~/stock-data/historic
target_folder=~/Library/Scripts/Stock-Data

config_file=$config_folder/config.yaml
application_config=$config_folder/application.yaml
data_file_json=$data_folder/records-latest.json
data_file=$data_folder/records-latest.csv

if [[ ! -e $data_folder ]]; then
   mkdir -p $data_folder
fi
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

curl 'https://www.jisilu.cn/data/stock/dividend_rate_list/?___jsl=LST' -o $data_file_json
printf '%s\n' "code,name,price,dividend_rate,dividend_rate_static,dividend_rate_5y,dividend_rate_average,date,time,industry" > $data_file
$JQ -r '.rows[] | [.id, .cell.stock_nm, .cell.price, .cell.dividend_rate, .cell.dividend_rate2, .cell.dividend_rate5, .cell.dividend_rate_average, .cell.last_dt, .cell.last_time, .cell.industry_nm] | @csv' $data_file_json >> $data_file


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
  $YQ e -i ".selected.stockcode += [$INPUT_TEXT]" $config_file
else
  LENGTH=`yq e '.selected.stockcode | length' $config_file`
  if [[ "$LENGTH" = "" ]] || [[ "$LENGTH" = "0" ]]; then
  	$YQ e -i ".selected.stockcode += [$INPUT_TEXT]" $config_file
  else
  	CONTAINS=`yq e ".selected.stockcode | contains([$INPUT_TEXT])" $config_file`
  	if [[ "$CONTAINS" = "true" ]]; then

osascript <<EOD
display notification "$config_file" with title "Stock Data" subtitle "Already exists stock code $INPUT_TEXT" sound name "Frog"
EOD
		exit 0
  	else
  		$YQ e -i ".selected.stockcode += [$INPUT_TEXT]" $config_file
  	fi
  fi
fi

MSG="Added stock code $INPUT_TEXT to $config_file"
echo $MSG
cat $config_file

langs=(`defaults read NSGlobalDomain AppleLanguages`);
lang=`echo ${langs[1]/,/} | sed -e 's/\"//g'  | awk -F'-' '{print $1}'`
if [[ "$lang" != "zh" ]]; then
  lang=en
fi

echo "language=$lang"

FILE_QUERY_DIVIDEND_HISTORY=`$YQ e ".translation.script.query-dividend-history.$lang" $application_config`

rm -f $target_folder/${FILE_QUERY_DIVIDEND_HISTORY}.*

$YQ e '.selected.stockcode[]' $config_file | while read code;
do
  echo "copy template for $code"
  cp $template_folder/query-dividend-history.sh $target_folder/$FILE_QUERY_DIVIDEND_HISTORY.${code}
done

osascript <<EOD
display notification "$config_file" with title "Stock Data" subtitle "Added stock code $INPUT_TEXT" sound name "Frog"
EOD
