#!/system/bin/sh

# Welcome to the main script of the module :)
# Side notes: Literally everything in this module relies on this script you're checking right now.
# customize.sh (installer script), action script and even WebUI!
# Now enjoy reading the code
# - ZG089, Founder of Re-Malwack.

# global variables:
throwOneToTwo=false
persistantDirectory="/data/adb/Re-Malwack"
realPath="$(readlink -f "$0")"
moduleDirectory="$(dirname "${realPath}")"
hostsFile="$moduleDirectory/system/etc/hosts"
systemHosts="/system/etc/hosts"
tmpHosts="/data/local/tmp/hosts"
version="$(grep '^version=' "$moduleDirectory/module.prop" | cut -d= -f2-)"
thisInstanceLogFile="$persistantDirectory/logs/Re-Malwack_$(date +%Y-%m-%d_%H%M%S).log"
thisSessionLock="$persistantDirectory/lock"

# pre-setup:
mkdir -p $persistantDirectory/{logs,counts,cache/whitelist}
PREVPATH="${PATH}"
PATH="/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:/data/data/com.termux/files/usr/bin:$PREVPATH"

# get values from the config.sh file.
source "$persistantDirectory/config.sh" || . "$persistantDirectory/config.sh"

# PURE FREEAKING HEADACHEEEEEE
function rmlwkBanner() {
    [ "$throwOneToTwo" = "true" ] && return
    clear
    case "$((($(date +%s) % 2) + 1))" in
        "1")
            printf '\033[0;31m'
            printf "    ____             __  ___      __                    __            \n"
            printf "   / __ \\___        /  |/  /___ _/ /      ______ ______/ /__          \n"
            printf "  / /_/ / _ \\______/ /|_/ / __ \`/ / | /| / / __ \`/ ___/ //_/       \n"
            printf " / _, _/  __/_____/ /  / / /_/ / /| |/ |/ / /_/ / /__/ ,<              \n"
            printf "/_/ |_|\\___/     /_/  /_/\\__,_/_/ |__/|__/\\__,_/\\___/_/|_|      \n"
            printf '\033[0;31m'
            echo "================================================================"
            printf '\033[0m'
            ;;
        "2")
            printf '\033[0;31m'
            printf "██████╗ ███████╗    ███╗   ███╗ █████╗ ██╗     ██╗    ██╗ █████╗  ██████╗██╗  ██╗\n"
            printf "██╔══██╗██╔════╝    ████╗ ████║██╔══██╗██║     ██║    ██║██╔══██╗██╔════╝██║ ██╔╝\n"
            printf "██████╔╝█████╗█████╗██╔████╔██║███████║██║     ██║ █╗ ██║███████║██║     █████╔╝ \n"
            printf "██╔══██╗██╔══╝╚════╝██║╚██╔╝██║██╔══██║██║     ██║███╗██║██╔══██║██║     ██╔═██╗ \n"
            printf "██║  ██║███████╗    ██║ ╚═╝ ██║██║  ██║███████╗╚███╔███╔╝██║  ██║╚██████╗██║  ██╗\n"
            printf "╚═╝  ╚═╝╚══════╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝\n"
            printf '\033[0;31m'
            echo "===================================================================================="
            printf '\033[0m'
            ;;
    esac
    updateStatus
}
# PURE FREEAKING HEADACHEEEEEE

# helper functions:
function consoleMessage() {
    [ "${throwOneToTwo}" == "true" ] && echo "[$(date +"%m-%d-%Y %I:%M:%S %p")] $2" >> ${thisInstanceLogFile} || echo "$1"
}

function logShit() {
    echo "[$(date +"%m-%d-%Y %I:%M:%S %p")] $1" >> ${thisInstanceLogFile}
}

function abortInstance() {
    consoleMessage "$1" "$2"
    export PATH="${PREVPATH}"
    exit 1;
}

function tolower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

function loopInternetCheck() {
	local state="$1"
	local pidFile="${moduleDirectory}/pidIC"
	local flagFile="${moduleDirectory}/.internet_ok"
	if [ "$state" = "--loop" ]; then
		(
			while true; do
				if ping -c 1 -w 5 8.8.8.8 >/dev/null 2>&1; then
					echo 1 > "$flagFile"
				else
					rm -f "$flagFile"
				fi
				sleep 5
			done
		) &
		echo $! > "$pidFile"
	elif [ "$state" = "--wait" ]; then
		while [ ! -f "$flagFile" ]; do
			consoleMessage "- Internet unavailable, waiting..."
			sleep 5
		done
	elif [ "$state" = "--killLoop" ]; then
		if [ -f "$pidFile" ]; then
			kill "$(cat "$pidFile")" >/dev/null 2>&1
			rm -f "$pidFile"
		fi
		rm -f "$flagFile"
	else
		echo "Usage: loopInternetCheck [--loop | --wait | --killLoop]" >&2
		return 1
	fi
}

function fetch() {
    local output="$1" url="$2"
    if command -v curl &>/dev/null; then
        while true; do
            loopInternetCheck --wait
            if curl -Ls "$url" > "$output" 2>"$thisInstanceLogFile"; then
                echo "" >> "$output"
                break
            else
                abortInstance "- Failed to download the file, send the logs to the developer if the issue persists." "fetch(): Failed to download the file, URL=$url | download path: $output"
            fi
        done
        loopInternetCheck --killLoop
    elif command -v wget &>/dev/null; then
        while true; do
            loopInternetCheck --wait
            if wget --no-check-certificate -qO - "$url" > "$output" 2>"$thisInstanceLogFile"; then
                echo "" >> "$output"
                break
            else
                abortInstance "- Failed to download the file, send the logs to the developer if the issue persists." "fetch(): Failed to download the file, URL=$url | download path: $output"
            fi
        done
        loopInternetCheck --killLoop
    fi
}
# helper functions:

# main functions:
function isDefaultHosts() {
    [ "$blocked_mod" -eq 0 ] && [ "$blocked_sys" -eq 0 ] \
    || { [ "$blocked_mod" -eq "$blacklist_count" ] && [ "$blocked_sys" -eq "$blacklist_count" ]; }
}

function hostsFilterer() {
    local file="$1"
    [ ! -f "$file" ] && return 1;
    echo "$file" | tr '[:upper:]' '[:lower:]' | grep -q "whitelist" && return 0
    sed -i '/^[[:space:]]*#/d; s/[[:space:]]*#.*$//; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/\r$//; s/[[:space:]]\+/ /g' "$file"
}

function stageBlocklistFiles() {
    local i=1
    for file in "$persistantDirectory/cache/$1/hosts"*; do
        [ -f "$file" ] || continue
        cp -f "$file" "${tmpHosts}${i}"
        i=$((i+1))
    done
}

function installHosts() {
    consoleMessage "- Trying to fetch module repo's whitelist files.." "installHosts(): fetchin' some whitelist from the origin repo.."
    fetch "$persistantDirectory/cache/whitelist/whitelist.txt" https://raw.githubusercontent.com/ZG089/Re-Malwack/main/whitelist.txt
    fetch "$persistantDirectory/cache/whitelist/social_whitelist.txt" https://raw.githubusercontent.com/ZG089/Re-Malwack/main/social_whitelist.txt
    consoleMessage "  Starting to install $1 hosts..." "installHosts(): Installing $1 hosts.."
    cp -f "$hostsFile" "${tmpHosts}0"
    consoleMessage "  Trying to prepare blocklists.." "installHosts(): Preparing blocklists.."
    local whitelistFile="${persistantDirectory}/cache/whitelist/whitelist.txt"
    [ "${block_social}" -eq 0 ] && whitelistFile="${whitelistFile} ${persistantDirectory}/cache/whitelist/social_whitelist.txt" || \
        consoleMessage "  Social block triggered, social whitelist won't be applied" "installHosts(): Social whitelist won't be applied because the social block is triggered already."
    [ -s "$persistantDirectory/whitelist.txt" ] && whitelistFile="$whitelistFile $persistantDirectory/whitelist.txt"
    
    # merge the whole whitelist into one single one!
    cat "$whitelistFile" | sed '/#/d; /^$/d' | awk '{print "0.0.0.0", $0}' > "${tmpHosts}w"
    [ ! -s "${tmpHosts}w" ] && echo "" > "${tmpHosts}w"
    
    # In case of hosts update (since only combined file exists only on --update-hosts)
    if [ -f "$combinedFile" ]; then
        consoleMessage "- Unified hosts has been found, sorting it.." "installHosts(): Sorting unified hosts.."
        cat "${tmpHosts}0" >> "$combinedFile" 
        awk '!seen[$0]++' "$combinedFile" > "${tmpHosts}merged.sorted"
    else
        consoleMessage "  Multiple hosts has been found, doing a merge + sort on them." "installHosts(): Doing a merge and sort on multiple hosts.."
        LC_ALL=C sort -u "${tmpHosts}"[!0] "${tmpHosts}0" > "${tmpHosts}merged.sorted"
    fi
    consoleMessage "Trying to merge hosts into one..." "installHosts(): Doing a hosts merge and copying them into one.."
    grep -Fvxf "${tmpHosts}w" "${tmpHosts}merged.sorted" > "$hostsFile"
    chmod 644 "$hostsFile"
    rm -f "${tmpHosts}"* 2>/dev/null
    consoleMessage "- Successfully installed $1 hosts, thank you!" "installHosts(): installed $1 hosts successfully."
    return 0
}

function removeHosts() {
    consoleMessage "- Starting to remove hosts" "removeHosts(): Tryin' to remove nonsense? idk"
    cp -f "$hostsFile" "${tmpHosts}0"
    cat "$cacheHosts"* | sort -u > "${tmpHosts}1"
    awk 'NR==FNR {seen[$0]=1; next} !seen[$0]' "${tmpHosts}1" "${tmpHosts}0" > "$hostsFile"
    if [ ! -s "$hostsFile" ]; then
        consoleMessage "  Seems like the main hosts file is empty, restoring it's default entries.." "removeHosts(): Restoring the default entries on the main hosts file.."
        echo -e "127.0.0.1 localhost\n::1 localhost" > "$hostsFile"
    fi
    rm -f "${tmpHosts}"* 2>/dev/null
    consoleMessage "- Finished removing hosts" "removeHosts(): Finished removin' nonsense."
}

function blockContent() {
    local blockType="$1" status="$2" returnCode=0
    cacheHosts="$persistantDirectory/cache/$blockType/hosts"
    mkdir -p "$persistantDirectory/cache/$blockType"
    if [ "$status" = 0 ]; then
        if [ ! -f "${cacheHosts}1" ]; then
            consoleMessage "- No cached $blockType blocklist is found, redownloading it to disable it properly.." "blockContent(): Cached ${blockType} blocklist is missing, setting it up again to disable it properly..."
            fetch "${cacheHosts}1" "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/${blockType}-only/hosts"
            if [ "${blockType}" == "porn" ]; then
                fetch "${cacheHosts}2" https://raw.githubusercontent.com/johnlouie09/Anti-Porn-HOSTS-File/refs/heads/master/HOSTS.txt
                fetch "${cacheHosts}3" https://raw.githubusercontent.com/Sinfonietta/hostfiles/refs/heads/master/pornography-hosts
                fetch "${cacheHosts}4" https://raw.githubusercontent.com/columndeeply/hosts/refs/heads/main/safebrowsing
            fi
            stageBlocklistFiles
            installHosts "${blockType}"
        fi
        removeHosts
        sed -i "s/^block_${blockType}=.*/block_${blockType}=0/" "$persistantDirectory/config.sh"
        consoleMessage "- Disabled $blockType blocklist" "blockContent(): Disabled $blockType"
    else
        if [ ! -f "${cacheHosts}1" ] || [ "${status}" = "update" ]; then
            consoleMessage "- Trying to download hosts for $blockType block.."
            fetch "${cacheHosts}1" "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/${blockType}-only/hosts"
            if [ "$blockType" = "porn" ]; then
                fetch "${cacheHosts}2" https://raw.githubusercontent.com/johnlouie09/Anti-Porn-HOSTS-File/refs/heads/master/HOSTS.txt
                fetch "${cacheHosts}3" https://raw.githubusercontent.com/Sinfonietta/hostfiles/refs/heads/master/pornography-hosts
                fetch "${cacheHosts}4" https://raw.githubusercontent.com/columndeeply/hosts/refs/heads/main/safebrowsing
            fi
            hostsFilterer "$persistantDirectory/cache/$blockType/hosts"*
        fi
        if [ "$status" != "update" ]; then
            stageBlocklistFiles "$blockType"
            installHosts "$blockType"
            sed -i "s/^block_${blockType}=.*/block_${blockType}=1/" "$persistantDirectory/config.sh"
            consoleMessage "- Enabled $blockType blocklist." "blockContent(): Enabled $blockType blocklist.."
        fi
    fi
}

function updateStatus() {
    local lastMod=$(stat -c '%y' "$hostsFile" 2>/dev/null | cut -d'.' -f1)
    # Module hosts count
    blocked_sys=$(cat "$persistantDirectory/counts/blocked_sys.count" 2>/dev/null)
    blocked_mod=$(cat "$persistantDirectory/counts/blocked_mod.count" 2>/dev/null)    
    # Count blacklisted entries (excluding comments and empty lines)
    blacklist_count=0
    [ -s "$persistantDirectory/blacklist.txt" ] && blacklist_count=$(grep -c '^[^#[:space:]]' "$persistantDirectory/blacklist.txt")
    # Count whitelisted entries (excluding comments and empty lines)
    whitelist_count=0
    [ -f "$persistantDirectory/whitelist.txt" ] && whitelist_count=$(grep -c '^[^#[:space:]]' "$persistantDirectory/whitelist.txt")
    # whatever
    logShit "Blacklist entries count: $blacklist_count"
    logShit "Whitelist entries count: $whitelist_count"
    logShit "System hosts entries count: $blocked_sys"
    logShit "Module hosts entries count: $blocked_mod"
    if isBlockerPaused; then
        statusMessage="Status: Re-Malwack is paused temporarily now."
    elif [ -d "/data/adb/modules_update/Re-Malwack" ]; then
        statusMessage="Status: Reboot required to apply the pending module update changes."
    elif [ -d /data/adb/modules_update/Re-Malwack ] && [ ! -d /data/adb/modules/Re-Malwack ]; then
        statusMessage="Status: Reboot required to apply first time install changes."
    elif isDefaultHosts; then
        if [ "$blacklist_count" -ge 2 ]; then
            plural="entries are active"
            [ "$blacklist_count" -eq 1 ] && plural="entry is active"
            statusMessage="Status: Protection is disabled due to reset | Only $blacklist_count blacklist $plural"
        else
            statusMessage="Status: Protection is disabled due to reset."
        fi
    elif [ "$blocked_mod" -ge 0 ]; then
        if [ "$blocked_sys" -eq 0 ] && [ "$blocked_mod" -gt 0 ]; then
            statusMessage="Critical: Hosts mount is broken and it needs to be fixed. Please check your root manager settings and disable any conflicted module(s)."
            consoleMessage "- Critical error found! Solution: Please check your root manager settings and disable any conflicted module(s)." "updateStatus(): Hosts mount is broken."
        elif [ "$blocked_mod" -ne "$blocked_sys" ]; then
            statusMessage="Status: Reboot required to apply changes | Module blocks: $blocked_mod domains, system hosts blocks $blocked_sys."
        else
            statusMessage="Status: Protection is enabled | Blocking $blocked_mod domains"
            [ "$blacklist_count" -ge 1 ] && statusMessage="Status: Protection is enabled | Blocking $((blocked_mod - blacklist_count)) domains + $blacklist_count (blacklist)"
            [ "$whitelist_count" -ge 1 ] && statusMessage="$status_msg | Whitelist: $whitelist_count"
            statusMessage="$statusMessage | Last updated: $lastMod"
        fi
    fi
    sed -i "s/^description=.*/description=$statusMessage/" "$moduleDirectory/module.prop"
}

function refreshCounts() {
    blocked_mod=$(grep -c '^0\.0\.0\.0[[:space:]]' "$hostsFile" 2>/dev/null)
    echo "${blocked_mod:-0}" > "$persistantDirectory/counts/blocked_mod.count"
    blocked_sys=$(grep -c '^0\.0\.0\.0[[:space:]]' "$systemHosts" 2>/dev/null)
    echo "${blocked_sys:-0}" > "$persistantDirectory/counts/blocked_sys.count"
}

function isBlockerPaused() {
    [ -f "$persistantDirectory/hosts.bak" ] || [ "$adblock_switch" -eq 1 ]
}

function pauseBlocker() {
    if isBlockerPaused; then
        resumeBlocker
        exit 0
    fi
    if isDefaultHosts && ! isBlockerPaused; then
        consoleMessage "- You cannot pause protections while hosts is reset." "pauseBlocker(): User tried to pause protections while the hosts is reset."
        exit 1
    fi
    consoleMessage "- Trying to resume protections..." "pauseBlocker(): Trying to resume protections.."
    cp "$hostsFile" "$persistantDirectory/hosts.bak"
    printf "127.0.0.1 localhost\n::1 localhost\n" > "$hostsFile"
    sed -i 's/^adblock_switch=.*/adblock_switch=1/' "$persistantDirectory/config.sh"
    refreshCounts
    updateStatus
    consoleMessage "  Protection has been paused." "pauseBlocker(): Re-Malwack is paused now, the services will remain suspended till the user resumes the service."
}

function resumeBlocker() {
    consoleMessage "- Trying to resume protection..." "resumeBlocker(): Trying to resume protections.."
    if [ -f "$persistantDirectory/hosts.bak" ]; then
        cat "$persistantDirectory/hosts.bak" > "$hostsFile"
        rm -f $persistantDirectory/hosts.bak
        sed -i 's/^adblock_switch=.*/adblock_switch=0/' "/data/adb/Re-Malwack/config.sh"
        refreshCounts
        updateStatus
        consoleMessage "  Protection has been resumed." "resumeBlocker(): Re-Malwack services has been started! the services will get resumed soon!"
    else
        consoleMessage "  Backup hosts file is missing in the expected path, running an update as a fallback action." "resumeBlocker(): Force resuming protection and running hosts update as a fallback action due to the missing backup hosts file."
        sed -i 's/^adblock_switch=.*/adblock_switch=0/' "/data/adb/Re-Malwack/config.sh"
        exec "$0" --update-hosts
    fi
}
# main functions:

# gbl starts from now on:
if [ -n "$WEBUI" ]; then
    refreshCounts
    updateStatus
fi

# log errors:
exec 2>>"$thisInstanceLogFile"

# Trap runtime errors (logs failing command + exit code)
trap '
err_code=$?
timestamp=$(date +"%Y-%m-%d %I:%M:%S %p")
echo "[$timestamp] - [ERROR] - Command \"$BASH_COMMAND\" failed at line $LINENO (exit code: $err_code)" >> "$thisInstanceLogFile"
' ERR

# Trap final script exit
trap '
exit_code=$?
timestamp=$(date +"%Y-%m-%d %I:%M:%S %p")

case $exit_code in
    0)
        echo "[$timestamp] - [SUCCESS] - Script ran successfully with no errors" >> "$thisInstanceLogFile"
        ;;
    1)   msg="General error" ;;
    126) msg="Command invoked cannot execute" ;;
    127) msg="Command not found" ;;
    130) msg="Terminated by Ctrl+C (SIGINT)" ;;
    137) msg="Killed (possibly OOM or SIGKILL)" ;;
    *)   msg="Unknown error (code $exit_code)" ;;
esac

[ $exit_code -ne 0 ] && echo "[$timestamp] - [ERROR] - $msg at line $LINENO (exit code: $exit_code)" >> "$thisInstanceLogFile"
' EXIT

# set `throwOneToTwo` if we got --quiet in the args
echo "$@" | grep -q "--quiet" && throwOneToTwo=true

# just show banner if necessory.
[ -z "$MAGISKTMP" ] && [ "$throwOneToTwo" = "false" ] && rmlwkBanner;

# argument handler thing:
while [ -n "$@" ]; do
    case "$(tolower "$1")"; in
        "--adblock-switch|-as")
            pauseBlocker
            break
        ;;
    esac
done