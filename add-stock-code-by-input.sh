#!/bin/bash

config_file=~/stock-data/config.yaml

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
