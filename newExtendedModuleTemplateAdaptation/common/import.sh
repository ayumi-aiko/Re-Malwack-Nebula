#!/system/bin/sh
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

# Note from ZG089: All respect for the developers of the mentioned modules/apps in this script.
# Note from bocchi-the-dev: PLEASE DON'T LOOK AT THIS AND THINK THAT IM WRITING JUKNS WITHOUT KNOWING ANYTHING! IM NOT DOING THIS ON PURPOSE AND THIS IS JUST A RE-WRITE I SWEAR TO SATAN OH MY LORD!


# gbl variables:
persistentDirectory="/data/adb/Re-Malwack"
adawayJSON="/sdcard/Download/adaway-backup.json"
importedAdAway=false
bindhostsPersistentDirectory="/data/adb/bindhosts"
bindhostsSources="$bindhostsPersistentDirectory/sources.txt"
destSources="$persistentDirectory/sources.txt"

# helper functions:
function bindhostsImportLists() {
    local listType="$1" mode="$2" sourceD="$bindhosts/$listType.txt" destD="$persistentDirectory/$listType.txt"
    [ ! -f "${sourceD}" ] && return 1;
    if grep -vq '^[[:space:]]*#' "$sourceD" && grep -vq '^[[:space:]]*$' "$sourceD"; then
        consolePrint "- Detected $listType file with entries..."
        case "$mode" in
            replace) 
                sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$sourceD" > "$destD"
            ;;
            merge)
                sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$sourceD" >> "$destD"
            ;;
        esac
    fi
}

function dedupFile() {
    local file="$@"
    for i in $file; do
        [ -f "$i" ] || continue;
        awk '!seen[$0]++' "$i" > "$i.tmp" && mv "$i.tmp" "$i"
    done
}

# import adaway contents if there's an backup file found.
if [ -f "${adawayJSON}" ]; then
    sourcesFile="${persistentDirectory}/sources.txt"
    whitelistFile="${persistentDirectory}/whitelist.txt"
    blocklistFile="${persistentDirectory}/blacklist.txt"
    tempSources="${persistentDirectory}/tmp.sources.$$"
    tempWhitelists="${persistentDirectory}/tmp.white.$$"
    tempBlocklists="${persistentDirectory}/tmp.black.$$"
    sourcesCount=0
    whitelistCount=0
    blocklistCount=0
    consolePrint "- AdAway backup file has been found!"
    consolePrint "  Importing whitelists, blocklists and sources are the supported options."
    consolePrint " "
    consolePrint "- Volume key options:"
    consolePrint "  1 - Yes, but use AdAway setup and replace it with default sources"
    consolePrint "  2 - Yes, but also merge AdAway setup with default sources [RECOMMENDED]"
    consolePrint "  3 - No, don't import."
    consolePrint " "
    recoveryAhhSelection 3
    case "${icrmntval}" in
        1)
            consolePrint "- Applying AdAway setup.."
            : > "$sourcesFile"
            : > "$whitelistFile"
            : > "$blocklistFile"
        ;;
        2)
            consolePrint "- Merging AdAway setup.."
        ;;
        3)
            consolePrint "- Skipped AdAway import.."
        ;;
    esac

    # Import enabled sources
    ${modulePath}/bin/${archPath}/jq -r '.sources[] | select(.enabled == true) | .url' "$adawayJSON" > "$tempSources"
    while IFS= read -r url; do
        [ -n "$url" ] || continue
        if ! grep -Fqx "$url" "$sourcesFile"; then
            echo "$url" >> "$sourcesFile"
            sourcesCount=$((sourcesCount + 1))
        fi
    done < "$tempSources"
    rm -f "$tempSources"

    # Import enabled whitelist
    ${modulePath}/bin/${archPath}/jq -r '.allowed[] | select(.enabled == true) | .host' "$adawayJSON" > "$tempWhitelists"
    while IFS= read -r domain; do
        [ -n "$domain" ] || continue
        if ! grep -Fqx "$domain" "$whitelistFile"; then
            echo "$domain" >> "$whitelistFile"
            whitelistCount=$((whitelistCount + 1))
        fi
    done < "$tempWhitelists"
    rm -f "$tempWhitelists"

    # Import enabled blacklist
    ${modulePath}/bin/${archPath}/jq -r '.blocked[] | select(.enabled == true) | .host' "$adawayJSON" > "$tempBlocklists"
    while IFS= read -r domain; do
        [ -n "$domain" ] || continue
        if ! grep -Fqx "$domain" "$blocklistFile"; then
            echo "$domain" >> "$blocklistFile"
            blocklistCount=$((blocklistCount + 1))
        fi
    done < "$tempBlocklists"
    rm -f "$tempBlocklists"

    # bruh
    consolePrint "  AdAway import completed."
    consolePrint "  Imported: $sourcesCount sources, $whitelistCount whitelist entries, $blocklistCount blacklist entries."
    importedAdAway=true
fi

# Detect other modules and run imports (only if not already imported)
for modules in /data/adb/modules/*; do
    moduleKID="$(grep_prop id "${modules}/module.prop")"
    moduleKName="$(grep_prop name "${modules}/module.prop")"
    # skip if we got into our own module or any other module that 
    # is disabled already.
    if [ "${moduleKID}" == "Re-Malwack" ] || [ -f "/data/adb/modules/$moduleKID/disable" ] || [ ! -f "/data/adb/modules/$moduleKID/system/etc/hosts" ]; then
        continue;
    fi
    # force disable systemless hosts module
    [ "$moduleKID" = "hosts" ] && touch /data/adb/modules/hosts/disable
    [ "${moduleKName}" == "bindhosts|cubic-adblock|StevenBlock" ] || consolePrint "  Cannot import sources from ${moduleKName}, this module is unsupported!"
    if "${importedAdAway}" && ask "- $moduleKName detected, press volume + (UP) to import it's setup!"; then
        case "${moduleKID}" in
            bindhosts)
                blocklistCount=0
                whitelistCount=0
                sourcesCount=0
                consolePrint "- How do you want to import your bindhosts setup?"
                consolePrint "  Importing whitelists, blocklists and sources are the supported options."
                consolePrint " "
                consolePrint "- Volume key options:"
                consolePrint "  1 - Import, but use bindhosts setup and replace it with default sources"
                consolePrint "  2 - Import, but also merge bindhosts setup with default sources [RECOMMENDED]"
                consolePrint "  3 - No, don't import."
                consolePrint " "
                recoveryAhhSelection 3
                case "${icrmntval}" in
                    1)
                        consolePrint "- Replacing Re-Malwack setup with bindhosts setup..."
                        echo " " > "${destSources}"
                        sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$bindhostsSources" > "$destSources"
                        sourcesCount=$(grep -c "$destSources")
                        bindhostsImportLists whitelist replace && whitelistCount=$(wc -l < "$persistentDirectory/whitelist.txt")
                        bindhostsImportLists blacklist replace && blocklistCount=$(wc -l < "$persistentDirectory/blacklist.txt")
                        consolePrint "  Bindhosts setup imported successfully."
                        consolePrint "  Imported: $sourcesCount sources, $whitelistCount whitelist entries, $blocklistCount blacklist entries."
                    ;;
                    2)
                        consolePrint "- Merging bindhosts setup.."
                        grep -Ev '^[[:space:]]*#|^[[:space:]]*$' "$bindhostsSources" >> "$destSources"
                        sourcesCount=$(grep -vc '^[[:space:]]*#|^[[:space:]]*$' "$bindhostsSources")
                        bindhostsImportLists whitelist merge && whitelistCount=$(wc -l < "$persistentDirectory/whitelist.txt")
                        bindhostsImportLists blacklist merge && blocklistCount=$(wc -l < "$persistentDirectory/blacklist.txt")
                        consolePrint "  Bindhosts setup imported successfully."
                        consolePrint "  Imported: $sourcesCount sources, $whitelistCount whitelist entries, $blocklistCount blacklist entries."
                    ;;
                    3)
                        consolePrint "- Skipped AdAway import.."
                    ;;
                esac
            ;;
            cubic-adblock)
                # destSources -> src_file
                consolePrint "- How do you want to import your cubic-adblock setup?"
                consolePrint "  Importing whitelists, blocklists and sources are the supported options."
                consolePrint " "
                consolePrint "- Volume key options:"
                consolePrint "  1 - Import, but use cubic-adblock setup and replace it with default sources"
                consolePrint "  2 - Import, but also merge cubic-adblock setup with default sources [RECOMMENDED]"
                consolePrint "  3 - No, don't import."
                consolePrint " "
                recoveryAhhSelection 3
                # WHAT THE HELL IS THIS EVEN FOR ZG? I SWEAR!
                case "${icrmntval}" in
                    1)
                        consolePrint "- Replacing Re-Malwack setup with bindhosts setup..."
                    ;;
                    2)
                        consolePrint "- Merging bindhosts setup.."
                    ;;
                    3)
                        consolePrint "- Skipped AdAway import.."
                        continue;
                    ;;
                esac
                # replace Hagezi pro with ultimate
                if grep -q 'https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro.txt' "$destSources"; then
                    consolePrint "- Replacing Hagezi Pro Plus hosts with Ultimate version..."
                    sed -i 's|https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro.txt|https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/ultimate.txt|' "$destSources"
                fi

                # replace 1Hosts Lite with Pro
                if grep -q 'https://badmojr.github.io/1Hosts/Lite/hosts.txt' "$destSources"; then
                    consolePrint "- Replacing 1Hosts Lite hosts with Pro version..."
                    sed -i 's|https://badmojr.github.io/1Hosts/Lite/hosts.txt|https://badmojr.github.io/1Hosts/Pro/hosts.txt|' "$destSources"
                fi

                # cubic-adblock sources
                while IFS= read -r url; do
                    [ -z "$url" ] && continue
                    if grep -Fq "$url" "$destSources"; then
                        consolePrint "  Skipped (already present): $url"
                        skipped=$((skipped + 1))
                    else
                        echo "$url" >> "$destSources"
                        consolePrint "  Imported: $url"
                        sourcesAdded=$((sourcesAdded + 1))
                    fi
                done <<EOF
https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
https://gitlab.com/quidsup/notrack-blocklists/-/raw/master/malware.hosts?ref_type=heads
https://gitlab.com/quidsup/notrack-blocklists/-/raw/master/trackers.hosts?ref_type=heads
https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Hosts/GoodbyeAds.txt
https://pgl.yoyo.org/adservers/serverlist.php?showintro=0;hostformat=hosts
https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/ultimate.txt
https://badmojr.github.io/1Hosts/Pro/hosts.txt
EOF
                consolePrint "  Cubic-Adblock import completed."
                consolePrint "  Imported: $sourcesAdded sources, skipped $skipped entries, total: $((sourcesAdded + skipped))."
            ;;
            StevenBlock)
                consolePrint "  StevenBlock sources are already included in this module, skipping it's import..."
            ;;
        esac
    else
        consolePrint "  Skipped import from $moduleKName."
    fi
    # Always disable module, even if already imported
    consolePrint "- Disabling: $moduleKName"
    touch "/data/adb/modules/$moduleKID/disable"
done

# Dedup everything at the end just in case
dedupFile ${persistentDirectory}/{sources,whitelist,blacklist}.txt