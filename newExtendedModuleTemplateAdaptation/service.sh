#!/system/bin/sh
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

# gbl vars:
MODDIR="${0%/*}"
hostsFile="$MODDIR/system/etc/hosts"
persistentDirectory="/data/adb/Re-Malwack"
systemHosts="/system/etc/hosts"
# Checks last modification date for hosts file
lastMod=$(stat -c '%y' "$hostsFile" 2>/dev/null | cut -d'.' -f1) 

# functions:
# Function to check hosts file reset state
# Becomes true in case of both hosts counts = 0
# And becomes also true in case of blocked entries in both module and system hosts equals the blacklist file
# AKA only blacklisted entries are active
function isDefaultHosts() {
    [ "$blockedMod" -eq 0 ] && [ "$blockedSys" -eq 0 ] \
    || { [ "$blockedMod" -eq "$blocklistCount" ] && [ "$blockedSys" -eq "$blocklistCount" ]; }
}

# Logging function
function logMessage() {
    touch "$persistentDirectory/logs/service.log"
    echo "[$(date +"%Y-%m-%d %I:%M:%S %p")] - $1" >> "$persistentDirectory/logs/service.log"   
}

# function to check adblock pause
function isProtectionPaused() {
    [ -f "$persistentDirectory/hosts.bak" ] && [ "$adblock_switch" -eq 1 ]
}
# functions:

# anyways, moving on!

# sourcing the config file to get variables from it.
source $persistentDirectory/config.sh

# create logs dir just in case and remove previous logs
mkdir -p "$persistentDirectory/logs"; rm -rf "$persistentDirectory/logs/"*

# log errors:
exec 2>>"$persistentDirectory/logs/service.log"

# append module version in the "log" thing
version=$(grep '^version=' "$MODDIR/module.prop" | cut -d= -f2-)
logMessage "Re-Malwack Version: $version"

# System hosts count
blockedSys=$(grep -c '^0\.0\.0\.0[[:space:]]' "$system_hosts" 2>/dev/null)
echo "${blockedSys:-0}" > "$persistentDirectory/counts/blockedSys.count"
logMessage "System hosts entries count: $blockedSys"

# Module hosts count
blockedMod=$(grep -c '^0\.0\.0\.0[[:space:]]' "$hosts_file" 2>/dev/null)
echo "${blockedMod:-0}" > "$persistentDirectory/counts/blockedMod.count"
logMessage "Module hosts entries count: $blockedMod"

# Count blacklisted entries (excluding comments and empty lines)
blocklistCount=0
[ -s "$persistentDirectory/blacklist.txt" ] && blocklistCount=$(grep -c '^[^#[:space:]]' "$persistentDirectory/blacklist.txt")
logMessage "Blacklist entries count: $blocklistCount"

# Count whitelisted entries (excluding comments and empty lines)
whitelistCount=0
[ -f "$persistentDirectory/whitelist.txt" ] && whitelistCount=$(grep -c '^[^#[:space:]]' "$persistentDirectory/whitelist.txt")
logMessage "Whitelist entries count: $whitelistCount"

# symlink rmlwk to manager path
if [ "$KSU" = "true" ]; then
    [ -L "/data/adb/ksud/bin/rmlwk" ] || ln -sf "$MODDIR/rmlwk.sh" "/data/adb/ksud/bin/rmlwk" && logMessage "symlink created at /data/adb/ksud/bin/rmlwk"
elif [ "$APATCH" = "true" ]; then
    [ -L "/data/adb/apd/bin/rmlwk" ] || ln -sf "$MODDIR/rmlwk.sh" "/data/adb/apd/bin/rmlwk" && logMessage "symlink created at /data/adb/apd/bin/rmlwk"
else
    [ -w /sbin ] && magisktmp=/sbin
    [ -w /debug_ramdisk ] && magisktmp=/debug_ramdisk
    ln -sf "$MODDIR/rmlwk.sh" "$magisktmp/rmlwk" && logMessage "symlink created at $magisktmp/rmlwk"
fi

# Module hosts count
blockedSys=$(cat "$persistentDirectory/counts/blockedSys.count" 2>/dev/null)
blockedMod=$(cat "$persistentDirectory/counts/blockedMod.count" 2>/dev/null)

# Count blacklisted entries (excluding comments and empty lines)
blocklistCount=0
[ -s "$persistentDirectory/blacklist.txt" ] && blocklistCount=$(grep -c '^[^#[:space:]]' "$persistentDirectory/blacklist.txt")

# Count whitelisted entries (excluding comments and empty lines)
whitelistCount=0
[ -f "$persistentDirectory/whitelist.txt" ] && whitelistCount=$(grep -c '^[^#[:space:]]' "$persistentDirectory/whitelist.txt")

# whatever:
logMessage "Blacklist entries count: $blocklistCount"
logMessage "Whitelist entries count: $whitelistCount"
logMessage "System hosts entries count: $blockedSys"
logMessage "Module hosts entries count: $blockedMod"

# Here goes the part where we actually determine module status
if isProtectionPaused; then
    statusMsg="Status: Protection is paused ⏸️"
elif isDefaultHosts; then
    if [ "$blocklistCount" -gt 0 ]; then
        plural="entries are active"
        [ "$blocklistCount" -eq 1 ] && plural="entry is active"
        statusMsg="Status: Protection is disabled due to reset ❌ | Only $blocklistCount blacklist $plural"
    else
        statusMsg="Status: Protection is disabled due to reset ❌"
    fi
elif [ "$blockedMod" -ge 0 ]; then
    if [ "$blockedSys" -eq 0 ] && [ "$blockedMod" -gt 0 ]; then
        statusMsg="Status: ❌ Critical Error Detected (Broken hosts mount). Please check your root manager settings and disable any conflicted module(s)."
    elif [ "$blockedMod" -ne "$blockedSys" ]; then # Only for cases if mount is broken between module hosts and system hosts
        statusMsg="Status: Reboot required to apply changes 🔃 | Module blocks $blockedMod domains, system hosts blocks $blockedSys."
    else
        statusMsg="Status: Protection is enabled ✅ | Blocking $blockedMod domains"
        [ "$blocklistCount" -gt 0 ] && statusMsg="Status: Protection is enabled ✅ | Blocking $((blockedMod - blocklistCount)) domains + $blocklistCount (blacklist)"
        [ "$whitelistCount" -gt 0 ] && statusMsg="$statusMsg | Whitelist: $whitelistCount"
        statusMsg="$statusMsg | Last updated: $lastMod"
    fi
fi

# Apply module status into module description
sed -i "s/^description=.*/description=$statusMsg/" "$MODDIR/module.prop"
logMessage "$statusMsg"

# Check if auto-update is enabled
if [ "$daily_update" = 1 ]; then
    # Check if crond is running
    if ! pgrep -x crond >/dev/null; then
        logMessage "Auto-update is enabled, but crond is not running. Starting crond..."
        busybox crond -c "/data/adb/Re-Malwack/auto_update" -L "/data/adb/Re-Malwack/logs/auto_update.log"
        logMessage "Crond started."
    else
        logMessage "Crond is already running."
    fi
fi