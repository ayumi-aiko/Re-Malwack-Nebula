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
BUILD_LOGFILE="./hoshiko/hoshiko-cli/build/log"
OUTPUT_DIR="./hoshiko/hoshiko-cli"
OUTPUT_DIR_MODULE_BINARY_BUILD="./newExtendedModuleTemplateAdaptation/bin"
HOSHIKO_HEADERS="./hoshiko/hoshiko-cli/src/include"
HOSHIKO_SOURCES="./hoshiko/hoshiko-cli/src/include/daemon.c"
TARGETS=("./hoshiko/hoshiko-cli/src/yuki/main.c" "./hoshiko/hoshiko-cli/src/alya/main.c")
OUTPUT_BINARY_NAMES=("hoshiko-yuki" "hoshiko-alya")
ARCH_CLANG_FOR_BUILDING_MODULE=("armv7a-linux-androideabi" "aarch64-linux-android")
ARCH_PATHS_FOR_MODULE_BINARIES=("armeabi-v7a" "arm64-v8a")
IS_TARGET_SATISFIED=false
SDK=""
CC=""

# first of all, let's just switch to the directory of this script temporarily.
if ! cd "$(realpath "$(dirname "$0")")"; then
    printf "\033[0;31mmake: Error: Failed to switch to the directory of this script, please try again.\033[0m\n"
    exit 1;
fi

# print the banner:
printf ":::.    :::..,::::::  :::::::.   ...    ::: :::      :::.     \n"
printf "\`;;;;,  \`;;;;;;;\'\'\'\'   ;;;\'\';;\'  ;;     ;;; ;;;      ;;\`;;    \n"
printf "  [[[[[. \'[[ [[cccc    [[[__[[\.[[\'     [[[ [[[     ,[[ \'[[,  \n"
printf "  \$\$$ \"Y\$c\$$ \$$\"\"\"\"    \$$\"\"\"\"Y\$\$\$$      \$\$\$ \$\$\'    c\$\$\$cc\$\$\$c \n"
printf "  888    Y88 888oo,__ _88o,,od8P88    .d888o88oo,.__888   888,\n"
printf "  MMM     YM \"\"\"\"YUMMM\"\"YUMMMP\"  \"YmmMMMM\"\"\"\"\"\"YUMMMYMM   \"\"\` \n"

# just make the dir 
mkdir -p "$(dirname "${BUILD_LOGFILE}")" "${OUTPUT_DIR}"
for args in "$@"; do
    lowerCaseArgument=$(echo "${args}" | tr '[:upper:]' '[:lower:]')
    if [[ -z "${SDK}" && "${lowerCaseArgument}" == sdk=* ]]; then
        if [ "${lowerCaseArgument#sdk=}" -le "22" ]; then
            printf "\033[0;31mmake: Error: You cannot build and use this module on a older android device, android 6.0 aka marshmallow is the minimum supported android version!\033[0m\n"
            exit 1;
        fi
        SDK="${lowerCaseArgument#sdk=}"
        continue;
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
        continue;
    fi
    if [ "${lowerCaseArgument}" == "clean" ]; then
        rm -f ${BUILD_LOGFILE} ${OUTPUT_DIR}/hoshiko-* ../Re-Malwack*.zip ./Re-Malwack*.zip ${OUTPUT_DIR_MODULE_BINARY_BUILD}/*/hoshiko-*
	    echo -e "\033[0;32mmake: Info: Clean complete.\033[0m"
        IS_TARGET_SATISFIED=true;
        break;
    elif [[ "${lowerCaseArgument}" == *module* ]]; then
        IS_TARGET_SATISFIED=true;
        echo -e "\e[0;35mmake: Info: Building Hoshiko binaries for arm64 and arm devices..\e[0;37m"
        # ask the user if they want to build for a specific sdk or not.
        printf "\e[0;35m- Do you want to build hoshiko binaries for the mentioned SDK version? \e[0;37m"
        read foo
        if [[ -z "$foo" || "$(echo "${foo}" | tr '[:upper:]' '[:lower:]')" != "y" ]]; then
            echo ""
            SDK=23
        elif [[ -z "$SDK" ]]; then
            printf "\033[0;31mmake: Error: SDK version is not mentioned, please either mention it in the arguments or proceed building with the default sdk version\033[0m\n"
            exit 1;
        fi
        for j in $(seq 0 1); do
            CC="${CC_ROOT}/${ARCH_CLANG_FOR_BUILDING_MODULE[${j}]}${SDK}-clang"
            for i in $(seq 0 1); do
                if ! ${CC} ${CFLAGS} "${HOSHIKO_SOURCES}" -I"${HOSHIKO_HEADERS}" "${TARGETS[$i]}" -o "${OUTPUT_DIR_MODULE_BINARY_BUILD}/${ARCH_PATHS_FOR_MODULE_BINARIES[${j}]}/${OUTPUT_BINARY_NAMES[$i]}" &> "${BUILD_LOGFILE}"; then
                    printf "\033[0;31mmake: Error: Build failed, check %s\033[0m\n" "${BUILD_LOGFILE}"
                    exit 1
                fi
            done
        done
        echo -e "\e[0;36mmake: Info: Build finished without errors, be sure to check logs if concerned. Thank you!\e[0;37m"
        echo -e "\e[0;35mmake: Info: Building Re-Malwack magisk module installer...\e[0;37m"
        lastestCommitNum="$(git rev-list --count HEAD)"
        lastestCommitHash="$(git rev-parse --short HEAD)"
        lastestVersion="$(grep version update.json | head -n 1 | awk '{print $2}' | sed 's/,//' | xargs)"
        sed -i "s/^version=.*/version=${lastestVersion}-lastest-commit-nebula (#${lastestCommitNum}-${lastestCommitHash})/" module/module.prop
        cd ./newExtendedModuleTemplateAdaptation/ || exit
        if ! zip -r "../Re-Malwack-Nebula.zip" . &>/dev/null; then
            git restore module/module.prop
            printf "\033[0;31mmake: Error: Failed to compress the module sources, please try again or install zip to proceed.\033[0m\n"
            exit 1
        fi
        cd ../
        git restore module/module.prop
        echo -e "\e[0;36mmake: Info: Build finished without errors\e[0;37m"
    elif [[ -n "${SDK}" && -n "${CC}" && "${lowerCaseArgument}" == *hoshiko* ]]; then
        IS_TARGET_SATISFIED=true;
        echo -e "\e[0;35mmake: Info: Building Hoshiko binaries...\e[0;37m"
        for i in $(seq 0 1); do
            if ! ${CC} ${CFLAGS} "${HOSHIKO_SOURCES}" -I"${HOSHIKO_HEADERS}" "${TARGETS[$i]}" -o "${OUTPUT_DIR}/${OUTPUT_BINARY_NAMES[$i]}" &> "${BUILD_LOGFILE}"; then
                printf "\033[0;31mmake: Error: Build failed, check %s\033[0m\n" "${BUILD_LOGFILE}"
                exit 1
            fi
        done
        echo -e "\e[0;36mmake: Info: Build finished without errors, be sure to check logs if concerned. Thank you!\e[0;37m"
    fi
done

if [ "${IS_TARGET_SATISFIED}" == "false" ]; then
	echo -e "\033[1;36mUsage:\033[0m make.sh [SDK=<level>] [ARCH=<arch>] <target>"
	echo ""
	echo -e "\033[1;36mTargets:\033[0m"
	echo -e "  \033[0;32mhoshiko\033[0m     Builds the essentials for the Hoshiko app"
	echo -e "  \033[0;32mmodule\033[0m     Builds the module zip package"
	echo -e "  \033[0;32mclean\033[0m       Removes build artifacts"
	echo -e "  \033[0;32mhelp\033[0m        Show this help message"
	echo ""
	echo -e "\033[1;36mExample:\033[0m"
	echo -e "  make.sh SDK=30 ARCH=arm64 \033[0;32mmodule\033[0m"
fi