#!/bin/bash

target_folder=~/Library/Scripts/Stock-Data
config_file=~/stock-data/config.yaml

if [[ ! -e $target_folder ]]; then
  echo "Open Script Editor -> Preference -> General -> Show Script menu in menu bar"
  mkdir -p $target_folder
fi

if [[ ! -e $config_file ]]; then
  touch $config_file
  yq e -i '.query.dividend-history[0] = 600000' $config_file
  echo "You can configure in $config_file"
fi


cp ./query-stocks-by-dividend-rate.sh $target_folder/

yq e '.query.dividend-history[]' $config_file | while read code;
do
  cp ./query-dividend-history.sh $target_folder/query-dividend-history.${code}.sh
done

echo "copied to $target_folder"
  
