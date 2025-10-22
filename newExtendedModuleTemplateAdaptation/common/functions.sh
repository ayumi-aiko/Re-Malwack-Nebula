#
# Copyright (C) 2025 愛子あゆみ <ayumi.aiko@outlook.com>
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

# gbl variable that is required by some functions for certain use cases:
archPath="$(getprop "ro.product.cpu.abi")"
moduleID="$(grep_prop id /dev/tmp/module.prop)"
if $BOOTMODE; then defaultModuleDirectory=modules_update; else defaultModuleDirectory=modules; fi
modulePath="/data/adb/${defaultModuleDirectory}/${moduleID}"
persistentDirectory="/data/adb/Re-Malwack"
configFile="$persistentDirectory/config.sh"

# the ui_print calls will get redirected to the Magisk log by the debugPrint function.
function consolePrint() {
    echo -e "$@" > /proc/self/fd/$OUTFD
}

# same as consolePrint
function abortInstance() {
	consolePrint "$@"
	rm -rf /dev/tmp/{banner,common,properties.prop} $modulePath $MODPATH/import.sh
    exit 1
}

# dhdhehhehehe
function ui_print() {
	echo "magisk: $@" > /proc/self/fd/2
}

# it was a whole diff thing back then, i swear!
function debugPrint() {
	echo "$@" > /proc/self/fd/2
}

# hdhhdhd
function logInterpreter() {
	local steps="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
	local service="$2"
	local message="$3"
	local command="$4"
	local failureMessage="$5"
	local failureCommand="$6"

	# Common message for all log requests.
	debugPrint "$service: $message"

	# handle arguments.
	case "$steps" in
		--ignore-failure)
			eval "$command" &> /proc/self/fd/2 || debugPrint "$service: $failureMessage"
		;;
		--exit-on-failure)
			if ! eval "$command" &> /proc/self/fd/2; then
				debugPrint "$service: $failureMessage"
				rm -rf /dev/tmp/{banner,common,properties.prop} $modulePath $MODPATH/import.sh
				exit 1
			fi
		;;
		--handle-failure-action)
			if ! eval "$command" &> /proc/self/fd/2; then
				debugPrint "$service: $failureMessage"
				eval "$failureCommand" 2&> /proc/self/fd/2 || debugPrint "logInterpreter: Failed to execute failure command."
				rm -rf /dev/tmp/{banner,common,properties.prop} $modulePath $MODPATH/import.sh
			fi
		;;
	esac
}

# prints banner
function printBanner() {
	[ -f "${modulePath}/banner" ] && cat ${modulePath}/banner > /proc/self/fd/$OUTFD
}

# for caching the keys
function registerKeys() {
    while true; do
        # Calling keycheck first time detects previous input. Calling it second time will do what we want
        ${modulePath}/bin/armeabi-v7a/keycheck
        ${modulePath}/bin/armeabi-v7a/keycheck
        local SEL=$?
        if [ "$1" == "UP" ]; then
            UP=$SEL
            echo "$UP" > ${modulePath}/volActionUp
            break
        elif [ "$1" == "DOWN" ]; then
            DOWN=$SEL
            echo "$DOWN" > ${modulePath}/volActionDown
            break
        elif [ $SEL -eq $UP ]; then
            return 1
        elif [ $SEL -eq $DOWN ]; then
            return 0
        fi
    done
}

# returns 0 when + is pressed, 1 when - 
function whichVolumeKey() {
    local SEL
    ${modulePath}/bin/armeabi-v7a/keycheck
    SEL="$?"
    if [ "$(cat "${modulePath}/volActionUp")" == "${SEL}" ]; then
        return 0
    elif [ "$(cat "${modulePath}/volActionDown")" == "${SEL}" ]; then
        return 1
    else
        debugPrint "Error | whichVolumeKey(): Unknown key register, here's the return value: ${SEL}"
        return 1
    fi
}

# like a prompt.
function ask() {
    consolePrint "$1 (+ / -)"
    whichVolumeKey
}

# most used crap
function recoveryAhhSelection() {
    local incrementation="$1"
    icrmntval=1
    consolePrint "- Select an option:"
    consolePrint "  Volume up = Switch option"
    consolePrint "  Volume down = Select option"
    while true; do
        if whichVolumeKey; then
			consolePrint "  $icrmntval"
            if [ $icrmntval -gt $incrementation ]; then
                icrmntval=0
            fi
			icrmntval=$((icrmntval + 1))
        else
            break
        fi
		# fix: stop the crap from incrementing twice because of a tiny human mistake.
		# if you are reading this, just comment the command below and see what it does. DUH
		sleep 0.5
    done
}

function setPerm() {
	chown "$2":"$3" "$1" || return 1
	chmod "$4" "$1" || return 1
	{
		if [[ -z "$5" ]]; then
			case $1 in
				*"system/vendor/app/"*) chcon 'u:object_r:vendor_app_file:s0' "$1";;
				*"system/vendor/etc/"*) chcon 'u:object_r:vendor_configs_file:s0' "$1";;
				*"system/vendor/overlay/"*) chcon 'u:object_r:vendor_overlay_file:s0' "$1";;
				*"system/vendor/"*) chcon 'u:object_r:vendor_file:s0' "$1";;
				*) chcon 'u:object_r:system_file:s0' "$1";;
			esac
		else
			chcon "$5" "$1"
		fi
	} || return 1
}

function setPermRecursive() {
	find "$1" -type d 2>/dev/null | while read dir; do
    	setPerm "$dir" "$2" "$3" "$4" "$6"
  	done
  	find "$1" -type f -o -type l 2>/dev/null | while read file; do
    	setPerm "$file" "$2" "$3" "$5" "$6"
  	done
}

# uninstalls the module in recovery if found to be installed. Helpful in certain situations.
function uninstallModule() {
	[ "${canModuleGetInstalledInRecovery}" == "false" ] || return 0;
	if ! $BOOTMODE; then
		for paths in /data/adb/*/${moduleID}; do
			if [ -f "$paths" ]; then 
				touch ${paths}/uninstall
				consolePrint "Found module on $paths, placing a file to remind magisk to uninstall this module."
			fi
		done
		abort "- You cannot install this module in recovery mode"
	fi
}

# extracts the correct required binary from the zipfile.
function extractBinaryFromModule() {
	local fileToExtract="$1" extractPath="$2"
	unzip -l "${ZIPFILE}" | grep -q "${fileToExtract}" || abort "- Cannot extract unknown file: ${fileToExtract}"
	unzip -o "${ZIPFILE}" "${fileToExtract}" -d "${extractPath}"
}

# i dont want to comment on this awful function
function loopInternetCheck() {
	local state="$1"
	local pidFile="${modulePath}/pidIC"
	local flagFile="${modulePath}/.internet_ok"
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
			consolePrint "- Internet unavailable, waiting..."
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

# adds url if not found in the sources file/
function appendUnavailableURL() {
    local url="$1"
    grep -q "^$url$" "$persistentDirectory/sources.txt" || echo "$url" >> "$persistentDirectory/sources.txt"
}

function getLatestReleaseFromGithub() {
    local githubReleaseURL="$1"
    if [[ -z "$githubReleaseURL" ]]; then
        echo "Error: No GitHub release URL provided."
        return 1
    fi
    local latestRelease=$(curl -s "$githubReleaseURL" | grep -oP '"browser_download_url": "\K[^"]+')
    if [[ -z "$latestRelease" ]]; then
        echo "Error: Could not retrieve the latest release URL."
        return 1
    fi
    echo "$latestRelease"
}

function downloadContentFromWEB() {
    local URL="$1"
    local outputPathAndFilename="$2"
    local prevPath="$PATH"
    export PATH="/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:/data/data/com.termux/files/usr/bin:${PATH}"
    mkdir -p "$(dirname "$outputPathAndFilename")"
    if command -v curl >/dev/null 2>&1; then
        curl -Ls "$URL" -o "$outputPathAndFilename" || abortInstance "Failed to download from $URL with curl"
    else
        wget --no-check-certificate -qO "$outputPathAndFilename" "$URL" || abortInstance "Failed to download from $URL with wget"
    fi
    export PATH="${prevPath}"
}