#!/bin/bash

git checkout live;
git pull;

versioncode=$(cat ./picsart/supporting_files/picsart-Info.plist | grep "CFBundleVersion" -A 1 | grep "[0-9]" | tr "<string/> " " " | tr -d '[:space:]');
versionstring=$(cat ./picsart/supporting_files/picsart-Info.plist | grep "CFBundleShortVersionString" -A 1 | grep "[0-9.]" | tr "<string/> " " " | tr -d '[:space:]')

git tag $versionstring;
git push --tags;
curl -X POST https://api.github.com/repos/PicsArt/picsart-ios/releases -d '{"tag_name": $versionstring, "target_commitish": "live", "name": $versionstring, "body": $1 }' > /tmp/result.txt;
status = $(cat /tmp/result.txt | grep "Status: 201");
if [ ! "$status" = 'Status: 201 Created' ]; then  
        (>&2 echo "failed to create release on github"); return -1; 
fi;
git checkout release;
git pull;

versioncode2=$(cat ./picsart/supporting_files/picsart-Info.plist | grep "CFBundleVersion" -A 1 | grep "[0-9]" | tr "<string/> " " " | tr -d '[:space:]');
versionstring2=$(cat ./picsart/supporting_files/picsart-Info.plist | grep "CFBundleShortVersionString" -A 1 | grep "[0-9.]" | tr "<string/> " " " | tr -d '[:space:]')

if [ ! "$2" = "$versioncode2" ] || [ ! "$3" = "$versionstring2" ]; then
        (>&2 echo "argument mismatch"); return -1;
fi;

git merge live;
git checkout live;
git merge release;
git push;