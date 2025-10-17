#!/usr/bin/env bash

# shutt up
CC_ROOT="/home/ayumi/android-ndk-r27d/toolchains/llvm/prebuilt/linux-x86_64/bin"
CFLAGS="-std=c23 -O3 -static"
BUILD_LOGFILE="./module/mitsuha/build/logs/build.log"
OUTPUT_DIR="./module/mitsuha/build"
MITSUHA_HEADERS="./module/mitsuha/src/include"
MITSUHA_SOURCES="./module/mitsuha/src/include/daemon.c"
TARGETS=("./module/mitsuha/src/yuki/main.c" "./module/mitsuha/src/alya/main.c")
OUTPUT_BINARY_NAMES=("mitsuha-yuki" "mitsuha-alya")
SDK=""
CC=""

# just make the dir 
mkdir -p "$(dirname "${BUILD_LOGFILE}")" "${OUTPUT_DIR}"
for args in "$@"; do
    lowerCaseArgument=$(echo "${args}" | tr '[:upper:]' '[:lower:]')
    if [ "${lowerCaseArgument}" == "clean" ]; then
        rm -f ${BUILD_LOGFILE} ${OUTPUT_DIR}/mitsuha-*
	    echo -e "\033[0;32mmake: Info: Clean complete.\033[0m"
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
