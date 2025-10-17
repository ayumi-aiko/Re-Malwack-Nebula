#!/usr/bin/env bash
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

# shutt up
CC_ROOT="/home/ayumi/android-ndk-r27d/toolchains/llvm/prebuilt/linux-x86_64/bin"
CFLAGS="-std=c23 -O3 -static"
BUILD_LOGFILE="./module/mitsuha/build/logs/build.log"
OUTPUT_DIR="./module/mitsuha/build"
MITSUHA_HEADERS="./module/mitsuha/src/include"
MITSUHA_SOURCES="./module/mitsuha/src/include/daemon.c"
TARGETS=("./module/mitsuha/src/yuki/main.c" "./module/mitsuha/src/alya/main.c")
OUTPUT_BINARY_NAMES=("mitsuha-yuki" "mitsuha-alya")
DEFAULT_MODULE_BINARIES_PATH=./module/bin/armeabi-v7a
SDK=""
CC=""

# first of all, let's just switch to the directory of this script temporarily.
if ! cd "$(realpath "$(dirname "$0")")"; then
    printf "\033[0;31mmake: Error: Failed to switch to the directory of this script, please try again.\033[0m\n"
    exit 1;
fi

# just make the dir 
mkdir -p "$(dirname "${BUILD_LOGFILE}")" "${OUTPUT_DIR}"
for args in "$@"; do
    lowerCaseArgument=$(echo "${args}" | tr '[:upper:]' '[:lower:]')
    if [ "${lowerCaseArgument}" == "clean" ]; then
        rm -f ${BUILD_LOGFILE} ${OUTPUT_DIR}/mitsuha-* ../Re-Malwack_*.zip
	    echo -e "\033[0;32mmake: Info: Clean complete.\033[0m"
        break;
    # for now, let's just build the old module template.
    elif [[ "${lowerCaseArgument}" == *module* ]]; then
        if [ ! -f "${OUTPUT_DIR}/${OUTPUT_BINARY_NAMES[0]}" ]; then
            printf "\033[0;31mmake: Error: Please build mitsuha before building this module.\033[0m\n"
            exit 1;
        fi
        echo -e "\e[0;35mmake: Info: Building Re-Malwack magisk module installer...\e[0;37m" 
        # no, im not using for loop for this.
        file "${OUTPUT_DIR}/${OUTPUT_BINARY_NAMES[0]}" | grep -q 64-bit && DEFAULT_MODULE_BINARIES_PATH=./module/bin/arm64-v8a
        mv "${OUTPUT_DIR}/${OUTPUT_BINARY_NAMES[0]}" "${DEFAULT_MODULE_BINARIES_PATH}"
        mv "${OUTPUT_DIR}/${OUTPUT_BINARY_NAMES[1]}" "${DEFAULT_MODULE_BINARIES_PATH}"
        lastestCommitNum="$(git rev-list --count HEAD)"
        lastestCommitHash="$(git rev-parse --short HEAD)"
        lastestCommitMessage="$(git log -1 --pretty=%B | head -n 1)"
        lastestVersion="$(grep version update.json | head -n 1 | awk '{print $2}' | sed 's/,//' | xargs)"
        sed -i "s/^version=.*/version=${lastestVersion}-lastest-commit-nebula (#${lastestCommitNum}-${lastestCommitHash})/" module/module.prop
        if ! zip -r "../Re-Malwack_${lastestVersion}-${lastestCommitNum}-${lastestCommitHash}.zip" ./module/ &>/dev/null; then
            git restore module/module.prop
            printf "\033[0;31mmake: Error: Failed to compress the module sources, please try again or install zip to proceed.\033[0m\n"
            exit 1
        fi
        git restore module/module.prop
        echo -e "\e[0;36mmake: Info: Build finished without errors\e[0;37m"
    fi
    if [[ -z "${SDK}" && "${lowerCaseArgument}" == sdk=* ]]; then
        SDK="${lowerCaseArgument#sdk=}"
    fi
    if [[ -z "${CC}" && -n "${SDK}" ]]; then
        case "${lowerCaseArgument}" in
            arch=arm)
                CC="${CC_ROOT}/armv7a-linux-androideabi${SDK}-clang"
            ;;
            arch=arm64)
                CC="${CC_ROOT}/aarch64-linux-android${SDK}-clang"
            ;;
            arch=x86)
                CC="${CC_ROOT}/i686-linux-android${SDK}-clang"
            ;;
            arch=x86_64)
                CC="${CC_ROOT}/x86_64-linux-android${SDK}-clang"
            ;;
        esac
    fi
    if [[ -n "${SDK}" && -n "${CC}" && "${lowerCaseArgument}" == *mitsuha* ]]; then
        echo -e "\e[0;35mmake: Info: Building Mitsuha binaries...\e[0;37m"
        for i in $(seq 0 1); do
            if ! ${CC} ${CFLAGS} "${MITSUHA_SOURCES}" -I"${MITSUHA_HEADERS}" "${TARGETS[$i]}" -o "${OUTPUT_DIR}/${OUTPUT_BINARY_NAMES[$i]}" &> "${BUILD_LOGFILE}"; then
                printf "\033[0;31mmake: Error: Build failed, check %s\033[0m\n" "${BUILD_LOGFILE}"
                exit 1
            fi
        done
        echo -e "\e[0;36mmake: Info: Build finished without errors, be sure to check logs if concerned. Thank you!\e[0;37m"
    fi
done