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
# the ui_print calls will get redirected to the Magisk log by the debugPrint function.
function consolePrint() {
    echo -e "$@" > /proc/self/fd/$OUTFD
}

# same as consolePrint
function abortInstance() {
	consolePrint "$@"
	rm -rf /data/local/tmp/{banner,common,properties.prop}
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
				exit 1
			fi
		;;
		--handle-failure-action)
			if ! eval "$command" &> /proc/self/fd/2; then
				debugPrint "$service: $failureMessage"
				eval "$failureCommand" 2&> /proc/self/fd/2 || debugPrint "logInterpreter: Failed to execute failure command."
			fi
		;;
	esac
}

# prints banner
function printBanner() {
	[ -f "/data/local/tmp/banner" ] && cat /data/local/tmp/banner > /proc/self/fd/$OUTFD
}

# for caching the keys
function registerKeys() {
    while true; do
        # Calling keycheck first time detects previous input. Calling it second time will do what we want
        /data/local/tmp/bin/arm/keycheck
        /data/local/tmp/bin/arm/keycheck
        local SEL=$?
        if [ "$1" == "UP" ]; then
            UP=$SEL
            echo "$UP" > /data/local/tmp/volActionUp
            break
        elif [ "$1" == "DOWN" ]; then
            DOWN=$SEL
            echo "$DOWN" > /data/local/tmp/volActionDown
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
    /data/local/tmp/bin/arm/keycheck
    SEL="$?"
    if [ "$(cat "/data/local/tmp/volActionUp")" == "${SEL}" ]; then
        return 0
    elif [ "$(cat "/data/local/tmp/volActionDown")" == "${SEL}" ]; then
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
    local text="$1"
    local incrementation="$2"
    icrmntval=0
    consolePrint "$text"
    consolePrint "\nSelect an option:"
    consolePrint "- Volume up = Switch option"
    consolePrint "- Volume down = Select option\n"
    while true; do
        consolePrint "  $icrmntval"
        if whichVolumeKey; then
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