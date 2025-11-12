#!/usr/bin/env bash
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

# shutt up
CC_ROOT="/home/ayumi/android-ndk-r27d/toolchains/llvm/prebuilt/linux-x86_64/bin"
CFLAGS="-std=c23 -O3 -static"
BUILD_LOGFILE="./hoshiko-cli/build/log"
OUTPUT_DIR="./hoshiko-cli/build"
HOSHIKO_HEADERS="./hoshiko-cli/src/include"
HOSHIKO_SOURCES="./hoshiko-cli/src/include/daemon.c"
TARGETS=("./hoshiko-cli/src/yuki/main.c" "./hoshiko-cli/src/alya/main.c")
OUTPUT_BINARY_NAMES=("hoshiko-yuki" "hoshiko-alya")
IS_TARGET_SATISFIED=false
SDK=""
CC=""

# first of all, let's just switch to the directory of this script temporarily.
if ! cd "$(realpath "$(dirname "$0")")"; then
    printf "\033[0;31mmake: Error: Failed to switch to the directory of this script, please try again.\033[0m\n"
    exit 1;
fi

# print the banner:
printf "\033[0;31mM\"\"MMMMM\"\"MM                   dP       oo dP\n"
printf "M  MMMMM  MM                   88          88\n"
printf "M         \`M .d8888b. .d8888b. 88d888b. dP 88  .dP  .d8888b.\n"
printf "M  MMMMM  MM 88'  \`88 Y8ooooo. 88'  \`88 88 88888\"   88'  \`88\n"
printf "M  MMMMM  MM 88.  .88       88 88    88 88 88  \`8b. 88.  .88\n"
printf "M  MMMMM  MM \`88888P' \`88888P' dP    dP dP dP   \`YP \`88888P'\n"
printf "MMMMMMMMMMMM                                                 \n"

# just make the dir 
mkdir -p "$(dirname "${BUILD_LOGFILE}")" "${OUTPUT_DIR}"
for args in "$@"; do
    lowerCaseArgument=$(echo "${args}" | tr '[:upper:]' '[:lower:]')
    if [ "${lowerCaseArgument}" == "clean" ]; then
        rm -f ${BUILD_LOGFILE} ${OUTPUT_DIR}/hoshiko-*
	    echo -e "\033[0;32mmake: Info: Clean complete.\033[0m"
        IS_TARGET_SATISFIED=true;
        break;
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
    if [[ -n "${SDK}" && -n "${CC}" && "${lowerCaseArgument}" == *yuki* ]]; then
        IS_TARGET_SATISFIED=true
        i=0
    elif [[ -n "${SDK}" && -n "${CC}" && "${lowerCaseArgument}" == *alya* ]]; then
        IS_TARGET_SATISFIED=true
        i=1
    fi
    if [ "${IS_TARGET_SATISFIED}" == "true" ]; then
        echo -e "\e[0;35mmake: Info: Building requested binary...\e[0;37m"
        if ! ${CC} ${CFLAGS} "${HOSHIKO_SOURCES}" -I"${HOSHIKO_HEADERS}" "${TARGETS[$i]}" -o "${OUTPUT_DIR}/${OUTPUT_BINARY_NAMES[$i]}" &> "${BUILD_LOGFILE}"; then
            printf "\033[0;31mmake: Error: Build failed, check %s\033[0m\n" "${BUILD_LOGFILE}"
            exit 1
        fi
        echo -e "\e[0;36mmake: Info: Build finished without errors, be sure to check logs if concerned. Thank you!\e[0;37m"
    fi
done

if [ "${IS_TARGET_SATISFIED}" == "false" ]; then
	echo -e "\033[1;36mUsage:\033[0m make.sh [SDK=<level>] [ARCH=<arch>] <target>"
	echo ""
	echo -e "\033[1;36mTargets:\033[0m"
	echo -e "  \033[0;32myuki\033[0m     Build the Hoshiko daemon binary"
	echo -e "  \033[0;32malya\033[0m     Build the Hoshiko daemon manager"
	echo -e "  \033[0;32mclean\033[0m      Remove build artifacts"
	echo -e "  \033[0;32mhelp\033[0m       Show this help message"
	echo ""
	echo -e "\033[1;36mExample:\033[0m"
	echo -e "  make.sh SDK=30 ARCH=arm64 \033[0;32myuki\033[0m"
fi