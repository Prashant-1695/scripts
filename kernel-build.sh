#!/usr/bin/env bash

# Configure system
export TZ=Asia/Kolkata

# Specify compiler.
if [[ "$@" =~ "gcc" ]]; then
      # Specify compiler.
      COMPILER=gcc
      # Specify toolchain.
      TOOLCHAIN=gcc
      # Specify linker.
      LINKER=ld.bfd
elif [[ "$@" =~ "clang" ]]; then
        # Specify compiler.
        COMPILER=clang
        # Specify toolchain. 'clang' | 'proton-clang'(default) | 'aosp-clang'
        TOOLCHAIN=aosp-clang
        # Specify linker.
        LINKER=ld.lld
fi

# Set enviroment and vaiables
DATE="$(date +%d%m%Y-%H%M%S)"
CHATID="-1001659048493"
CI_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# The defult directory where the kernel should be placed.
KERNEL_DIR=$(pwd)

# The name of the Kernel, to name the ZIP.
ZIPNAME="aRise-HMP"

# The name of the device for which the kernel is built.
MODEL="Redmi Note 7"

# The codename of the device.
DEVICE="lavender"

# The version of the Kernel
VERSION=x1.0

# Set your anykernel3 repo and branch (Required)
AK3_REPO="ImPrashantt/AnyKernel3" BRANCH="lavender"

# The defconfig which should be used. Get it from config.gz from your device or check source
CONFIG="lavender-perf_defconfig"

# Generate a full DEFCONFIG prior building. 1 is YES | 0 is NO(default)
DEF_REG=0

# File/artifact
IMG=Image.gz-dtb

# Set ccache compilation. 1 = YES | 0 = NO(default)
KERNEL_USE_CCACHE=0

# Verbose build 0 is Quiet(default)) | 1 is verbose | 2 gives reason for rebuilding targets
VERBOSE=0

# Debug purpose. Send logs on every successfull builds. 1 is YES | 0 is NO(default)
DEBUG_LOG=0

# Check Kernel Version
KERVER=$(make kernelversion)

# Set a commit head
COMMIT_HEAD=$(git log --oneline -1)

# shellcheck source=/etc/os-release
DISTRO=$(source /etc/os-release && echo "${NAME}")

# Toolchain Directory defaults
GCC64_DIR=${KERNEL_DIR}/gcc64
GCC32_DIR=${KERNEL_DIR}/gcc32
CLANG_DIR=${KERNEL_DIR}/clang

# AnyKernel3 Directory default
AK3_DIR=${KERNEL_DIR}/anykernel3

#-----------------------------------------------------------#

function clone() {
    if [[ $COMPILER == "clang" ]]; then
         if [[ $TOOLCHAIN == "clang" ]]; then
              git clone --depth=1 https://github.com/theradcolor/clang clang
         elif [[ $TOOLCHAIN == "proton-clang" ]]; then
                git clone --depth=1 https://github.com/kdrag0n/proton-clang clang
         elif [[ $TOOLCHAIN == "aosp-clang" ]]; then
                git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 gcc64
                git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 gcc32
                mkdir clang
                cd clang || exit
                wget -q https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/clang-r416183.tar.gz
                tar -xzf clang*
                cd .. || exit
         fi
    elif [[ $COMPILER == "gcc" ]]; then
         if [[ $TOOLCHAIN == "gcc" ]]; then
              git clone --depth=1 https://github.com/mvaisakh/gcc-arm64.git -b gcc-new gcc64
              git clone --depth=1 https://github.com/mvaisakh/gcc-arm.git -b gcc-new gcc32
         fi
    fi
    if [ $AK3_REPO ]
    then
         git clone --depth=1 https://github.com/${AK3_REPO}.git -b ${BRANCH} anykernel3
    fi
}

#-----------------------------------------------------------#

# Export vaiables
export BOT_MSG_URL="https://api.telegram.org/bot${token}/sendMessage"
export BOT_BUILD_URL="https://api.telegram.org/bot${token}/sendDocument"

# Export ARCH <arm, arm64, x86, x86_64>
export ARCH=arm64

#Export SUBARCH <arm, arm64, x86, x86_64>
export SUBARCH=arm64

# Kbuild host and user
export KBUILD_BUILD_USER="ImPrashantt"
export KBUILD_BUILD_HOST="archlinux"
export KBUILD_JOBS="$(($(grep -c '^processor' /proc/cpuinfo) * 2))"
if [ "$CI" ]
then
	if [ "$CIRCLECI" ]
	then
		export KBUILD_BUILD_VERSION=${CIRCLE_BUILD_NUM}
		export CI_BRANCH=${CIRCLE_BRANCH}
	elif [ "$DRONE" ]
	then
		export KBUILD_BUILD_VERSION=${DRONE_BUILD_NUMBER}
		export CI_BRANCH=${DRONE_BRANCH}
	fi
fi
if [[ $KERNEL_USE_CCACHE == "1" ]]; then
	  export CCACHE_DIR="${KERNEL_DIR}/.ccache"
fi
if [ $VERSION ]
then
     # The version of the Kernel at end
     # if you don't need then disable it '#'
	 export LOCALVERSION="-${VERSION}"
fi

#-----------------------------------------------------------#

function setup() {
    if [[ $COMPILER == "clang" ]]; then
         export KBUILD_COMPILER_STRING=$(${CLANG_DIR}/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
         PATH=${CLANG_DIR}/bin/:$PATH
    elif [[ $COMPILER == "gcc" ]]; then
           export KBUILD_COMPILER_STRING=$(${GCC64_DIR}/bin/aarch64-elf-gcc --version | head -n 1)
           PATH=${GCC64_DIR}/bin/:${GCC32_DIR}/bin/:/usr/bin:$PATH
    fi
}

#-----------------------------------------------------------#

function post_msg() {
	curl -s -X POST "${BOT_MSG_URL}" \
    -d chat_id="${CHATID}" \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"
}

#-----------------------------------------------------------#

function post_file() {
    curl -F document=@$1 "${BOT_BUILD_URL}" \
        -F chat_id="${CHATID}"  \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="$2"
}

#-----------------------------------------------------------#

function compile() {
    post_msg "<b>$KBUILD_BUILD_VERSION CI Build Triggered</b>%0A<b>Docker OS : </b><code>$DISTRO</code>%0A<b>Kernel Version : </b><code>$KERVER</code>%0A<b>Date : </b><code>$(TZ=Asia/Kolkata date)</code>%0A<b>Device : </b><code>$MODEL [$DEVICE]</code>%0A<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>%0A<b>Linker : </b><code>$LINKER</code>%0a<b>Branch : </b><code>$CI_BRANCH</code>%0A<b>Top Commit : </b><a href='$DRONE_COMMIT_LINK'>$COMMIT_HEAD</a>"
    make O=out ${CONFIG}
    if [[ $DEF_REG == "1" ]]; then
		  cp .config arch/arm64/configs/${CONFIG}
		  git add arch/arm64/configs/${CONFIG}
		  git commit -m "${CONFIG}: Regenerate
						This is an auto-generated commit"
	fi
    BUILD_START=$(date +"%s")
    if [[ $COMPILER == "clang" ]]; then
		  make -kj"${KBUILD_JOBS}" O=out \
			        ARCH=arm64 \
			        CC=${COMPILER} \
			        CROSS_COMPILE=aarch64-linux-gnu- \
			        CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
			        LD=${LINKER} \
			        AR=llvm-ar \
			        NM=llvm-nm \
			        OBJCOPY=llvm-objcopy \
			        OBJDUMP=llvm-objdump \
			        STRIP=llvm-strip \
			        READELF=llvm-readelf \
			        OBJSIZE=llvm-size \
			        V=${VERBOSE} 2>&1 | tee build.log
	elif [[ $COMPILER == "gcc" ]]; then
			make -kj"${KBUILD_JOBS}" O=out \
			          ARCH=arm64 \
			          CROSS_COMPILE_ARM32=arm-eabi- \
			          CROSS_COMPILE=aarch64-elf- \
			          LD=aarch64-elf-${LINKER} \
			          AR=llvm-ar \
			          NM=llvm-nm \
			          OBJCOPY=llvm-objcopy \
			          OBJDUMP=llvm-objdump \
			          STRIP=llvm-strip \
			          OBJSIZE=llvm-size \
			          V=${VERBOSE} 2>&1 | tee build.log
	fi
    BUILD_END=$(date +"%s")
    DIFF=$(($BUILD_END - $BUILD_START))
    if ! [ -a "${KERNEL_DIR}"/out/arch/arm64/boot/${IMG} ]; then
          echo "Build failed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s)."
          post_file "build.log" "Build failed, please fix the errors first bish!"
          exit
    else
          echo "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s)."
          cp "${KERNEL_DIR}"/out/arch/arm64/boot/${IMG} ${AK3_DIR}
          finalize
    fi
}

#-----------------------------------------------------------#

function finalize() {
    echo "Now making a flashable zip of kernel with AnyKernel3"
    cd ${AK3_DIR} || exit
    zip -r9 ${ZIPNAME}-${VERSION}-${DEVICE}-"${DATE}" ./* -x .git modules patch ramdisk LICENSE README.md

    # Prepare a final zip variable
    FINAL_ZIP="${ZIPNAME}-${VERSION}-${DEVICE}-${DATE}.zip"

    #Post MD5Checksum alongwith for easeness
    MD5CHECK=$(md5sum "${FINAL_ZIP}" | cut -d' ' -f1)

    post_file "${FINAL_ZIP}" "Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | <b>MD5 Checksum : </b><code>$MD5CHECK</code> | Compiler : $KBUILD_COMPILER_STRING"
}

#-----------------------------------------------------------#

clone
setup
compile

#-----------------------------------------------------------#

if [[ $DEBUG_LOG == "1" ]]; then
	 post_file "build.log" "Debug Mode Logs"
fi

#-----------------------------------------------------------#
