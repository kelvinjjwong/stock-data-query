#!/bin/bash

data_folder=~/stock-data
config_folder=~/stock-data/config
template_folder=~/stock-data/template
historic_folder=~/stock-data/historic
target_folder=~/Library/Scripts/Stock-Data

config_file=$config_folder/config.yaml
application_config=$config_folder/application.yaml


mkdir -p $config_folder
mkdir -p $template_folder
mkdir -p $historic_folder

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

cp ./application.yaml $config_folder
cp ./query-dividend-history.sh $template_folder

if [[ ! -e $target_folder ]]; then
  echo "Open Script Editor -> Preference -> General -> Show Script menu in menu bar"
  mkdir -p $target_folder
fi

if [[ ! -e $config_file ]]; then
  touch $config_file
  yq e -i '.selected.stockcode[0] = 600000' $config_file
  echo "You can configure in $config_file"
fi

langs=(`defaults read NSGlobalDomain AppleLanguages`);
lang=`echo ${langs[1]/,/} | sed -e 's/\"//g'  | awk -F'-' '{print $1}'`
if [[ "$lang" != "zh" ]]; then
  lang=en
fi

FILE_ADD_STOCK_BY_INPUT=`yq e ".translation.script.add-stock-code-by-input.$lang" $application_config`
FILE_ADD_STOCK_BY_SELECT=`yq e ".translation.script.add-stock-code-by-select.$lang" $application_config`
FILE_QUERY_STOCKS_BY_DIVIDED_RATE=`yq e ".translation.script.query-stocks-by-dividend-rate.$lang" $application_config`
FILE_QUERY_SELECTED_STOCKS_BY_DIVIDED_RATE=`yq e ".translation.script.query-selected-stocks-by-dividend-rate.$lang" $application_config`
FILE_QUERY_DIVIDEND_HISTORY=`yq e ".translation.script.query-dividend-history.$lang" $application_config`
FILE_REMOVE_STOCK_CODE=`yq e ".translation.script.remove-stock-code.$lang" $application_config`

rm -f $target_folder/*

cp ./add-stock-code-by-select.sh $target_folder/$FILE_ADD_STOCK_BY_SELECT
cp ./add-stock-code-by-input.sh $target_folder/$FILE_ADD_STOCK_BY_INPUT
cp ./query-stocks-by-dividend-rate.sh $target_folder/$FILE_QUERY_STOCKS_BY_DIVIDED_RATE
cp ./query-selected-stocks-by-dividend-rate.sh $target_folder/$FILE_QUERY_SELECTED_STOCKS_BY_DIVIDED_RATE
cp ./remove-stock-code.sh $target_folder/$FILE_REMOVE_STOCK_CODE

yq e '.selected.stockcode[]' $config_file | while read code;
do
  cp ./query-dividend-history.sh $target_folder/$FILE_QUERY_DIVIDEND_HISTORY.${code}
done

echo "copied to $target_folder"
  
