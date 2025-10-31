#!/usr/bin/env bash
#
# Copyright (C) 2025 ぼっち <ayumi.aiko@outlook.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# gbl vars:
nthPullFromScript=0
changes=0
baseURL="https://github.com/ZG089/Re-Malwack"
baseBranch="main"
baseModuleURL="https://raw.githubusercontent.com/ZG089/Re-Malwack/${baseBranch}/module"
latestHash=$(git ls-remote https://github.com/ZG089/Re-Malwack.git HEAD | awk '{print $1}' | cut -c 1-7)
thingsToFetchAndMergeFromOrigin=(
    "banner.png"
    "rmlwk.sh"
    "bin/armeabi-v7a/jq"
    "bin/arm64-v8a/jq"
    "common/sources.txt"
    "webroot/config.json"
    "webroot/contributors.json"
    "webroot/icon.png"
    "webroot/index.html"
    "webroot/index.js"
    "webroot/styles.css"
    "webroot/assets/kernelsu.js"
    "webroot/assets/snowflakes.png"
)
thingsToVerifyChangesFromOrigin=(
    "action.sh"
    "customize.sh"
    "import.sh"
    "post-fs-data.sh"
    "service.sh"
)
# gbl vars:

# functions:
function downloadContentFromWEB() {
    local URL="$1"
    local outputPathAndFilename="$2"
    local prevPath="$PATH"
    mkdir -p "$(dirname "$outputPathAndFilename")"
    if command -v curl >/dev/null 2>&1; then
        if ! curl -Ls "$URL" -o "$outputPathAndFilename"; then
            echo "Failed to download from $URL";
            exit 1;
        fi
    else
        if ! wget --no-check-certificate -qO "$outputPathAndFilename" "$URL"; then
            echo "Failed to download from $URL";
            exit 1;
        fi
    fi
}
# functions:

# main:
mkdir -p module/originVerify
cd module/originVerify || exit 1
for i in "${thingsToFetchAndMergeFromOrigin[@]}"; do
    downloadContentFromWEB "${baseModuleURL}/${i}" "${i}"
    if [ ! -f "../${i}" ] || ! git --no-pager diff --ignore-cr-at-eol -w --no-index "${i}" "../${i}" &>/dev/null; then
        echo "[0] - ${i} differs from base repository..."
        cp "${i}" "../${i}"
        git add "../${i}"
        ((changes += 1))
    fi
done
for j in "${thingsToVerifyChangesFromOrigin[@]}"; do
    downloadContentFromWEB "${baseModuleURL}/${j}" "${j}"
    git --no-pager diff --ignore-cr-at-eol -w --no-index "${j}" "../${j}" &>/dev/null || echo "[1] - ${j} differs from base repository..."
done
rm -rf ./*
cd ../../ || exit 1
if (( changes == 0 )); then
    echo "- No changes detected. Mirror is up to date."
else
    ((nthPullFromScript += 1))
    sed -i "s/^nthPullFromScript=.*/nthPullFromScript=${nthPullFromScript}/" ./verifyAndPullChangesFromBase.sh
    git commit -m "github-actions: Sync ${latestHash} into Nebula's mirror (#${nthPullFromScript})"
    git push -u origin main &>/dev/null
fi
# main: