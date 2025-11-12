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

# Checking and disabling other hosts modules
# Some nerds are installing multiple adblock modules after installing Re-Malwack
# Thinking that will push adblocking to max, but it causes conflicts and issues 😭
for module in /data/adb/modules/*; do
    module_id="$(grep_prop id "${module}/module.prop")"
    [ "$module_id" == "Re-Malwack" ] && continue
    if [ -f "${module}/system/etc/hosts" ]; then
        [ -f "/data/adb/modules/$module_id/disable" ] && continue
        touch "/data/adb/modules/$module_id/disable"
    fi
done

# Mount hosts manually if KernelSU .nomount / APatch .litemode_enable and mountify exist
if [ -d /data/adb/modules/mountify ]
    && { [ "$KSU_MAGIC_MOUNT" = "true" ] && [ -f /data/adb/ksu/.nomount ]; }
    || { [ "$APATCH_BIND_MOUNT" = "true" ] && [ -f /data/adb/.litemode_enable ]; }; then
    mount --bind "$MODPATH/system/etc/hosts" /system/etc/hosts
fi