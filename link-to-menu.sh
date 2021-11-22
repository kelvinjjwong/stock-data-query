if [[ ! -e ~/Library/Scripts/Stock-Data ]]; then
  echo "Open Script Editor -> Preference -> General -> Show Script menu in menu bar"
  mkdir -p ~/Library/Scripts/Stock-Data
fi
cp ./query-stocks-by-dividend-rate.sh ~/Library/Scripts/Stock-Data/
echo "copied to ~/Library/Scripts/Stock-Data/"
  
