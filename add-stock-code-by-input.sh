#!/bin/bash

data_folder=~/stock-data
config_folder=~/stock-data/config
template_folder=~/stock-data/template
historic_folder=~/stock-data/historic
target_folder=~/Library/Scripts/Stock-Data

config_file=$config_folder/config.yaml
application_config=$config_folder/application.yaml

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

AS_OUTPUT="$(osascript <<EOD
  set theResponse to display dialog "Stock code?" default answer "" with icon note buttons {"Cancel", "Continue"} default button "Continue"
--> {button returned:"Continue", text returned:"Jen"}
EOD
2>&1)"
OUTPUT=`echo "$AS_OUTPUT" | sed -e 's/, text returned:/\\ntext returned:/g' -e 's/ returned:/:/g'`
CLICKED_BUTTON=`echo "$OUTPUT" | grep "button:" | awk -F':' '{print $2}' | xargs`
INPUT_TEXT=`echo "$OUTPUT" | grep "text:" | awk -F':' '{print $2}' | xargs`

if [[ "$CLICKED_BUTTON" = "Cancel" ]]; then
	exit 0;
fi

echo "user input: $INPUT_TEXT"

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
