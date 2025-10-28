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

# setup stuff: give perms to the binaries inside /bin!
chmod 755 ${modulePath}/bin/*/*
chown root:root ${modulePath}/bin/*/*
chcon u:r:system_file:s0 ${modulePath}/bin/*/*
mkdir -p "$persistentDirectory"
rm -rf "${configFile}"
touch "$configFile"

# urhm i dont wanna die for the-
source /data/local/tmp/properties.prop
printBanner;

# tell usrs to stop installing from recovery if they are installing for the first time
# and uninstall the module if found 
uninstallModule;

# skip installations if x86* not supported.
[ "$(getprop "ro.product.cpu.abi")" == "x86|x86_64" ] && [ "${doesModuleSupportHavingX86LibrariesAndBinaries}" == "false" ] && \
    abort "- Your device is not supported to install this module."

# alert users to uninstall adaway.
pm list packages | grep -q org.adaway && abort "- Adaway detected, Please uninstall to prevent conflicts, backup your setup optionally before uninstalling in case you want to import your setup."

# check volume keyyyyyyy
consolePrint "- Starting to register your device's volume key inputs..."
consolePrint "  Please press volume + (UP)"
registerKeys "UP"
consolePrint "  Please press volume - (DOWN)"
registerKeys "DOWN"
consolePrint " "

# Add a persistent directory to save configuration
consolePrint "- Preparing Re-Malwack environment.."
for types in block_porn block_gambling block_fakenews block_social block_trackers daily_update; do
    grep -q "^$types=" "$configFile" || echo "$types=0" >> "$configFile"
done

# Import from other ad-block modules.
. $MODPATH/import.sh

# okie pls dont bash me for plugging my stuff into ts.
consolePrint "- Hoshiko is an unofficial app made by Ayumi that helps Re-Malwack to stop adblocking in certain apps requested by the user."
if ask "  Do you want to install Hoshiko?"; then
    downloadContentFromWEB "$(getLatestReleaseFromGithub "https://api.github.com/repos/ayumi-aiko/Hoshiko/releases/latest")" "/data/local/tmp/hoshiko.apk";
    # selinux moments hehe~ 🥰
    logInterpreter --exit-on-failure "customize.sh" "Trying to install Hoshiko application into the device..." "pm install /data/local/tmp/hoshiko.apk" "Failed to install hoshiko application, please try again.";
    consolePrint "- Thank you for installing hoshiko, i hope you will have a good experience with it.";
    consolePrint "  Regards, Ayumi, the creater of Hoshiko and a contributor to Re-Malwack.";
    consolePrint "  One more thing, please don't bash me for having an \"complex\" ui design"
    consolePrint "  I'm not someone who's good and i will upload a example video on github soon."
fi

# set permissions
chmod 0755 $persistent_dir/config.sh $MODPATH/action.sh $MODPATH/rmlwk.sh $MODPATH/uninstall.sh

# Initialize hosts files
mkdir -p $MODPATH/system/etc
rm -rf $persistentDirectory/logs/* 2>/dev/null
rm -rf $persistentDirectory/cache/* 2>/dev/null

# handle hosts sources file:
if [ ! -s "${persistentDirectory}/sources.txt" ]; then
    mv -f $MODPATH/common/sources.txt $persistentDirectory/sources.txt
else 
    # update sources
    rm -f $MODPATH/common/sources.txt
    sed -i 's|https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro.plus.txt|https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro.txt|' $persistentDirectory/sources.txt
    sed -i 's|https://o0.pages.dev/Pro/hosts.txt|https://badmojr.github.io/1Hosts/Lite/hosts.txt|' $persistentDirectory/sources.txt
    appendUnavailableURL "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.tiktok.txt"
fi

# Initialize
if ! sh $MODPATH/rmlwk.sh --update-hosts --quiet; then
    consolePrint "  Failed to initialize script"
    tarFileName="/sdcard/Download/Re-Malwack_install_log_$(date +%Y-%m-%d_%H%M%S).tar.gz"
    tar -czvf ${tarFileName} --exclude="$persistentDirectory" -C $persistentDirectory logs
    # cleanup in case of failure (in worst cases on first install)
    [ -d /data/adb/modules/Re-Malwack ] || rm -rf /data/adb/Re-Malwack
    abortInstance "  Logs are saved in ${tarFileName}"
fi

# Create symlink on install for ksu/ap
for i in /data/adb/ap/bin /data/adb/ksu/bin; do
    [ -d "$i" ] && ln -sf "/data/adb/modules/Re-Malwack/rmlwk.sh" "$i/rmlwk"
done

# Cleanup
rm -f $MODPATH/import.sh

# extract the init services 
[ "${doesModuleRequireLSS}" == "true" ] && logInterpreter --exit-on-failure "customize.sh" "Trying to extract the late start service script..." "unzip -o ${ZIPFILE} service.sh -d $MODPATH"
[ "${doesModuleRequirePFS}" == "true" ] && logInterpreter --exit-on-failure "customize.sh" "Trying to extract the post-fs-data script..." "unzip -o ${ZIPFILE} post-fs-data.sh -d $MODPATH"

# move the appropriate bbinaries into the system path.
mkdir -p "${modulePath}/system/bin"
mv "${modulePath}/bin/$(getprop "ro.product.cpu.abi")/hoshiko-alya" "${modulePath}/system/bin/"
mv "${modulePath}/bin/$(getprop "ro.product.cpu.abi")/hoshiko-yuki" "${modulePath}/system/bin/"

# uhrm idc
consolePrint "\n- Installed Re-Malwack into your device, please be sure to thank us on our Telegram!"