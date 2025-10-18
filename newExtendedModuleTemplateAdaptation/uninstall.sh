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

rm -rf /data/adb/Re-Malwack /data/adb/*/bin/rmlwk
if [ -f $INFO ]; then
    while read LINE; do
        if [ "$(echo -n $LINE | tail -c 1)" == "~" ]; then
            continue
        elif [ -f "$LINE~" ]; then
            mv -f $LINE~ $LINE
        else
            rm -f $LINE
            while true; do
                LINE=$(dirname $LINE)
                [ "$(ls -A $LINE 2>/dev/null)" ] && break 1 || rm -rf $LINE
            done
        fi
    done < $INFO
    rm -f $INFO
fi