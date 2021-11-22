Bash shell scripts to query China stock market data

Target environment: macOS

### Requirement

jq is required for JSON extraction. To install, run: 

```
brew install jq
```

### Usage

1. Use link-to-menu.sh to copy scripts to Script Editor's user library folder
2. Open Script Editor -> Preference -> General, select "Show Script menu in menu bar"
3. Run script from "Script Editor" sub-menu in menu bar


### Output

1. CSV file will be produced
2. CSV file will be copied to iCloud / Numbers folder
3. CSV file will be opened by Numbers


### Configuration

#### config.yaml

config.yaml will be loaded from

```
~/stock-data/config.yaml
```

#### Sample configuration 

- For link-to-menu.sh to dispatch scripts

```
query:
  dividend-history: [
    code1,
    code2,
    code3
  ]
```

Accordingly, following scripts will be created in Script Editor's user library folder:

```
query-dividend-history.code1.sh
query-dividend-history.code2.sh
query-dividend-history.code3.sh
```


#### API Keys

secret.properties will be loaded from

```
~/stock-data/secret.properties
```

Following items are expected for APIs of https://webapi.cninfo.com.cn

```
api_cninfo_access_key
api_cninfo_access_secret
```
