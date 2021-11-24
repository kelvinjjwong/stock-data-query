#!/bin/bash

target_folder=~/Library/Scripts/Stock-Data
config_file=~/stock-data/config.yaml
application_config=~/stock-data/application.yaml

cp ./application.yaml ~/stock-data/

if [[ ! -e $target_folder ]]; then
  echo "Open Script Editor -> Preference -> General -> Show Script menu in menu bar"
  mkdir -p $target_folder
fi

if [[ ! -e $config_file ]]; then
  touch $config_file
  yq e -i '.query.dividend-history[0] = 600000' $config_file
  echo "You can configure in $config_file"
fi

langs=(`defaults read NSGlobalDomain AppleLanguages`);
lang=`echo ${langs[1]/,/} | sed -e 's/\"//g'  | awk -F'-' '{print $1}'`
if [[ "$lang" != "zh" ]]; then
  lang=end
fi

FILE_ADD_STOCK_BY_INPUT=`yq e ".translation.script.add-stock-code-by-input.$lang" $application_config`
FILE_ADD_STOCK_BY_SELECT=`yq e ".translation.script.add-stock-code-by-select.$lang" $application_config`
FILE_QUERY_STOCKS_BY_DIVIDED_RATE=`yq e ".translation.script.query-stocks-by-dividend-rate.$lang" $application_config`
FILE_QUERY_SELECTED_STOCKS_BY_DIVIDED_RATE=`yq e ".translation.script.query-selected-stocks-by-dividend-rate.$lang" $application_config`
FILE_QUERY_DIVIDEND_HISTORY=`yq e ".translation.script.query-dividend-history.$lang" $application_config`

cp ./add-stock-code-by-select.sh $target_folder/$FILE_ADD_STOCK_BY_SELECT
cp ./add-stock-code-by-input.sh $target_folder/$FILE_ADD_STOCK_BY_INPUT
cp ./query-stocks-by-dividend-rate.sh $target_folder/$FILE_QUERY_STOCKS_BY_DIVIDED_RATE
cp ./query-selected-stocks-by-dividend-rate.sh $target_folder/$FILE_QUERY_SELECTED_STOCKS_BY_DIVIDED_RATE

yq e '.query.dividend-history[]' $config_file | while read code;
do
  cp ./query-dividend-history.sh $target_folder/$FILE_QUERY_DIVIDEND_HISTORY.${code}
done

echo "copied to $target_folder"
  
