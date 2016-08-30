#!/bin/bash

plistpath="./picsart-Info.plist"

git checkout live;
git pull;

versioncode=$(cat "$plistpath" | grep "CFBundleVersion" -A 1 | grep "[0-9]" | tr "<string/> " " " | tr -d '[:space:]');
echo "version code is $versioncode"
versionstring=$(cat "$plistpath" | grep "CFBundleShortVersionString" -A 1 | grep "[0-9.]" | tr "<string/> " " " | tr -d '[:space:]')
echo "version string is $versionstring"


git tag $versionstring;
git push --tags;
params="{\"tag_name\": \"$versionstring\", \"target_commitish\": \"live\", \"name\": \"$versionstring\", \"body\": \"$1\" }"
echo "params are $params"
curl -i -X POST https://api.github.com/repos/hovox/downloading-file-example/releases?access_token=66580f935a3d0f0c513a86fb67c5a9cccf577cb4 -d "$params" > /tmp/result.txt;
stt=$(cat /tmp/result.txt | grep "Status: 201 Created" | tr -d '\r' | tr -d '\n');

echo "$stt"


if [ "$stt" != "Status: 201 Created" ]; then
        (>&2 echo "failed to create release on github $stt"); exit -1;
fi;
git checkout release;
git pull;

versioncode2=$(cat "$plistpath" | grep "CFBundleVersion" -A 1 | grep "[0-9]" | tr "<string/> " " " | tr -d '[:space:]');
versionstring2=$(cat "$plistpath" | grep "CFBundleShortVersionString" -A 1 | grep "[0-9.]" | tr "<string/> " " " | tr -d '[:space:]')

if [ ! "$2" = "$versioncode2" ] || [ ! "$3" = "$versionstring2" ]; then
        (>&2 echo "argument mismatch"); exit -1;
fi;

git merge live;
git checkout live;
git merge release;
git push;