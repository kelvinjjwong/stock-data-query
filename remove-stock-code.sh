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

CODES=`$YQ e '.selected.stockcode[]' $config_file | sort | tr '\n' ',' | sed -e 's/,/\",\"/g' `
if [[ "$CODES" = "" ]]; then

osascript <<EOD
display notification "$config_file" with title "Stock Data" subtitle "No stock code configured." sound name "Frog"
EOD
	exit 1;
fi
if [[ $CODES = *,\" ]]; then
	CODES=`echo "$CODES" | rev | cut -c 4- | rev`
fi
CODES="\"$CODES\""

echo "$CODES"

AS_OUTPUT="$(osascript <<EOD
  set theFruitChoices to {$CODES}
set theFavoriteFruit to choose from list theFruitChoices with prompt "Select a stock code to remove:" default items {}
theFavoriteFruit
EOD
2>&1)"
INPUT_TEXT=`echo "$AS_OUTPUT" | xargs`

echo "user input: $INPUT_TEXT"

if [[ "$INPUT_TEXT" = "false" ]]; then
	exit 0;
fi

$YQ e -i ".selected.stockcode -= [$INPUT_TEXT]" $config_file

langs=(`defaults read NSGlobalDomain AppleLanguages`);
lang=`echo ${langs[1]/,/} | sed -e 's/\"//g'  | awk -F'-' '{print $1}'`
if [[ "$lang" != "zh" ]]; then
  lang=end
fi

echo "language=$lang"

FILE_QUERY_DIVIDEND_HISTORY=`$YQ e ".translation.script.query-dividend-history.$lang" $application_config`

rm -f $target_folder/$FILE_QUERY_DIVIDEND_HISTORY.${INPUT_TEXT}*

echo "Removed stock code $INPUT_TEXT"

osascript <<EOD
display notification "$config_file" with title "Stock Data" subtitle "Removed stock code $INPUT_TEXT" sound name "Frog"
EOD
