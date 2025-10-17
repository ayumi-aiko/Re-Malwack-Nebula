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
sleep 2
chmod 755 /data/local/tmp/bin/arm/keycheck
chmod 755 /data/local/tmp/bin/*/jq
debugPrint "customize.sh: Loaded without errors."
printBanner
source /data/local/tmp/properties.prop
[ "${doesModuleRequireLSS}" == "true" ] && logInterpreter --exit-on-failure "customize.sh" "Trying to extract the late start service script..." "unzip -o ${ZIPFILE} service.sh -d $MODPATH"
[ "${doesModuleRequirePFS}" == "true" ] && logInterpreter --exit-on-failure "customize.sh" "Trying to extract the post-fs-data script..." "unzip -o ${ZIPFILE} post-fs-data.sh -d $MODPATH"
consolePrint "Done flashing the module.."