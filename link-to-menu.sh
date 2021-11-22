target_folder=~/Library/Scripts/Stock-Data
if [[ ! -e $target_folder ]]; then
  echo "Open Script Editor -> Preference -> General -> Show Script menu in menu bar"
  mkdir -p $target_folder
fi
cp ./query-stocks-by-dividend-rate.sh $target_folder/
cp ./query-dividend-history.sh $target_folder/query-dividend-history.601006.sh
cp ./query-dividend-history.sh $target_folder/query-dividend-history.600028.sh
cp ./query-dividend-history.sh $target_folder/query-dividend-history.601328.sh
echo "copied to $target_folder"
  
